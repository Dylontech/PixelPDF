import '../../../core/services/file_storage_service.dart';
import '../../vault/domain/entities/documento_escaneado.dart';
import '../../vault/domain/repositories/documento_repository.dart';
import '../datasources/documento_local_datasource.dart';

class DocumentoRepositoryImpl implements DocumentoRepository {
  DocumentoRepositoryImpl(this._local, this._storage);

  final DocumentoLocalDataSource _local;
  final FileStorageService _storage;

  @override
  Future<List<DocumentoEscaneado>> obtenerTodos() => _local.todos();

  @override
  Future<void> guardar(DocumentoEscaneado documento) =>
      _local.guardar(documento);

  /// Borra el archivo, la miniatura y el registro. En ese orden: si fallara el
  /// borrado de una miniatura, el registro seguiría existiendo y el usuario
  /// puede reintentar, en lugar de quedar basura invisible en disco.
  @override
  Future<void> eliminar(DocumentoEscaneado documento) async {
    await _storage.borrarSiExiste(documento.rutaArchivo);
    await _storage.borrarSiExiste(documento.rutaMiniatura);
    await _local.eliminar(documento.id);
  }
}
