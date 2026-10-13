import 'package:cross_file/cross_file.dart';
import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

/// Único punto de contacto con la API de `share_plus`.
///
/// Aislarlo tiene un motivo práctico: `share_plus` cambió su API pública
/// (`Share.shareXFiles` quedó deprecado en favor de `SharePlus.instance.share`).
/// Si hay que bajar de 13.x a 10.x porque el SDK de Flutter instalado es
/// antiguo, este es el único archivo que hay que tocar.
class CompartirService {
  const CompartirService();

  Future<void> compartirArchivo({
    required String ruta,
    required String nombre,
    Rect? origen,
  }) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(ruta)],
        text: nombre,
        // En iPad la hoja de compartir es un popover que se ancla a un
        // rectángulo; sin esto aparece centrado y puede quedar descolgado.
        sharePositionOrigin: origen,
      ),
    );
  }
}

/// Rectángulo global del widget que dispara la acción, para anclar el popover.
Rect? origenDeCompartir(BuildContext context) {
  final objeto = context.findRenderObject();
  if (objeto is! RenderBox || !objeto.hasSize) return null;
  return objeto.localToGlobal(Offset.zero) & objeto.size;
}
