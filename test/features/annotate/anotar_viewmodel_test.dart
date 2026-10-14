import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/fuente_documento.dart';
import 'package:pixel_pvr/features/annotate/domain/usecases/exportar_documento_anotado.dart';
import 'package:pixel_pvr/features/annotate/presentation/viewmodels/anotar_viewmodel.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

import '../../soporte/fakes.dart';

void main() {
  late FakeDocumentoRepository repo;
  late FakeFileStorageService almacenamiento;
  late FakeImageProcessingService imagen;
  late FakePdfAnotadoService pdf;
  late FakeFirmaService firma;
  late FakeFuenteDocumentoService fuenteService;
  late ExportarDocumentoAnotado exportar;

  setUp(() {
    repo = FakeDocumentoRepository();
    almacenamiento = FakeFileStorageService();
    imagen = FakeImageProcessingService();
    pdf = FakePdfAnotadoService();
    firma = FakeFirmaService();
    fuenteService = FakeFuenteDocumentoService(
      paginas: [paginaFalsa(), paginaFalsa()],
    );
    exportar = ExportarDocumentoAnotado(
      repositorio: repo,
      almacenamiento: almacenamiento,
      imagen: imagen,
      pdf: pdf,
    );
  });

  AnotarViewModel crear({
    FormatoEntrada formato = FormatoEntrada.pdf,
    FakeFuenteDocumentoService? servicio,
  }) => AnotarViewModel(
    fuente: FuenteDocumento.deBytes(
      nombre: formato == FormatoEntrada.pdf ? 'informe.pdf' : 'foto.png',
      formato: formato,
      bytes: Uint8List.fromList([1, 2, 3]),
    ),
    fuenteService: servicio ?? fuenteService,
    exportar: exportar,
    firma: firma,
  );

  group('carga del documento', () {
    test('un PDF se convierte en páginas y se limpia el error', () async {
      final vm = crear();

      await vm.cargar();

      expect(vm.cargando, isFalse);
      expect(vm.totalPaginas, 2);
      expect(vm.error, isNull);
      expect(vm.seleccionada, isNull);
      expect(fuenteService.llamadasPdf, 1);
    });

    test('una imagen entra por el camino de imagen', () async {
      final vm = crear(formato: FormatoEntrada.imagen);

      await vm.cargar();

      expect(fuenteService.llamadasImagen, 1);
      expect(fuenteService.llamadasPdf, 0);
    });

    test('si no se puede leer avisa y no deja páginas', () async {
      final roto = FakeFuenteDocumentoService(error: StateError('boom'));
      final vm = crear(servicio: roto);

      await vm.cargar();

      expect(vm.paginas, isEmpty);
      expect(vm.error, 'NO SE PUDO LEER EL PDF');
      expect(vm.cargando, isFalse);
    });

    test('un PDF sin páginas se trata como error', () async {
      final vacio = FakeFuenteDocumentoService(paginas: const []);
      final vm = crear(servicio: vacio);

      await vm.cargar();

      expect(vm.error, 'NO SE PUDO LEER EL PDF');
    });
  });

  group('anotaciones', () {
    test('un texto vacío no crea anotación ni historial', () async {
      final vm = crear();
      await vm.cargar();

      vm.agregarTexto('   ');

      expect(vm.anotaciones, isEmpty);
      expect(vm.puedeDeshacer, isFalse);
    });

    test(
      'el texto se coloca centrado en la página actual y queda seleccionado',
      () async {
        final vm = crear();
        await vm.cargar();
        vm.irPagina(1);

        vm.agregarTexto('Firmado', color: ColorAnotacion.azul);

        final anotacion = vm.anotaciones.single as AnotacionTexto;
        expect(anotacion.pagina, 1);
        expect(anotacion.texto, 'Firmado');
        expect(anotacion.color, ColorAnotacion.azul);
        expect(anotacion.zona.left, closeTo(0.2, 1e-9));
        expect(vm.seleccionadaId, anotacion.id);
        expect(vm.anotacionesPagina, hasLength(1));
        expect(vm.puedeDeshacer, isTrue);
      },
    );

    test('la firma conserva su proporción', () async {
      final vm = crear();
      await vm.cargar();

      vm.agregarFirma(Uint8List.fromList([9]), 2);

      final anotacion = vm.anotaciones.single as AnotacionFirma;
      expect(anotacion.zona.width, closeTo(0.45, 1e-9));
      expect(anotacion.zona.height, closeTo(0.225, 1e-9));
      expect(anotacion.zona.left, closeTo(0.275, 1e-9));
    });

    test('mover y redimensionar solo afectan a la seleccionada', () async {
      final vm = crear();
      await vm.cargar();
      vm.agregarTexto('Uno');
      vm.agregarTexto('Dos');

      final antes = vm.seleccionada!.zona;
      vm.moverSeleccion(0.1, 0.05);
      final movida = vm.seleccionada!.zona;

      expect(movida.left, closeTo(antes.left + 0.1, 1e-9));
      expect(movida.top, closeTo(antes.top + 0.05, 1e-9));
      expect(movida.width, antes.width);

      vm.redimensionarSeleccion(-0.1, 0);
      expect(vm.seleccionada!.zona.width, closeTo(antes.width - 0.1, 1e-9));

      final otra = vm.anotaciones.first as AnotacionTexto;
      expect(otra.zona, antes);
    });

    test('eliminar y deshacer devuelven el estado anterior', () async {
      final vm = crear();
      await vm.cargar();
      vm.agregarTexto('Uno');
      vm.agregarTexto('Dos');

      vm.eliminarSeleccion();
      expect(vm.anotaciones, hasLength(1));
      expect(vm.seleccionadaId, isNull);

      vm.deshacer();
      expect(vm.anotaciones, hasLength(2));
    });

    test('cambiar de página limpia la selección', () async {
      final vm = crear();
      await vm.cargar();
      vm.agregarTexto('Uno');

      vm.irPagina(1);

      expect(vm.seleccionadaId, isNull);
      expect(vm.anotacionesPagina, isEmpty);
    });
  });

  group('exportar', () {
    test('guarda una copia con las anotaciones y las páginas reales', () async {
      final vm = crear();
      await vm.cargar();
      vm.agregarTexto('Firmado aqui');

      final doc = await vm.exportar();

      expect(doc, isNotNull);
      expect(doc!.formato, FormatoExportacion.pdf);
      expect(doc.paginas, 2);
      expect(doc.nombre, startsWith('FIRMA_'));
      expect(pdf.llamadas, 1);
      expect(pdf.ultimasAnotaciones, hasLength(1));
      expect(pdf.ultimasPaginas, hasLength(2));
      expect(repo.documentos, hasLength(1));
      expect(vm.exportando, isFalse);
      expect(vm.error, isNull);
    });

    test('un fallo al guardar se comunica sin perder el trabajo', () async {
      final vm = crear();
      await vm.cargar();
      vm.agregarTexto('Firmado aqui');
      pdf.error = StateError('disco lleno');

      final doc = await vm.exportar();

      expect(doc, isNull);
      expect(vm.error, 'NO SE PUDO GUARDAR');
      expect(vm.anotaciones, hasLength(1));
      expect(vm.exportando, isFalse);
    });
  });
}
