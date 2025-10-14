import 'package:flutter/material.dart';
import 'advanced_filters_panel.dart';
import 'credit_filter_state.dart';

/// Widget contenedor para el panel de filtros avanzados
/// Este widget proporciona la estructura y comportamiento para mostrar/ocultar filtros avanzados
class AdvancedFiltersWidget extends StatelessWidget {
  final CreditFilterState filterState;
  final Function(CreditFilterState) onApply;

  const AdvancedFiltersWidget({
    super.key,
    required this.filterState,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: AdvancedFiltersPanel(
            filterState: filterState,
            onApplyFilters: onApply,
            onClose: () => onApply(
              filterState.copyWith(),
            ), // Mantener estado actual pero cerrar
          ),
        ),
      ),
    );
  }
}
