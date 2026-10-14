import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/zona_normalizada.dart';
import 'package:pixel_pvr/features/annotate/domain/usecases/exportar_documento_anotado.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

import '../../soporte/fakes.dart';

void main() {
  late FakeDocumentoRepository repo;
  late FakeFileStorageService almacenamiento;
  late FakeImageProcessingService imagen;
  late FakePdfAnotadoService pdf;
  late ExportarDocumentoAnotado caso;

  setUp(() {
    repo = FakeDocumentoRepository();
    almacenamiento = FakeFileStorageService();
    imagen = FakeImageProcessingService();
    pdf = FakePdfAnotadoService();
    caso = ExportarDocumentoAnotado(
      repositorio: repo,
      almacenamiento: almacenamiento,
      imagen: imagen,
      pdf: pdf,
    );
  });

  const texto = AnotacionTexto(
    id: 'a1',
    pagina: 0,
    zona: ZonaNormalizada(left: 0.1, top: 0.1, width: 0.4, height: 0.1),
    texto: 'Firmado',
    tamanoRelativo: 0.05,
  );

  group('ExportarDocumentoAnotado', () {
    test('compone el PDF, guarda la copia, la miniatura y registra', () async {
      final doc = await caso(
        paginas: [paginaFalsa(), paginaFalsa(), paginaFalsa()],
        anotaciones: const [texto],
        nombre: 'FIRMA_20261013_1200',
      );

      expect(pdf.llamadas, 1);
      expect(pdf.ultimasAnotaciones, hasLength(1));
      expect(pdf.ultimasPaginas, hasLength(3));
      expect(doc.nombre, 'FIRMA_20261013_1200');
      expect(doc.formato, FormatoExportacion.pdf);
      expect(doc.filtro, FiltroImagen.original);
      expect(doc.paginas, 3);
      expect(doc.rutaArchivo, endsWith('.pdf'));
      expect(doc.tamanoBytes, 5);
      expect(doc.rutaMiniatura, endsWith('_thumb.jpg'));
      expect(repo.documentos, hasLength(1));
      expect(almacenamiento.guardados, hasLength(2));
      expect(
        almacenamiento.guardados.keys.any((k) => k.endsWith('.pdf')),
        isTrue,
      );
      expect(
        almacenamiento.guardados.keys.any((k) => k.endsWith('_thumb.jpg')),
        isTrue,
      );
    });

    test('crea un documento nuevo por cada exportación', () async {
      final uno = await caso(
        paginas: [paginaFalsa()],
        anotaciones: const [],
        nombre: 'FIRMA_A',
      );
      final dos = await caso(
        paginas: [paginaFalsa()],
        anotaciones: const [],
        nombre: 'FIRMA_B',
      );

      expect(uno.id, isNot(dos.id));
      expect(repo.documentos, hasLength(2));
      expect(almacenamiento.guardados, hasLength(4));
    });

    test('sin páginas no genera nada', () async {
      await expectLater(
        caso(paginas: const [], anotaciones: const [], nombre: 'X'),
        throwsStateError,
      );

      expect(pdf.llamadas, 0);
      expect(repo.documentos, isEmpty);
      expect(almacenamiento.guardados, isEmpty);
    });

    test('la miniatura sale de la primera página', () async {
      await caso(
        paginas: [paginaFalsa(ancho: 10, alto: 10), paginaFalsa()],
        anotaciones: const [],
        nombre: 'FIRMA_A',
      );

      expect(imagen.bytesMiniatura, isNotEmpty);
    });
  });
}
