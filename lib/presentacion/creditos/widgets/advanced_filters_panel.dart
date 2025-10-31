import 'package:flutter/material.dart';
import '../../../negocio/modelos/credit_filter_state.dart';

class AdvancedFiltersPanel extends StatelessWidget {
  final CreditFilterState filterState;
  final Function(CreditFilterState) onApplyFilters;

  const AdvancedFiltersPanel({
    super.key,
    required this.filterState,
    required this.onApplyFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Filtros Avanzados',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            // TODO: Implementar campos de filtro avanzado aquí
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    onApplyFilters(CreditFilterState());
                  },
                  child: const Text('Limpiar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    onApplyFilters(filterState);
                  },
                  child: const Text('Aplicar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
