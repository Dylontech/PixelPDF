import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/anotacion.dart';
import 'package:pixel_pvr/features/annotate/domain/entities/zona_normalizada.dart';

void main() {
  const zona = ZonaNormalizada(left: 0.2, top: 0.2, width: 0.2, height: 0.2);

  group('ZonaNormalizada', () {
    test('desplazar mueve sin deformar la zona', () {
      final movida = zona.desplazar(0.1, 0.05);

      expect(movida.left, closeTo(0.3, 1e-9));
      expect(movida.top, closeTo(0.25, 1e-9));
      expect(movida.width, zona.width);
      expect(movida.height, zona.height);
    });

    test('desplazar no deja la anotación fuera de la página', () {
      const pegada = ZonaNormalizada(
        left: 0.85,
        top: 0.85,
        width: 0.15,
        height: 0.15,
      );
      final movida = pegada.desplazar(1, 1);

      expect(movida.left, closeTo(0.85, 1e-9));
      expect(movida.top, closeTo(0.85, 1e-9));
      expect(movida.derecha, lessThanOrEqualTo(1.0));
      expect(movida.abajo, lessThanOrEqualTo(1.0));
    });

    test('desplazar hacia el borde opuesto tampoco sale de la página', () {
      final movida = zona.desplazar(-5, -5);

      expect(movida.left, 0);
      expect(movida.top, 0);
    });

    test('redimensionar respeta un tamaño mínimo usable', () {
      final encogida = zona.redimensionar(-5, -5);

      expect(encogida.width, ZonaNormalizada.minimaDimension);
      expect(encogida.height, ZonaNormalizada.minimaDimension);
    });

    test('redimensionar no crece más allá de la página', () {
      const pegada = ZonaNormalizada(
        left: 0.9,
        top: 0.9,
        width: 0.1,
        height: 0.1,
      );
      final crecida = pegada.redimensionar(1, 1);

      expect(crecida.derecha, closeTo(1.0, 1e-9));
      expect(crecida.abajo, closeTo(1.0, 1e-9));
    });
  });

  group('Anotacion', () {
    test('el texto conserva su contenido al cambiar de zona', () {
      const original = AnotacionTexto(
        id: 'a1',
        pagina: 2,
        zona: zona,
        texto: 'Firmado',
        tamanoRelativo: 0.05,
        color: ColorAnotacion.azul,
      );
      final movida = original.conZona(zona.desplazar(0.1, 0.1));

      expect(movida.tipo, TipoAnotacion.texto);
      expect(movida.id, 'a1');
      expect(movida.pagina, 2);
      expect(movida.texto, 'Firmado');
      expect(movida.tamanoRelativo, 0.05);
      expect(movida.color, ColorAnotacion.azul);
      expect(movida.zona.left, closeTo(0.3, 1e-9));
    });

    test('la firma conserva sus bytes al cambiar de zona', () {
      final png = Uint8List.fromList([1, 2, 3]);
      final original = AnotacionFirma(
        id: 'f1',
        pagina: 0,
        zona: zona,
        png: png,
      );
      final movida = original.conZona(zona.redimensionar(0.1, 0.1));

      expect(movida.tipo, TipoAnotacion.firma);
      expect(movida.png, png);
      expect(movida.zona.width, closeTo(0.3, 1e-9));
    });
  });
}
