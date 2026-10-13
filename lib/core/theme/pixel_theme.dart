import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pixel_colors.dart';

/// Tipografías y [ThemeData] de la app.
///
/// Las dos fuentes van empaquetadas en `assets/fonts/`, así que `google_fonts`
/// las resuelve del bundle y nunca necesita red en el primer arranque.
class PixelTheme {
  PixelTheme._();

  /// Estilo para títulos y botones (Press Start 2P, muy pequeño: es ancho).
  static TextStyle titulo({
    double size = 12,
    Color color = PixelColors.texto,
  }) => GoogleFonts.pressStart2P(fontSize: size, color: color, height: 1.4);

  /// Estilo para texto de lectura (VT323, más legible en tamaños medios).
  static TextStyle cuerpo({
    double size = 20,
    Color color = PixelColors.texto,
  }) => GoogleFonts.vt323(fontSize: size, color: color);

  static ThemeData build() {
    final base = ThemeData(brightness: Brightness.dark);

    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: PixelColors.magenta,
        onPrimary: Colors.black,
        secondary: PixelColors.cian,
        onSecondary: Colors.black,
        tertiary: PixelColors.amarillo,
        surface: PixelColors.superficie,
        onSurface: PixelColors.texto,
        error: PixelColors.rojo,
      ),
      scaffoldBackgroundColor: PixelColors.fondo,
      // Nada de ondas Material: el feedback lo da el propio PixelButton.
      splashFactory: NoSplash.splashFactory,
      textTheme: GoogleFonts.vt323TextTheme(base.textTheme)
          .apply(bodyColor: PixelColors.texto, displayColor: PixelColors.texto)
          .copyWith(
            titleLarge: titulo(size: 16),
            titleMedium: titulo(size: 12),
            titleSmall: titulo(size: 10),
            labelLarge: titulo(size: 10),
            bodyLarge: cuerpo(size: 22),
            bodyMedium: cuerpo(size: 20),
            bodySmall: cuerpo(size: 16, color: PixelColors.textoSuave),
          ),
      appBarTheme: AppBarThemeData(
        backgroundColor: PixelColors.fondo,
        foregroundColor: PixelColors.cian,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: titulo(size: 14, color: PixelColors.cian),
        iconTheme: const IconThemeData(color: PixelColors.cian),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: PixelColors.superficieAlta,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: PixelColors.borde, width: 3),
        ),
        contentTextStyle: cuerpo(size: 20),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: PixelColors.cian,
      ),
    );
  }
}
