// Entidad de dominio (pura, sin dependencias de Flutter/Hive).

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

  /// Tolerante a datos viejos o corruptos: los enums desconocidos caen a un
  /// valor por defecto en lugar de romper la carga de todo el vault.
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
