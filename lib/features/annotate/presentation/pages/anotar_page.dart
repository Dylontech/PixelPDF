import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/services/archivos_service.dart';
import 'package:pixel_pvr/core/services/compartir_service.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/utils/formatters.dart';
import 'package:pixel_pvr/core/widgets/pixel_box.dart';
import 'package:pixel_pvr/core/widgets/pixel_button.dart';
import 'package:pixel_pvr/core/widgets/pixel_dialog.dart';
import 'package:pixel_pvr/features/annotate/data/services/firma_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/fuente_documento_service.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/fuente_documento.dart';
import 'package:pixel_pvr/features/annotate/domain/usecases/exportar_documento_anotado.dart';
import 'package:pixel_pvr/features/annotate/presentation/viewmodels/anotar_viewmodel.dart';
import 'package:pixel_pvr/features/annotate/presentation/widgets/dialogos_anotacion.dart';
import 'package:pixel_pvr/features/annotate/presentation/widgets/lienzo_anotaciones.dart';
import 'package:pixel_pvr/features/vault/presentation/viewmodels/vault_viewmodel.dart';
import 'package:provider/provider.dart';

/// Pantalla para firmar y escribir sobre un documento (PDF o imagen).
///
/// Siempre guarda una copia nueva: el documento de origen no se modifica.
class AnotarPage extends StatelessWidget {
  const AnotarPage({super.key, required this.fuente});

  final FuenteDocumento fuente;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AnotarViewModel>(
      create: (c) => AnotarViewModel(
        fuente: fuente,
        fuenteService: c.read<FuenteDocumentoService>(),
        exportar: c.read<ExportarDocumentoAnotado>(),
        firma: c.read<FirmaService>(),
      )..cargar(),
      child: const _AnotarView(),
    );
  }
}

class _AnotarView extends StatelessWidget {
  const _AnotarView();

  Future<void> _agregarFirma(BuildContext context) async {
    final vm = context.read<AnotarViewModel>();
    final archivos = context.read<ArchivosService>();
    final capturada = await mostrarDialogoFirma(
      context,
      firma: vm.firma,
      archivos: archivos,
    );
    if (capturada == null) return;
    vm.agregarFirma(capturada.png, capturada.relacionAspecto);
  }

  Future<void> _agregarTexto(BuildContext context) async {
    final vm = context.read<AnotarViewModel>();
    final capturado = await mostrarDialogoTexto(context);
    if (capturado == null) return;
    vm.agregarTexto(capturado.texto, color: capturado.color);
  }

  Future<void> _guardar(BuildContext context) async {
    final vm = context.read<AnotarViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final vault = context.read<VaultViewModel>();
    final compartir = context.read<CompartirService>();
    final origen = origenDeCompartir(context);

    final doc = await vm.exportar();
    if (doc == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'NO SE PUDO GUARDAR')),
      );
      return;
    }
    await vault.cargar();
    if (!context.mounted) return;

    await mostrarPixelDialogo(
      context,
      titulo: 'LEVEL CLEAR!',
      colorTitulo: PixelColors.verde,
      mensaje:
          'PDF firmado con ${vm.anotaciones.length} anotacion(es)\n'
          '${doc.nombre}\n${formatearTamano(doc.tamanoBytes)}',
      acciones: [
        PixelButton(
          label: 'COMPARTIR',
          icon: Icons.share,
          color: PixelColors.cian,
          onPressed: () => compartir.compartirArchivo(
            ruta: doc.rutaArchivo,
            nombre: doc.nombre,
            origen: origen,
          ),
        ),
        PixelButton(
          label: 'OK',
          color: PixelColors.verde,
          onPressed: () {
            Navigator.of(context).pop();
            navigator.pop();
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AnotarViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('FIRMA + TEXTO'),
        actions: [
          IconButton(
            tooltip: 'Deshacer',
            icon: const Icon(Icons.undo),
            onPressed: vm.puedeDeshacer && !vm.ocupado ? vm.deshacer : null,
          ),
        ],
      ),
      body: SafeArea(
        child: vm.cargando
            ? const Center(child: CircularProgressIndicator())
            : vm.error != null
            ? _MensajeError(mensaje: vm.error!)
            : _contenido(context, vm),
      ),
    );
  }

  Widget _contenido(BuildContext context, AnotarViewModel vm) {
    final pagina = vm.paginas[vm.paginaActual];
    final seleccion = vm.seleccionada;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Stack(
              children: [
                Positioned.fill(
                  child: LienzoAnotaciones(
                    pagina: pagina,
                    anotaciones: vm.anotacionesPagina,
                    seleccionadaId: vm.seleccionadaId,
                    onSeleccionar: vm.seleccionar,
                    onMover: vm.moverSeleccion,
                    onRedimensionar: vm.redimensionarSeleccion,
                    onEliminar: vm.eliminarSeleccion,
                  ),
                ),
                if (vm.ocupado)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black54,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 12),
                          Text(
                            vm.exportando ? 'GUARDANDO...' : 'CARGANDO...',
                            style: PixelTheme.titulo(
                              size: 10,
                              color: PixelColors.cian,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Navegación entre páginas del documento.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              PixelButton(
                label: 'ANT',
                icon: Icons.chevron_left,
                color: PixelColors.superficieAlta,
                textColor: PixelColors.texto,
                onPressed: vm.hayPaginaAnterior && !vm.ocupado
                    ? () => vm.irPagina(vm.paginaActual - 1)
                    : null,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    'PAGINA ${vm.paginaActual + 1}/${vm.totalPaginas}',
                    style: PixelTheme.titulo(
                      size: 9,
                      color: PixelColors.amarillo,
                    ),
                  ),
                ),
              ),
              PixelButton(
                label: 'SIG',
                icon: Icons.chevron_right,
                color: PixelColors.superficieAlta,
                textColor: PixelColors.texto,
                onPressed: vm.hayPaginaSiguiente && !vm.ocupado
                    ? () => vm.irPagina(vm.paginaActual + 1)
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Herramientas de anotación.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'FIRMA',
                  icon: Icons.draw,
                  color: PixelColors.cian,
                  expanded: true,
                  onPressed: vm.ocupado ? null : () => _agregarFirma(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PixelButton(
                  label: 'TEXTO',
                  icon: Icons.text_fields,
                  color: PixelColors.amarillo,
                  expanded: true,
                  onPressed: vm.ocupado ? null : () => _agregarTexto(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PixelButton(
                  label: 'BORRAR',
                  icon: Icons.delete,
                  color: PixelColors.rojo,
                  expanded: true,
                  onPressed: vm.ocupado || seleccion == null
                      ? null
                      : vm.eliminarSeleccion,
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: PixelButton(
            label: 'GUARDAR PDF',
            icon: Icons.save,
            color: PixelColors.magenta,
            expanded: true,
            onPressed: vm.ocupado ? null : () => _guardar(context),
          ),
        ),
      ],
    );
  }
}

class _MensajeError extends StatelessWidget {
  const _MensajeError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PixelBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME OVER',
                style: PixelTheme.titulo(size: 14, color: PixelColors.rojo),
              ),
              const SizedBox(height: 12),
              Text(
                mensaje,
                textAlign: TextAlign.center,
                style: PixelTheme.cuerpo(size: 20),
              ),
              const SizedBox(height: 16),
              PixelButton(
                label: 'VOLVER',
                icon: Icons.arrow_back,
                color: PixelColors.superficieAlta,
                textColor: PixelColors.texto,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
