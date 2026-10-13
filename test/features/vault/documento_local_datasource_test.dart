import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pixel_pvr/features/vault/data/datasources/documento_local_datasource.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

DocumentoEscaneado _doc(String id, DateTime fecha) => DocumentoEscaneado(
  id: id,
  nombre: 'SCAN_$id',
  creadoEn: fecha,
  rutaArchivo: '/tmp/$id.pdf',
  rutaMiniatura: '/tmp/${id}_thumb.jpg',
  formato: FormatoExportacion.pdf,
  filtro: FiltroImagen.original,
  tamanoBytes: 100,
);

void main() {
  late Directory temporal;
  late DocumentoLocalDataSource ds;

  setUpAll(() async {
    temporal = await Directory.systemTemp.createTemp('pixel_pvr_hive');
    Hive.init(temporal.path);
    await Hive.openBox<String>(DocumentoLocalDataSource.boxName);
  });

  setUp(() async {
    await Hive.box<String>(DocumentoLocalDataSource.boxName).clear();
    ds = DocumentoLocalDataSource();
  });

  tearDownAll(() async {
    await Hive.close();
    await temporal.delete(recursive: true);
  });

  group('DocumentoLocalDataSource', () {
    test(
      'guarda y recupera documentos ordenados por fecha descendente',
      () async {
        await ds.guardar(_doc('viejo', DateTime(2026, 1, 1)));
        await ds.guardar(_doc('nuevo', DateTime(2026, 6, 1)));
        await ds.guardar(_doc('medio', DateTime(2026, 3, 1)));

        final todos = await ds.todos();

        expect(todos.map((d) => d.id).toList(), ['nuevo', 'medio', 'viejo']);
      },
    );

    test('el valor guardado es el JSON del documento', () async {
      await ds.guardar(_doc('7', DateTime(2026, 3, 3)));

      final crudo = Hive.box<String>(DocumentoLocalDataSource.boxName).get('7');

      expect(crudo, isNotNull);
      expect(crudo, contains('"schemaVersion":1'));
      expect(crudo, contains('"id":"7"'));
    });

    test('eliminar borra el registro pero no los demás', () async {
      await ds.guardar(_doc('a', DateTime(2026, 1, 1)));
      await ds.guardar(_doc('b', DateTime(2026, 2, 1)));

      await ds.eliminar('a');

      expect((await ds.todos()).map((d) => d.id).toList(), ['b']);
    });

    test('con la caja vacía devuelve una lista vacía', () async {
      expect(await ds.todos(), isEmpty);
    });
  });
}
