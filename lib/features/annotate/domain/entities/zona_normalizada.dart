/// Rectángulo en coordenadas normalizadas (0..1) relativas a una página.
///
/// Se guarda normalizado y no en píxeles para que la anotación sobreviva al
/// zoom, al tamaño del lienzo en pantalla y a la resolución de exportación.
class ZonaNormalizada {
  const ZonaNormalizada({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  /// Tamaño mínimo de una anotación, para que nunca quede inalcanzable.
  static const double minimaDimension = 0.04;

  double get derecha => left + width;
  double get abajo => top + height;

  /// Desplaza la zona sin deformarla y sin salirse de la página.
  ZonaNormalizada desplazar(double dx, double dy) {
    final maxLeft = (1 - width).clamp(0.0, 1.0);
    final maxTop = (1 - height).clamp(0.0, 1.0);
    return ZonaNormalizada(
      left: (left + dx).clamp(0.0, maxLeft),
      top: (top + dy).clamp(0.0, maxTop),
      width: width,
      height: height,
    );
  }

  /// Cambia el tamaño arrastrando la esquina inferior derecha.
  ZonaNormalizada redimensionar(double dw, double dh) {
    final maxWidth = (1 - left).clamp(minimaDimension, 1.0);
    final maxHeight = (1 - top).clamp(minimaDimension, 1.0);
    return ZonaNormalizada(
      left: left,
      top: top,
      width: (width + dw).clamp(minimaDimension, maxWidth),
      height: (height + dh).clamp(minimaDimension, maxHeight),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ZonaNormalizada &&
      other.left == left &&
      other.top == top &&
      other.width == width &&
      other.height == height;

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() => 'ZonaNormalizada($left, $top, $width, $height)';
}
