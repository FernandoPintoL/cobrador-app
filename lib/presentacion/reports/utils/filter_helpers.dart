/// Clase para detectar el tipo de filtro basado en el nombre
class FilterTypeDetector {
  static bool isDateFilter(String filterKey) {
    return filterKey.toLowerCase().contains('date') ||
           filterKey.toLowerCase().contains('fecha');
  }

  static bool isCobradorFilter(String filterKey) {
    return filterKey.toLowerCase().contains('cobrador') ||
           filterKey.toLowerCase().contains('collector') ||
           filterKey.toLowerCase().contains('delivered');
  }

  static bool isClienteFilter(String filterKey) {
    return filterKey.toLowerCase().contains('client') ||
           filterKey.toLowerCase().contains('cliente');
  }

  static bool isCategoryFilter(String filterKey) {
    return filterKey.toLowerCase().contains('category') ||
           filterKey.toLowerCase().contains('categor');
  }

  static bool isStatusFilter(String filterKey) {
    return filterKey.toLowerCase().contains('status') ||
           filterKey.toLowerCase().contains('estado');
  }
}

/// Traductor centralizado de etiquetas de filtros
/// Una única fuente de verdad para todas las traducciones de etiquetas
class FilterLabelTranslator {
  // Mapa completo de traducciones español-inglés
  // Consolidado de múltiples fuentes para evitar duplicación
  static const Map<String, String> _translations = {
    // Filtros de fecha
    'start date': 'Fecha Inicio',
    'start_date': 'Fecha Inicio',
    'end date': 'Fecha Fin',
    'end_date': 'Fecha Fin',
    'date_from': 'Fecha Inicio',
    'date_to': 'Fecha Fin',
    'date': 'Fecha',
    'payment date': 'Fecha Pago',
    'payment_date': 'Fecha Pago',
    'created at': 'Creado',
    'created_at': 'Creado',
    'updated at': 'Actualizado',
    'updated_at': 'Actualizado',
    'deleted at': 'Eliminado',
    'deleted_at': 'Eliminado',

    // Filtros de cliente
    'client': 'Cliente',
    'client name': 'Nombre Cliente',
    'client_name': 'Nombre Cliente',
    'client_id': 'ID Cliente',
    'client id': 'ID Cliente',
    'customer_id': 'Cliente',

    // Filtros de cobrador
    'cobrador': 'Cobrador',
    'cobrador name': 'Nombre Cobrador',
    'cobrador_name': 'Nombre Cobrador',
    'cobrador_id': 'ID Cobrador',
    'cobrador id': 'ID Cobrador',
    'collector_id': 'Cobrador',
    'deliveredBy': 'Entregado por',
    'collected_by': 'Cobrado por',

    // Filtros de categoría
    'category': 'Categoría',
    'categoria': 'Categoría',
    'category_id': 'Categoría',
    'credit_category': 'Categoría del Crédito',

    // Filtros de crédito
    'credit': 'Crédito',
    'credit id': 'ID Crédito',
    'credit_id': 'ID Crédito',
    'credit_status': 'Estado Crédito',
    'credit status': 'Estado Crédito',
    'frequency': 'Frecuencia',
    'interest': 'Interés',

    // Filtros de estado
    'status': 'Estado',
    'payment_status': 'Estado Pago',
    'payment status': 'Estado Pago',

    // Filtros de pago
    'payment': 'Pago',
    'payment_method': 'Método de Pago',
    'pending payment': 'Pago Pendiente',
    'pending_payment': 'Pago Pendiente',
    'paid payment': 'Pago Realizado',
    'paid_payment': 'Pago Realizado',

    // Filtros de monto
    'amount': 'Monto',
    'amount_from': 'Monto Desde',
    'amount_to': 'Monto Hasta',
    'total amount': 'Monto Total',
    'total_amount': 'Monto Total',
    'balance': 'Balance',

    // Filtros de atrasos
    'overdue': 'Vencido',
    'overdue days': 'Días Vencido',
    'overdue_days': 'Días Vencido',
    'days_overdue': 'Días de Atraso',
    'severity': 'Severidad',

    // Filtros de cartera
    'portfolio_quality': 'Calidad de Cartera',
    'active_credits': 'Créditos Activos',

    // Filtros de comisión
    'commission': 'Comisión',
    'commission_type': 'Tipo de Comisión',
    'performance': 'Rendimiento',
    'performance_level': 'Nivel de Desempeño',

    // Filtros de usuario
    'user': 'Usuario',
    'user_id': 'ID Usuario',
    'user id': 'ID Usuario',
    'username': 'Nombre Usuario',
    'email': 'Correo',
    'phone': 'Teléfono',

    // Ubicación
    'location': 'Ubicación',
    'address': 'Dirección',
    'city': 'Ciudad',
    'state': 'Estado',
    'country': 'País',
    'zip code': 'Código Postal',
    'zip_code': 'Código Postal',

    // Estados generales
    'active': 'Activo',
    'inactive': 'Inactivo',
    'is_active': 'Activo',
    'is active': 'Activo',
    'enabled': 'Habilitado',
    'disabled': 'Deshabilitado',
    'open': 'Abierto',
    'closed': 'Cerrado',
    'reconciled': 'Reconciliado',
    'rejected': 'Rechazado',
    'approved': 'Aprobado',
    'paid': 'Pagado',
    'pending': 'Pendiente',

    // Términos económicos
    'collection': 'Cobranza',
    'collected': 'Cobrado',
    'lent': 'Prestado',
    'owed': 'Adeudado',
    'efficiency': 'Eficiencia',

    // Genéricos
    'id': 'ID',
    'name': 'Nombre',
    'type': 'Tipo',
    'description': 'Descripción',
    'reason': 'Motivo',
    'notes': 'Notas',
    'observation': 'Observación',
    'period': 'Período',
    'month': 'Mes',
    'year': 'Año',
    'week': 'Semana',
    'day': 'Día',
    'range': 'Rango',
    'minimum': 'Mínimo',
    'maximum': 'Máximo',
    'min': 'Mínimo',
    'max': 'Máximo',
    'total': 'Total',
    'count': 'Cantidad',
    'quantity': 'Cantidad',
    'rate': 'Tasa',
    'percentage': 'Porcentaje',
    'percent': 'Porcentaje',
    'summary': 'Resumen',
    'detail': 'Detalle',
    'details': 'Detalles',
    'source': 'Origen',
    'bank': 'Banco',
    'account': 'Cuenta',
    'reference': 'Referencia',
    'report_type': 'Tipo de Reporte',
    'format': 'Formato',
    'search': 'Búsqueda',
    'keyword': 'Palabra clave',
  };

  /// Obtiene la etiqueta traducida para una clave de filtro
  /// Usa búsqueda exacta, luego búsqueda por palabras clave, luego humaniza
  static String translate(String key) {
    final normalized = key.toLowerCase().replaceAll('_', ' ');

    // 1. Búsqueda exacta en el diccionario
    if (_translations.containsKey(normalized)) {
      return _translations[normalized]!;
    }

    // 2. Búsqueda con clave original (para entradas que tienen guiones bajos)
    if (_translations.containsKey(key)) {
      return _translations[key]!;
    }

    // 3. Búsqueda por palabras clave contenidas
    for (final keyword in _translations.keys) {
      if (normalized.contains(keyword)) {
        return _translations[keyword]!;
      }
    }

    // 4. Si no hay traducción, humanizar la clave
    return _humanize(key);
  }

  /// Convierte una clave tipo snake_case a formato legible
  /// Ejemplo: 'user_id' -> 'User Id'
  static String _humanize(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
        .join(' ');
  }

  /// Obtiene todas las traducciones
  static Map<String, String> getAll() => _translations;
}
