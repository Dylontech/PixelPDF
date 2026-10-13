import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfExportService {
  /// Genera un PDF A4 con la imagen centrada y ajustada (sin deformarla).
  Future<Uint8List> crearPdf(Uint8List jpgBytes) async {
    final documento = pw.Document(title: 'PixelPDF', creator: 'PixelPDF');
    final imagen = pw.MemoryImage(jpgBytes);

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (_) =>
            pw.Center(child: pw.Image(imagen, fit: pw.BoxFit.contain)),
      ),
    );

    return documento.save();
  }
}
