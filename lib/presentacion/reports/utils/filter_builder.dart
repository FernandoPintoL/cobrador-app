import 'package:flutter/material.dart';
import '../widgets/date_filter_field.dart';
import '../widgets/search_select_field.dart';
import 'filter_helpers.dart';

/// Constructor genérico de widgets de filtros dinámicos
///
/// Responsabilidades:
/// - Detectar el tipo de filtro por nombre (date, cobrador, cliente, etc.)
/// - Crear el widget UI apropiado para cada tipo
/// - Construir lista completa de filtros para un reporte
///
/// Patrones utilizados:
/// - Strategy Pattern: diferentes widgets según tipo de filtro
/// - Builder Pattern: construcción paso a paso de lista de filtros
///
/// Ejemplo de uso:
/// ```dart
/// final filters = FilterBuilder.buildFiltersForReportType(
///   reportTypeDefinition: types['payments'],
///   currentFilters: _filters,
///   isManualDateRange: false,
///   onFilterChanged: (key, value) {
///     setState(() { /* actualizar estado */ });
///   },
/// );
/// ```
///
/// Ver también: FilterLabelTranslator, DateFilterField, SearchSelectField
class FilterBuilder {
  /// Detecta el tipo de filtro basado en su nombre
  static FilterType detectFilterType(String filterKey) {
    final key = filterKey.toLowerCase();

    // Detectar filtros de fecha
    if (key.contains('date') || key.contains('fecha')) {
      return FilterType.date;
    }

    // Detectar filtros de cobrador
    if (key.contains('cobrador') ||
        key.contains('collector') ||
        key.contains('delivered')) {
      return FilterType.cobrador;
    }

    // Detectar filtros de cliente
    if (key.contains('client') || key.contains('cliente')) {
      return FilterType.cliente;
    }

    // Detectar filtros de categoría
    if (key.contains('categoria') || key.contains('category')) {
      return FilterType.categoria;
    }

    // Por defecto, texto
    return FilterType.text;
  }

  /// Construye un widget de filtro apropiado basado en el tipo
  static Widget buildFilterWidget({
    required String filterKey,
    required FilterType type,
    required String? currentValue,
    required Function(String?) onChanged,
    bool showDateManualOnly = false,
  }) {
    final label = FilterLabelTranslator.translate(filterKey);
    final padding = const EdgeInsets.only(bottom: 8.0);

    switch (type) {
      case FilterType.date:
        return Padding(
          padding: padding,
          child: DateFilterField(
            label: label,
            value: currentValue,
            onChanged: onChanged,
          ),
        );

      case FilterType.cobrador:
      case FilterType.cliente:
      case FilterType.categoria:
        final searchType = type == FilterType.cobrador
            ? 'cobrador'
            : type == FilterType.cliente
                ? 'cliente'
                : 'categoria';
        return Padding(
          padding: padding,
          child: SearchSelectField(
            label: label,
            initialValue: currentValue,
            type: searchType,
            onSelected: (id, name) {
              onChanged(id ?? name);
            },
          ),
        );

      case FilterType.text:
        return Padding(
          padding: padding,
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        );
    }
  }

  /// Construye una lista de widgets de filtros dinámicamente
  /// Solo incluye filtros de fecha si isManualDateRange es true
  static List<Widget> buildFiltersForReportType({
    required dynamic reportTypeDefinition,
    required Map<String, dynamic> currentFilters,
    required bool isManualDateRange,
    required Function(String, String?) onFilterChanged,
  }) {
    final widgets = <Widget>[];
    final filters = (reportTypeDefinition?['filters'] as List<dynamic>?) ?? [];

    for (final filter in filters) {
      final filterKey = filter as String;
      final filterType = detectFilterType(filterKey);

      // Saltar filtros de fecha si no estamos en modo "Rango de fechas manual"
      if (filterType == FilterType.date && !isManualDateRange) {
        continue;
      }

      final widget = buildFilterWidget(
        filterKey: filterKey,
        type: filterType,
        currentValue: currentFilters[filterKey]?.toString(),
        onChanged: (value) {
          if (value == null || value.isEmpty) {
            currentFilters.remove(filterKey);
          } else {
            currentFilters[filterKey] = value;
          }
          onFilterChanged(filterKey, value);
        },
      );

      widgets.add(widget);
    }

    return widgets;
  }
}

/// Tipos de filtro detectados por FilterBuilder
enum FilterType {
  date,
  cobrador,
  cliente,
  categoria,
  text,
}
