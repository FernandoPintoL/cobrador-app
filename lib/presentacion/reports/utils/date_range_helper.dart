/// Helper para manejar rangos de fecha rápidos en reportes
class DateRangeHelper {
  static const List<String> labels = [
    'Hoy',
    'Ayer',
    'Últimos 7 días',
    'Mes actual',
    'Mes pasado',
    'Rango de fechas',
  ];

  /// Obtiene el rango de fechas para un índice (0-5)
  /// Retorna mapa con 'start' y 'end' en formato ISO
  static Map<String, String> getRangeForIndex(int idx) {
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String().split('T').first;

    switch (idx) {
      case 0: // Hoy
        final d = DateTime(now.year, now.month, now.day);
        return {'start': iso(d), 'end': iso(d)};

      case 1: // Ayer
        final d = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        return {'start': iso(d), 'end': iso(d)};

      case 2: // Últimos 7 días
        final end = DateTime(now.year, now.month, now.day);
        final start = end.subtract(const Duration(days: 6));
        return {'start': iso(start), 'end': iso(end)};

      case 3: // Mes actual
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month, now.day);
        return {'start': iso(start), 'end': iso(end)};

      case 4: // Mes pasado
        final firstThis = DateTime(now.year, now.month, 1);
        final lastPrev = firstThis.subtract(const Duration(days: 1));
        final firstPrev = DateTime(lastPrev.year, lastPrev.month, 1);
        return {'start': iso(firstPrev), 'end': iso(lastPrev)};

      default: // Rango de fechas (no aplicar rango automático)
        return {'start': '', 'end': ''};
    }
  }

  /// Obtiene el label para un índice
  static String getLabelForIndex(int idx) {
    if (idx >= 0 && idx < labels.length) {
      return labels[idx];
    }
    return 'Personalizado';
  }

  /// Verifica si un índice corresponde a "Rango de fechas" (índice 5)
  static bool isCustomRangeIndex(int idx) => idx == 5;
}
