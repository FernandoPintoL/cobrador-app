import 'package:flutter/material.dart';
import '../../../negocio/modelos/credit_filter_state.dart';

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Icon(Icons.filter_list),
            const SizedBox(width: 8),
            const Text('Filtros activos'),
            const Spacer(),
            TextButton(onPressed: onClearFilters, child: const Text('Limpiar')),
          ],
        ),
      ),
    );
  }
}
