import '../../../datos/modelos/usuario.dart';

/// Configuración de qué filtros mostrar para cada rol y reporte
class FilterVisibilityConfig {
  final String filterKey;
  final String label;
  final String type; // 'date', 'select', 'text', 'number', 'search_select'
  final String? description;
  final bool required;
  final Map<String, dynamic>? options; // Para select
  final String? searchType; // Para search_select: 'cobrador', 'cliente', 'categoria'

  FilterVisibilityConfig({
    required this.filterKey,
    required this.label,
    required this.type,
    this.description,
    this.required = false,
    this.options,
    this.searchType,
  });
}

/// Servicio para determinar qué filtros mostrar según el rol del usuario
class FilterVisibilityService {
  /// Obtiene la lista de filtros a mostrar para un reporte y rol específico
  static List<FilterVisibilityConfig> getVisibleFilters({
    required String reportType,
    required Usuario usuario,
  }) {
    // Normalizar nombre del reporte (balance vs balances)
    final normalizedType = _normalizeReportType(reportType);

    // Admin ve todos los filtros disponibles
    if (usuario.esAdmin()) {
      return _getAllFiltersForReport(normalizedType);
    }

    // Manager ve filtros limitados (sin filtro de cobrador_id)
    if (usuario.esManager()) {
      return _getManagerFiltersForReport(normalizedType);
    }

    // Cobrador ve filtros muy limitados
    if (usuario.esCobrador()) {
      return _getCobradorFiltersForReport(normalizedType);
    }

    return [];
  }

  /// Retorna TODOS los filtros disponibles para un reporte (Admin)
  static List<FilterVisibilityConfig> _getAllFiltersForReport(String reportType) {
    final type = reportType.toLowerCase();
    switch (type) {
      case 'payments':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            description: 'Desde qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            description: 'Hasta qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'cobrador_id',
            label: 'Cobrador',
            type: 'search_select',
            description: 'Filtrar por cobrador específico',
            required: false,
            searchType: 'cobrador',
          ),
          FilterVisibilityConfig(
            filterKey: 'status',
            label: 'Estado del Pago',
            type: 'select',
            description: 'Filtrar por estado',
            required: false,
            options: {
              'completed': 'Completado',
              'pending': 'Pendiente',
              'failed': 'Fallido',
              'cancelled': 'Cancelado',
            },
          ),
        ];

      case 'credits':
        return [
          FilterVisibilityConfig(
            filterKey: 'status',
            label: 'Estado del Crédito',
            type: 'select',
            description: 'Filtrar por estado',
            required: false,
            options: {
              'active': 'Activo',
              'completed': 'Completado',
              'pending_approval': 'Pendiente Aprobación',
              'rejected': 'Rechazado',
              'cancelled': 'Cancelado',
            },
          ),
          FilterVisibilityConfig(
            filterKey: 'cobrador_id',
            label: 'Cobrador',
            type: 'search_select',
            description: 'Filtrar por cobrador',
            required: false,
            searchType: 'cobrador',
          ),
          FilterVisibilityConfig(
            filterKey: 'client_id',
            label: 'Cliente',
            type: 'search_select',
            description: 'Filtrar por cliente',
            required: false,
            searchType: 'cliente',
          ),
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            description: 'Desde qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            description: 'Hasta qué fecha',
            required: false,
          ),
        ];

      case 'balance':
      case 'balances':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            description: 'Desde qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            description: 'Hasta qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'cobrador_id',
            label: 'Cobrador',
            type: 'search_select',
            description: 'Filtrar por cobrador',
            required: false,
            searchType: 'cobrador',
          ),
          FilterVisibilityConfig(
            filterKey: 'status',
            label: 'Estado',
            type: 'select',
            description: 'Filtrar por estado',
            required: false,
            options: {
              'active': 'Activo',
              'inactive': 'Inactivo',
              'suspended': 'Suspendido',
            },
          ),
        ];

      case 'overdue':
        return [
          FilterVisibilityConfig(
            filterKey: 'client_category',
            label: 'Categoría de Cliente',
            type: 'search_select',  // ✅ Cambiar a search_select para usar SearchSelectField
            description: 'Filtrar por categoría',
            required: false,
            searchType: 'categoria',  // ✅ Indica que debe cargar categorías desde backend
          ),
          FilterVisibilityConfig(
            filterKey: 'min_days_overdue',
            label: 'Días de Atraso Mínimo',
            type: 'number',
            description: 'Mostrar clientes con al menos N días de atraso',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'min_amount',
            label: 'Monto Mínimo',
            type: 'number',
            description: 'Mostrar deudas mayores a este monto',
            required: false,
          ),
        ];

      case 'performance':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            description: 'Desde qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            description: 'Hasta qué fecha',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'cobrador_id',
            label: 'Cobrador',
            type: 'search_select',
            description: 'Filtrar por cobrador específico',
            required: false,
            searchType: 'cobrador',
          ),
        ];

      case 'daily_activity':
      case 'daily-activity':
        return [
          FilterVisibilityConfig(
            filterKey: 'date',
            label: 'Fecha',
            type: 'date',
            description: 'Seleccionar fecha',
            required: true,
          ),
        ];

      default:
        return [];
    }
  }

  /// Retorna filtros para MANAGER (puede filtrar por cobrador asignado)
  static List<FilterVisibilityConfig> _getManagerFiltersForReport(String reportType) {
    final allFilters = _getAllFiltersForReport(reportType);

    // Manager puede filtrar por cobrador_id (solo sus cobradores asignados)
    // pero no puede filtrar por client_id
    return allFilters
        .where((f) => f.filterKey != 'client_id')
        .toList();
  }

  /// Retorna filtros para COBRADOR (muy limitados)
  static List<FilterVisibilityConfig> _getCobradorFiltersForReport(String reportType) {
    switch (reportType.toLowerCase()) {
      case 'payments':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'status',
            label: 'Estado del Pago',
            type: 'select',
            required: false,
            options: {
              'completed': 'Completado',
              'pending': 'Pendiente',
              'failed': 'Fallido',
              'cancelled': 'Cancelado',
            },
          ),
        ];

      case 'credits':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            description: 'Desde qué fecha (créditos creados)',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            description: 'Hasta qué fecha (créditos creados)',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'status',
            label: 'Estado del Crédito',
            type: 'select',
            required: false,
            options: {
              'active': 'Activo',
              'completed': 'Completado',
              'pending_approval': 'Pendiente Aprobación',
              'rejected': 'Rechazado',
              'cancelled': 'Cancelado',
            },
          ),
        ];

      case 'balance':
      case 'balances':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            required: false,
          ),
        ];

      case 'performance':
        return [
          FilterVisibilityConfig(
            filterKey: 'start_date',
            label: 'Fecha Inicio',
            type: 'date',
            required: false,
          ),
          FilterVisibilityConfig(
            filterKey: 'end_date',
            label: 'Fecha Fin',
            type: 'date',
            required: false,
          ),
        ];

      case 'daily_activity':
      case 'daily-activity':
        return [
          FilterVisibilityConfig(
            filterKey: 'date',
            label: 'Fecha',
            type: 'date',
            required: true,
          ),
        ];

      default:
        return [];
    }
  }

  /// Obtiene la descripción de qué datos está viendo el usuario
  static String getDataContextDescription({
    required String reportType,
    required Usuario usuario,
  }) {
    if (usuario.esAdmin()) {
      return 'Visualizando todos los datos del sistema';
    }

    if (usuario.esManager()) {
      return 'Visualizando datos de tus cobradores asignados';
    }

    if (usuario.esCobrador()) {
      return 'Visualizando solo tu información';
    }

    return '';
  }

  /// Retorna la cantidad de filtros disponibles
  static int getFilterCount({
    required String reportType,
    required Usuario usuario,
  }) {
    return getVisibleFilters(
      reportType: reportType,
      usuario: usuario,
    ).length;
  }

  /// Normaliza el nombre del reporte para compatibilidad
  /// Convierte 'balances' -> 'balance', etc.
  static String _normalizeReportType(String reportType) {
    final name = reportType.toLowerCase().trim();

    if (name == 'balances') return 'balance';
    if (name == 'daily-activity') return 'daily_activity';
    if (name == 'daily_activity') return 'daily_activity';

    return name;
  }
}
