import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';
import 'package:pixel_pvr/core/widgets/pixel_box.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/pagina_documento.dart';
import 'package:pixel_pvr/features/annotate/presentation/widgets/dialogos_anotacion.dart';

/// Arrastre expresado en unidades normalizadas de la página.
typedef DeltaCallback = void Function(double dx, double dy);

/// Muestra la página con sus anotaciones encima.
///
/// Las anotaciones se posicionan con coordenadas normalizadas (0..1) por lo que
/// se ven y se editan igual en cualquier tamaño de pantalla.
class LienzoAnotaciones extends StatelessWidget {
  const LienzoAnotaciones({
    super.key,
    required this.pagina,
    required this.anotaciones,
    required this.seleccionadaId,
    required this.onSeleccionar,
    required this.onMover,
    required this.onRedimensionar,
    required this.onEliminar,
  });

  final PaginaDocumento pagina;
  final List<Anotacion> anotaciones;
  final String? seleccionadaId;
  final ValueChanged<String?> onSeleccionar;
  final DeltaCallback onMover;
  final DeltaCallback onRedimensionar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, restricciones) {
        // Se descuentan los bordes/relleno/sombra del PixelBox para no
        // desbordar el hueco disponible.
        final disponibleAncho = restricciones.maxWidth.isFinite
            ? restricciones.maxWidth
            : pagina.ancho.toDouble();
        final disponibleAlto = restricciones.maxHeight.isFinite
            ? restricciones.maxHeight
            : pagina.alto.toDouble();
        final escala = math.max(
          0.0,
          math.min(
            (disponibleAncho - 24) / pagina.ancho,
            (disponibleAlto - 24) / pagina.alto,
          ),
        );
        final ancho = pagina.ancho * escala;
        final alto = pagina.alto * escala;

        return Center(
          child: PixelBox(
            color: Colors.black,
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: ancho,
              height: alto,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSeleccionar(null),
                      child: Image.memory(
                        pagina.png,
                        fit: BoxFit.fill,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                  for (final anotacion in anotaciones)
                    _AnotacionWidget(
                      anotacion: anotacion,
                      anchoPagina: ancho,
                      altoPagina: alto,
                      seleccionada: anotacion.id == seleccionadaId,
                      onSeleccionar: () => onSeleccionar(anotacion.id),
                      onMover: onMover,
                      onRedimensionar: onRedimensionar,
                      onEliminar: onEliminar,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AnotacionWidget extends StatelessWidget {
  const _AnotacionWidget({
    required this.anotacion,
    required this.anchoPagina,
    required this.altoPagina,
    required this.seleccionada,
    required this.onSeleccionar,
    required this.onMover,
    required this.onRedimensionar,
    required this.onEliminar,
  });

  final Anotacion anotacion;
  final double anchoPagina;
  final double altoPagina;
  final bool seleccionada;
  final VoidCallback onSeleccionar;
  final DeltaCallback onMover;
  final DeltaCallback onRedimensionar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final zona = anotacion.zona;
    final ancho = zona.width * anchoPagina;
    final alto = zona.height * altoPagina;

    return Positioned(
      left: zona.left * anchoPagina,
      top: zona.top * altoPagina,
      width: ancho,
      height: alto,
      child: Stack(
        children: [
          // El arrastre vive solo aquí, para no competir con los tiradores.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSeleccionar,
              onPanUpdate: (detalle) {
                if (!seleccionada) onSeleccionar();
                onMover(
                  detalle.delta.dx / anchoPagina,
                  detalle.delta.dy / altoPagina,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: seleccionada
                      ? Border.all(color: PixelColors.cian, width: 2)
                      : null,
                ),
                child: ClipRect(child: _contenido()),
              ),
            ),
          ),
          if (seleccionada) ...[
            Positioned(
              right: 0,
              top: 0,
              child: _Tirador(
                color: PixelColors.rojo,
                icon: Icons.close,
                onTap: onEliminar,
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: _Tirador(
                color: PixelColors.verde,
                icon: Icons.open_in_full,
                onDelta: (dx, dy) =>
                    onRedimensionar(dx / anchoPagina, dy / altoPagina),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _contenido() => switch (anotacion) {
    AnotacionTexto(:final texto, :final tamanoRelativo, :final color) => Align(
      alignment: Alignment.topLeft,
      child: Text(
        texto,
        style: TextStyle(
          color: colorDeAnotacion(color),
          fontSize: tamanoRelativo * altoPagina,
          height: 1.1,
        ),
      ),
    ),
    AnotacionFirma(:final png) => Image.memory(png, fit: BoxFit.contain),
  };
}

/// Cuadrado de agarre en la esquina de una anotación seleccionada.
class _Tirador extends StatelessWidget {
  const _Tirador({
    required this.color,
    required this.icon,
    this.onTap,
    this.onDelta,
  });

  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  final DeltaCallback? onDelta;

  @override
  Widget build(BuildContext context) {
    final arrastre = onDelta;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onPanUpdate: arrastre == null
          ? null
          : (detalle) => arrastre(detalle.delta.dx, detalle.delta.dy),
      child: Container(
        width: 22,
        height: 22,
        color: color,
        child: Icon(icon, size: 14, color: Colors.black),
      ),
    );
  }
}
