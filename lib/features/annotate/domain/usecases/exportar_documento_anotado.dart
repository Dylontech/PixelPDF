import 'package:pixel_pvr/core/services/file_storage_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/pdf_anotado_service.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/pagina_documento.dart';
import 'package:pixel_pvr/features/editor/data/services/image_processing_service.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';
import 'package:pixel_pvr/features/vault/domain/repositories/documento_repository.dart';

/// Caso de uso: compone el PDF anotado, lo guarda y lo registra en el vault.
///
/// El documento de origen nunca se modifica: siempre se crea una copia nueva.
class ExportarDocumentoAnotado {
  ExportarDocumentoAnotado({
    required this.repositorio,
    required this.almacenamiento,
    required this.imagen,
    required this.pdf,
  });

  final DocumentoRepository repositorio;
  final FileStorageService almacenamiento;
  final ImageProcessingService imagen;
  final PdfAnotadoService pdf;

  Future<DocumentoEscaneado> call({
    required List<PaginaDocumento> paginas,
    required List<Anotacion> anotaciones,
    required String nombre,
  }) async {
    if (paginas.isEmpty) {
      throw StateError('No hay páginas que exportar');
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final salida = await pdf.componer(
      paginas: paginas,
      anotaciones: anotaciones,
      titulo: nombre,
    );
    final rutaArchivo = await almacenamiento.guardar('$id.pdf', salida);

    // La miniatura sale de la primera página para que la tarjeta del vault
    // muestre el documento anotado y no un icono roto.
    final miniatura = await imagen.miniatura(paginas.first.png);
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
      formato: FormatoExportacion.pdf,
      filtro: FiltroImagen.original,
      tamanoBytes: salida.length,
      paginas: paginas.length,
    );
    await repositorio.guardar(documento);
    return documento;
  }
}
