import '../../datos/modelos/usuario.dart';

/// Servicio para autorizar y validar filtros de reportes según el rol del usuario
///
/// Este servicio actúa como una capa de seguridad que valida y modifica
/// los parámetros de los reportes antes de enviarlos al backend.
class ReportAuthorizationService {
  /// Valida y autoriza los filtros para un reporte específico según el rol del usuario
  /// Modifica los filtros para cumplir con las restricciones de autorización
  static Map<String, dynamic> authorizeFilters({
    required String reportType,
    required Map<String, dynamic> filters,
    required Usuario usuario,
  }) {
    // Normalizar nombre del reporte (balance vs balances, etc)
    final normalizedType = _normalizeReportType(reportType);

    // Si es admin, permite todos los filtros sin modificación
    if (usuario.esAdmin()) {
      return filters;
    }

    // Crear una copia de los filtros para modificar
    final authorizedFilters = Map<String, dynamic>.from(filters);

    // Aplicar reglas de autorización según el tipo de reporte
    switch (normalizedType.toLowerCase()) {
      case 'payments':
        return _authorizePaymentsFilters(
          authorizedFilters,
          usuario,
        );

      case 'credits':
        return _authorizeCreditsFilters(
          authorizedFilters,
          usuario,
        );

      case 'balance':
        return _authorizeBalanceFilters(
          authorizedFilters,
          usuario,
        );

      case 'overdue':
        return _authorizeOverdueFilters(
          authorizedFilters,
          usuario,
        );

      case 'performance':
        return _authorizePerformanceFilters(
          authorizedFilters,
          usuario,
        );

      case 'daily_activity':
        return _authorizeDailyActivityFilters(
          authorizedFilters,
          usuario,
        );

      default:
        // Para otros reportes, devolver los filtros sin modificación
        return authorizedFilters;
    }
  }

  /// Autoriza filtros para reporte de Pagos
  /// Manager: Puede filtrar por cobrador específico (de sus asignados)
  /// Cobrador: Solo puede ver sus propios pagos
  static Map<String, dynamic> _authorizePaymentsFilters(
    Map<String, dynamic> filters,
    Usuario usuario,
  ) {
    if (usuario.esManager()) {
      // Manager: PUEDE filtrar por cobrador_id específico (de sus asignados)
      // El backend validará que el cobrador esté asignado al manager
      return filters;
    } else if (usuario.esCobrador()) {
      // Cobrador: Solo ve sus propios pagos
      filters['cobrador_id'] = usuario.id.toInt(); // Forzar su propio ID
      return filters;
    }

    return filters;
  }

  /// Autoriza filtros para reporte de Créditos
  /// Manager: Puede filtrar por cobrador específico (de sus asignados)
  /// Cobrador: Solo puede ver créditos asignados a él
  static Map<String, dynamic> _authorizeCreditsFilters(
    Map<String, dynamic> filters,
    Usuario usuario,
  ) {
    if (usuario.esManager()) {
      // Manager: PUEDE filtrar por cobrador_id específico (de sus asignados)
      // El backend validará que el cobrador esté asignado al manager
      // Solo removemos client_id por seguridad
      filters.remove('client_id');
      return filters;
    } else if (usuario.esCobrador()) {
      // Cobrador: Solo ve créditos asignados a él
      filters['cobrador_id'] = usuario.id.toInt();
      filters.remove('client_id'); // Cobrador no filtra específicamente por cliente
      return filters;
    }

    return filters;
  }

  /// Autoriza filtros para reporte de Balance
  /// Manager: Puede filtrar por cobrador específico (de sus asignados)
  /// Cobrador: Solo ve su balance
  static Map<String, dynamic> _authorizeBalanceFilters(
    Map<String, dynamic> filters,
    Usuario usuario,
  ) {
    if (usuario.esManager()) {
      // Manager: PUEDE filtrar por cobrador_id específico (de sus asignados)
      return filters;
    } else if (usuario.esCobrador()) {
      // Cobrador: Solo su balance
      filters['cobrador_id'] = usuario.id.toInt();
      return filters;
    }

    return filters;
  }

  /// Autoriza filtros para reporte de Morosos
  /// Manager: Solo ve clientes de sus cobradores
  /// Cobrador: Solo ve sus clientes morosos
  static Map<String, dynamic> _authorizeOverdueFilters(
    Map<String, dynamic> filters,
    Usuario usuario,
  ) {
    if (usuario.esManager()) {
      // Manager: Backend filtra sus clientes
      filters.remove('client_id');
      return filters;
    } else if (usuario.esCobrador()) {
      // Cobrador: Backend filtra sus clientes
      filters.remove('client_id');
      return filters;
    }

    return filters;
  }

  /// Autoriza filtros para reporte de Desempeño
  /// Manager: Puede filtrar por cobrador específico (de sus asignados)
  /// Cobrador: Solo ve su desempeño
  static Map<String, dynamic> _authorizePerformanceFilters(
    Map<String, dynamic> filters,
    Usuario usuario,
  ) {
    if (usuario.esManager()) {
      // Manager: PUEDE filtrar por cobrador_id específico (de sus asignados)
      return filters;
    } else if (usuario.esCobrador()) {
      // Cobrador: Solo su desempeño
      filters['cobrador_id'] = usuario.id.toInt();
      return filters;
    }

    return filters;
  }

  /// Autoriza filtros para reporte de Actividad Diaria
  /// Manager: Puede filtrar por cobrador específico (de sus asignados)
  /// Cobrador: Solo ve su actividad
  static Map<String, dynamic> _authorizeDailyActivityFilters(
    Map<String, dynamic> filters,
    Usuario usuario,
  ) {
    if (usuario.esManager()) {
      // Manager: PUEDE filtrar por cobrador_id específico (de sus asignados)
      return filters;
    } else if (usuario.esCobrador()) {
      // Cobrador: Solo su actividad
      filters['cobrador_id'] = usuario.id.toInt();
      return filters;
    }

    return filters;
  }

  /// Valida si un usuario tiene permiso para ver un reporte específico
  static bool hasReportAccess(String reportType, Usuario usuario) {
    final type = reportType.toLowerCase().trim();

    // Admin tiene acceso a todos los reportes
    if (usuario.esAdmin()) return true;

    // Manager tiene acceso a reportes de gestión
    if (usuario.esManager()) {
      return ['payments', 'credits', 'balance', 'balances', 'overdue', 'performance', 'daily_activity', 'daily-activity']
          .contains(type);
    }

    // Cobrador tiene acceso a reportes de su actividad
    if (usuario.esCobrador()) {
      return ['payments', 'credits', 'balance', 'balances', 'performance', 'daily_activity', 'daily-activity']
          .contains(type);
    }

    return false;
  }

  /// Obtiene una descripción de las restricciones de filtros para un rol
  static String getFilterRestrictionsDescription(String reportType, Usuario usuario) {
    if (usuario.esAdmin()) {
      return 'Acceso sin restricciones';
    }

    if (usuario.esManager()) {
      return 'Visualizando datos de tus cobradores asignados';
    }

    if (usuario.esCobrador()) {
      return 'Visualizando solo tu información';
    }

    return 'Acceso denegado';
  }

  /// Normaliza el nombre del reporte para el switch statement en authorizeFilters
  /// Convierte variantes a forma canónica para matching
  static String _normalizeReportType(String reportType) {
    final name = reportType.toLowerCase().trim();

    // Normalizar nombres con guiones y plurales para el switch
    if (name == 'balances') return 'balance';
    if (name == 'daily-activity') return 'daily_activity';

    return name;
  }
}
