import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pixel_pvr/core/utils/formatters.dart';
import 'package:pixel_pvr/features/editor/data/services/image_processing_service.dart';
import 'package:pixel_pvr/features/export/domain/usecases/exportar_documento.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

class EditorViewModel extends ChangeNotifier {
  EditorViewModel({
    required String rutaOriginal,
    required ExportarDocumento exportarDocumento,
    required ImageProcessingService procesamiento,
  }) : _ruta = rutaOriginal,
       _exportar = exportarDocumento,
       _procesamiento = procesamiento;

  final ExportarDocumento _exportar;
  final ImageProcessingService _procesamiento;

  String _ruta;
  Uint8List? _bytesOriginales;
  final Map<FiltroImagen, Uint8List> _cache = {};
  bool _disposed = false;

  FiltroImagen filtro = FiltroImagen.colorOptimizado;
  FormatoExportacion formato = FormatoExportacion.pdf;
  bool procesando = false;
  bool exportando = false;
  String? error;

  String get rutaActual => _ruta;
  Uint8List? get vista => _cache[filtro];

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> iniciar() => cargarDesdeRuta(_ruta);

  /// Carga (o recarga tras recortar) la imagen base y reaplica el filtro.
  /// La caché se invalida porque todos los bytes anteriores son de otra imagen.
  Future<void> cargarDesdeRuta(String ruta) async {
    _ruta = ruta;
    _cache.clear();
    procesando = true;
    error = null;
    _notificar();
    try {
      _bytesOriginales = await File(ruta).readAsBytes();
      await _procesar(filtro);
    } catch (_) {
      _bytesOriginales = null;
      error = 'NO SE PUDO CARGAR LA IMAGEN';
    }
    procesando = false;
    _notificar();
  }

  Future<void> seleccionarFiltro(FiltroImagen nuevo) async {
    filtro = nuevo;
    if (_cache.containsKey(nuevo)) {
      _notificar();
      return;
    }
    procesando = true;
    _notificar();
    try {
      await _procesar(nuevo);
    } catch (_) {
      error = 'ERROR AL APLICAR EL FILTRO';
    }
    procesando = false;
    _notificar();
  }

  void seleccionarFormato(FormatoExportacion nuevo) {
    formato = nuevo;
    _notificar();
  }

  Future<void> _procesar(FiltroImagen f) async {
    final originales = _bytesOriginales;
    if (originales == null) throw StateError('No hay imagen cargada');
    _cache[f] = await _procesamiento.aplicarFiltro(originales, f);
  }

  Future<DocumentoEscaneado?> exportar() async {
    final bytes = vista;
    if (bytes == null) return null;
    exportando = true;
    error = null;
    _notificar();
    try {
      return await _exportar(
        imagenProcesada: bytes,
        nombre: nombreAutomatico(DateTime.now()),
        formato: formato,
        filtro: filtro,
      );
    } catch (_) {
      error = 'NO SE PUDO EXPORTAR';
      return null;
    } finally {
      exportando = false;
      _notificar();
    }
  }
}
