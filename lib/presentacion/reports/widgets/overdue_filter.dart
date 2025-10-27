import 'package:flutter/material.dart';

/// Widget de filtros para reporte de mora
/// Se adapta según el rol del usuario
class OverdueFilter extends StatefulWidget {
  final String? userRole; // admin, manager, cobrador
  final Function(Map<String, dynamic>)? onFilterChanged;
  final Function(String)? onSearch; // Callback para búsqueda con API
  final bool isSearching; // Indicador de carga

  const OverdueFilter({
    this.userRole = 'admin',
    this.onFilterChanged,
    this.onSearch,
    this.isSearching = false,
    Key? key,
  }) : super(key: key);

  @override
  State<OverdueFilter> createState() => _OverdueFilterState();
}

class _OverdueFilterState extends State<OverdueFilter> {
  String _selectedSeverity = 'all';
  String _selectedDayRange = 'all';
  String _searchText = '';
  bool _expandedFilters = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Ejecuta la búsqueda con API
  void _performSearch() {
    final searchValue = _searchController.text.trim();
    if (searchValue.isNotEmpty) {
      widget.onSearch?.call(searchValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Búsqueda con botón
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por cliente o teléfono...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchText = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onChanged: (value) => setState(() => _searchText = value),
                onSubmitted: (_) => _performSearch(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: widget.isSearching ? null : _performSearch,
              icon: widget.isSearching
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    )
                  : const Icon(Icons.search),
              label: const Text('Buscar'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Botón de filtros adicionales
        InkWell(
          onTap: () => setState(() => _expandedFilters = !_expandedFilters),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  _expandedFilters ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Filtros avanzados',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),

        // Filtros expandibles
        if (_expandedFilters) ...[
          const SizedBox(height: 12),
          _buildFilterChips(),
        ],
      ],
    );
  }

  /// Construye chips de filtros
  Widget _buildFilterChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtro por severidad
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Severidad:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildFilterChip('all', 'Todas', Colors.grey),
                  _buildFilterChip('light', 'Leve', Colors.amber),
                  _buildFilterChip('moderate', 'Moderada', Colors.orange),
                  _buildFilterChip('severe', 'Crítica', Colors.red),
                ],
              ),
            ],
          ),
        ),

        // Filtro por rango de días
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rango de Atraso:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildDayRangeChip('all', 'Todos'),
                _buildDayRangeChip('1-5', '1-5 días'),
                _buildDayRangeChip('6-15', '6-15 días'),
                _buildDayRangeChip('16+', '16+ días'),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Construye un chip de filtro de severidad
  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _selectedSeverity == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedSeverity = value);
        widget.onFilterChanged?.call({
          'severity': value,
          'dayRange': _selectedDayRange,
          'search': _searchText,
        });
      },
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: isSelected
          ? Icon(Icons.check_circle, size: 18, color: color)
          : null,
    );
  }

  /// Construye un chip de filtro de rango de días
  Widget _buildDayRangeChip(String value, String label) {
    final isSelected = _selectedDayRange == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedDayRange = value);
        widget.onFilterChanged?.call({
          'severity': _selectedSeverity,
          'dayRange': value,
          'search': _searchText,
        });
      },
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: isSelected ? Colors.blue : Colors.grey.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue[700] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      avatar: isSelected
          ? const Icon(Icons.check_circle, size: 18, color: Colors.blue)
          : null,
    );
  }
}
