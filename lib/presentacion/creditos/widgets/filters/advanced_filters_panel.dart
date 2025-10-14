import 'package:flutter/material.dart';
import 'credit_filter_state.dart';
import 'specific_filter_input.dart';

/// Panel de filtros avanzados para créditos
/// Permite seleccionar un tipo de filtro y configurar sus valores específicos
class AdvancedFiltersPanel extends StatefulWidget {
  final CreditFilterState filterState;
  final Function(CreditFilterState) onApplyFilters;
  final VoidCallback onClose;

  const AdvancedFiltersPanel({
    super.key,
    required this.filterState,
    required this.onApplyFilters,
    required this.onClose,
  });

  @override
  State<AdvancedFiltersPanel> createState() => _AdvancedFiltersPanelState();
}

class _AdvancedFiltersPanelState extends State<AdvancedFiltersPanel> {
  late String _specificFilter;
  late CreditFilterState _tempFilterState;

  @override
  void initState() {
    super.initState();
    _specificFilter = 'busqueda_general';
    _tempFilterState = widget.filterState;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 12),
            _buildFilterTypeChips(),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: SpecificFilterInput(
                key: ValueKey(_specificFilter),
                filterType: _specificFilter,
                filterState: _tempFilterState,
                onFilterChange: (newState) {
                  setState(() {
                    _tempFilterState = newState;
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.filter_alt,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Filtros Específicos',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 18),
          onPressed: _handleClose,
          tooltip: 'Cerrar filtros',
        ),
      ],
    );
  }

  Widget _buildFilterTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildChip('estado', 'Estado', Icons.verified),
        _buildChip('frecuencia', 'Frecuencia', Icons.event_repeat),
        _buildChip('montos', 'Montos', Icons.attach_money),
        _buildChip('fechas', 'Fechas', Icons.date_range),
        _buildChip('cuotas_atrasadas', 'Cuotas Atrasadas', Icons.money_off),
        _buildChip('categoria_cliente', 'Categoría', Icons.category),
      ],
    );
  }

  Widget _buildChip(String key, String label, IconData icon) {
    final selected = _specificFilter == key;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => setState(() {
        _specificFilter = key;
      }),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _handleClear,
            child: const Text('Limpiar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _handleApply,
            child: const Text('Aplicar'),
          ),
        ),
      ],
    );
  }

  void _handleClose() {
    setState(() {
      _specificFilter = 'busqueda_general';
      _tempFilterState = widget.filterState;
    });
    widget.onClose();
  }

  void _handleClear() {
    setState(() {
      _specificFilter = 'busqueda_general';
      _tempFilterState = _tempFilterState.copyWith(
        clearStatusFilter: true,
        clearAmountMin: true,
        clearAmountMax: true,
        clearStartDateFrom: true,
        clearStartDateTo: true,
        clearIsOverdue: true,
        clearOverdueAmountMin: true,
        clearOverdueAmountMax: true,
        frequencies: const {},
        clientCategories: const {},
      );
    });
  }

  void _handleApply() {
    // Normalizar valores si es necesario
    var finalState = _tempFilterState;

    // Normalizar rangos de montos
    if (finalState.amountMin != null &&
        finalState.amountMax != null &&
        finalState.amountMin! > finalState.amountMax!) {
      finalState = finalState.copyWith(
        amountMin: _tempFilterState.amountMax,
        amountMax: _tempFilterState.amountMin,
      );
    }

    // Normalizar rangos de fechas
    if (finalState.startDateFrom != null &&
        finalState.startDateTo != null &&
        finalState.startDateFrom!.isAfter(finalState.startDateTo!)) {
      finalState = finalState.copyWith(
        startDateFrom: _tempFilterState.startDateTo,
        startDateTo: _tempFilterState.startDateFrom,
      );
    }

    widget.onApplyFilters(finalState);
  }
}
