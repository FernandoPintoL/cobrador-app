import 'package:flutter/material.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import 'date_range_helper.dart';

/// Gestor centralizado de estado y lógica de reportes
///
/// Responsabilidades:
/// - Crear ReportRequest con parámetros validados
/// - Gestionar rangos de fecha rápidos (hoy, ayer, últimos 7 días, etc.)
/// - Construir widgets de rango rápido (ChoiceChips)
/// - Validar si es posible generar un reporte
///
/// Ventajas de centralización:
/// - Una única fuente de verdad para labels de rangos rápidos
/// - Lógica de fecha consistente en toda la app
/// - Fácil de testear (sin dependencias de UI)
/// - Separación clara de responsabilidades
///
/// Ejemplo de uso:
/// ```dart
/// // Crear request
/// final request = ReportStateHelper.createReportRequest(
///   reportType: 'payments',
///   filters: {'client_id': '123'},
///   format: 'json',
/// );
///
/// // Aplicar rango rápido
/// ReportStateHelper.applyQuickDateRange(0, _filters);  // Hoy
/// ReportStateHelper.applyQuickDateRange(2, _filters);  // Últimos 7 días
///
/// // Validar
/// if (ReportStateHelper.canGenerateReport(_selectedReport)) {
///   _generateReport();
/// }
/// ```
///
/// Ver también: FilterBuilder, ReportFormatters, DateRangeHelper
class ReportStateHelper {
  /// Etiquetas para los rangos rápidos de fecha
  static const List<String> quickRangeLabels = [
    'Hoy',
    'Ayer',
    'Últimos 7 días',
    'Este mes',
    'Mes pasado',
    'Rango de fechas',
  ];

  /// Genera un ReportRequest con los parámetros dados
  static rp.ReportRequest createReportRequest({
    required String reportType,
    required Map<String, dynamic> filters,
    required String format,
  }) {
    return rp.ReportRequest(
      type: reportType,
      filters: Map<String, dynamic>.from(filters),
      format: format,
    );
  }

  /// Aplica un rango rápido de fecha a los filtros
  /// El índice 5 es "Rango de fechas" (no aplica automáticamente)
  static void applyQuickDateRange(
    int rangeIndex,
    Map<String, dynamic> filters,
  ) {
    if (rangeIndex == 5) {
      // "Rango de fechas" - no aplicar automáticamente
      filters.remove('start_date');
      filters.remove('end_date');
    } else {
      // Aplicar el rango correspondiente
      final range = DateRangeHelper.getRangeForIndex(rangeIndex);
      filters['start_date'] = range['start'];
      filters['end_date'] = range['end'];
    }
  }

  /// Limpia los filtros de fecha
  static void clearDateFilters(Map<String, dynamic> filters) {
    filters.remove('start_date');
    filters.remove('end_date');
  }

  /// Valida si se puede generar un reporte
  static bool canGenerateReport(String? selectedReportType) {
    return selectedReportType != null && selectedReportType.isNotEmpty;
  }

  /// Obtiene la etiqueta para un índice de rango rápido
  static String getQuickRangeLabel(int index) {
    if (index < 0 || index >= quickRangeLabels.length) {
      return '';
    }
    return quickRangeLabels[index];
  }

  /// Verifica si un índice corresponde al modo "Rango de fechas manual"
  static bool isManualDateRange(int? quickRangeIndex) {
    return quickRangeIndex == 5;
  }

  /// Genera la lista de widgets para los chips de rango rápido
  static List<ChoiceChip> buildQuickRangeChips({
    required int? selectedIndex,
    required Function(int) onSelected,
    required ColorScheme colorScheme,
  }) {
    return List<ChoiceChip>.generate(
      quickRangeLabels.length,
      (index) {
        final isSelected = selectedIndex == index;
        return ChoiceChip(
          label: Text(quickRangeLabels[index]),
          selected: isSelected,
          labelStyle: TextStyle(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          ),
          selectedColor: colorScheme.primaryContainer,
          backgroundColor: colorScheme.surface,
          shape: const StadiumBorder(),
          side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.4),
          ),
          onSelected: (selected) {
            onSelected(selected ? index : -1);
          },
        );
      },
    );
  }
}
