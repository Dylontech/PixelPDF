import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:pixel_pvr/features/annotate/domain/entities/pagina_documento.dart';
import 'package:printing/printing.dart';

/// Resolución a la que se rasterizan las páginas del PDF de entrada.
///
/// 140 dpi es un equilibrio: suficiente para leer y firmar en pantalla sin
/// llenar la memoria con documentos largos.
const double _dpiRasterizado = 140;

/// Convierte la fuente (PDF o imagen) en páginas PNG anotables.
class FuenteDocumentoService {
  const FuenteDocumentoService();

  /// PDF -> una página PNG por cada página del documento.
  ///
  /// `Printing.raster` usa el rasterizador del propio sistema (PdfRenderer en
  /// Android), así que sirve para cualquier PDF, no sólo para los que genera
  /// la app.
  Future<List<PaginaDocumento>> desdePdf(Uint8List bytes) async {
    final paginas = <PaginaDocumento>[];
    await for (final raster in Printing.raster(bytes, dpi: _dpiRasterizado)) {
      paginas.add(
        PaginaDocumento(
          png: await raster.toPng(),
          ancho: raster.width,
          alto: raster.height,
        ),
      );
    }
    return paginas;
  }

  /// JPG/PNG -> una única página (se normaliza a PNG, sin recortar).
  Future<List<PaginaDocumento>> desdeImagen(Uint8List bytes) async {
    final pagina = await compute(_normalizarImagen, bytes);
    return [pagina];
  }
}

PaginaDocumento _normalizarImagen(Uint8List bytes) {
  final decodificada = img.decodeImage(bytes);
  if (decodificada == null) throw Exception('Imagen no válida');
  final imagen = img.bakeOrientation(decodificada);
  return PaginaDocumento(
    png: Uint8List.fromList(img.encodePng(imagen)),
    ancho: imagen.width,
    alto: imagen.height,
  );
}
