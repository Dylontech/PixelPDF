import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

DocumentoEscaneado _doc() => DocumentoEscaneado(
  id: '123',
  nombre: 'SCAN_20261012_1930',
  creadoEn: DateTime(2026, 10, 12, 19, 30),
  rutaArchivo: '/tmp/123.pdf',
  rutaMiniatura: '/tmp/123_thumb.jpg',
  formato: FormatoExportacion.pdf,
  filtro: FiltroImagen.pixelArt,
  tamanoBytes: 2048,
);

void main() {
  group('DocumentoEscaneado', () {
    test('toMap/fromMap conserva todos los campos', () {
      final original = _doc();

      final copia = DocumentoEscaneado.fromMap(original.toMap());

      expect(copia.id, original.id);
      expect(copia.nombre, original.nombre);
      expect(copia.creadoEn, original.creadoEn);
      expect(copia.rutaArchivo, original.rutaArchivo);
      expect(copia.rutaMiniatura, original.rutaMiniatura);
      expect(copia.formato, FormatoExportacion.pdf);
      expect(copia.filtro, FiltroImagen.pixelArt);
      expect(copia.tamanoBytes, 2048);
      expect(copia.paginas, 1);
    });

    test('toMap incluye schemaVersion para migraciones', () {
      expect(_doc().toMap()['schemaVersion'], 1);
    });

    test('un formato desconocido cae a pdf en lugar de romper la carga', () {
      final mapa = _doc().toMap()..['formato'] = 'tiff';
      expect(DocumentoEscaneado.fromMap(mapa).formato, FormatoExportacion.pdf);
    });

    test('un filtro desconocido cae a original', () {
      final mapa = _doc().toMap()..['filtro'] = 'sepia';
      expect(DocumentoEscaneado.fromMap(mapa).filtro, FiltroImagen.original);
    });

    test('campos numéricos ausentes usan valores por defecto', () {
      final mapa = _doc().toMap()
        ..remove('tamanoBytes')
        ..remove('paginas');

      final doc = DocumentoEscaneado.fromMap(mapa);
      expect(doc.tamanoBytes, 0);
      expect(doc.paginas, 1);
    });
  });

  group('etiquetas de los enums', () {
    test('los formatos se muestran en mayúsculas', () {
      expect(FormatoExportacion.jpg.etiqueta, 'JPG');
      expect(FormatoExportacion.pdf.extension, 'pdf');
    });

    test('cada filtro tiene su etiqueta de chip', () {
      expect(FiltroImagen.values.map((f) => f.etiqueta).toList(), [
        'ORIGINAL',
        'COLOR+',
        'B/N',
        'GRISES',
        'PIXEL',
      ]);
    });
  });
}
