import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pvr/core/utils/formatters.dart';

void main() {
  group('formatearFecha', () {
    test('rellena día, mes, hora y minuto con ceros', () {
      expect(formatearFecha(DateTime(2026, 1, 5, 9, 7)), '05/01/2026 09:07');
    });

    test('usa dos dígitos cuando ya los tiene', () {
      expect(
        formatearFecha(DateTime(2026, 12, 31, 23, 59)),
        '31/12/2026 23:59',
      );
    });
  });

  group('formatearTamano', () {
    test('menos de 1 KB se muestra en bytes', () {
      expect(formatearTamano(0), '0 B');
      expect(formatearTamano(512), '512 B');
      expect(formatearTamano(1023), '1023 B');
    });

    test('desde 1 KB se muestra en KB con un decimal', () {
      expect(formatearTamano(1024), '1.0 KB');
      expect(formatearTamano(2048), '2.0 KB');
    });

    test('desde 1 MB se muestra en MB con un decimal', () {
      expect(formatearTamano(1024 * 1024), '1.0 MB');
      expect(formatearTamano(3 * 1024 * 1024), '3.0 MB');
    });
  });

  group('nombreAutomatico', () {
    test('sigue el patrón SCAN_aaaammdd_hhmm', () {
      expect(
        nombreAutomatico(DateTime(2026, 10, 12, 19, 30)),
        'SCAN_20261012_1930',
      );
    });
  });
}
