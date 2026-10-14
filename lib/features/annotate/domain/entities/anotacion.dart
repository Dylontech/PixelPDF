import 'dart:typed_data';

import 'zona_normalizada.dart';

enum TipoAnotacion { texto, firma }

/// Colores disponibles para el texto, sin depender de Flutter en el dominio.
enum ColorAnotacion { negro, azul, rojo }

/// Anotación colocada sobre una página concreta.
///
/// Es inmutable: mover o redimensionar devuelve una copia, de modo que el
/// historial de deshacer es una lista de instantáneas.
sealed class Anotacion {
  const Anotacion({required this.id, required this.pagina, required this.zona});

  final String id;
  final int pagina;
  final ZonaNormalizada zona;

  TipoAnotacion get tipo;

  Anotacion conZona(ZonaNormalizada nueva);
}

class AnotacionTexto extends Anotacion {
  const AnotacionTexto({
    required super.id,
    required super.pagina,
    required super.zona,
    required this.texto,
    required this.tamanoRelativo,
    this.color = ColorAnotacion.negro,
  });

  final String texto;

  /// Alto de la fuente dividido entre el alto de la página (0..1).
  final double tamanoRelativo;
  final ColorAnotacion color;

  @override
  TipoAnotacion get tipo => TipoAnotacion.texto;

  @override
  AnotacionTexto conZona(ZonaNormalizada nueva) => AnotacionTexto(
    id: id,
    pagina: pagina,
    zona: nueva,
    texto: texto,
    tamanoRelativo: tamanoRelativo,
    color: color,
  );
}

class AnotacionFirma extends Anotacion {
  const AnotacionFirma({
    required super.id,
    required super.pagina,
    required super.zona,
    required this.png,
  });

  /// PNG con transparencia de la firma (dibujada a mano o importada).
  final Uint8List png;

  @override
  TipoAnotacion get tipo => TipoAnotacion.firma;

  @override
  AnotacionFirma conZona(ZonaNormalizada nueva) =>
      AnotacionFirma(id: id, pagina: pagina, zona: nueva, png: png);
}
