import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Offset;
import 'package:image/image.dart' as img;
import 'package:pixel_pvr/core/services/archivos_service.dart';
import 'package:pixel_pvr/core/services/enlaces_service.dart';
import 'package:pixel_pvr/core/services/file_storage_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/firma_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/fuente_documento_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/pdf_anotado_service.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/pagina_documento.dart';
import 'package:pixel_pvr/features/editor/data/services/image_processing_service.dart';
import 'package:pixel_pvr/features/export/data/services/pdf_export_service.dart';
import 'package:pixel_pvr/features/scanner/data/services/escaner_service.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';
import 'package:pixel_pvr/features/vault/domain/repositories/documento_repository.dart';

/// Dobles de prueba: sustituyen Hive, los isolates y los plugins nativos para
/// que los tests sean rápidos y deterministas.

class FakeDocumentoRepository implements DocumentoRepository {
  FakeDocumentoRepository({List<DocumentoEscaneado> iniciales = const []})
    : documentos = [...iniciales];

  final List<DocumentoEscaneado> documentos;

  /// Si se asigna, `obtenerTodos` se queda esperando hasta completarlo
  /// (para poder observar el estado "cargando" de forma determinista).
  Completer<void>? bloqueo;

  bool fallaAlLeer = false;

  @override
  Future<List<DocumentoEscaneado>> obtenerTodos() async {
    if (bloqueo != null) await bloqueo!.future;
    if (fallaAlLeer) throw StateError('fallo simulado de lectura');
    return [...documentos];
  }

  @override
  Future<void> guardar(DocumentoEscaneado documento) async =>
      documentos.add(documento);

  @override
  Future<void> eliminar(DocumentoEscaneado documento) async =>
      documentos.removeWhere((d) => d.id == documento.id);
}

class FakeFileStorageService extends FileStorageService {
  final Map<String, int> guardados = {};
  final List<String> borrados = [];

  @override
  Future<String> guardar(String nombreArchivo, Uint8List bytes) async {
    guardados[nombreArchivo] = bytes.length;
    return '/fake/$nombreArchivo';
  }

  @override
  Future<void> borrarSiExiste(String ruta) async => borrados.add(ruta);
}

class FakeImageProcessingService extends ImageProcessingService {
  int filtrosAplicados = 0;
  final List<FiltroImagen> filtrosPedidos = [];
  bool fallaAplicando = false;

  /// Últimos bytes que recibió `miniatura`, para comprobar de dónde salen.
  List<int> bytesMiniatura = const [];

  @override
  Future<Uint8List> aplicarFiltro(
    Uint8List bytes,
    FiltroImagen filtro, {
    int anchoMax = 1600,
  }) async {
    if (fallaAplicando) throw StateError('fallo simulado de filtro');
    filtrosAplicados++;
    filtrosPedidos.add(filtro);
    // Marca el filtro aplicado al final para poder distinguir el resultado.
    return Uint8List.fromList([...bytes, filtro.index]);
  }

  @override
  Future<Uint8List> codificar(
    Uint8List bytes,
    FormatoExportacion formato,
  ) async {
    if (formato == FormatoExportacion.jpg) {
      return Uint8List.fromList([...bytes, 0xAA]);
    }
    return Uint8List.fromList(bytes);
  }

  @override
  Future<Uint8List> miniatura(Uint8List bytes) async {
    bytesMiniatura = bytes;
    return Uint8List.fromList(bytes);
  }
}

class FakePdfExportService extends PdfExportService {
  int llamadas = 0;
  final List<int> ultimoJpgRecibido = [];

  @override
  Future<Uint8List> crearPdf(Uint8List jpgBytes) async {
    llamadas++;
    ultimoJpgRecibido
      ..clear()
      ..addAll(jpgBytes);
    // Cabecera "%PDF" para que el tamaño sea reconocible: 4 bytes.
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46]);
  }
}

class FakeEscanerService implements EscanerService {
  FakeEscanerService({this.ruta, this.error});

  /// Ruta que devuelve el escáner (null equivale a "el usuario canceló").
  final String? ruta;

  /// Si se indica, `capturar` lo lanza.
  final Object? error;

  int llamadas = 0;

  @override
  Future<String?> capturar() async {
    llamadas++;
    if (error != null) throw error!;
    return ruta;
  }
}

/// PNG real (no bytes arbitrarios) para que `Image.memory` pueda pintarlo.
Uint8List pngFalso({int ancho = 30, int alto = 40}) =>
    Uint8List.fromList(img.encodePng(img.Image(width: ancho, height: alto)));

PaginaDocumento paginaFalsa({int ancho = 30, int alto = 40}) => PaginaDocumento(
  png: pngFalso(ancho: ancho, alto: alto),
  ancho: ancho,
  alto: alto,
);

class FakeFuenteDocumentoService extends FuenteDocumentoService {
  FakeFuenteDocumentoService({this.paginas = const [], this.error});

  final List<PaginaDocumento> paginas;
  final Object? error;

  int llamadasPdf = 0;
  int llamadasImagen = 0;

  @override
  Future<List<PaginaDocumento>> desdePdf(Uint8List bytes) async {
    llamadasPdf++;
    if (error != null) throw error!;
    return paginas;
  }

  @override
  Future<List<PaginaDocumento>> desdeImagen(Uint8List bytes) async {
    llamadasImagen++;
    if (error != null) throw error!;
    return paginas;
  }
}

class FakeFirmaService extends FirmaService {
  FakeFirmaService({Uint8List? png})
    : png = png ?? Uint8List.fromList(pngFalso());

  final Uint8List png;
  int rasterizados = 0;
  int importadas = 0;

  @override
  Future<FirmaRasterizada?> rasterizar(
    List<List<Offset>> trazos, {
    int anchoSalida = 900,
  }) async {
    if (trazos.isEmpty) return null;
    rasterizados++;
    return FirmaRasterizada(png: png, ancho: 100, alto: 50);
  }

  @override
  Future<FirmaRasterizada> normalizarImagen(Uint8List bytes) async {
    importadas++;
    return FirmaRasterizada(png: png, ancho: 100, alto: 50);
  }
}

class FakePdfAnotadoService extends PdfAnotadoService {
  int llamadas = 0;
  List<PaginaDocumento> ultimasPaginas = const [];
  List<Anotacion> ultimasAnotaciones = const [];

  /// Si se indica, `componer` lo lanza (simula un fallo al guardar).
  Object? error;

  @override
  Future<Uint8List> componer({
    required List<PaginaDocumento> paginas,
    required List<Anotacion> anotaciones,
    required String titulo,
  }) async {
    if (error != null) throw error!;
    llamadas++;
    ultimasPaginas = paginas;
    ultimasAnotaciones = anotaciones;
    // Cabecera "%PDF-" para que el tamaño sea reconocible: 5 bytes.
    return Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]);
  }
}

class FakeEnlacesService extends EnlacesService {
  final List<String> abiertos = [];
  bool exito = true;

  @override
  Future<bool> abrir(String url) async {
    abiertos.add(url);
    return exito;
  }
}

class FakeArchivosService extends ArchivosService {
  FakeArchivosService({this.archivo});

  /// Lo que devuelve el selector; `null` equivale a "el usuario canceló".
  ArchivoElegido? archivo;
  int llamadas = 0;

  @override
  Future<ArchivoElegido?> elegir({
    required List<String> extensiones,
    required String titulo,
  }) async {
    llamadas++;
    return archivo;
  }
}
