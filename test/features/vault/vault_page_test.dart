import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:pixel_pvr/core/services/compartir_service.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/core/widgets/pixel_fab.dart';
import 'package:pixel_pvr/features/scanner/data/services/escaner_service.dart';
import 'package:pixel_pvr/features/vault/domain/entities/documento_escaneado.dart';
import 'package:pixel_pvr/features/vault/presentation/pages/vault_page.dart';
import 'package:pixel_pvr/features/vault/presentation/viewmodels/vault_viewmodel.dart';
import 'package:provider/provider.dart';

import '../../soporte/fakes.dart';

Widget _app(FakeDocumentoRepository repo) => MultiProvider(
  providers: [
    ChangeNotifierProvider<VaultViewModel>(
      create: (_) => VaultViewModel(repo)..cargar(),
    ),
    Provider<EscanerService>(create: (_) => FakeEscanerService()),
    Provider<CompartirService>(create: (_) => const CompartirService()),
  ],
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PixelTheme.build(),
    home: const VaultPage(),
  ),
);

/// Fija un tamaño de pantalla de teléfono: con el viewport por defecto
/// (800x600) la tarjeta es tan alta que el nombre cae fuera y no se puede tocar.
void _pantallaDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  late Directory temporal;
  late String miniatura;
  setUpAll(() async {
    // Las fuentes están en assets/fonts: nada de red en los tests.
    GoogleFonts.config.allowRuntimeFetching = false;

    temporal = await Directory.systemTemp.createTemp('pixel_pvr_ui');
    final archivo = File('${temporal.path}/mini.png');
    await archivo.writeAsBytes(img.encodePng(img.Image(width: 8, height: 8)));
    miniatura = archivo.path;
  });

  tearDownAll(() async => temporal.delete(recursive: true));

  DocumentoEscaneado doc() => DocumentoEscaneado(
    id: '1',
    nombre: 'SCAN_20261012_1930',
    creadoEn: DateTime(2026, 10, 12, 19, 30),
    rutaArchivo: '${temporal.path}/1.pdf',
    rutaMiniatura: miniatura,
    formato: FormatoExportacion.pdf,
    filtro: FiltroImagen.colorOptimizado,
    tamanoBytes: 2048,
  );

  testWidgets('sin documentos muestra el estado vacío retro', (tester) async {
    await tester.pumpWidget(_app(FakeDocumentoRepository()));
    await tester.pumpAndSettle();

    expect(find.text('INSERT COIN'), findsOneWidget);
    expect(find.text('PIXEL VAULT'), findsOneWidget);
    expect(find.byType(PixelFab), findsOneWidget);
  });

  testWidgets('mientras carga muestra el indicador y luego el vault', (
    tester,
  ) async {
    final repo = FakeDocumentoRepository()..bloqueo = Completer<void>();

    await tester.pumpWidget(_app(repo));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('INSERT COIN'), findsNothing);

    repo.bloqueo!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('INSERT COIN'), findsOneWidget);
  });

  testWidgets('con documentos muestra contador, nombre y formato', (
    tester,
  ) async {
    await tester.pumpWidget(_app(FakeDocumentoRepository(iniciales: [doc()])));
    await tester.pumpAndSettle();

    expect(find.text('DOCS x1'), findsOneWidget);
    expect(find.text('HI-SCORE: 100'), findsOneWidget);
    expect(find.text('SCAN_20261012_1930'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('INSERT COIN'), findsNothing);
  });

  testWidgets('tocar una tarjeta abre el menú de opciones', (tester) async {
    _pantallaDeTelefono(tester);
    await tester.pumpWidget(_app(FakeDocumentoRepository(iniciales: [doc()])));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SCAN_20261012_1930'));
    await tester.pumpAndSettle();

    expect(find.text('OPCIONES'), findsOneWidget);
    expect(find.text('COMPARTIR'), findsOneWidget);
    expect(find.text('BORRAR'), findsOneWidget);
    expect(find.text('CERRAR'), findsOneWidget);
  });

  testWidgets('BORRAR quita la tarjeta del vault', (tester) async {
    _pantallaDeTelefono(tester);
    final repo = FakeDocumentoRepository(iniciales: [doc()]);

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('SCAN_20261012_1930'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BORRAR'));
    await tester.pumpAndSettle();

    expect(repo.documentos, isEmpty);
    expect(find.text('SCAN_20261012_1930'), findsNothing);
    expect(find.text('INSERT COIN'), findsOneWidget);
  });

  testWidgets('un fallo de lectura muestra la pantalla de error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(FakeDocumentoRepository()..fallaAlLeer = true),
    );
    await tester.pumpAndSettle();

    expect(find.text('GAME OVER'), findsOneWidget);
    expect(find.text('REINTENTAR'), findsOneWidget);
  });
}
