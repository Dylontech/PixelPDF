import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/compartir_service.dart';
import '../../../core/theme/pixel_colors.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pixel_box.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_dialog.dart';
import '../../../core/widgets/pixel_fab.dart';
import '../../../editor/presentation/pages/editor_page.dart';
import '../../../scanner/data/services/escaner_service.dart';
import '../../domain/entities/documento_escaneado.dart';
import '../viewmodels/vault_viewmodel.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  Future<void> _escanear(BuildContext context) async {
    // Se capturan antes del await: el context puede haberse desmontado cuando
    // el escáner nativo devuelve el control.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final escaner = context.read<EscanerService>();
    final vault = context.read<VaultViewModel>();

    try {
      final ruta = await escaner.capturar();
      if (ruta == null) return; // el usuario canceló: no es un error
      await navigator.push(
        MaterialPageRoute<void>(builder: (_) => EditorPage(rutaImagen: ruta)),
      );
      await vault.cargar();
    } on EscanerExcepcion catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            e.permisoDenegado
                ? 'PERMISO DE CAMARA DENEGADO'
                : 'NO SE PUDO ABRIR LA CAMARA',
          ),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('NO SE PUDO ABRIR LA CAMARA')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaultViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('PIXEL VAULT')),
      floatingActionButton: PixelFab(onPressed: () => _escanear(context)),
      body: SafeArea(
        child: vm.cargando
            ? const Center(child: CircularProgressIndicator())
            : vm.error != null
            ? _MensajeError(mensaje: vm.error!)
            : vm.documentos.isEmpty
            ? const _EstadoVacio()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'DOCS x${vm.documentos.length}',
                          style: PixelTheme.titulo(
                            size: 10,
                            color: PixelColors.amarillo,
                          ),
                        ),
                        Text(
                          'HI-SCORE: ${vm.documentos.length * 100}',
                          style: PixelTheme.cuerpo(
                            size: 20,
                            color: PixelColors.verde,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                      itemCount: vm.documentos.length,
                      itemBuilder: (_, i) =>
                          _TarjetaDocumento(doc: vm.documentos[i]),
                    ),
                  ),
                ],
              ),
      ),
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
                label: 'REINTENTAR',
                icon: Icons.refresh,
                onPressed: () => context.read<VaultViewModel>().cargar(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

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
                'INSERT COIN',
                style: PixelTheme.titulo(size: 14, color: PixelColors.amarillo),
              ),
              const SizedBox(height: 16),
              const Icon(
                Icons.sports_esports,
                size: 56,
                color: PixelColors.magenta,
              ),
              const SizedBox(height: 16),
              Text(
                'Tu vault esta vacio.\nPulsa el boton de abajo para\nescanear tu primer documento.',
                textAlign: TextAlign.center,
                style: PixelTheme.cuerpo(size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaDocumento extends StatelessWidget {
  const _TarjetaDocumento({required this.doc});

  final DocumentoEscaneado doc;

  Future<void> _abrirMenu(BuildContext context) async {
    final vault = context.read<VaultViewModel>();
    final compartir = context.read<CompartirService>();
    final origen = origenDeCompartir(context);

    await mostrarPixelDialogo(
      context,
      titulo: 'OPCIONES',
      colorTitulo: PixelColors.cian,
      mensaje:
          '${doc.nombre}\n${doc.formato.etiqueta} · ${formatearTamano(doc.tamanoBytes)}',
      acciones: [
        PixelButton(
          label: 'COMPARTIR',
          icon: Icons.share,
          color: PixelColors.cian,
          onPressed: () async {
            Navigator.of(context).pop();
            await compartir.compartirArchivo(
              ruta: doc.rutaArchivo,
              nombre: doc.nombre,
              origen: origen,
            );
          },
        ),
        PixelButton(
          label: 'BORRAR',
          icon: Icons.delete,
          color: PixelColors.rojo,
          onPressed: () async {
            Navigator.of(context).pop();
            await vault.eliminar(doc);
          },
        ),
        PixelButton(
          label: 'CERRAR',
          color: PixelColors.superficieAlta,
          textColor: PixelColors.texto,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (doc.formato) {
      FormatoExportacion.pdf => PixelColors.magenta,
      FormatoExportacion.jpg => PixelColors.amarillo,
      FormatoExportacion.png => PixelColors.verde,
    };

    return GestureDetector(
      onTap: () => _abrirMenu(context),
      child: PixelBox(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Image.file(
                  File(doc.rutaMiniatura),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: PixelColors.textoSuave,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doc.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PixelTheme.titulo(size: 8),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: color,
                  child: Text(
                    doc.formato.etiqueta,
                    style: PixelTheme.cuerpo(size: 16, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatearFecha(doc.creadoEn).split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    style: PixelTheme.cuerpo(
                      size: 16,
                      color: PixelColors.textoSuave,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
