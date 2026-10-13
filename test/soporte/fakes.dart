import 'dart:async';
import 'dart:typed_data';

import 'package:pixel_pvr/core/services/file_storage_service.dart';
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
  Future<Uint8List> miniatura(Uint8List bytes) async =>
      Uint8List.fromList(bytes);
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
