import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixel_pvr/core/app_info.dart';
import 'package:pixel_pvr/core/services/enlaces_service.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/features/about/presentation/pages/acerca_de_page.dart';
import 'package:provider/provider.dart';

import '../../soporte/fakes.dart';

Widget _app(EnlacesService enlaces) => Provider<EnlacesService>.value(
  value: enlaces,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: PixelTheme.build(),
    home: const AcercaDePage(),
  ),
);

void _pantallaDeTelefono(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('cuenta qué es, que se hizo con IA y agradece', (tester) async {
    _pantallaDeTelefono(tester);
    await tester.pumpWidget(_app(FakeEnlacesService()));
    await tester.pumpAndSettle();

    expect(find.text('PIXELPDF'), findsOneWidget);
    expect(find.text('v${AppInfo.version}'), findsOneWidget);
    expect(find.text('QUE ES'), findsOneWidget);
    expect(find.text('CREADA CON IA'), findsOneWidget);
    expect(find.text('FUNCIONES'), findsOneWidget);
    expect(find.text('TODO PDF Y DYLONTECH'), findsOneWidget);
    expect(find.text('AGRADECIMIENTOS'), findsOneWidget);
  });

  testWidgets('menciona la firma de PDFs y el texto en cuadros', (
    tester,
  ) async {
    _pantallaDeTelefono(tester);
    await tester.pumpWidget(_app(FakeEnlacesService()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Firmar PDFs'), findsOneWidget);
    expect(find.textContaining('Cuadros de texto'), findsOneWidget);
  });

  testWidgets('muestra las dos direcciones de DylonTech', (tester) async {
    _pantallaDeTelefono(tester);
    await tester.pumpWidget(_app(FakeEnlacesService()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(AppInfo.urlTodoPdf),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text(AppInfo.urlTodoPdf), findsOneWidget);
    expect(find.text(AppInfo.urlDylontech), findsOneWidget);
  });

  testWidgets('los botones abren Todo PDF y DylonTech', (tester) async {
    _pantallaDeTelefono(tester);
    final enlaces = FakeEnlacesService();
    await tester.pumpWidget(_app(enlaces));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('TODO PDF'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('TODO PDF'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('DYLONTECH'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('DYLONTECH'));
    await tester.pumpAndSettle();

    expect(enlaces.abiertos, [AppInfo.urlTodoPdf, AppInfo.urlDylontech]);
    expect(find.text('NO SE PUDO ABRIR EL ENLACE'), findsNothing);
  });

  testWidgets('si el sistema no abre el enlace, lo avisa', (tester) async {
    _pantallaDeTelefono(tester);
    final enlaces = FakeEnlacesService()..exito = false;
    await tester.pumpWidget(_app(enlaces));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('TODO PDF'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('TODO PDF'));
    await tester.pumpAndSettle();

    expect(find.text('NO SE PUDO ABRIR EL ENLACE'), findsOneWidget);
  });
}
