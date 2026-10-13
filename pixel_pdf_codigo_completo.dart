// =============================================================================
//  PIXEL PVR — Código base completo (MVP)
//  Escáner de documentos con estética Retro Pixel Art
//
//  Este archivo reúne TODO el código del MVP en un solo documento, organizado
//  por capas de Clean Architecture + MVVM. Puede ejecutarse tal cual como
//  `lib/main.dart`, o dividirse en carpetas siguiendo los marcadores
//  "// ▓▓▓ ARCHIVO: lib/..." (ver PIXEL_PVR_ANOTACIONES.md).
//
//  pubspec.yaml (ajusta a las últimas versiones estables):
//
//    dependencies:
//      flutter: { sdk: flutter }
//      provider: ^6.1.2
//      hive: ^2.2.3
//      hive_flutter: ^1.1.0
//      google_fonts: ^6.2.1
//      cunning_document_scanner: ^1.2.4   # detección de bordes + recorte auto
//      image_cropper: ^8.0.2              # ajuste manual de recorte
//      image: ^4.2.0                      # filtros de imagen
//      pdf: ^3.11.1                       # generación de PDF
//      path_provider: ^2.1.4
//      share_plus: ^10.1.0
//
//  Android: minSdkVersion 21+ (ver anotaciones para permisos/Manifest).
//  iOS: agregar NSCameraUsageDescription en Info.plist.
// =============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

// ▓▓▓ ARCHIVO: lib/core/utils/formatters.dart ▓▓▓

String formatearFecha(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return '${dos(d.day)}/${dos(d.month)}/${d.year} ${dos(d.hour)}:${dos(d.minute)}';
}

String formatearTamano(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String nombreAutomatico(DateTime d) {
  String dos(int n) => n.toString().padLeft(2, '0');
  return 'SCAN_${d.year}${dos(d.month)}${dos(d.day)}_${dos(d.hour)}${dos(d.minute)}';
}

// ▓▓▓ ARCHIVO: lib/core/theme/pixel_colors.dart ▓▓▓

/// Paleta "Neon Arcade": fondo azul noche + acentos de alto contraste.
class PixelColors {
  PixelColors._();

  static const fondo = Color(0xFF14122B); // azul noche
  static const superficie = Color(0xFF2A2750); // paneles
  static const superficieAlta = Color(0xFF3B3870); // paneles elevados
  static const magenta = Color(0xFFFF2E93); // acción principal
  static const cian = Color(0xFF00F5D4); // selección / títulos
  static const amarillo = Color(0xFFFEE440); // destacados / puntos
  static const verde = Color(0xFF9EF01A); // éxito
  static const texto = Color(0xFFF4F1FF);
  static const textoSuave = Color(0xFF9D9AC9);
  static const borde = Color(0xFFF4F1FF);
  static const sombra = Color(0xFF000000);
}

// ▓▓▓ ARCHIVO: lib/core/theme/pixel_theme.dart ▓▓▓

class PixelTheme {
  PixelTheme._();

  /// Estilo para títulos y botones (Press Start 2P, muy pequeño: es ancho).
  static TextStyle titulo({double size = 12, Color color = PixelColors.texto}) =>
      GoogleFonts.pressStart2P(fontSize: size, color: color, height: 1.4);

  /// Estilo para texto de lectura (VT323, más legible en tamaños medios).
  static TextStyle cuerpo({double size = 20, Color color = PixelColors.texto}) =>
      GoogleFonts.vt323(fontSize: size, color: color);

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: PixelColors.fondo,
      splashFactory: NoSplash.splashFactory,
      colorScheme: const ColorScheme.dark(
        primary: PixelColors.magenta,
        onPrimary: Colors.black,
        secondary: PixelColors.cian,
        onSecondary: Colors.black,
        tertiary: PixelColors.amarillo,
        surface: PixelColors.superficie,
        onSurface: PixelColors.texto,
        error: Color(0xFFFF5964),
      ),
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
      appBarTheme: AppBarTheme(
        backgroundColor: PixelColors.fondo,
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
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: PixelColors.cian),
    );
  }
}

// ▓▓▓ ARCHIVO: lib/core/widgets/pixel_box.dart ▓▓▓

/// Contenedor con esquinas "escalonadas", borde grueso y sombra dura offset.
/// Es la pieza base de toda la UI (tarjetas, botones, diálogos, chips).
class PixelBox extends StatelessWidget {
  const PixelBox({
    super.key,
    required this.child,
    this.color = PixelColors.superficie,
    this.borderColor = PixelColors.borde,
    this.pixel = 4,
    this.shadow = 4,
    this.padding = const EdgeInsets.all(12),
  });

  final Widget child;
  final Color color;
  final Color borderColor;

  /// Tamaño del "píxel" (profundidad del escalón de las esquinas).
  final double pixel;

  /// Desplazamiento de la sombra dura (0 = sin sombra).
  final double shadow;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: shadow, bottom: shadow),
      child: CustomPaint(
        painter: _PixelBoxPainter(
          color: color,
          borderColor: borderColor,
          pixel: pixel,
          shadow: shadow,
        ),
        child: Padding(
          padding: padding + EdgeInsets.all(pixel),
          child: child,
        ),
      ),
    );
  }
}

class _PixelBoxPainter extends CustomPainter {
  _PixelBoxPainter({
    required this.color,
    required this.borderColor,
    required this.pixel,
    required this.shadow,
  });

  final Color color;
  final Color borderColor;
  final double pixel;
  final double shadow;

  Path _escalon(Rect r, double n) => Path()
    ..moveTo(r.left + n, r.top)
    ..lineTo(r.right - n, r.top)
    ..lineTo(r.right - n, r.top + n)
    ..lineTo(r.right, r.top + n)
    ..lineTo(r.right, r.bottom - n)
    ..lineTo(r.right - n, r.bottom - n)
    ..lineTo(r.right - n, r.bottom)
    ..lineTo(r.left + n, r.bottom)
    ..lineTo(r.left + n, r.bottom - n)
    ..lineTo(r.left, r.bottom - n)
    ..lineTo(r.left, r.top + n)
    ..lineTo(r.left + n, r.top + n)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _escalon(Offset.zero & size, pixel);
    if (shadow > 0) {
      canvas.drawPath(
        path.shift(Offset(shadow, shadow)),
        Paint()
          ..isAntiAlias = false
          ..color = PixelColors.sombra,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = false
        ..color = color,
    );
    canvas.drawPath(
      path,
      Paint()
        ..isAntiAlias = false
        ..style = PaintingStyle.stroke
        ..strokeWidth = pixel / 2
        ..strokeJoin = StrokeJoin.miter
        ..color = borderColor,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelBoxPainter old) =>
      old.color != color ||
      old.borderColor != borderColor ||
      old.pixel != pixel ||
      old.shadow != shadow;
}

// ▓▓▓ ARCHIVO: lib/core/widgets/pixel_button.dart ▓▓▓

/// Botón tipo arcade: al presionarlo se "hunde" (se mueve y pierde sombra).
class PixelButton extends StatefulWidget {
  const PixelButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.color = PixelColors.magenta,
    this.textColor = Colors.black,
    this.expanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final bool expanded;

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _abajo = false;

  void _set(bool v) {
    if (widget.onPressed == null) return;
    setState(() => _abajo = v);
  }

  @override
  Widget build(BuildContext context) {
    final habilitado = widget.onPressed != null;
    final fondo = habilitado ? widget.color : PixelColors.superficieAlta;
    final texto = habilitado ? widget.textColor : PixelColors.textoSuave;

    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onPressed,
      child: Transform.translate(
        offset: _abajo ? const Offset(3, 3) : Offset.zero,
        child: PixelBox(
          color: fondo,
          shadow: _abajo ? 1 : 4,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: texto),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: PixelTheme.titulo(size: 10, color: texto),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ▓▓▓ ARCHIVO: lib/core/widgets/pixel_fab.dart ▓▓▓

/// Botón flotante con forma de botón de consola (ícono de gamepad).
class PixelFab extends StatefulWidget {
  const PixelFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<PixelFab> createState() => _PixelFabState();
}

class _PixelFabState extends State<PixelFab> {
  bool _abajo = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Escanear documento',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _abajo = true),
        onTapUp: (_) => setState(() => _abajo = false),
        onTapCancel: () => setState(() => _abajo = false),
        onTap: widget.onPressed,
        child: Transform.translate(
          offset: _abajo ? const Offset(4, 4) : Offset.zero,
          child: PixelBox(
            color: PixelColors.magenta,
            pixel: 6,
            shadow: _abajo ? 2 : 6,
            padding: EdgeInsets.zero,
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Center(
                child: Icon(Icons.sports_esports, size: 34, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ▓▓▓ ARCHIVO: lib/core/widgets/pixel_dialog.dart ▓▓▓

Future<void> mostrarPixelDialogo(
  BuildContext context, {
  required String titulo,
  required String mensaje,
  required List<Widget> acciones,
  Color colorTitulo = PixelColors.amarillo,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: PixelBox(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: PixelTheme.titulo(size: 12, color: colorTitulo)),
            const SizedBox(height: 12),
            Text(mensaje, style: PixelTheme.cuerpo(size: 20)),
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: acciones),
          ],
        ),
      ),
    ),
  );
}

// ▓▓▓ ARCHIVO: lib/features/vault/domain/entities/documento_escaneado.dart ▓▓▓

enum FormatoExportacion {
  pdf,
  jpg,
  png;

  String get extension => name;
  String get etiqueta => name.toUpperCase();
}

enum FiltroImagen {
  original,
  colorOptimizado,
  blancoNegro,
  escalaGrises,
  pixelArt;

  String get etiqueta => switch (this) {
        FiltroImagen.original => 'ORIGINAL',
        FiltroImagen.colorOptimizado => 'COLOR+',
        FiltroImagen.blancoNegro => 'B/N',
        FiltroImagen.escalaGrises => 'GRISES',
        FiltroImagen.pixelArt => 'PIXEL',
      };
}

/// Entidad de dominio (pura, sin dependencias de Flutter/Hive).
class DocumentoEscaneado {
  const DocumentoEscaneado({
    required this.id,
    required this.nombre,
    required this.creadoEn,
    required this.rutaArchivo,
    required this.rutaMiniatura,
    required this.formato,
    required this.filtro,
    required this.tamanoBytes,
    this.paginas = 1,
  });

  final String id;
  final String nombre;
  final DateTime creadoEn;
  final String rutaArchivo;
  final String rutaMiniatura;
  final FormatoExportacion formato;
  final FiltroImagen filtro;
  final int tamanoBytes;
  final int paginas;

  Map<String, dynamic> toMap() => {
        'id': id,
        'nombre': nombre,
        'creadoEn': creadoEn.toIso8601String(),
        'rutaArchivo': rutaArchivo,
        'rutaMiniatura': rutaMiniatura,
        'formato': formato.name,
        'filtro': filtro.name,
        'tamanoBytes': tamanoBytes,
        'paginas': paginas,
        'schemaVersion': 1,
      };

  factory DocumentoEscaneado.fromMap(Map<String, dynamic> m) =>
      DocumentoEscaneado(
        id: m['id'] as String,
        nombre: m['nombre'] as String,
        creadoEn: DateTime.parse(m['creadoEn'] as String),
        rutaArchivo: m['rutaArchivo'] as String,
        rutaMiniatura: m['rutaMiniatura'] as String,
        formato: FormatoExportacion.values.firstWhere(
          (f) => f.name == m['formato'],
          orElse: () => FormatoExportacion.pdf,
        ),
        filtro: FiltroImagen.values.firstWhere(
          (f) => f.name == m['filtro'],
          orElse: () => FiltroImagen.original,
        ),
        tamanoBytes: (m['tamanoBytes'] as num?)?.toInt() ?? 0,
        paginas: (m['paginas'] as num?)?.toInt() ?? 1,
      );
}

// ▓▓▓ ARCHIVO: lib/features/vault/domain/repositories/documento_repository.dart ▓▓▓

/// Contrato del repositorio. Hoy: almacenamiento local (Hive).
/// Mañana: una implementación híbrida local + Firebase sin tocar la UI.
abstract class DocumentoRepository {
  Future<List<DocumentoEscaneado>> obtenerTodos();
  Future<void> guardar(DocumentoEscaneado documento);
  Future<void> eliminar(DocumentoEscaneado documento);
}

// ▓▓▓ ARCHIVO: lib/features/vault/data/datasources/documento_local_datasource.dart ▓▓▓

/// Persistencia en Hive guardando cada documento como JSON (String).
/// Sin build_runner ni TypeAdapters: fácil de migrar a Isar después.
class DocumentoLocalDataSource {
  static const boxName = 'pixel_vault';

  Box<String> get _box => Hive.box<String>(boxName);

  Future<List<DocumentoEscaneado>> todos() async {
    final lista = _box.values
        .map((s) => DocumentoEscaneado.fromMap(
              jsonDecode(s) as Map<String, dynamic>,
            ))
        .toList();
    lista.sort((a, b) => b.creadoEn.compareTo(a.creadoEn));
    return lista;
  }

  Future<void> guardar(DocumentoEscaneado d) =>
      _box.put(d.id, jsonEncode(d.toMap()));

  Future<void> eliminar(String id) => _box.delete(id);
}

// ▓▓▓ ARCHIVO: lib/core/services/file_storage_service.dart ▓▓▓

class FileStorageService {
  Future<Directory> _directorio() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/pixel_vault');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Guarda bytes en el directorio de la app y devuelve la ruta absoluta.
  Future<String> guardar(String nombreArchivo, Uint8List bytes) async {
    final dir = await _directorio();
    final archivo = File('${dir.path}/$nombreArchivo');
    await archivo.writeAsBytes(bytes, flush: true);
    return archivo.path;
  }

  Future<void> borrarSiExiste(String ruta) async {
    final f = File(ruta);
    if (await f.exists()) await f.delete();
  }
}

// ▓▓▓ ARCHIVO: lib/features/vault/data/repositories/documento_repository_impl.dart ▓▓▓

class DocumentoRepositoryImpl implements DocumentoRepository {
  DocumentoRepositoryImpl(this._local, this._storage);

  final DocumentoLocalDataSource _local;
  final FileStorageService _storage;

  @override
  Future<List<DocumentoEscaneado>> obtenerTodos() => _local.todos();

  @override
  Future<void> guardar(DocumentoEscaneado documento) =>
      _local.guardar(documento);

  @override
  Future<void> eliminar(DocumentoEscaneado documento) async {
    await _storage.borrarSiExiste(documento.rutaArchivo);
    await _storage.borrarSiExiste(documento.rutaMiniatura);
    await _local.eliminar(documento.id);
  }
}

// ▓▓▓ ARCHIVO: lib/features/editor/data/services/image_processing_service.dart ▓▓▓

class _FiltroParams {
  const _FiltroParams(this.bytes, this.filtroIndex, this.anchoMax);
  final Uint8List bytes;
  final int filtroIndex;
  final int anchoMax;
}

class _CodificarParams {
  const _CodificarParams(this.bytes, this.jpg);
  final Uint8List bytes;
  final bool jpg;
}

/// Se ejecuta en un isolate (compute) para no congelar la UI.
Uint8List _aplicarFiltroIsolate(_FiltroParams p) {
  final decodificada = img.decodeImage(p.bytes);
  if (decodificada == null) throw Exception('Imagen inválida');

  img.Image imagen = img.bakeOrientation(decodificada);
  if (imagen.width > p.anchoMax) {
    imagen = img.copyResize(imagen, width: p.anchoMax);
  }

  switch (FiltroImagen.values[p.filtroIndex]) {
    case FiltroImagen.original:
      break;

    case FiltroImagen.colorOptimizado:
      imagen = img.adjustColor(
        imagen,
        contrast: 1.25,
        saturation: 1.15,
        brightness: 1.05,
      );
      break;

    case FiltroImagen.escalaGrises:
      imagen = img.grayscale(imagen);
      break;

    case FiltroImagen.blancoNegro:
      imagen = img.grayscale(imagen);
      imagen = img.adjustColor(imagen, contrast: 1.4);
      for (final px in imagen) {
        final v = px.r > 140 ? 255 : 0;
        px
          ..r = v
          ..g = v
          ..b = v;
      }
      break;

    case FiltroImagen.pixelArt:
      final anchoOriginal = imagen.width;
      final pequena = img.copyResize(
        imagen,
        width: 120,
        interpolation: img.Interpolation.average,
      );
      final cuantizada = img.quantize(pequena, numberOfColors: 16);
      imagen = img.copyResize(
        cuantizada,
        width: anchoOriginal,
        interpolation: img.Interpolation.nearest,
      );
      break;
  }

  return Uint8List.fromList(img.encodePng(imagen));
}

Uint8List _codificarIsolate(_CodificarParams p) {
  final imagen = img.decodeImage(p.bytes);
  if (imagen == null) throw Exception('Imagen inválida');
  return p.jpg
      ? Uint8List.fromList(img.encodeJpg(imagen, quality: 90))
      : Uint8List.fromList(img.encodePng(imagen));
}

Uint8List _miniaturaIsolate(Uint8List bytes) {
  final imagen = img.decodeImage(bytes);
  if (imagen == null) throw Exception('Imagen inválida');
  final mini = img.copyResize(imagen, width: 240);
  return Uint8List.fromList(img.encodeJpg(mini, quality: 80));
}

class ImageProcessingService {
  /// Aplica un filtro y devuelve PNG (lossless) para la vista previa.
  Future<Uint8List> aplicarFiltro(
    Uint8List bytes,
    FiltroImagen filtro, {
    int anchoMax = 1600,
  }) =>
      compute(_aplicarFiltroIsolate, _FiltroParams(bytes, filtro.index, anchoMax));

  /// Convierte a JPG o PNG para exportar.
  Future<Uint8List> codificar(Uint8List bytes, FormatoExportacion formato) =>
      compute(
        _codificarIsolate,
        _CodificarParams(bytes, formato == FormatoExportacion.jpg),
      );

  Future<Uint8List> miniatura(Uint8List bytes) =>
      compute(_miniaturaIsolate, bytes);
}

// ▓▓▓ ARCHIVO: lib/features/export/data/services/pdf_export_service.dart ▓▓▓

class PdfExportService {
  /// Genera un PDF A4 con la imagen centrada y ajustada (sin deformarla).
  Future<Uint8List> crearPdf(Uint8List jpgBytes) async {
    final documento = pw.Document(title: 'Pixel PVR', creator: 'Pixel PVR');
    final imagen = pw.MemoryImage(jpgBytes);

    documento.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => pw.Center(
          child: pw.Image(imagen, fit: pw.BoxFit.contain),
        ),
      ),
    );

    return documento.save();
  }
}

// ▓▓▓ ARCHIVO: lib/features/export/domain/usecases/exportar_documento.dart ▓▓▓

/// Caso de uso: convierte → guarda archivo → guarda miniatura → registra.
class ExportarDocumento {
  ExportarDocumento({
    required this.repositorio,
    required this.almacenamiento,
    required this.imagen,
    required this.pdf,
  });

  final DocumentoRepository repositorio;
  final FileStorageService almacenamiento;
  final ImageProcessingService imagen;
  final PdfExportService pdf;

  Future<DocumentoEscaneado> call({
    required Uint8List imagenProcesada,
    required String nombre,
    required FormatoExportacion formato,
    required FiltroImagen filtro,
  }) async {
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    Uint8List salida;
    if (formato == FormatoExportacion.pdf) {
      final jpg = await imagen.codificar(imagenProcesada, FormatoExportacion.jpg);
      salida = await pdf.crearPdf(jpg);
    } else {
      salida = await imagen.codificar(imagenProcesada, formato);
    }

    final rutaArchivo =
        await almacenamiento.guardar('$id.${formato.extension}', salida);
    final miniatura = await imagen.miniatura(imagenProcesada);
    final rutaMiniatura =
        await almacenamiento.guardar('${id}_thumb.jpg', miniatura);

    final documento = DocumentoEscaneado(
      id: id,
      nombre: nombre,
      creadoEn: DateTime.now(),
      rutaArchivo: rutaArchivo,
      rutaMiniatura: rutaMiniatura,
      formato: formato,
      filtro: filtro,
      tamanoBytes: salida.length,
    );
    await repositorio.guardar(documento);
    return documento;
  }
}

// ▓▓▓ ARCHIVO: lib/features/scanner/data/services/escaner_service.dart ▓▓▓

/// Abstracción del escáner: permite cambiar el motor (ML Kit, OpenCV, etc.)
/// sin afectar presentación ni dominio.
abstract class EscanerService {
  /// Devuelve la ruta de la imagen recortada o null si el usuario cancela.
  Future<String?> capturar();
}

/// Usa el escáner nativo (ML Kit en Android / VisionKit en iOS): detección
/// automática de bordes, corrección de perspectiva y recorte, con ajuste
/// manual de esquinas dentro de su propia interfaz.
class NativoEscanerService implements EscanerService {
  @override
  Future<String?> capturar() async {
    final rutas = await CunningDocumentScanner.getPictures(
      noOfPages: 1,
      isGalleryImportAllowed: true,
    );
    if (rutas == null || rutas.isEmpty) return null;
    return rutas.first;
  }
}

// ▓▓▓ ARCHIVO: lib/features/vault/presentation/viewmodels/vault_viewmodel.dart ▓▓▓

class VaultViewModel extends ChangeNotifier {
  VaultViewModel(this._repositorio);

  final DocumentoRepository _repositorio;

  List<DocumentoEscaneado> documentos = [];
  bool cargando = true;

  Future<void> cargar() async {
    cargando = true;
    notifyListeners();
    documentos = await _repositorio.obtenerTodos();
    cargando = false;
    notifyListeners();
  }

  Future<void> eliminar(DocumentoEscaneado doc) async {
    await _repositorio.eliminar(doc);
    documentos = documentos.where((d) => d.id != doc.id).toList();
    notifyListeners();
  }
}

// ▓▓▓ ARCHIVO: lib/features/editor/presentation/viewmodels/editor_viewmodel.dart ▓▓▓

class EditorViewModel extends ChangeNotifier {
  EditorViewModel({
    required String rutaOriginal,
    required ExportarDocumento exportarDocumento,
    required ImageProcessingService procesamiento,
  })  : _ruta = rutaOriginal,
        _exportar = exportarDocumento,
        _procesamiento = procesamiento;

  final ExportarDocumento _exportar;
  final ImageProcessingService _procesamiento;

  String _ruta;
  Uint8List? _bytesOriginales;
  final Map<FiltroImagen, Uint8List> _cache = {};
  bool _disposed = false;

  FiltroImagen filtro = FiltroImagen.colorOptimizado;
  FormatoExportacion formato = FormatoExportacion.pdf;
  bool procesando = false;
  bool exportando = false;
  String? error;

  String get rutaActual => _ruta;
  Uint8List? get vista => _cache[filtro];

  void _notificar() {
    if (!_disposed) notifyListeners();
  }

  Future<void> iniciar() => cargarDesdeRuta(_ruta);

  /// Carga (o recarga tras recortar) la imagen base y reaplica el filtro.
  Future<void> cargarDesdeRuta(String ruta) async {
    _ruta = ruta;
    _cache.clear();
    procesando = true;
    error = null;
    _notificar();
    try {
      _bytesOriginales = await File(ruta).readAsBytes();
      await _procesar(filtro);
    } catch (_) {
      error = 'NO SE PUDO CARGAR LA IMAGEN';
    }
    procesando = false;
    _notificar();
  }

  Future<void> seleccionarFiltro(FiltroImagen nuevo) async {
    filtro = nuevo;
    if (_cache.containsKey(nuevo)) {
      _notificar();
      return;
    }
    procesando = true;
    _notificar();
    try {
      await _procesar(nuevo);
    } catch (_) {
      error = 'ERROR AL APLICAR EL FILTRO';
    }
    procesando = false;
    _notificar();
  }

  void seleccionarFormato(FormatoExportacion nuevo) {
    formato = nuevo;
    _notificar();
  }

  Future<void> _procesar(FiltroImagen f) async {
    final resultado = await _procesamiento.aplicarFiltro(_bytesOriginales!, f);
    _cache[f] = resultado;
  }

  Future<DocumentoEscaneado?> exportar() async {
    final bytes = vista;
    if (bytes == null) return null;
    exportando = true;
    error = null;
    _notificar();
    try {
      return await _exportar(
        imagenProcesada: bytes,
        nombre: nombreAutomatico(DateTime.now()),
        formato: formato,
        filtro: filtro,
      );
    } catch (_) {
      error = 'NO SE PUDO EXPORTAR';
      return null;
    } finally {
      exportando = false;
      _notificar();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

// ▓▓▓ ARCHIVO: lib/features/vault/presentation/pages/vault_page.dart ▓▓▓

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  Future<void> _escanear(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final escaner = context.read<EscanerService>();
    final vault = context.read<VaultViewModel>();

    try {
      final ruta = await escaner.capturar();
      if (ruta == null) return;
      await navigator.push(
        MaterialPageRoute(builder: (_) => EditorPage(rutaImagen: ruta)),
      );
      await vault.cargar();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('NO SE PUDO ABRIR LA CAMARA')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<VaultViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('PIXEL VAULT')),
      floatingActionButton: PixelFab(onPressed: () => _escanear(context)),
      body: SafeArea(
        child: vm.cargando
            ? const Center(child: CircularProgressIndicator())
            : vm.documentos.isEmpty
                ? const _EstadoVacio()
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'DOCS x${vm.documentos.length}',
                              style: PixelTheme.titulo(
                                size: 10,
                                color: PixelColors.amarillo,
                              ),
                            ),
                            Text('HI-SCORE: ${vm.documentos.length * 100}',
                                style: PixelTheme.cuerpo(
                                  size: 20,
                                  color: PixelColors.verde,
                                )),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: vm.documentos.length,
                          itemBuilder: (_, i) =>
                              _TarjetaDocumento(doc: vm.documentos[i]),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: PixelBox(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('INSERT COIN',
                  style: PixelTheme.titulo(size: 14, color: PixelColors.amarillo)),
              const SizedBox(height: 16),
              const Icon(Icons.sports_esports,
                  size: 56, color: PixelColors.magenta),
              const SizedBox(height: 16),
              Text(
                'Tu vault esta vacio.\nPulsa el boton de abajo para\nescanear tu primer documento.',
                textAlign: TextAlign.center,
                style: PixelTheme.cuerpo(size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TarjetaDocumento extends StatelessWidget {
  const _TarjetaDocumento({required this.doc});

  final DocumentoEscaneado doc;

  Future<void> _abrirMenu(BuildContext context) async {
    final vault = context.read<VaultViewModel>();
    await mostrarPixelDialogo(
      context,
      titulo: 'OPCIONES',
      colorTitulo: PixelColors.cian,
      mensaje: '${doc.nombre}\n${doc.formato.etiqueta} · ${formatearTamano(doc.tamanoBytes)}',
      acciones: [
        PixelButton(
          label: 'COMPARTIR',
          icon: Icons.share,
          color: PixelColors.cian,
          onPressed: () {
            Navigator.of(context).pop();
            Share.shareXFiles([XFile(doc.rutaArchivo)], text: doc.nombre);
          },
        ),
        PixelButton(
          label: 'BORRAR',
          icon: Icons.delete,
          color: const Color(0xFFFF5964),
          onPressed: () async {
            Navigator.of(context).pop();
            await vault.eliminar(doc);
          },
        ),
        PixelButton(
          label: 'CERRAR',
          color: PixelColors.superficieAlta,
          textColor: PixelColors.texto,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = switch (doc.formato) {
      FormatoExportacion.pdf => PixelColors.magenta,
      FormatoExportacion.jpg => PixelColors.amarillo,
      FormatoExportacion.png => PixelColors.verde,
    };

    return GestureDetector(
      onTap: () => _abrirMenu(context),
      child: PixelBox(
        padding: const EdgeInsets.all(6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.black,
                child: Image.file(
                  File(doc.rutaMiniatura),
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.none,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image,
                    color: PixelColors.textoSuave,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              doc.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PixelTheme.titulo(size: 8),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  color: color,
                  child: Text(doc.formato.etiqueta,
                      style: PixelTheme.cuerpo(size: 16, color: Colors.black)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    formatearFecha(doc.creadoEn).split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    style: PixelTheme.cuerpo(
                      size: 16,
                      color: PixelColors.textoSuave,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ▓▓▓ ARCHIVO: lib/features/editor/presentation/pages/editor_page.dart ▓▓▓

class EditorPage extends StatelessWidget {
  const EditorPage({super.key, required this.rutaImagen});

  final String rutaImagen;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (c) => EditorViewModel(
        rutaOriginal: rutaImagen,
        exportarDocumento: c.read<ExportarDocumento>(),
        procesamiento: c.read<ImageProcessingService>(),
      )..iniciar(),
      child: const _EditorView(),
    );
  }
}

class _EditorView extends StatelessWidget {
  const _EditorView();

  Future<void> _recortar(BuildContext context, EditorViewModel vm) async {
    final recortado = await ImageCropper().cropImage(
      sourcePath: vm.rutaActual,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'AJUSTAR RECORTE',
          toolbarColor: PixelColors.fondo,
          toolbarWidgetColor: PixelColors.cian,
          backgroundColor: PixelColors.fondo,
          activeControlsWidgetColor: PixelColors.magenta,
          cropFrameColor: PixelColors.cian,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'AJUSTAR RECORTE',
          aspectRatioLockEnabled: false,
        ),
      ],
    );
    if (recortado != null) await vm.cargarDesdeRuta(recortado.path);
  }

  Future<void> _guardar(BuildContext context, EditorViewModel vm) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final doc = await vm.exportar();
    if (doc == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(vm.error ?? 'NO SE PUDO GUARDAR')),
      );
      return;
    }
    if (!context.mounted) return;

    await mostrarPixelDialogo(
      context,
      titulo: 'LEVEL CLEAR!',
      colorTitulo: PixelColors.verde,
      mensaje:
          'Guardado como ${doc.formato.etiqueta}\n${doc.nombre}\n${formatearTamano(doc.tamanoBytes)}',
      acciones: [
        PixelButton(
          label: 'COMPARTIR',
          icon: Icons.share,
          color: PixelColors.cian,
          onPressed: () =>
              Share.shareXFiles([XFile(doc.rutaArchivo)], text: doc.nombre),
        ),
        PixelButton(
          label: 'OK',
          color: PixelColors.verde,
          onPressed: () {
            Navigator.of(context).pop(); // cierra diálogo
            navigator.pop(); // vuelve al vault
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<EditorViewModel>();
    final ocupado = vm.procesando || vm.exportando;

    return Scaffold(
      appBar: AppBar(title: const Text('EDITOR')),
      body: SafeArea(
        child: Column(
          children: [
            // Vista previa
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: PixelBox(
                    color: Colors.black,
                    padding: const EdgeInsets.all(6),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (vm.vista != null)
                          InteractiveViewer(
                            maxScale: 5,
                            child: Image.memory(
                              vm.vista!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: vm.filtro == FiltroImagen.pixelArt
                                  ? FilterQuality.none
                                  : FilterQuality.medium,
                            ),
                          ),
                        if (vm.error != null && vm.vista == null)
                          Text(vm.error!,
                              style: PixelTheme.titulo(
                                size: 10,
                                color: const Color(0xFFFF5964),
                              )),
                        if (ocupado)
                          Container(
                            color: Colors.black54,
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  vm.exportando ? 'GUARDANDO...' : 'CARGANDO...',
                                  style: PixelTheme.titulo(
                                    size: 10,
                                    color: PixelColors.cian,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Filtros
            _Seccion(
              titulo: 'FILTRO',
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final f in FiltroImagen.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _PixelChip(
                          label: f.etiqueta,
                          seleccionado: vm.filtro == f,
                          onTap: ocupado ? null : () => vm.seleccionarFiltro(f),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Formato
            _Seccion(
              titulo: 'FORMATO',
              child: Row(
                children: [
                  for (final f in FormatoExportacion.values)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _PixelChip(
                          label: f.etiqueta,
                          seleccionado: vm.formato == f,
                          onTap: ocupado ? null : () => vm.seleccionarFormato(f),
                          expandido: true,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Acciones
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: PixelButton(
                      label: 'RECORTAR',
                      icon: Icons.crop,
                      color: PixelColors.amarillo,
                      expanded: true,
                      onPressed: ocupado ? null : () => _recortar(context, vm),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PixelButton(
                      label: 'GUARDAR',
                      icon: Icons.save,
                      color: PixelColors.magenta,
                      expanded: true,
                      onPressed:
                          ocupado || vm.vista == null ? null : () => _guardar(context, vm),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: PixelTheme.titulo(size: 8, color: PixelColors.textoSuave)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _PixelChip extends StatelessWidget {
  const _PixelChip({
    required this.label,
    required this.seleccionado,
    required this.onTap,
    this.expandido = false,
  });

  final String label;
  final bool seleccionado;
  final VoidCallback? onTap;
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final fondo = seleccionado ? PixelColors.cian : PixelColors.superficie;
    final texto = seleccionado ? Colors.black : PixelColors.texto;

    return GestureDetector(
      onTap: onTap,
      child: PixelBox(
        color: fondo,
        pixel: 3,
        shadow: seleccionado ? 0 : 3,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: expandido
            ? Center(
                child: Text(label, style: PixelTheme.titulo(size: 9, color: texto)),
              )
            : Text(label, style: PixelTheme.titulo(size: 9, color: texto)),
      ),
    );
  }
}

// ▓▓▓ ARCHIVO: lib/app.dart ▓▓▓

class PixelPvrApp extends StatelessWidget {
  const PixelPvrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Infraestructura
        Provider<FileStorageService>(create: (_) => FileStorageService()),
        Provider<ImageProcessingService>(create: (_) => ImageProcessingService()),
        Provider<PdfExportService>(create: (_) => PdfExportService()),
        Provider<EscanerService>(create: (_) => NativoEscanerService()),

        // Repositorio (punto de extensión para Firebase en el futuro)
        Provider<DocumentoRepository>(
          create: (c) => DocumentoRepositoryImpl(
            DocumentoLocalDataSource(),
            c.read<FileStorageService>(),
          ),
        ),

        // Casos de uso
        Provider<ExportarDocumento>(
          create: (c) => ExportarDocumento(
            repositorio: c.read<DocumentoRepository>(),
            almacenamiento: c.read<FileStorageService>(),
            imagen: c.read<ImageProcessingService>(),
            pdf: c.read<PdfExportService>(),
          ),
        ),

        // ViewModels globales
        ChangeNotifierProvider<VaultViewModel>(
          create: (c) => VaultViewModel(c.read<DocumentoRepository>())..cargar(),
        ),
      ],
      child: MaterialApp(
        title: 'Pixel PVR',
        debugShowCheckedModeBanner: false,
        theme: PixelTheme.build(),
        home: const VaultPage(),
      ),
    );
  }
}

// ▓▓▓ ARCHIVO: lib/main.dart ▓▓▓

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>(DocumentoLocalDataSource.boxName);
  runApp(const PixelPvrApp());
}
