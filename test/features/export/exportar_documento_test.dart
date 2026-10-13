import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/features/export/domain/usecases/exportar_documento.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

import '../../soporte/fakes.dart';

void main() {
  late FakeDocumentoRepository repo;
  late FakeFileStorageService almacenamiento;
  late FakeImageProcessingService imagen;
  late FakePdfExportService pdf;
  late ExportarDocumento caso;

  setUp(() {
    repo = FakeDocumentoRepository();
    almacenamiento = FakeFileStorageService();
    imagen = FakeImageProcessingService();
    pdf = FakePdfExportService();
    caso = ExportarDocumento(
      repositorio: repo,
      almacenamiento: almacenamiento,
      imagen: imagen,
      pdf: pdf,
    );
  });

  Future<DocumentoEscaneado> exportar(FormatoExportacion formato) => caso(
    imagenProcesada: Uint8List.fromList([1, 2, 3]),
    nombre: 'SCAN_20261012_1930',
    formato: formato,
    filtro: FiltroImagen.blancoNegro,
  );

  group('ExportarDocumento', () {
    test('en PDF: codifica a JPG, genera el PDF y registra todo', () async {
      final doc = await exportar(FormatoExportacion.pdf);

      expect(pdf.llamadas, 1);
      // El JPG que recibe el PDF es el resultado de codificar(..., jpg).
      expect(pdf.ultimoJpgRecibido, [1, 2, 3, 0xAA]);
      expect(doc.rutaArchivo, endsWith('.pdf'));
      expect(doc.rutaMiniatura, endsWith('_thumb.jpg'));
      expect(doc.formato, FormatoExportacion.pdf);
      expect(doc.filtro, FiltroImagen.blancoNegro);
      expect(doc.tamanoBytes, 4); // los que devolvió el generador de PDF falso
      expect(doc.nombre, 'SCAN_20261012_1930');
      expect(repo.documentos, hasLength(1));
      expect(almacenamiento.guardados, hasLength(2));
    });

    test('en JPG no toca el generador de PDF y usa la extensión jpg', () async {
      final doc = await exportar(FormatoExportacion.jpg);

      expect(pdf.llamadas, 0);
      expect(doc.rutaArchivo, endsWith('.jpg'));
      expect(doc.tamanoBytes, 4);
      expect(
        almacenamiento.guardados.keys.any((k) => k.endsWith('.jpg')),
        isTrue,
      );
    });

    test('en PNG guarda los bytes sin recomprimir', () async {
      final doc = await exportar(FormatoExportacion.png);

      expect(pdf.llamadas, 0);
      expect(doc.rutaArchivo, endsWith('.png'));
      expect(doc.tamanoBytes, 3);
    });

    test('la miniatura se guarda siempre, con el sufijo _thumb.jpg', () async {
      final doc = await exportar(FormatoExportacion.png);

      expect(doc.rutaMiniatura, endsWith('_thumb.jpg'));
      expect(
        almacenamiento.guardados.keys.any((k) => k.endsWith('_thumb.jpg')),
        isTrue,
      );
    });

    test('el id es único y la fecha es la de creación', () async {
      final uno = await exportar(FormatoExportacion.png);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final dos = await exportar(FormatoExportacion.png);

      expect(uno.id, isNot(dos.id));
      expect(
        dos.creadoEn.difference(DateTime.now()).inMinutes.abs(),
        lessThan(1),
      );
    });
  });
}
