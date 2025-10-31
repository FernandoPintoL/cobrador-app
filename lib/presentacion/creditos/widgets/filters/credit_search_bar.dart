import 'package:flutter/material.dart';

/// Widget para la barra de búsqueda rápida de créditos
class CreditSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String currentSearch;
  final bool showAdvancedFilters;
  final VoidCallback onSearch;
  final VoidCallback onClear;
  final VoidCallback onToggleAdvancedFilters;

  const CreditSearchBar({
    super.key,
    required this.searchController,
    required this.currentSearch,
    required this.showAdvancedFilters,
    required this.onSearch,
    required this.onClear,
    required this.onToggleAdvancedFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: searchController,
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Buscar por nombre, CI o celular del cliente',
          suffixIcon: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentSearch.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpiar',
                    onPressed: onClear,
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                  onPressed: onSearch,
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: showAdvancedFilters ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.tune),
                  ),
                  onPressed: onToggleAdvancedFilters,
                  tooltip: showAdvancedFilters
                      ? 'Ocultar filtros avanzados'
                      : 'Mostrar filtros avanzados',
                ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        onSubmitted: (_) => onSearch(),
      ),
    );
  }
}
