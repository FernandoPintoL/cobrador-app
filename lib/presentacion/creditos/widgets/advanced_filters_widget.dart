import 'package:flutter/material.dart';
import '../../../negocio/modelos/credit_filter_state.dart';

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
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
              // TODO: Implementar los campos de filtro avanzado aquí
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      onApply(
                        filterState.copyWith(
                          // TODO: Limpiar todos los filtros avanzados
                        ),
                      );
                    },
                    child: const Text('Limpiar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      onApply(filterState);
                    },
                    child: const Text('Aplicar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
