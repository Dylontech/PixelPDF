import 'package:flutter/foundation.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';
import 'package:pixel_pvr/features/vault/domain/repositories/documento_repository.dart';

class VaultViewModel extends ChangeNotifier {
  VaultViewModel(this._repositorio);

  final DocumentoRepository _repositorio;

  List<DocumentoEscaneado> documentos = [];
  bool cargando = true;
  String? error;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  Future<void> cargar() async {
    cargando = true;
    error = null;
    _notificar();
    try {
      documentos = await _repositorio.obtenerTodos();
    } catch (_) {
      error = 'NO SE PUDO LEER EL VAULT';
    }
    cargando = false;
    _notificar();
  }

  Future<void> eliminar(DocumentoEscaneado doc) async {
    await _repositorio.eliminar(doc);
    documentos = documentos.where((d) => d.id != doc.id).toList();
    _notificar();
  }
}
