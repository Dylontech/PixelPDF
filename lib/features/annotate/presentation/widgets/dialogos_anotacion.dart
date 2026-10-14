import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/services/archivos_service.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/widgets/pixel_box.dart';
import 'package:pixel_pvr/core/widgets/pixel_button.dart';
import 'package:pixel_pvr/features/annotate/data/services/firma_service.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/presentation/widgets/firma_pad.dart';

/// Firma lista para colocar en la página.
class FirmaCapturada {
  const FirmaCapturada({required this.png, required this.relacionAspecto});

  final Uint8List png;
  final double relacionAspecto;
}

/// Texto y color elegidos por el usuario.
class TextoCapturado {
  const TextoCapturado({required this.texto, required this.color});

  final String texto;
  final ColorAnotacion color;
}

/// Diálogo de firma: dibujar a mano o importar una imagen.
///
/// Devuelve `null` si el usuario cancela. Se usan formularios propios y no
/// `prompt`/`confirm`, que no funcionan de forma fiable en el navegador
/// integrado ni en todas las plataformas.
Future<FirmaCapturada?> mostrarDialogoFirma(
  BuildContext context, {
  required FirmaService firma,
  required ArchivosService archivos,
}) => showDialog<FirmaCapturada>(
  context: context,
  barrierColor: Colors.black87,
  builder: (_) => _DialogoFirma(firma: firma, archivos: archivos),
);

/// Diálogo para escribir un cuadro de texto y elegir su color.
Future<TextoCapturado?> mostrarDialogoTexto(BuildContext context) =>
    showDialog<TextoCapturado>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const _DialogoTexto(),
    );

/// El controlador vive en el State del diálogo: si se liberase al volver de
/// `showDialog`, el campo seguiría reconstruyéndose durante la animación de
/// cierre y se usaría ya liberado.
class _DialogoTexto extends StatefulWidget {
  const _DialogoTexto();

  @override
  State<_DialogoTexto> createState() => _DialogoTextoState();
}

class _DialogoTextoState extends State<_DialogoTexto> {
  final TextEditingController _controlador = TextEditingController();
  ColorAnotacion _color = ColorAnotacion.negro;

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PixelBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NUEVO TEXTO',
              style: PixelTheme.titulo(size: 12, color: PixelColors.amarillo),
            ),
            const SizedBox(height: 12),
            PixelBox(
              color: PixelColors.superficieAlta,
              pixel: 2,
              shadow: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: _controlador,
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                style: PixelTheme.cuerpo(size: 22),
                cursorColor: PixelColors.cian,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Escribe aqui...',
                  hintStyle: TextStyle(color: PixelColors.textoSuave),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'COLOR',
              style: PixelTheme.titulo(size: 8, color: PixelColors.textoSuave),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final opcion in ColorAnotacion.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _MuestraColor(
                      color: opcion,
                      seleccionado: _color == opcion,
                      onTap: () => setState(() => _color = opcion),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PixelButton(
                  label: 'CANCELAR',
                  color: PixelColors.superficieAlta,
                  textColor: PixelColors.texto,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                PixelButton(
                  label: 'ANADIR',
                  icon: Icons.check,
                  color: PixelColors.verde,
                  onPressed: () => Navigator.of(context).pop(
                    TextoCapturado(texto: _controlador.text, color: _color),
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

class _DialogoFirma extends StatefulWidget {
  const _DialogoFirma({required this.firma, required this.archivos});

  final FirmaService firma;
  final ArchivosService archivos;

  @override
  State<_DialogoFirma> createState() => _DialogoFirmaState();
}

class _DialogoFirmaState extends State<_DialogoFirma> {
  final List<List<Offset>> _trazos = [];
  bool _ocupado = false;

  void _iniciar(Offset punto) => setState(() => _trazos.add([punto]));

  void _ampliar(Offset punto) {
    if (_trazos.isEmpty) return;
    setState(() => _trazos.last.add(punto));
  }

  Future<void> _usar() async {
    setState(() => _ocupado = true);
    final resultado = await widget.firma.rasterizar(_trazos);
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (resultado == null) return;
    Navigator.of(context).pop(
      FirmaCapturada(
        png: resultado.png,
        relacionAspecto: resultado.relacionAspecto,
      ),
    );
  }

  Future<void> _importar() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final archivo = await widget.archivos.elegir(
      extensiones: ['png', 'jpg', 'jpeg'],
      titulo: 'Elige tu firma',
    );
    if (archivo == null) return;

    setState(() => _ocupado = true);
    try {
      final resultado = await widget.firma.normalizarImagen(archivo.bytes);
      if (!mounted) return;
      navigator.pop(
        FirmaCapturada(
          png: resultado.png,
          relacionAspecto: resultado.relacionAspecto,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _ocupado = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('NO SE PUDO LEER ESA IMAGEN')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PixelBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TU FIRMA',
              style: PixelTheme.titulo(size: 12, color: PixelColors.cian),
            ),
            const SizedBox(height: 8),
            Text(
              'Dibuja con el dedo o importa una imagen.',
              style: PixelTheme.cuerpo(size: 20, color: PixelColors.textoSuave),
            ),
            const SizedBox(height: 12),
            PixelBox(
              color: Colors.black,
              pixel: 2,
              shadow: 0,
              padding: const EdgeInsets.all(2),
              child: SizedBox(
                width: 300,
                height: 150,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FirmaPad(
                        trazos: _trazos,
                        onInicio: _iniciar,
                        onPunto: _ampliar,
                        onFin: () {},
                      ),
                    ),
                    if (_ocupado)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black54,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                PixelButton(
                  label: 'LIMPIAR',
                  icon: Icons.cleaning_services,
                  color: PixelColors.superficieAlta,
                  textColor: PixelColors.texto,
                  onPressed: _ocupado ? null : () => setState(_trazos.clear),
                ),
                PixelButton(
                  label: 'IMPORTAR',
                  icon: Icons.image,
                  color: PixelColors.amarillo,
                  onPressed: _ocupado ? null : _importar,
                ),
                PixelButton(
                  label: 'USAR FIRMA',
                  icon: Icons.check,
                  color: PixelColors.verde,
                  onPressed: _ocupado || _trazos.isEmpty ? null : _usar,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MuestraColor extends StatelessWidget {
  const _MuestraColor({
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  final ColorAnotacion color;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Color ${color.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: colorDeAnotacion(color),
            border: Border.all(
              color: seleccionado ? PixelColors.cian : PixelColors.borde,
              width: seleccionado ? 3 : 1,
            ),
          ),
        ),
      ),
    );
  }
}

/// Color con el que se pinta cada opción (compartido con el lienzo).
Color colorDeAnotacion(ColorAnotacion color) => switch (color) {
  ColorAnotacion.negro => Colors.black,
  ColorAnotacion.azul => const Color(0xFF1543C4),
  ColorAnotacion.rojo => const Color(0xFFC62828),
};
