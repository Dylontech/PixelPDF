import 'package:flutter/material.dart';

import '../theme/pixel_colors.dart';

/// Contenedor con esquinas "escalonadas", borde grueso y sombra dura offset.
/// Es la pieza base de toda la UI (tarjetas, botones, diálogos, chips).
class PixelBox extends StatelessWidget {
  const PixelBox({
    super.key,
    required this.child,
    this.color = PixelColors.superficie,
    this.borderColor = PixelColors.borde,
    this.pixel = 4,
    this.shadow = 4,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  /// Tamaño del "píxel" (profundidad del escalón de las esquinas).
  final double pixel;

  /// Desplazamiento de la sombra dura (0 = sin sombra).
  final double shadow;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: shadow, bottom: shadow),
      child: CustomPaint(
        painter: _PixelBoxPainter(
          color: color,
          borderColor: borderColor,
          pixel: pixel,
          shadow: shadow,
        ),
        child: Padding(padding: padding + EdgeInsets.all(pixel), child: child),
      ),
    );
  }
}

class _PixelBoxPainter extends CustomPainter {
  _PixelBoxPainter({
    required this.color,
    required this.borderColor,
    required this.pixel,
    required this.shadow,
  });

  final Color color;
  final Color borderColor;
  final double pixel;
  final double shadow;

  Path _escalon(Rect r, double n) => Path()
    ..moveTo(r.left + n, r.top)
    ..lineTo(r.right - n, r.top)
    ..lineTo(r.right - n, r.top + n)
    ..lineTo(r.right, r.top + n)
    ..lineTo(r.right, r.bottom - n)
    ..lineTo(r.right - n, r.bottom - n)
    ..lineTo(r.right - n, r.bottom)
    ..lineTo(r.left + n, r.bottom)
    ..lineTo(r.left + n, r.bottom - n)
    ..lineTo(r.left, r.bottom - n)
    ..lineTo(r.left, r.top + n)
    ..lineTo(r.left + n, r.top + n)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _escalon(Offset.zero & size, pixel);
    if (shadow > 0) {
      canvas.drawPath(
        path.shift(Offset(shadow, shadow)),
        Paint()
          ..isAntiAlias = false
          ..color = PixelColors.sombra,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = false
        ..color = color,
    );
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.stroke
        ..strokeWidth = pixel / 2
        ..strokeJoin = StrokeJoin.miter
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelBoxPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.pixel != pixel ||
      old.shadow != shadow;
}
