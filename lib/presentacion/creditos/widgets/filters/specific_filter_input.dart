import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../negocio/providers/credit_provider.dart';
import 'credit_filter_state.dart';

/// Widget que muestra el input específico según el tipo de filtro seleccionado
class SpecificFilterInput extends ConsumerStatefulWidget {
  final String filterType;
  final CreditFilterState filterState;
  final Function(CreditFilterState) onFilterChange;

  const SpecificFilterInput({
    super.key,
    required this.filterType,
    required this.filterState,
    required this.onFilterChange,
  });

  @override
  ConsumerState<SpecificFilterInput> createState() =>
      _SpecificFilterInputState();
}

class _SpecificFilterInputState extends ConsumerState<SpecificFilterInput> {
  late TextEditingController _clientController;
  late TextEditingController _creditIdController;
  late TextEditingController _amountMinController;
  late TextEditingController _amountMaxController;
  late TextEditingController _overdueMinController;
  late TextEditingController _overdueMaxController;

  @override
  void initState() {
    super.initState();
    _clientController = TextEditingController();
    _creditIdController = TextEditingController();
    _amountMinController = TextEditingController(
      text: widget.filterState.amountMin?.toStringAsFixed(0) ?? '',
    );
    _amountMaxController = TextEditingController(
      text: widget.filterState.amountMax?.toStringAsFixed(0) ?? '',
    );
    _overdueMinController = TextEditingController(
      text: widget.filterState.overdueAmountMin?.toStringAsFixed(0) ?? '',
    );
    _overdueMaxController = TextEditingController(
      text: widget.filterState.overdueAmountMax?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _clientController.dispose();
    _creditIdController.dispose();
    _amountMinController.dispose();
    _amountMaxController.dispose();
    _overdueMinController.dispose();
    _overdueMaxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.filterType) {
      case 'cliente':
        return _buildClientInput();
      case 'credit_id':
        return _buildCreditIdInput();
      case 'estado':
        return _buildStatusInput();
      case 'frecuencia':
        return _buildFrequencyInput();
      case 'montos':
        return _buildAmountInput();
      case 'fechas':
        return _buildDateInput();
      case 'cuotas_atrasadas':
        return _buildOverdueInput();
      case 'categoria_cliente':
        return _buildClientCategoryInput();
      default:
        return _buildDefaultInfo();
    }
  }

  Widget _buildClientInput() {
    return TextField(
      key: const ValueKey('cliente'),
      controller: _clientController,
      decoration: const InputDecoration(
        labelText: 'Nombre del cliente',
        prefixIcon: Icon(Icons.person),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildCreditIdInput() {
    return TextField(
      key: const ValueKey('credit_id'),
      controller: _creditIdController,
      keyboardType: TextInputType.number,
      decoration: const InputDecoration(
        labelText: 'ID del crédito',
        prefixIcon: Icon(Icons.numbers),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildStatusInput() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Activos'),
          selected: widget.filterState.statusFilter == 'active',
          onSelected: (_) => _updateStatus('active'),
        ),
        ChoiceChip(
          label: const Text('Pendientes'),
          selected: widget.filterState.statusFilter == 'pending_approval',
          onSelected: (_) => _updateStatus('pending_approval'),
        ),
        ChoiceChip(
          label: const Text('En espera'),
          selected: widget.filterState.statusFilter == 'waiting_delivery',
          onSelected: (_) => _updateStatus('waiting_delivery'),
        ),
      ],
    );
  }

  Widget _buildFrequencyInput() {
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Diaria'),
          selected: widget.filterState.frequencies.contains('daily'),
          onSelected: (v) => _toggleFrequency('daily', v),
        ),
        FilterChip(
          label: const Text('Semanal'),
          selected: widget.filterState.frequencies.contains('weekly'),
          onSelected: (v) => _toggleFrequency('weekly', v),
        ),
        FilterChip(
          label: const Text('Quincenal'),
          selected: widget.filterState.frequencies.contains('biweekly'),
          onSelected: (v) => _toggleFrequency('biweekly', v),
        ),
        FilterChip(
          label: const Text('Mensual'),
          selected: widget.filterState.frequencies.contains('monthly'),
          onSelected: (v) => _toggleFrequency('monthly', v),
        ),
      ],
    );
  }

  Widget _buildAmountInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            key: const ValueKey('monto_min'),
            controller: _amountMinController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto mínimo',
              prefixIcon: Icon(Icons.remove_circle_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              _updateAmountMin(parsed);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            key: const ValueKey('monto_max'),
            controller: _amountMaxController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Monto máximo',
              prefixIcon: Icon(Icons.add_circle_outline),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              _updateAmountMax(parsed);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDateInput() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('fecha_desde'),
            onPressed: () => _selectStartDate(),
            icon: const Icon(Icons.calendar_today),
            label: Text(
              widget.filterState.startDateFrom == null
                  ? 'Desde (inicio)'
                  : DateFormat('dd/MM/yyyy')
                      .format(widget.filterState.startDateFrom!),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            key: const ValueKey('fecha_hasta'),
            onPressed: () => _selectEndDate(),
            icon: const Icon(Icons.event),
            label: Text(
              widget.filterState.startDateTo == null
                  ? 'Hasta (inicio)'
                  : DateFormat('dd/MM/yyyy')
                      .format(widget.filterState.startDateTo!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverdueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          dense: true,
          title: const Text('Solo créditos con cuotas atrasadas'),
          value: widget.filterState.isOverdue ?? false,
          onChanged: (value) => _updateIsOverdue(value),
        ),
        const SizedBox(height: 12),
        const Text('Rango de monto atrasado (opcional):'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('overdue_min'),
                controller: _overdueMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto mínimo atrasado',
                  prefixIcon: Icon(Icons.remove_circle_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  _updateOverdueMin(parsed);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('overdue_max'),
                controller: _overdueMaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto máximo atrasado',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  _updateOverdueMax(parsed);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildClientCategoryInput() {
    final allCredits = ref.watch(creditProvider).credits;
    final available = allCredits
        .map((c) => c.client?.clientCategory)
        .where((e) => e != null && (e as String).isNotEmpty)
        .cast<String>()
        .toSet()
        .toList()
      ..sort();
    final categories = available.isNotEmpty ? available : ['A', 'B', 'C'];

    return Wrap(
      spacing: 8,
      children: [
        for (final cat in categories)
          FilterChip(
            label: Text(cat),
            selected: widget.filterState.clientCategories.contains(cat),
            onSelected: (v) => _toggleCategory(cat, v),
          ),
      ],
    );
  }

  Widget _buildDefaultInfo() {
    return const Row(
      children: [
        Icon(Icons.info_outline, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Usa la barra superior para buscar. Aquí solo configura filtros avanzados.',
          ),
        ),
      ],
    );
  }

  // Update methods
  void _updateStatus(String status) {
    widget.onFilterChange(
      widget.filterState.copyWith(statusFilter: status),
    );
  }

  void _toggleFrequency(String frequency, bool selected) {
    final newFrequencies = Set<String>.from(widget.filterState.frequencies);
    if (selected) {
      newFrequencies.add(frequency);
    } else {
      newFrequencies.remove(frequency);
    }
    widget.onFilterChange(
      widget.filterState.copyWith(frequencies: newFrequencies),
    );
  }

  void _updateAmountMin(double? value) {
    widget.onFilterChange(
      widget.filterState.copyWith(
        amountMin: value,
        clearAmountMin: value == null,
      ),
    );
  }

  void _updateAmountMax(double? value) {
    widget.onFilterChange(
      widget.filterState.copyWith(
        amountMax: value,
        clearAmountMax: value == null,
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: widget.filterState.startDateFrom ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      widget.onFilterChange(
        widget.filterState.copyWith(startDateFrom: d),
      );
    }
  }

  Future<void> _selectEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: widget.filterState.startDateTo ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      widget.onFilterChange(
        widget.filterState.copyWith(startDateTo: d),
      );
    }
  }

  void _updateIsOverdue(bool? value) {
    widget.onFilterChange(
      widget.filterState.copyWith(
        isOverdue: value,
        clearIsOverdue: value == null,
      ),
    );
  }

  void _updateOverdueMin(double? value) {
    widget.onFilterChange(
      widget.filterState.copyWith(
        overdueAmountMin: value,
        clearOverdueAmountMin: value == null,
      ),
    );
  }

  void _updateOverdueMax(double? value) {
    widget.onFilterChange(
      widget.filterState.copyWith(
        overdueAmountMax: value,
        clearOverdueAmountMax: value == null,
      ),
    );
  }

  void _toggleCategory(String category, bool selected) {
    final newCategories =
        Set<String>.from(widget.filterState.clientCategories);
    if (selected) {
      newCategories.add(category);
    } else {
      newCategories.remove(category);
    }
    widget.onFilterChange(
      widget.filterState.copyWith(clientCategories: newCategories),
    );
  }
}
