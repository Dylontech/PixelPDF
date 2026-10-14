import 'package:flutter/material.dart';
import 'package:pixel_pvr/core/theme/pixel_colors.dart';

/// Lienzo donde se dibuja la firma con el dedo.
///
/// No guarda estado: los trazos los controla quien lo usa, de modo que puede
/// limpiarlos y rasterizarlos desde fuera.
class FirmaPad extends StatelessWidget {
  const FirmaPad({
    super.key,
    required this.trazos,
    required this.onInicio,
    required this.onPunto,
    required this.onFin,
  });

  final List<List<Offset>> trazos;
  final ValueChanged<Offset> onInicio;
  final ValueChanged<Offset> onPunto;
  final VoidCallback onFin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (detalle) => onInicio(detalle.localPosition),
      onPanUpdate: (detalle) => onPunto(detalle.localPosition),
      onPanEnd: (_) => onFin(),
      // Un toque suelto también deja un punto, para firmas con puntitos.
      onTapUp: (detalle) {
        onInicio(detalle.localPosition);
        onFin();
      },
      child: CustomPaint(
        painter: _TrazosPainter(trazos),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _TrazosPainter extends CustomPainter {
  const _TrazosPainter(this.trazos);

  final List<List<Offset>> trazos;

  @override
  void paint(Canvas canvas, Size size) {
    final linea = Paint()
      ..color = PixelColors.texto
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final trazo in trazos) {
      if (trazo.length == 1) {
        canvas.drawCircle(trazo.first, 1.5, Paint()..color = PixelColors.texto);
        continue;
      }
      final camino = Path()..moveTo(trazo.first.dx, trazo.first.dy);
      for (final punto in trazo.skip(1)) {
        camino.lineTo(punto.dx, punto.dy);
      }
      canvas.drawPath(camino, linea);
    }
  }

  // Los trazos se mutan dentro de la misma lista; repintar siempre es barato
  // (solo ocurre al mover el dedo) y evita comparaciones frágiles.
  @override
  bool shouldRepaint(covariant _TrazosPainter oldDelegate) => true;
}
