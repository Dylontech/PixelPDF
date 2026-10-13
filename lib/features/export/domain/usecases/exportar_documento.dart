import 'dart:typed_data';

import '../../../core/services/file_storage_service.dart';
import '../../../editor/data/services/image_processing_service.dart';
import '../../../vault/domain/entities/documento_escaneado.dart';
import '../../../vault/domain/repositories/documento_repository.dart';
import '../../data/services/pdf_export_service.dart';

/// Caso de uso: convierte → guarda archivo → guarda miniatura → registra.
class ExportarDocumento {
  ExportarDocumento({
    required this.repositorio,
    required this.almacenamiento,
    required this.imagen,
    required this.pdf,
  });

  final DocumentoRepository repositorio;
  final FileStorageService almacenamiento;
  final ImageProcessingService imagen;
  final PdfExportService pdf;

  Future<DocumentoEscaneado> call({
    required Uint8List imagenProcesada,
    required String nombre,
    required FormatoExportacion formato,
    required FiltroImagen filtro,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    Uint8List salida;
    if (formato == FormatoExportacion.pdf) {
      // El PDF se arma con un JPG dentro: el paquete `pdf` sólo acepta
      // imágenes en JPEG o PNG crudo, no cualquier PNG paletizado.
      final jpg = await imagen.codificar(
        imagenProcesada,
        FormatoExportacion.jpg,
      );
      salida = await pdf.crearPdf(jpg);
    } else {
      salida = await imagen.codificar(imagenProcesada, formato);
    }

    final rutaArchivo = await almacenamiento.guardar(
      '$id.${formato.extension}',
      salida,
    );
    final miniatura = await imagen.miniatura(imagenProcesada);
    final rutaMiniatura = await almacenamiento.guardar(
      '${id}_thumb.jpg',
      miniatura,
    );

    final documento = DocumentoEscaneado(
      id: id,
      nombre: nombre,
      creadoEn: DateTime.now(),
      rutaArchivo: rutaArchivo,
      rutaMiniatura: rutaMiniatura,
      formato: formato,
      filtro: filtro,
      tamanoBytes: salida.length,
    );
    await repositorio.guardar(documento);
    return documento;
  }
}
