import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Firma ya rasterizada, lista para colocar en la página.
class FirmaRasterizada {
  const FirmaRasterizada({
    required this.png,
    required this.ancho,
    required this.alto,
  });

  final Uint8List png;
  final int ancho;
  final int alto;

  double get relacionAspecto => alto == 0 ? 1 : ancho / alto;
}

/// Convierte los trazos de la firma manuscrita en un PNG con transparencia.
///
/// El recorte se ajusta al rectángulo que ocupan los trazos (más un margen),
/// para que la firma no arrastre un lienzo en blanco enorme.
class FirmaService {
  const FirmaService();

  static const double _margen = 8;
  static const double _grosor = 3;

  /// Devuelve `null` si no hay ningún trazo.
  Future<FirmaRasterizada?> rasterizar(
    List<List<Offset>> trazos, {
    int anchoSalida = 900,
  }) async {
    final puntos = <Offset>[for (final trazo in trazos) ...trazo];
    if (puntos.isEmpty) return null;

    var minX = puntos.first.dx;
    var maxX = minX;
    var minY = puntos.first.dy;
    var maxY = minY;
    for (final punto in puntos) {
      if (punto.dx < minX) minX = punto.dx;
      if (punto.dx > maxX) maxX = punto.dx;
      if (punto.dy < minY) minY = punto.dy;
      if (punto.dy > maxY) maxY = punto.dy;
    }

    final anchoRecorte = (maxX - minX) + _margen * 2;
    final altoRecorte = (maxY - minY) + _margen * 2;
    final escala = anchoSalida / anchoRecorte;

    final grabador = ui.PictureRecorder();
    final canvas = Canvas(grabador);
    canvas.scale(escala);
    canvas.translate(-(minX - _margen), -(minY - _margen));

    final trazo = Paint()
      ..color = Colors.black
      ..strokeWidth = _grosor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final puntosDelTrazo in trazos) {
      if (puntosDelTrazo.length == 1) {
        canvas.drawCircle(
          puntosDelTrazo.first,
          _grosor / 2,
          Paint()..color = Colors.black,
        );
        continue;
      }
      final camino = Path()
        ..moveTo(puntosDelTrazo.first.dx, puntosDelTrazo.first.dy);
      for (final punto in puntosDelTrazo.skip(1)) {
        camino.lineTo(punto.dx, punto.dy);
      }
      canvas.drawPath(camino, trazo);
    }

    final ancho = (anchoRecorte * escala).round();
    final alto = (altoRecorte * escala).round();
    final imagen = await grabador.endRecording().toImage(ancho, alto);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    imagen.dispose();
    if (datos == null) return null;

    return FirmaRasterizada(
      png: datos.buffer.asUint8List(),
      ancho: ancho,
      alto: alto,
    );
  }

  /// Normaliza una imagen de firma importada (JPG/PNG) a PNG.
  Future<FirmaRasterizada> normalizarImagen(Uint8List bytes) async {
    final decodificada = img.decodeImage(bytes);
    if (decodificada == null) throw Exception('Imagen de firma no válida');
    final imagen = img.bakeOrientation(decodificada);
    return FirmaRasterizada(
      png: Uint8List.fromList(img.encodePng(imagen)),
      ancho: imagen.width,
      alto: imagen.height,
    );
  }
}
