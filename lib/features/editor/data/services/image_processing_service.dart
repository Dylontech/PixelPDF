import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../../vault/domain/entities/documento_escaneado.dart';

/// Argumentos serializables para los isolates (`compute`).
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
  }) => compute(
    _aplicarFiltroIsolate,
    _FiltroParams(bytes, filtro.index, anchoMax),
  );

  /// Convierte a JPG o PNG para exportar.
  Future<Uint8List> codificar(Uint8List bytes, FormatoExportacion formato) =>
      compute(
        _codificarIsolate,
        _CodificarParams(bytes, formato == FormatoExportacion.jpg),
      );

  Future<Uint8List> miniatura(Uint8List bytes) =>
      compute(_miniaturaIsolate, bytes);
}
