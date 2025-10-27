import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/reports_provider.dart' as rp;
import 'utils/filter_builder.dart';
import 'utils/report_state_helper.dart';
import 'views/report_view_factory.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final String userRole; // 'manager' o 'cobrador'

  const ReportsScreen({super.key, required this.userRole});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedReport;
  Map<String, dynamic> _filters = {};
  String _format = 'json';
  rp.ReportRequest? _currentRequest;
  int? _quickRangeIndex;
  bool _showFilters = true; // Controla si los filtros están visibles

  @override
  Widget build(BuildContext context) {
    final reportTypesAsync = ref.watch(rp.reportTypesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Generador de Reportes'),
        actions: [
          IconButton(
            onPressed: () {
              showAboutDialog(
                context: context,
                applicationName: 'Generador de Reportes',
                applicationVersion: '',
                children: const [
                  Text(
                    'Seleccione un tipo de reporte, configure filtros y genere resultados en JSON, Excel o PDF.',
                  ),
                ],
              );
            },
            icon: const Icon(Icons.help_outline),
            tooltip: 'Ayuda',
          ),
        ],
      ),
      body: reportTypesAsync.when(
        data: (types) {
          final entries = types.entries.toList();
          final theme = Theme.of(context);
          final cs = theme.colorScheme;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // 🎯 CARD DE FILTROS COLAPSABLE
                Card(
                  elevation: _showFilters ? 2 : 0.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header colapsable
                      GestureDetector(
                        onTap: () =>
                            setState(() => _showFilters = !_showFilters),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _showFilters
                                ? cs.primaryContainer.withValues(alpha: 0.3)
                                : cs.surfaceContainerHighest.withValues(
                                    alpha: 0.5,
                                  ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _showFilters
                                    ? Icons.filter_alt
                                    : Icons.filter_alt_off,
                                color: cs.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Filtros de búsqueda',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: cs.primary,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _showFilters ? 0 : 0.5,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.expand_more,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Contenido colapsable
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _showFilters
                            ? Container(
                                constraints: const BoxConstraints(
                                  maxHeight:
                                      400, // Limita altura del contenedor
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Selector de tipo de reporte
                                        Row(
                                          children: const [
                                            Icon(
                                              Icons.insights_outlined,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Tipo de reporte',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: cs.outline.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedReport,
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            menuMaxHeight: 300,
                                            items: entries
                                                .map(
                                                  (e) => DropdownMenuItem(
                                                    value: e.key,
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                          ),
                                                      child: Text(
                                                        e.value['name'] ??
                                                            e.key,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                            onChanged: (v) => setState(() {
                                              _selectedReport = v;
                                              _quickRangeIndex = null;
                                              _filters.remove('start_date');
                                              _filters.remove('end_date');
                                            }),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        if (_selectedReport != null) ...[
                                          if ((types[_selectedReport!]?['filters']
                                                      as List<dynamic>? ??
                                                  [])
                                              .any(
                                                (f) =>
                                                    f.toString() ==
                                                        'start_date' ||
                                                    f.toString() == 'end_date',
                                              ))
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8.0,
                                              ),
                                              child: Wrap(
                                                spacing: 8,
                                                children: ReportStateHelper.buildQuickRangeChips(
                                                  selectedIndex:
                                                      _quickRangeIndex,
                                                  colorScheme: cs,
                                                  onSelected: (index) {
                                                    setState(() {
                                                      if (index == -1) {
                                                        // Deseleccionar
                                                        _quickRangeIndex = null;
                                                        ReportStateHelper.clearDateFilters(
                                                          _filters,
                                                        );
                                                      } else {
                                                        _quickRangeIndex =
                                                            index;
                                                        ReportStateHelper.applyQuickDateRange(
                                                          index,
                                                          _filters,
                                                        );
                                                      }
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          // Filtros dinámicos
                                          Flexible(
                                            child: SingleChildScrollView(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: FilterBuilder.buildFiltersForReportType(
                                                  reportTypeDefinition:
                                                      types[_selectedReport!],
                                                  currentFilters: _filters,
                                                  isManualDateRange:
                                                      ReportStateHelper.isManualDateRange(
                                                        _quickRangeIndex,
                                                      ),
                                                  onFilterChanged: (key, value) {
                                                    setState(() {
                                                      // El state ya se actualiza en FilterBuilder
                                                    });
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      // Footer con botones de acción
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'Formato:',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: _format,
                                    items:
                                        ((types[_selectedReport]?['formats']
                                                    as List<dynamic>?) ??
                                                ['json'])
                                            .map(
                                              (f) => DropdownMenuItem(
                                                value: f as String,
                                                child: Text(
                                                  f.toString().toUpperCase(),
                                                  style:
                                                      theme.textTheme.bodySmall,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                    onChanged: (v) =>
                                        setState(() => _format = v ?? 'json'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _filters.clear();
                                        _quickRangeIndex = null;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Filtros limpiados'),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.clear_all, size: 18),
                                    label: const Text('Limpiar'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _selectedReport == null
                                  ? null
                                  : _generateReport,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Generar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 📊 CARD DE RESULTADOS - Ahora toma más espacio
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _ReportResultView(request: _currentRequest),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text('Error cargando tipos de reportes: $e')),
      ),
    );
  }

  void _generateReport() {
    if (!ReportStateHelper.canGenerateReport(_selectedReport)) {
      return;
    }

    setState(() {
      _currentRequest = ReportStateHelper.createReportRequest(
        reportType: _selectedReport ?? '',
        filters: _filters,
        format: _format,
      );
    });
  }
}

class _ReportResultView extends ConsumerWidget {
  final rp.ReportRequest? request;

  const _ReportResultView({required this.request, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (request == null) {
      return const Center(
        child: Text('Seleccione un reporte y presione Generar'),
      );
    }

    final req = request!;
    if (req.type.isEmpty) {
      return const Center(
        child: Text('Seleccione un reporte y presione Generar'),
      );
    }

    final asyncVal = ref.watch(rp.generateReportProvider(req));

    return asyncVal.when(
      data: (value) {
        // Si es formato JSON, usar la factory para crear la vista especializada
        if (req.format == 'json') {
          final dynamic payload = value is Map && value.containsKey('data')
              ? value['data']
              : value;

          // Usar factory para crear la vista apropiada según el tipo de payload
          return ReportViewFactory.createView(request: req, payload: payload);
        } else {
          // Para formatos binarios (PDF, Excel), mostrar vista genérica
          return _BinaryReportView(payload: value);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error generando reporte: $e')),
    );
  }
}

/// Vista para mostrar reportes en formato binario (PDF, Excel, etc.)
class _BinaryReportView extends StatelessWidget {
  final dynamic payload;

  const _BinaryReportView({required this.payload, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description, size: 64, color: Colors.blue[300]),
          const SizedBox(height: 16),
          const Text(
            'Reporte Generado',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'El reporte fue descargado exitosamente',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
