import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/features/editor/presentation/viewmodels/editor_viewmodel.dart';
import 'package:pixel_pvr/features/export/domain/usecases/exportar_documento.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';

import '../../soporte/fakes.dart';

void main() {
  late Directory temporal;
  late File imagenA;
  late File imagenB;
  late FakeImageProcessingService procesamiento;
  late EditorViewModel vm;

  EditorViewModel crear(String ruta) => EditorViewModel(
    rutaOriginal: ruta,
    exportarDocumento: ExportarDocumento(
      repositorio: FakeDocumentoRepository(),
      almacenamiento: FakeFileStorageService(),
      imagen: procesamiento,
      pdf: FakePdfExportService(),
    ),
    procesamiento: procesamiento,
  );

  setUpAll(() async {
    temporal = await Directory.systemTemp.createTemp('pixel_pvr_editor');
    imagenA = File('${temporal.path}/a.jpg')..writeAsBytesSync([1, 2, 3]);
    imagenB = File('${temporal.path}/b.jpg')..writeAsBytesSync([4, 5, 6, 7]);
  });

  tearDownAll(() async => temporal.delete(recursive: true));

  setUp(() {
    procesamiento = FakeImageProcessingService();
    vm = crear(imagenA.path);
  });

  tearDown(() => vm.dispose());

  group('EditorViewModel', () {
    test('iniciar carga la imagen y aplica el filtro por defecto', () async {
      await vm.iniciar();

      expect(vm.procesando, isFalse);
      expect(vm.error, isNull);
      expect(vm.filtro, FiltroImagen.colorOptimizado);
      expect(vm.formato, FormatoExportacion.pdf);
      expect(vm.vista, [1, 2, 3, FiltroImagen.colorOptimizado.index]);
      expect(procesamiento.filtrosAplicados, 1);
    });

    test('los filtros ya calculados salen de caché', () async {
      await vm.iniciar(); // 1: colorOptimizado

      await vm.seleccionarFiltro(FiltroImagen.pixelArt); // 2
      expect(procesamiento.filtrosAplicados, 2);

      await vm.seleccionarFiltro(FiltroImagen.colorOptimizado); // caché
      await vm.seleccionarFiltro(FiltroImagen.pixelArt); // caché
      expect(procesamiento.filtrosAplicados, 2);
      expect(vm.filtro, FiltroImagen.pixelArt);
    });

    test('cada filtro produce bytes distintos', () async {
      await vm.iniciar();
      final color = vm.vista;

      await vm.seleccionarFiltro(FiltroImagen.blancoNegro);

      expect(vm.vista, isNot(color));
    });

    test('recortar invalida la caché y mantiene el filtro elegido', () async {
      await vm.iniciar(); // 1
      await vm.seleccionarFiltro(FiltroImagen.pixelArt); // 2

      await vm.cargarDesdeRuta(imagenB.path); // 3: recalcula el filtro actual

      expect(vm.rutaActual, imagenB.path);
      expect(procesamiento.filtrosAplicados, 3);
      expect(vm.filtro, FiltroImagen.pixelArt);
      expect(vm.vista, [4, 5, 6, 7, FiltroImagen.pixelArt.index]);
    });

    test('una ruta inexistente deja error y no propaga la excepción', () async {
      final roto = crear('${temporal.path}/no-existe.jpg');

      await roto.iniciar();

      expect(roto.error, 'NO SE PUDO CARGAR LA IMAGEN');
      expect(roto.vista, isNull);
      expect(roto.procesando, isFalse);
      roto.dispose();
    });

    test('un fallo del filtro se refleja en el estado', () async {
      await vm.iniciar();

      procesamiento.fallaAplicando = true;
      await vm.seleccionarFiltro(FiltroImagen.pixelArt);

      expect(vm.error, 'ERROR AL APLICAR EL FILTRO');
      expect(vm.procesando, isFalse);
    });

    test('exportar usa el formato elegido y devuelve el documento', () async {
      await vm.iniciar();
      vm.seleccionarFormato(FormatoExportacion.png);

      final doc = await vm.exportar();

      expect(doc, isNotNull);
      expect(doc!.formato, FormatoExportacion.png);
      expect(doc.rutaArchivo, endsWith('.png'));
      expect(doc.filtro, FiltroImagen.colorOptimizado);
      expect(doc.nombre, startsWith('SCAN_'));
      expect(vm.exportando, isFalse);
      expect(vm.error, isNull);
    });

    test('exportar sin imagen cargada no hace nada', () async {
      expect(await vm.exportar(), isNull);
      expect(vm.exportando, isFalse);
    });
  });
}
