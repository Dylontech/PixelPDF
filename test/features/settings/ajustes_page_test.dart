import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pixel_pvr/core/app_info.dart';
import 'package:pixel_pvr/core/theme/pixel_theme.dart';
import 'package:pixel_pvr/features/settings/presentation/pages/ajustes_page.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('Ajustes queda para opciones futuras y conserva Acerca de', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PixelTheme.build(),
        home: const AjustesPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AJUSTES'), findsOneWidget);
    expect(find.text('${AppInfo.nombre} v${AppInfo.version}'), findsOneWidget);
    expect(find.text('ACERCA DE'), findsOneWidget);
    expect(find.text('PROXIMAMENTE'), findsOneWidget);

    // La firma de PDFs vive en el menú de la cabecera del vault, no aquí.
    expect(find.text('FIRMAR UN PDF'), findsNothing);
  });
}
