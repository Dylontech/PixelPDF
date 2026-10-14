import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart'
    show MissingPluginException, PlatformException;

/// Abstracción del escáner: permite cambiar el motor (ML Kit, OpenCV, etc.)
/// sin afectar presentación ni dominio.
abstract class EscanerService {
  /// Devuelve la ruta de la imagen recortada o null si el usuario cancela.
  Future<String?> capturar();
}

/// Error del escáner ya traducido a algo que la UI puede explicar.
class EscanerExcepcion implements Exception {
  const EscanerExcepcion(this.mensaje, {this.permisoDenegado = false});

  final String mensaje;
  final bool permisoDenegado;

  @override
  String toString() => 'EscanerExcepcion: $mensaje';
}

/// Usa el escáner nativo (ML Kit en Android / VisionKit en iOS): detección
/// automática de bordes, corrección de perspectiva y recorte, con ajuste
/// manual de esquinas dentro de su propia interfaz.
class NativoEscanerService implements EscanerService {
  @override
  Future<String?> capturar() async {
    try {
      final rutas = await CunningDocumentScanner.getPictures(
        noOfPages: 1,
        // `isGalleryImportAllowed` está deprecado desde 2.5.0.
        scannerSource: ScannerSource.cameraAndGallery,
      );
      if (rutas == null || rutas.isEmpty) return null;
      return rutas.first;
    } on ArgumentError catch (e) {
      throw EscanerExcepcion('Argumentos inválidos del escáner: $e');
    } on CunningDocumentScannerException catch (e) {
      // El plugin informa del rechazo de cámara con este código.
      throw EscanerExcepcion(
        e.message,
        permisoDenegado: e.code == 'permission_denied',
      );
    } on PlatformException catch (e) {
      // Errores del lado nativo (ML Kit, Play Services, permisos...). Si no se
      // traducen, la UI solo puede decir "no se pudo abrir la cámara" y el
      // motivo real se pierde.
      throw EscanerExcepcion(
        e.message ?? e.code,
        permisoDenegado: e.code.toLowerCase().contains('permission'),
      );
    } on MissingPluginException {
      // Sintoma tipico de una build de release con el plugin no disponible.
      throw const EscanerExcepcion(
        'El escaner nativo no esta disponible en esta instalacion',
      );
    }
  }
}
