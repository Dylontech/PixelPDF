import 'package:url_launcher/url_launcher.dart';

/// Único punto de contacto con `url_launcher`.
///
/// Aislarlo permite sustituirlo en pruebas y cambiar de paquete sin tocar la
/// interfaz.
class EnlacesService {
  const EnlacesService();

  /// Devuelve `false` si la URL es inválida o el sistema no puede abrirla.
  Future<bool> abrir(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
