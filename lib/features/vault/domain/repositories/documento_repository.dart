import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

/// Contrato del repositorio. Hoy: almacenamiento local (Hive).
/// Mañana: una implementación híbrida local + Firebase sin tocar la UI.
abstract class DocumentoRepository {
  Future<List<DocumentoEscaneado>> obtenerTodos();
  Future<void> guardar(DocumentoEscaneado documento);
  Future<void> eliminar(DocumentoEscaneado documento);
}
