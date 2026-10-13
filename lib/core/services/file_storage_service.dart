import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Lectura/escritura de los archivos que produce la app.
///
/// Todo vive en `<documentos de la app>/pixel_vault/`:
///   `<id>.pdf|jpg|png`  -> archivo final
///   `<id>_thumb.jpg`    -> miniatura del vault
class FileStorageService {
  Future<Directory> _directorio() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/pixel_vault');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Guarda bytes en el directorio de la app y devuelve la ruta absoluta.
  Future<String> guardar(String nombreArchivo, Uint8List bytes) async {
    final dir = await _directorio();
    final archivo = File('${dir.path}/$nombreArchivo');
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo.path;
  }

  Future<void> borrarSiExiste(String ruta) async {
    final f = File(ruta);
    if (await f.exists()) await f.delete();
  }
}
