import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pixel_pvr/features/annotate/data/services/firma_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/fuente_documento_service.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/fuente_documento.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/pagina_documento.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/zona_normalizada.dart';
import 'package:pixel_pvr/features/annotate/domain/usecases/exportar_documento_anotado.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

/// Estado de la pantalla de firma y texto: páginas cargadas, anotaciones por
/// página, selección e historial de deshacer.
class AnotarViewModel extends ChangeNotifier {
  AnotarViewModel({
    required this.fuente,
    required FuenteDocumentoService fuenteService,
    required ExportarDocumentoAnotado exportar,
    required this.firma,
  }) : _fuenteService = fuenteService,
       _exportar = exportar;

  final FuenteDocumento fuente;
  final FuenteDocumentoService _fuenteService;
  final ExportarDocumentoAnotado _exportar;

  /// Expuesto para que el diálogo de firma rasterice los trazos.
  final FirmaService firma;

  List<PaginaDocumento> paginas = const [];
  final List<Anotacion> anotaciones = [];
  final List<List<Anotacion>> _historial = [];

  int paginaActual = 0;
  String? seleccionadaId;
  bool cargando = true;
  bool exportando = false;
  String? error;

  int _contador = 0;
  bool _disposed = false;

  List<Anotacion> get anotacionesPagina => [
    for (final anotacion in anotaciones)
      if (anotacion.pagina == paginaActual) anotacion,
  ];

  Anotacion? get seleccionada {
    final id = seleccionadaId;
    if (id == null) return null;
    for (final anotacion in anotaciones) {
      if (anotacion.id == id) return anotacion;
    }
    return null;
  }

  int get totalPaginas => paginas.length;
  bool get hayPaginaAnterior => paginaActual > 0;
  bool get hayPaginaSiguiente => paginaActual < paginas.length - 1;
  bool get puedeDeshacer => _historial.isNotEmpty;
  bool get ocupado => cargando || exportando;

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    _notificar();
    try {
      final bytes = fuente.bytes ?? await File(fuente.ruta!).readAsBytes();
      paginas = fuente.formato == FormatoEntrada.pdf
          ? await _fuenteService.desdePdf(bytes)
          : await _fuenteService.desdeImagen(bytes);
      if (paginas.isEmpty) throw StateError('El documento no tiene páginas');
    } catch (_) {
      paginas = const [];
      error = fuente.formato == FormatoEntrada.pdf
          ? 'NO SE PUDO LEER EL PDF'
          : 'NO SE PUDO LEER LA IMAGEN';
    }
    cargando = false;
    _notificar();
  }

  void irPagina(int indice) {
    if (indice < 0 || indice >= paginas.length || indice == paginaActual) {
      return;
    }
    paginaActual = indice;
    seleccionadaId = null;
    _notificar();
  }

  void seleccionar(String? id) {
    if (seleccionadaId == id) return;
    seleccionadaId = id;
    _notificar();
  }

  /// Coloca la firma centrada, conservando su proporción.
  void agregarFirma(Uint8List png, double relacionAspecto) {
    _registrarHistorial();
    const ancho = 0.45;
    final alto = (ancho / (relacionAspecto <= 0 ? 2 : relacionAspecto)).clamp(
      ZonaNormalizada.minimaDimension,
      0.6,
    );
    _agregar(
      AnotacionFirma(
        id: _nuevoId(),
        pagina: paginaActual,
        zona: ZonaNormalizada(
          left: (1 - ancho) / 2,
          top: (1 - alto) / 2,
          width: ancho,
          height: alto,
        ),
        png: png,
      ),
    );
  }

  /// Coloca un cuadro de texto centrado.
  void agregarTexto(
    String texto, {
    ColorAnotacion color = ColorAnotacion.negro,
    double tamanoRelativo = 0.045,
  }) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return;
    _registrarHistorial();
    const ancho = 0.6;
    const alto = 0.12;
    _agregar(
      AnotacionTexto(
        id: _nuevoId(),
        pagina: paginaActual,
        zona: const ZonaNormalizada(
          left: (1 - ancho) / 2,
          top: (1 - alto) / 2,
          width: ancho,
          height: alto,
        ),
        texto: limpio,
        tamanoRelativo: tamanoRelativo,
        color: color,
      ),
    );
  }

  void moverSeleccion(double dx, double dy) {
    final actual = seleccionada;
    if (actual == null) return;
    _reemplazar(actual.conZona(actual.zona.desplazar(dx, dy)));
  }

  void redimensionarSeleccion(double dw, double dh) {
    final actual = seleccionada;
    if (actual == null) return;
    _reemplazar(actual.conZona(actual.zona.redimensionar(dw, dh)));
  }

  void eliminarSeleccion() {
    final actual = seleccionada;
    if (actual == null) return;
    _registrarHistorial();
    anotaciones.removeWhere((a) => a.id == actual.id);
    seleccionadaId = null;
    _notificar();
  }

  void deshacer() {
    if (_historial.isEmpty) return;
    final anterior = _historial.removeLast();
    anotaciones
      ..clear()
      ..addAll(anterior);
    if (!anotaciones.any((a) => a.id == seleccionadaId)) seleccionadaId = null;
    _notificar();
  }

  Future<DocumentoEscaneado?> exportar() async {
    if (paginas.isEmpty) return null;
    exportando = true;
    error = null;
    _notificar();
    try {
      return await _exportar(
        paginas: paginas,
        anotaciones: List.unmodifiable(anotaciones),
        nombre: _nombreSalida(),
      );
    } catch (_) {
      error = 'NO SE PUDO GUARDAR';
      return null;
    } finally {
      exportando = false;
      _notificar();
    }
  }

  void _agregar(Anotacion anotacion) {
    anotaciones.add(anotacion);
    seleccionadaId = anotacion.id;
    _notificar();
  }

  void _reemplazar(Anotacion actualizada) {
    final indice = anotaciones.indexWhere((a) => a.id == actualizada.id);
    if (indice < 0) return;
    anotaciones[indice] = actualizada;
    _notificar();
  }

  void _registrarHistorial() {
    _historial.add(List.of(anotaciones));
    if (_historial.length > 30) _historial.removeAt(0);
  }

  String _nuevoId() =>
      'a${_contador++}_${DateTime.now().microsecondsSinceEpoch}';

  String _nombreSalida() {
    final ahora = DateTime.now();
    String dos(int n) => n.toString().padLeft(2, '0');
    return 'FIRMA_${ahora.year}${dos(ahora.month)}${dos(ahora.day)}_'
        '${dos(ahora.hour)}${dos(ahora.minute)}';
  }
}
