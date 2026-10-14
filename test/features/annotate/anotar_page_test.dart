import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixel_pvr/core/services/archivos_service.dart';
import 'package:pixel_pvr/core/services/compartir_service.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/widgets/pixel_button.dart';
import 'package:pixel_pvr/features/annotate/data/services/firma_service.dart';
import 'package:pixel_pvr/features/annotate/data/services/fuente_documento_service.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/fuente_documento.dart';
import 'package:pixel_pvr/features/annotate/domain/usecases/exportar_documento_anotado.dart';
import 'package:pixel_pvr/features/annotate/presentation/pages/anotar_page.dart';
import 'package:pixel_pvr/features/annotate/presentation/widgets/firma_pad.dart';
import 'package:pixel_pvr/features/vault/presentation/viewmodels/vault_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../soporte/fakes.dart';

void main() {
  late FakeDocumentoRepository repo;
  late FakeFirmaService firma;
  late ExportarDocumentoAnotado exportar;

  setUp(() {
    repo = FakeDocumentoRepository();
    firma = FakeFirmaService();
    exportar = ExportarDocumentoAnotado(
      repositorio: repo,
      almacenamiento: FakeFileStorageService(),
      imagen: FakeImageProcessingService(),
      pdf: FakePdfAnotadoService(),
    );
  });

  Widget app() => MultiProvider(
    providers: [
      Provider<FuenteDocumentoService>(
        create: (_) =>
            FakeFuenteDocumentoService(paginas: [paginaFalsa(), paginaFalsa()]),
      ),
      Provider<FirmaService>.value(value: firma),
      Provider<ArchivosService>(create: (_) => FakeArchivosService()),
      Provider<ExportarDocumentoAnotado>.value(value: exportar),
      Provider<CompartirService>(create: (_) => const CompartirService()),
      ChangeNotifierProvider<VaultViewModel>(
        create: (_) => VaultViewModel(repo)..cargar(),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: PixelTheme.build(),
      home: AnotarPage(
        fuente: FuenteDocumento.deBytes(
          nombre: 'informe.pdf',
          formato: FormatoEntrada.pdf,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      ),
    ),
  );

  /// Fija un tamaño de teléfono: con el viewport por defecto las tres filas de
  /// herramientas no caben y el test fallaría por desbordamiento.
  void pantallaDeTelefono(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  /// Deja que `cargar()` termine y se pinten las páginas.
  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.pump();
  }

  PixelButton boton(WidgetTester tester, String etiqueta) =>
      tester.widget<PixelButton>(find.widgetWithText(PixelButton, etiqueta));

  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('muestra la primera página y todas las herramientas', (
    tester,
  ) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    expect(find.text('PAGINA 1/2'), findsOneWidget);
    expect(find.text('FIRMA'), findsOneWidget);
    expect(find.text('TEXTO'), findsOneWidget);
    expect(find.text('BORRAR'), findsOneWidget);
    expect(find.text('GUARDAR PDF'), findsOneWidget);
  });

  testWidgets('sin selección no se puede borrar', (tester) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    expect(boton(tester, 'BORRAR').onPressed, isNull);
  });

  testWidgets('añadir texto lo pinta sobre la página y lo selecciona', (
    tester,
  ) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    await tester.tap(find.text('TEXTO'));
    await tester.pumpAndSettle();
    expect(find.text('NUEVO TEXTO'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Firmado aqui');
    await tester.tap(find.text('ANADIR'));
    await tester.pumpAndSettle();

    expect(find.text('NUEVO TEXTO'), findsNothing);
    expect(find.text('Firmado aqui'), findsOneWidget);
    expect(boton(tester, 'BORRAR').onPressed, isNotNull);
  });

  testWidgets('borrar quita la anotación seleccionada', (tester) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    await tester.tap(find.text('TEXTO'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Firmado aqui');
    await tester.tap(find.text('ANADIR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('BORRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Firmado aqui'), findsNothing);
    expect(boton(tester, 'BORRAR').onPressed, isNull);
  });

  testWidgets('dibujar una firma la añade a la página', (tester) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    await tester.tap(find.text('FIRMA'));
    await tester.pumpAndSettle();
    expect(find.text('TU FIRMA'), findsOneWidget);

    // Sin trazos, el botón de confirmar está deshabilitado.
    expect(boton(tester, 'USAR FIRMA').onPressed, isNull);

    await tester.drag(find.byType(FirmaPad), const Offset(40, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.text('USAR FIRMA'));
    await tester.pumpAndSettle();

    expect(find.text('TU FIRMA'), findsNothing);
    expect(firma.rasterizados, 1);
    expect(boton(tester, 'BORRAR').onPressed, isNotNull);
  });

  testWidgets('se puede navegar entre las páginas del documento', (
    tester,
  ) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    await tester.tap(find.text('SIG'));
    await tester.pumpAndSettle();

    expect(find.text('PAGINA 2/2'), findsOneWidget);
  });

  testWidgets('guardar exporta el PDF y confirma en pantalla', (tester) async {
    pantallaDeTelefono(tester);
    await abrir(tester);

    await tester.tap(find.text('TEXTO'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Firmado aqui');
    await tester.tap(find.text('ANADIR'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GUARDAR PDF'));
    await tester.pumpAndSettle();

    expect(find.text('LEVEL CLEAR!'), findsOneWidget);
    expect(repo.documentos, hasLength(1));
    expect(repo.documentos.single.paginas, 2);
  });
}
