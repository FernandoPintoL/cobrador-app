import 'package:flutter/material.dart';
import 'credit_search_bar.dart';

/// Widget para el encabezado de búsqueda de créditos
/// Incluye la barra de búsqueda y botones adicionales para filtros
class SearchHeader extends StatelessWidget {
  final TextEditingController searchController;
  final String currentSearch;
  final bool showAdvancedFilters;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;
  final VoidCallback onToggleAdvanced;

  const SearchHeader({
    super.key,
    required this.searchController,
    required this.currentSearch,
    required this.showAdvancedFilters,
    required this.onSearch,
    required this.onClearSearch,
    required this.onToggleAdvanced
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CreditSearchBar(
                searchController: searchController,
                currentSearch: currentSearch,
                showAdvancedFilters: showAdvancedFilters,
                onSearch: onSearch,
                onClear: onClearSearch,
                onToggleAdvancedFilters: onToggleAdvanced,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
