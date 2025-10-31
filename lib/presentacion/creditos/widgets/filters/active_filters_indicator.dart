import 'package:flutter/material.dart';
import 'credit_filter_state.dart';

/// Widget para mostrar un indicador de filtros activos
/// Muestra una barra con la descripción de los filtros aplicados y un botón para limpiarlos
class ActiveFiltersIndicator extends StatelessWidget {
  final CreditFilterState filterState;
  final VoidCallback onClearFilters;

  const ActiveFiltersIndicator({
    super.key,
    required this.filterState,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (!filterState.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtros activos: ${filterState.getActiveFiltersDescription()}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onClearFilters,
            icon: const Icon(Icons.clear, size: 16, color: Colors.red),
            label: const Text(
              'Limpiar filtros',
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}
