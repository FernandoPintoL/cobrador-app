import '../../../datos/modelos/usuario.dart';

/// Servicio para proporcionar valores por defecto inteligentes
/// para filtros de reportes según el tipo de reporte y rol del usuario
class ReportDefaultsService {
  /// Obtiene los filtros por defecto para un tipo de reporte específico
  ///
  /// Estrategia:
  /// - FECHAS: "HOY" para la mayoría de reportes (datos más recientes y relevantes)
  /// - ESTADOS: Según el contexto del reporte (activos, completed, etc.)
  /// - COBRADOR: Usuario actual si es cobrador, null si es manager/admin
  static Map<String, dynamic> getDefaultFilters({
    required String reportType,
    required Usuario? usuario,
  }) {
    final now = DateTime.now();

    // Defaults comunes para todos los reportes
    final defaults = <String, dynamic>{};

    // Si es cobrador, siempre filtrar por su ID
    if (usuario?.esCobrador() == true) {
      defaults['cobrador_id'] = usuario!.id.toInt();
    }

    // Defaults específicos por tipo de reporte
    switch (reportType) {
      case 'payments':
        return {
          ...defaults,
          'start_date': now,
          'end_date': now,
          'status': 'completed', // Solo pagos completados por defecto
        };

      case 'credits':
        return {
          ...defaults,
          'start_date': now, // HOY por defecto (más relevante)
          'end_date': now,
          'status': 'active', // Solo créditos activos por defecto
        };

      case 'overdue':
        // Mora: Mostrar datos de hoy, todos los estados
        return {
          ...defaults,
          // No filtro de fechas para mora - queremos ver TODA la mora acumulada
          // Opcionalmente se puede descomentar esto:
          // 'min_days_overdue': 1, // Al menos 1 día de atraso
        };

      case 'daily-activity':
        return {
          ...defaults,
          'date': now, // Actividad de HOY
        };

      case 'balances':
        return {
          ...defaults,
          'start_date': now,
          'end_date': now,
          'status': 'open', // Solo balances abiertos
        };

      case 'users':
        // Reporte de usuarios: sin defaults de fecha
        return defaults;

      case 'performance':
        // Performance: Última semana
        return {
          ...defaults,
          'start_date': now.subtract(const Duration(days: 7)),
          'end_date': now,
        };

      case 'waiting-list':
        // Lista de espera: sin defaults de fecha (mostrar todo)
        return defaults;

      case 'portfolio':
        // Portafolio: sin defaults de fecha (snapshot actual)
        return defaults;

      case 'commissions':
        // Comisiones: Mes actual
        return {
          ...defaults,
          'start_date': DateTime(now.year, now.month, 1), // Primer día del mes
          'end_date': now,
        };

      default:
        // Default genérico: HOY
        return {
          ...defaults,
          'start_date': now,
          'end_date': now,
        };
    }
  }

  /// Obtiene el índice del chip de rango rápido que corresponde a los defaults
  ///
  /// Índices de chips rápidos:
  /// 0: Hoy
  /// 1: Ayer
  /// 2: Esta semana
  /// 3: Semana pasada
  /// 4: Este mes
  /// 5: Mes pasado
  static int? getDefaultQuickRangeIndex(String reportType) {
    switch (reportType) {
      case 'payments':
      case 'daily-activity':
      case 'balances':
      case 'credits': // ✅ Cambiar credits a "Hoy" en vez de "Esta semana"
        return 0; // Hoy

      case 'performance':
        return 2; // Esta semana

      case 'commissions':
        return 4; // Este mes

      case 'overdue':
      case 'users':
      case 'waiting-list':
      case 'portfolio':
        return null; // Sin rango rápido por defecto

      default:
        return 0; // Hoy por defecto
    }
  }

  /// Obtiene una descripción legible de los filtros aplicados
  /// Útil para mostrar al usuario qué está viendo
  static String getFiltersDescription(
    Map<String, dynamic> filters,
    String reportType,
  ) {
    final parts = <String>[];

    // Descripción de fechas
    if (filters.containsKey('date')) {
      final date = filters['date'] as DateTime;
      final isToday = _isSameDay(date, DateTime.now());
      parts.add(isToday ? 'Hoy' : _formatDate(date));
    } else if (filters.containsKey('start_date') && filters.containsKey('end_date')) {
      final start = filters['start_date'] as DateTime;
      final end = filters['end_date'] as DateTime;

      if (_isSameDay(start, end)) {
        final isToday = _isSameDay(start, DateTime.now());
        parts.add(isToday ? 'Hoy' : _formatDate(start));
      } else {
        parts.add('${_formatDate(start)} - ${_formatDate(end)}');
      }
    }

    // Descripción de estado
    if (filters.containsKey('status')) {
      final status = filters['status'] as String;
      parts.add(_translateStatus(status, reportType));
    }

    // Descripción de cobrador
    if (filters.containsKey('cobrador_id')) {
      parts.add('Mis datos');
    }

    return parts.isEmpty ? 'Sin filtros' : parts.join(' • ');
  }

  /// Verifica si dos fechas son el mismo día
  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Formatea una fecha de manera legible
  static String _formatDate(DateTime date) {
    final now = DateTime.now();

    if (_isSameDay(date, now)) return 'Hoy';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return 'Ayer';

    return '${date.day}/${date.month}/${date.year}';
  }

  /// Traduce el código de estado a texto legible
  static String _translateStatus(String status, String reportType) {
    if (reportType == 'credits') {
      switch (status) {
        case 'active': return 'Activos';
        case 'completed': return 'Completados';
        case 'pending_approval': return 'Pendientes';
        case 'cancelled': return 'Cancelados';
        default: return status;
      }
    } else if (reportType == 'payments') {
      switch (status) {
        case 'completed': return 'Completados';
        case 'pending': return 'Pendientes';
        case 'failed': return 'Fallidos';
        default: return status;
      }
    } else if (reportType == 'balances') {
      switch (status) {
        case 'open': return 'Abiertos';
        case 'closed': return 'Cerrados';
        case 'reconciled': return 'Reconciliados';
        default: return status;
      }
    }

    return status;
  }

  /// Verifica si los filtros actuales son los defaults
  static bool areDefaultFilters({
    required Map<String, dynamic> currentFilters,
    required Map<String, dynamic> defaultFilters,
  }) {
    // Si tienen diferente cantidad de keys, no son defaults
    if (currentFilters.length != defaultFilters.length) return false;

    // Verificar cada key
    for (final key in defaultFilters.keys) {
      if (!currentFilters.containsKey(key)) return false;

      final currentValue = currentFilters[key];
      final defaultValue = defaultFilters[key];

      // Comparación especial para DateTime
      if (currentValue is DateTime && defaultValue is DateTime) {
        if (!_isSameDay(currentValue, defaultValue)) return false;
      } else if (currentValue != defaultValue) {
        return false;
      }
    }

    return true;
  }
}
