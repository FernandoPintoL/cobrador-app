import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_download_helper.dart';
import 'base_report_view.dart';
import '../widgets/overdue_dashboard.dart';
import '../widgets/overdue_filter.dart';
import '../widgets/overdue_severity_tabs.dart';

// Provider para manejar el estado de filtrado
final overdueFilterStateProvider = StateNotifierProvider.family<
    OverdueFilterNotifier,
    OverdueFilterState,
    dynamic>((ref, payload) {
  return OverdueFilterNotifier(payload);
});

class OverdueFilterState {
  final String searchFilter;
  final String severityFilter;
  final String dayRangeFilter;
  final bool isSearching;
  final List<Map<String, dynamic>> filteredItems;

  OverdueFilterState({
    this.searchFilter = '',
    this.severityFilter = 'all',
    this.dayRangeFilter = 'all',
    this.isSearching = false,
    this.filteredItems = const [],
  });

  OverdueFilterState copyWith({
    String? searchFilter,
    String? severityFilter,
    String? dayRangeFilter,
    bool? isSearching,
    List<Map<String, dynamic>>? filteredItems,
  }) {
    return OverdueFilterState(
      searchFilter: searchFilter ?? this.searchFilter,
      severityFilter: severityFilter ?? this.severityFilter,
      dayRangeFilter: dayRangeFilter ?? this.dayRangeFilter,
      isSearching: isSearching ?? this.isSearching,
      filteredItems: filteredItems ?? this.filteredItems,
    );
  }
}

class OverdueFilterNotifier extends StateNotifier<OverdueFilterState> {
  final dynamic payload;

  OverdueFilterNotifier(this.payload) : super(OverdueFilterState()) {
    _initializeItems();
  }

  void _initializeItems() {
    // ✅ El backend SIEMPRE envía 'items' (estandarizado)
    final items = payload is Map
        ? payload['items'] as List?
        : null;

    if (items != null) {
      final itemList = List<Map<String, dynamic>>.from(items);
      state = state.copyWith(filteredItems: itemList);
      _applyFilters();
    }
  }

  void _applyFilters() {
    // ✅ El backend SIEMPRE envía 'items' (estandarizado)
    final items = payload is Map
        ? payload['items'] as List?
        : null;

    if (items == null) return;

    final filtered = (items as List?)?.cast<Map<String, dynamic>>().where((item) {
      final client = item['client'] as Map<String, dynamic>?;
      final clientName = client?['name']?.toString().toLowerCase() ?? '';
      final clientPhone = client?['phone']?.toString() ?? '';
      final daysOverdue = (item['days_overdue'] as num?)?.toInt() ?? 0;
      final absDays = daysOverdue.abs();

      // Filtro de búsqueda
      if (state.searchFilter.isNotEmpty) {
        final searchLower = state.searchFilter.toLowerCase();
        if (!clientName.contains(searchLower) && !clientPhone.contains(searchLower)) {
          return false;
        }
      }

      // Filtro de severidad
      if (state.severityFilter != 'all') {
        bool matchesSeverity = false;
        switch (state.severityFilter) {
          case 'light':
            matchesSeverity = absDays >= 1 && absDays <= 5;
            break;
          case 'moderate':
            matchesSeverity = absDays >= 6 && absDays <= 15;
            break;
          case 'severe':
            matchesSeverity = absDays > 15;
            break;
        }
        if (!matchesSeverity) return false;
      }

      // Filtro de rango de días
      if (state.dayRangeFilter != 'all') {
        bool matchesRange = false;
        switch (state.dayRangeFilter) {
          case '1-5':
            matchesRange = absDays >= 1 && absDays <= 5;
            break;
          case '6-15':
            matchesRange = absDays >= 6 && absDays <= 15;
            break;
          case '16+':
            matchesRange = absDays > 15;
            break;
        }
        if (!matchesRange) return false;
      }

      return true;
    }).toList() ?? [];

    state = state.copyWith(filteredItems: filtered);
  }

  Future<void> performSearch(String searchText) async {
    if (searchText.isEmpty) {
      state = state.copyWith(searchFilter: '', filteredItems: []);
      _initializeItems();
      return;
    }

    state = state.copyWith(isSearching: true, searchFilter: searchText);
    try {
      _applyFilters();
    } catch (e) {
      print('❌ Error en búsqueda: $e');
    } finally {
      state = state.copyWith(isSearching: false);
    }
  }

  void onFilterChanged(Map<String, dynamic> filters) {
    state = state.copyWith(
      severityFilter: filters['severity'] ?? 'all',
      dayRangeFilter: filters['dayRange'] ?? 'all',
    );
    _applyFilters();
  }
}

/// Vista especializada para reportes de Mora (Overdue)
/// Muestra un resumen de créditos en mora con estadísticas y detalles
/// Adaptada para Admin, Manager y Cobrador
class OverdueReportView extends BaseReportView {
  const OverdueReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  IconData getReportIcon() => Icons.warning;

  @override
  String getReportTitle() => 'Reporte de Mora';

  @override
  bool hasValidPayload() {
    if (!super.hasValidPayload()) return false;
    return payload is Map && (payload.containsKey('items') || payload.containsKey('credits'));
  }

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(overdueFilterStateProvider(payload));
    final notifier = ref.read(overdueFilterStateProvider(payload).notifier);

    // ✅ El backend SIEMPRE envía 'items' (estandarizado)
    final items = payload is Map
        ? payload['items'] as List?
        : null;
    final summary = payload is Map ? payload['summary'] as Map<String, dynamic>? : null;

    final hasOverdue = filterState.filteredItems.isNotEmpty;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Botones de descarga
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => ReportDownloadHelper.downloadReport(
                      context,
                      ref,
                      request,
                      'excel',
                    ),
                    icon: const Icon(Icons.grid_on),
                    label: const Text('Excel'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ReportDownloadHelper.downloadReport(
                      context,
                      ref,
                      request,
                      'pdf',
                    ),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('PDF'),
                  ),
                ],
              ),
            ),

            // Dashboard con resumen
            if (summary != null) ...[
              Text(
                'Resumen General',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OverdueDashboard(
                summary: summary.cast<String, dynamic>(),
              ),
              const SizedBox(height: 24),
            ],

            // Filtros
            if (hasOverdue) ...[
              Text(
                'Filtros',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OverdueFilter(
                onFilterChanged: (filters) => notifier.onFilterChanged(filters),
                onSearch: (search) => notifier.performSearch(search),
                isSearching: filterState.isSearching,
              ),
              const SizedBox(height: 24),
            ],

            // Mostrar cantidad de resultados filtrados
            if (hasOverdue) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Mostrando ${filterState.filteredItems.length} de ${items?.length ?? 0} créditos en mora',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],

            // Créditos en mora por severidad
            if (hasOverdue) ...[
              Text(
                'Créditos en Mora',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              OverdueSeverityTabs(
                items: filterState.filteredItems,
              ),
              const SizedBox(height: 24),
            ] else
              Container(
                margin: const EdgeInsets.symmetric(vertical: 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No hay créditos en mora',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.green[700]),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
