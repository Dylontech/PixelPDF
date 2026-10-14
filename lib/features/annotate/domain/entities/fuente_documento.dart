import 'dart:typed_data';

/// Formato del documento de entrada.
enum FormatoEntrada { pdf, imagen }

/// De dónde sale el documento que se va a anotar.
class FuenteDocumento {
  const FuenteDocumento._({
    required this.nombre,
    required this.formato,
    this.ruta,
    this.bytes,
  });

  /// Documento que ya vive en el vault: se lee de disco al abrir la pantalla.
  factory FuenteDocumento.deRuta({
    required String nombre,
    required String ruta,
    required FormatoEntrada formato,
  }) => FuenteDocumento._(nombre: nombre, formato: formato, ruta: ruta);

  /// PDF o imagen elegidos fuera del vault (importados con el selector).
  factory FuenteDocumento.deBytes({
    required String nombre,
    required FormatoEntrada formato,
    required Uint8List bytes,
  }) => FuenteDocumento._(nombre: nombre, formato: formato, bytes: bytes);

  final String nombre;
  final FormatoEntrada formato;
  final String? ruta;
  final Uint8List? bytes;

  static FormatoEntrada formatoDeNombre(String nombre) =>
      nombre.toLowerCase().endsWith('.pdf')
      ? FormatoEntrada.pdf
      : FormatoEntrada.imagen;
}
