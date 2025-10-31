import 'package:flutter/material.dart';
import 'credit_filter_state.dart';
import 'active_filters_indicator.dart';
import 'credit_quick_filters.dart';

/// Widget para mostrar y gestionar filtros rápidos y activos
/// Incluye indicadores de filtros activos y acceso a filtros predefinidos
class QuickFiltersWidget extends StatelessWidget {
  final CreditFilterState filterState;
  final VoidCallback onClearFilters;
  final Function(CreditFilterState) onApplyQuickFilter;

  const QuickFiltersWidget({
    super.key,
    required this.filterState,
    required this.onClearFilters,
    required this.onApplyQuickFilter,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilters = filterState.hasActiveFilters;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ActiveFiltersIndicator(
              filterState: filterState,
              onClearFilters: onClearFilters,
            ),
          ),
        CreditQuickFilters(onApplyFilter: onApplyQuickFilter),
      ],
    );
  }
}
