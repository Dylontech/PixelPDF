import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Archivo elegido por el usuario, ya cargado en memoria.
class ArchivoElegido {
  const ArchivoElegido({required this.nombre, required this.bytes});

  final String nombre;
  final Uint8List bytes;
}

/// Único punto de contacto con `file_picker`.
class ArchivosService {
  const ArchivosService();

  /// Devuelve `null` si el usuario cancela la selección.
  Future<ArchivoElegido?> elegir({
    required List<String> extensiones,
    required String titulo,
  }) async {
    final archivo = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: extensiones,
      dialogTitle: titulo,
    );
    if (archivo == null) return null;
    return ArchivoElegido(
      nombre: archivo.name,
      bytes: await archivo.readAsBytes(),
    );
  }
}
