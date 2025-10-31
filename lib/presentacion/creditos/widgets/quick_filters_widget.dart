import 'package:flutter/material.dart';
import '../../../negocio/modelos/credit_filter_state.dart';

class QuickFiltersWidget extends StatelessWidget {
  final CreditFilterState filterState;
  final VoidCallback onClearFilters;
  final Function(String, bool) onApplyQuickFilter;

  const QuickFiltersWidget({
    super.key,
    required this.filterState,
    required this.onClearFilters,
    required this.onApplyQuickFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (!filterState.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Filtros activos:'),
                const Spacer(),
                TextButton(
                  onPressed: onClearFilters,
                  child: const Text('Limpiar todo'),
                ),
              ],
            ),
            Wrap(
              spacing: 8.0,
              children: [
                // TODO: Implementar chips de filtros rápidos aquí
              ],
            ),
          ],
        ),
      ),
    );
  }
}
