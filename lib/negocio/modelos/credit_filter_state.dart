class CreditFilterState {
  final String search;
  final bool hasActiveFilters;
  final String? statusFilter;
  final Set<String> frequencies;
  final DateTime? startDateFrom;
  final DateTime? startDateTo;
  final double? amountMin;
  final double? amountMax;
  final int? selectedCobradorId;
  final bool? isOverdue;
  final double? overdueAmountMin;
  final double? overdueAmountMax;
  final Set<String> clientCategories;

  const CreditFilterState({
    this.search = '',
    this.hasActiveFilters = false,
    this.statusFilter,
    this.frequencies = const {},
    this.startDateFrom,
    this.startDateTo,
    this.amountMin,
    this.amountMax,
    this.selectedCobradorId,
    this.isOverdue,
    this.overdueAmountMin,
    this.overdueAmountMax,
    this.clientCategories = const {},
  });

  CreditFilterState copyWith({
    String? search,
    bool? hasActiveFilters,
    String? statusFilter,
    Set<String>? frequencies,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    double? amountMin,
    double? amountMax,
    int? selectedCobradorId,
    bool? isOverdue,
    double? overdueAmountMin,
    double? overdueAmountMax,
    Set<String>? clientCategories,
  }) {
    return CreditFilterState(
      search: search ?? this.search,
      hasActiveFilters: hasActiveFilters ?? this.hasActiveFilters,
      statusFilter: statusFilter ?? this.statusFilter,
      frequencies: frequencies ?? this.frequencies,
      startDateFrom: startDateFrom ?? this.startDateFrom,
      startDateTo: startDateTo ?? this.startDateTo,
      amountMin: amountMin ?? this.amountMin,
      amountMax: amountMax ?? this.amountMax,
      selectedCobradorId: selectedCobradorId ?? this.selectedCobradorId,
      isOverdue: isOverdue ?? this.isOverdue,
      overdueAmountMin: overdueAmountMin ?? this.overdueAmountMin,
      overdueAmountMax: overdueAmountMax ?? this.overdueAmountMax,
      clientCategories: clientCategories ?? this.clientCategories,
    );
  }

  static CreditFilterState empty() {
    return const CreditFilterState();
  }
}
