import 'dart:typed_data';

/// Una página ya rasterizada a PNG, lista para mostrar y anotar.
class PaginaDocumento {
  const PaginaDocumento({
    required this.png,
    required this.ancho,
    required this.alto,
  });

  final Uint8List png;
  final int ancho;
  final int alto;

  double get relacionAspecto => alto == 0 ? 1 : ancho / alto;
}
