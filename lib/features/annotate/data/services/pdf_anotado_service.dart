import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/pagina_documento.dart';

/// Compone el PDF final: cada página rasterizada con sus anotaciones encima.
///
/// Limitación asumida y documentada: las páginas de salida van como imagen, el
/// PDF resultante no conserva el texto seleccionable del original. A cambio, el
/// resultado se ve exactamente igual que la vista previa y funciona con
/// cualquier PDF de entrada.
class PdfAnotadoService {
  const PdfAnotadoService();

  /// Ancho de referencia de la página de salida en puntos (A4). El alto se
  /// calcula con la proporción real de cada página.
  static const double anchoPaginaPt = 595.28;

  Future<Uint8List> componer({
    required List<PaginaDocumento> paginas,
    required List<Anotacion> anotaciones,
    required String titulo,
  }) async {
    final documento = pw.Document(title: titulo, creator: 'PixelPDF');

    for (var i = 0; i < paginas.length; i++) {
      final pagina = paginas[i];
      final altoPt = anchoPaginaPt / pagina.relacionAspecto;
      final imagen = pw.MemoryImage(pagina.png);

      documento.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(anchoPaginaPt, altoPt),
          margin: pw.EdgeInsets.zero,
          build: (_) => pw.Stack(
            children: [
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Image(
                  imagen,
                  width: anchoPaginaPt,
                  height: altoPt,
                  fit: pw.BoxFit.fill,
                ),
              ),
              for (final anotacion in anotaciones)
                if (anotacion.pagina == i) _widget(anotacion, altoPt),
            ],
          ),
        ),
      );
    }

    return documento.save();
  }

  pw.Widget _widget(Anotacion anotacion, double altoPt) {
    final zona = anotacion.zona;

    return pw.Positioned(
      left: zona.left * anchoPaginaPt,
      top: zona.top * altoPt,
      child: switch (anotacion) {
        AnotacionTexto(:final texto, :final tamanoRelativo, :final color) =>
          pw.Container(
            width: zona.width * anchoPaginaPt,
            height: zona.height * altoPt,
            alignment: pw.Alignment.topLeft,
            child: pw.Text(
              texto,
              style: pw.TextStyle(
                font: pw.Font.helvetica(),
                fontSize: tamanoRelativo * altoPt,
                color: _colorPdf(color),
              ),
            ),
          ),
        AnotacionFirma(:final png) => pw.Image(
          pw.MemoryImage(png),
          width: zona.width * anchoPaginaPt,
          height: zona.height * altoPt,
          fit: pw.BoxFit.contain,
        ),
      },
    );
  }

  PdfColor _colorPdf(ColorAnotacion color) => switch (color) {
    ColorAnotacion.negro => PdfColors.black,
    ColorAnotacion.azul => PdfColors.blue800,
    ColorAnotacion.rojo => PdfColors.red800,
  };
}
