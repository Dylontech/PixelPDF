import 'dart:convert';

import 'package:hive/hive.dart';

import '../../domain/entities/documento_escaneado.dart';

/// Persistencia en Hive guardando cada documento como JSON (String).
/// Sin build_runner ni TypeAdapters: fácil de migrar a Isar después.
class DocumentoLocalDataSource {
  static const boxName = 'pixel_vault';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<DocumentoEscaneado>> todos() async {
    final lista = _box.values
        .map(
          (s) =>
              DocumentoEscaneado.fromMap(jsonDecode(s) as Map<String, dynamic>),
        )
        .toList();
    lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return lista;
  }

  Future<void> guardar(DocumentoEscaneado d) =>
      _box.put(d.id, jsonEncode(d.toMap()));

  Future<void> eliminar(String id) => _box.delete(id);
}
