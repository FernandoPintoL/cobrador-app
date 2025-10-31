/// Modelo inmutable para gestionar el estado de filtros de créditos
class CreditFilterState {
  final String? statusFilter;
  final Set<String> frequencies;
  final double? amountMin;
  final double? amountMax;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final String search;
  final int? selectedCobradorId;
  final bool? isOverdue;
  final double? overdueAmountMin;
  final double? overdueAmountMax;
  final Set<String> clientCategories;

  const CreditFilterState({
    this.statusFilter,
    this.frequencies = const {},
    this.amountMin,
    this.amountMax,
    this.startDateFrom,
    this.startDateTo,
    this.search = '',
    this.selectedCobradorId,
    this.isOverdue,
    this.overdueAmountMin,
    this.overdueAmountMax,
    this.clientCategories = const {},
  });

  /// Factory constructor para crear un estado de filtros vacío/inicial
  factory CreditFilterState.empty() {
    return const CreditFilterState();
  }

  /// Verifica si hay algún filtro activo
  bool get hasActiveFilters {
    return statusFilter != null ||
        frequencies.isNotEmpty ||
        amountMin != null ||
        amountMax != null ||
        startDateFrom != null ||
        startDateTo != null ||
        selectedCobradorId != null ||
        search.isNotEmpty ||
        isOverdue != null ||
        overdueAmountMin != null ||
        overdueAmountMax != null ||
        clientCategories.isNotEmpty;
  }

  /// Método para crear una copia con cambios específicos
  CreditFilterState copyWith({
    String? statusFilter,
    Set<String>? frequencies,
    double? amountMin,
    double? amountMax,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    String? search,
    int? selectedCobradorId,
    bool? isOverdue,
    double? overdueAmountMin,
    double? overdueAmountMax,
    Set<String>? clientCategories,
    // Flags para permitir limpiar campos opcionales (establecer a null)
    bool clearStatusFilter = false,
    bool clearAmountMin = false,
    bool clearAmountMax = false,
    bool clearStartDateFrom = false,
    bool clearStartDateTo = false,
    bool clearSelectedCobradorId = false,
    bool clearIsOverdue = false,
    bool clearOverdueAmountMin = false,
    bool clearOverdueAmountMax = false,
  }) {
    return CreditFilterState(
      statusFilter: clearStatusFilter ? null : statusFilter ?? this.statusFilter,
      frequencies: frequencies ?? this.frequencies,
      amountMin: clearAmountMin ? null : amountMin ?? this.amountMin,
      amountMax: clearAmountMax ? null : amountMax ?? this.amountMax,
      startDateFrom: clearStartDateFrom ? null : startDateFrom ?? this.startDateFrom,
      startDateTo: clearStartDateTo ? null : startDateTo ?? this.startDateTo,
      search: search ?? this.search,
      selectedCobradorId: clearSelectedCobradorId ? null : selectedCobradorId ?? this.selectedCobradorId,
      isOverdue: clearIsOverdue ? null : isOverdue ?? this.isOverdue,
      overdueAmountMin: clearOverdueAmountMin ? null : overdueAmountMin ?? this.overdueAmountMin,
      overdueAmountMax: clearOverdueAmountMax ? null : overdueAmountMax ?? this.overdueAmountMax,
      clientCategories: clientCategories ?? this.clientCategories,
    );
  }

  /// Limpia todos los filtros y retorna un estado vacío
  CreditFilterState clear() {
    return CreditFilterState.empty();
  }

  /// Obtiene una descripción legible de los filtros activos
  String getActiveFiltersDescription() {
    final parts = <String>[];

    if (statusFilter != null) {
      final statusName = _getStatusName(statusFilter!);
      parts.add('Estado: $statusName');
    }

    if (frequencies.isNotEmpty) {
      final freqNames = frequencies.map(_getFrequencyName).join(', ');
      parts.add('Frecuencia: $freqNames');
    }

    if (amountMin != null) {
      parts.add('Monto mín.: ${amountMin!.toStringAsFixed(0)}');
    }

    if (amountMax != null) {
      parts.add('Monto máx.: ${amountMax!.toStringAsFixed(0)}');
    }

    if (startDateFrom != null) {
      parts.add('Desde: ${_formatDate(startDateFrom!)}');
    }

    if (startDateTo != null) {
      parts.add('Hasta: ${_formatDate(startDateTo!)}');
    }

    if (selectedCobradorId != null) {
      parts.add('Cobrador ID: $selectedCobradorId');
    }

    if (isOverdue != null) {
      parts.add('Cuotas atrasadas: ${isOverdue! ? 'Sí' : 'No'}');
    }

    if (overdueAmountMin != null) {
      parts.add('Monto atrasado mín.: ${overdueAmountMin!.toStringAsFixed(0)}');
    }

    if (overdueAmountMax != null) {
      parts.add('Monto atrasado máx.: ${overdueAmountMax!.toStringAsFixed(0)}');
    }

    if (clientCategories.isNotEmpty) {
      parts.add('Categorías: ${clientCategories.join(', ')}');
    }

    return parts.join(', ');
  }

  String _getStatusName(String status) {
    switch (status) {
      case 'active':
        return 'Activos';
      case 'pending_approval':
        return 'Pendientes';
      case 'waiting_delivery':
        return 'En espera';
      default:
        return status;
    }
  }

  String _getFrequencyName(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diaria';
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quincenal';
      case 'monthly':
        return 'Mensual';
      default:
        return frequency;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CreditFilterState &&
        other.statusFilter == statusFilter &&
        _setEquals(other.frequencies, frequencies) &&
        other.amountMin == amountMin &&
        other.amountMax == amountMax &&
        other.startDateFrom == startDateFrom &&
        other.startDateTo == startDateTo &&
        other.search == search &&
        other.selectedCobradorId == selectedCobradorId &&
        other.isOverdue == isOverdue &&
        other.overdueAmountMin == overdueAmountMin &&
        other.overdueAmountMax == overdueAmountMax &&
        _setEquals(other.clientCategories, clientCategories);
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    return a.every((element) => b.contains(element));
  }

  @override
  int get hashCode {
    return Object.hash(
      statusFilter,
      Object.hashAll(frequencies),
      amountMin,
      amountMax,
      startDateFrom,
      startDateTo,
      search,
      selectedCobradorId,
      isOverdue,
      overdueAmountMin,
      overdueAmountMax,
      Object.hashAll(clientCategories),
    );
  }

  @override
  String toString() {
    return 'CreditFilterState('
        'statusFilter: $statusFilter, '
        'frequencies: $frequencies, '
        'amountMin: $amountMin, '
        'amountMax: $amountMax, '
        'startDateFrom: $startDateFrom, '
        'startDateTo: $startDateTo, '
        'search: $search, '
        'selectedCobradorId: $selectedCobradorId, '
        'isOverdue: $isOverdue, '
        'overdueAmountMin: $overdueAmountMin, '
        'overdueAmountMax: $overdueAmountMax, '
        'clientCategories: $clientCategories'
        ')';
  }
}