import 'package:flutter/material.dart';

class SearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String currentSearch;
  final bool showAdvancedFilters;
  final Function(String) onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleAdvanced;
  final VoidCallback onFilter;

  const SearchHeader({
    super.key,
    required this.searchController,
    required this.currentSearch,
    required this.showAdvancedFilters,
    required this.onSearch,
    required this.onClearSearch,
    required this.onToggleAdvanced,
    required this.onFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar créditos...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: currentSearch.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClearSearch,
                        )
                      : null,
                ),
                onChanged: onSearch,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
              ),
              onPressed: onToggleAdvanced,
              tooltip: showAdvancedFilters
                  ? 'Ocultar filtros'
                  : 'Mostrar filtros',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: onFilter,
              tooltip: 'Filtros rápidos',
            ),
          ],
        ),
      ],
    );
  }
}
