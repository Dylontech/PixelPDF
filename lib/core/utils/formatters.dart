/// Utilidades de formato para la interfaz (fechas, tamaños, nombres).

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
