import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

import '../../../core/services/compartir_service.dart';
import '../../../core/theme/pixel_colors.dart';
import '../../../core/theme/pixel_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/pixel_box.dart';
import '../../../core/widgets/pixel_button.dart';
import '../../../core/widgets/pixel_dialog.dart';
import '../../../export/domain/usecases/exportar_documento.dart';
import '../../../vault/domain/entities/documento_escaneado.dart';
import '../../data/services/image_processing_service.dart';
import '../viewmodels/editor_viewmodel.dart';

class EditorPage extends StatelessWidget {
  const EditorPage({super.key, required this.rutaImagen});

  final String rutaImagen;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditorViewModel>(
      create: (c) => EditorViewModel(
        rutaOriginal: rutaImagen,
        exportarDocumento: c.read<ExportarDocumento>(),
        procesamiento: c.read<ImageProcessingService>(),
      )..iniciar(),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView();

  Future<void> _recortar(BuildContext context, EditorViewModel vm) async {
    final recortado = await ImageCropper().cropImage(
      sourcePath: vm.rutaActual,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'AJUSTAR RECORTE',
          toolbarColor: PixelColors.fondo,
          toolbarWidgetColor: PixelColors.cian,
          backgroundColor: PixelColors.fondo,
          activeControlsWidgetColor: PixelColors.magenta,
          cropFrameColor: PixelColors.cian,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'AJUSTAR RECORTE', aspectRatioLockEnabled: false),
      ],
    );
    // Al recortar, la imagen base cambia y hay que recalcular los filtros.
    if (recortado != null) await vm.cargarDesdeRuta(recortado.path);
  }

  Future<void> _guardar(BuildContext context, EditorViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final compartir = context.read<CompartirService>();
    final origen = origenDeCompartir(context);

    final doc = await vm.exportar();
    if (doc == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'NO SE PUDO GUARDAR')),
      );
      return;
    }
    if (!context.mounted) return;

    await mostrarPixelDialogo(
      context,
      titulo: 'LEVEL CLEAR!',
      colorTitulo: PixelColors.verde,
      mensaje:
          'Guardado como ${doc.formato.etiqueta}\n${doc.nombre}\n${formatearTamano(doc.tamanoBytes)}',
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
            Navigator.of(context).pop(); // cierra el diálogo
            navigator.pop(); // vuelve al vault
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final ocupado = vm.procesando || vm.exportando;

    return Scaffold(
      appBar: AppBar(title: const Text('EDITOR')),
      body: SafeArea(
        child: Column(
          children: [
            // Vista previa
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: PixelBox(
                    color: Colors.black,
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (vm.vista != null)
                          InteractiveViewer(
                            maxScale: 5,
                            child: Image.memory(
                              vm.vista!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: vm.filtro == FiltroImagen.pixelArt
                                  ? FilterQuality.none
                                  : FilterQuality.medium,
                            ),
                          ),
                        if (vm.error != null && vm.vista == null)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              vm.error!,
                              textAlign: TextAlign.center,
                              style: PixelTheme.titulo(
                                size: 10,
                                color: PixelColors.rojo,
                              ),
                            ),
                          ),
                        if (ocupado)
                          Positioned.fill(
                            child: ColoredBox(
                              color: Colors.black54,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 12),
                                  Text(
                                    vm.exportando
                                        ? 'GUARDANDO...'
                                        : 'CARGANDO...',
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
              ),
            ),

            // Filtros
            _Seccion(
              titulo: 'FILTRO',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in FiltroImagen.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _PixelChip(
                          label: f.etiqueta,
                          seleccionado: vm.filtro == f,
                          onTap: ocupado ? null : () => vm.seleccionarFiltro(f),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Formato
            _Seccion(
              titulo: 'FORMATO',
              child: Row(
                children: [
                  for (final f in FormatoExportacion.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _PixelChip(
                          label: f.etiqueta,
                          seleccionado: vm.formato == f,
                          onTap: ocupado
                              ? null
                              : () => vm.seleccionarFormato(f),
                          expandido: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Acciones
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'RECORTAR',
                      icon: Icons.crop,
                      color: PixelColors.amarillo,
                      expanded: true,
                      onPressed: ocupado ? null : () => _recortar(context, vm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PixelButton(
                      label: 'GUARDAR',
                      icon: Icons.save,
                      color: PixelColors.magenta,
                      expanded: true,
                      onPressed: ocupado || vm.vista == null
                          ? null
                          : () => _guardar(context, vm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: PixelTheme.titulo(size: 8, color: PixelColors.textoSuave),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PixelChip extends StatelessWidget {
  const _PixelChip({
    required this.label,
    required this.seleccionado,
    required this.onTap,
    this.expandido = false,
  });

  final String label;
  final bool seleccionado;
  final VoidCallback? onTap;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final fondo = seleccionado ? PixelColors.cian : PixelColors.superficie;
    final texto = seleccionado ? Colors.black : PixelColors.texto;

    return Semantics(
      button: true,
      selected: seleccionado,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: PixelBox(
          color: fondo,
          pixel: 3,
          shadow: seleccionado ? 0 : 3,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: expandido
              ? Center(
                  child: Text(
                    label,
                    style: PixelTheme.titulo(size: 9, color: texto),
                  ),
                )
              : Text(label, style: PixelTheme.titulo(size: 9, color: texto)),
        ),
      ),
    );
  }
}
