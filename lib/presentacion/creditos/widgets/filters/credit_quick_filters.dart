import 'package:flutter/material.dart';
import 'credit_filter_state.dart';

/// Widget para filtros rápidos de créditos
/// Proporciona accesos directos a filtros comúnmente usados
class CreditQuickFilters extends StatelessWidget {
  final Function(CreditFilterState) onApplyFilter;

  const CreditQuickFilters({
    super.key,
    required this.onApplyFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Rápidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyActiveFilter(),
                  child: const Text('Activos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyPendingFilter(),
                  child: const Text('Pendientes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyWaitingFilter(),
                  child: const Text('En Espera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyDailyFilter(),
                  child: const Text('Hoy'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyWeeklyFilter(),
                  child: const Text('Esta Semana'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyMonthlyFilter(),
                  child: const Text('Este Mes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _applyOverdueFilter(),
                  child: const Text('Con Cuotas Atrasadas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(), // Espacio vacío para mantener la disposición
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyActiveFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      statusFilter: 'active',
    ));
  }

  void _applyPendingFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      statusFilter: 'pending_approval',
    ));
  }

  void _applyWaitingFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      statusFilter: 'waiting_delivery',
    ));
  }

  void _applyDailyFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      frequencies: {'daily'},
    ));
  }

  void _applyWeeklyFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      frequencies: {'weekly'},
    ));
  }

  void _applyMonthlyFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      frequencies: {'monthly'},
    ));
  }

  void _applyOverdueFilter() {
    onApplyFilter(CreditFilterState.empty().copyWith(
      isOverdue: true,
    ));
  }
}
