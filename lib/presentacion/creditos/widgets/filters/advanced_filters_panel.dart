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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme, isDark),
              const SizedBox(height: 16),
              _buildFilterTypeChips(isDark),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.0, 0.1),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
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
              const SizedBox(height: 20),
              _buildActionButtons(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                  theme.colorScheme.primary.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.filter_alt,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Filtros Específicos',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                fontSize: 18,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              onPressed: _handleClose,
              tooltip: 'Cerrar filtros',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTypeChips(bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildChip('estado', 'Estado', Icons.verified, isDark),
        _buildChip('frecuencia', 'Frecuencia', Icons.event_repeat, isDark),
        _buildChip('montos', 'Montos', Icons.attach_money, isDark),
        _buildChip('fechas', 'Fechas', Icons.date_range, isDark),
        _buildChip(
          'cuotas_atrasadas',
          'Cuotas Atrasadas',
          Icons.money_off,
          isDark,
        ),
        _buildChip('categoria_cliente', 'Categoría', Icons.category, isDark),
      ],
    );
  }

  Widget _buildChip(String key, String label, IconData icon, bool isDark) {
    final selected = _specificFilter == key;
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        gradient: selected
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.3),
                  theme.colorScheme.primary.withValues(alpha: 0.2),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          width: selected ? 2 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() {
            _specificFilter = key;
          }),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.grey[300] : Colors.grey[800]),
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleClear,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.clear_all,
                        size: 20,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Limpiar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleApply,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Aplicar',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
