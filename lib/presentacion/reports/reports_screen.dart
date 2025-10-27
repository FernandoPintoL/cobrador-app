import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/reports_provider.dart' as rp;
import 'utils/filter_builder.dart';
import 'utils/report_state_helper.dart';
import 'views/report_view_factory.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

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
          return Column(
            children: [
              // 🎯 BARRA DE FILTROS COMPACTA EN LA PARTE SUPERIOR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    bottom: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header colapsable compacto
                    GestureDetector(
                      onTap: () =>
                          setState(() => _showFilters = !_showFilters),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                                maxHeight: 400,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 12, 8, 12),
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
                                                        const EdgeInsets
                                                            .symmetric(
                                                      horizontal: 12,
                                                    ),
                                                    child: Text(
                                                      e.value['label'] ??
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
                                              children: ReportStateHelper
                                                  .buildQuickRangeChips(
                                                selectedIndex: _quickRangeIndex,
                                                colorScheme: cs,
                                                onSelected: (index) {
                                                  setState(() {
                                                    if (index == -1) {
                                                      _quickRangeIndex = null;
                                                      ReportStateHelper
                                                          .clearDateFilters(
                                                        _filters,
                                                      );
                                                    } else {
                                                      _quickRangeIndex = index;
                                                      ReportStateHelper
                                                          .applyQuickDateRange(
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
                                              children: FilterBuilder
                                                  .buildFiltersForReportType(
                                                reportTypeDefinition:
                                                    types[_selectedReport!],
                                                currentFilters: _filters,
                                                isManualDateRange:
                                                    ReportStateHelper
                                                        .isManualDateRange(
                                                      _quickRangeIndex,
                                                    ),
                                                onFilterChanged:
                                                    (key, value) {
                                                  setState(() {});
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
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
                                  items: ((types[_selectedReport]?['formats']
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
                                  onChanged: (v) => setState(
                                    () => _format = v ?? 'json',
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _filters.clear();
                                      _quickRangeIndex = null;
                                    });
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('Filtros limpiados'),
                                      ),
                                    );
                                  },
                                  icon:
                                      const Icon(Icons.clear_all, size: 18),
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
              // 📊 CONTENIDO DE RESULTADOS - OCUPA MÁXIMO ESPACIO
              Expanded(
                child: Container(
                  color: cs.brightness == Brightness.dark
                      ? cs.surface
                      : const Color(0xFFF5F7FB),
                  padding: const EdgeInsets.all(12),
                  child: _ReportResultView(request: _currentRequest),
                ),
              ),
            ],
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
          return _BinaryReportView(payload: value, format: req.format);
        }
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error generando reporte: $e')),
    );
  }
}

/// Vista para mostrar reportes en formato binario (PDF, Excel, etc.)
class _BinaryReportView extends StatefulWidget {
  final dynamic payload;
  final String format;

  const _BinaryReportView({
    required this.payload,
    required this.format,
    Key? key,
  }) : super(key: key);

  @override
  State<_BinaryReportView> createState() => _BinaryReportViewState();
}

class _BinaryReportViewState extends State<_BinaryReportView> {
  late Future<String> _fileSaveFuture;

  @override
  void initState() {
    super.initState();
    _fileSaveFuture = _saveAndOpenFile();
  }

  Future<String> _saveAndOpenFile() async {
    try {
      // Convertir payload (lista de integers) a Uint8List
      final List<int> byteList;
      if (widget.payload is List<int>) {
        byteList = widget.payload as List<int>;
      } else if (widget.payload is Uint8List) {
        byteList = widget.payload as Uint8List;
      } else {
        throw Exception('Formato de archivo inválido');
      }

      final bytes = Uint8List.fromList(byteList);

      // Validar que el archivo tenga contenido
      if (bytes.isEmpty) {
        throw Exception('El archivo descargado está vacío');
      }

      // Obtener extensión según el formato
      final extension = _getFileExtension(widget.format);

      // Obtener directorio apropiado según el formato
      final Directory? dir;
      if (widget.format.toLowerCase() == 'excel') {
        // Para Excel, usar directorio de documentos de la app
        dir = await getApplicationDocumentsDirectory();
      } else {
        // Para PDF y otros, usar descargas
        dir = await getDownloadsDirectory();
      }

      if (dir == null) {
        throw Exception('No se pudo acceder al directorio de almacenamiento');
      }

      // Crear nombre de archivo con timestamp
      final now = DateTime.now();
      final timestamp =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
      final fileName = 'Reporte_$timestamp.$extension';
      final filePath = '${dir.path}/$fileName';

      // Guardar archivo
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // Verificar que el archivo fue escrito correctamente
      final exists = await file.exists();
      if (!exists) {
        throw Exception('No se pudo guardar el archivo');
      }

      final savedSize = await file.length();
      if (savedSize != bytes.length) {
        throw Exception('El tamaño del archivo guardado no coincide (esperado: ${bytes.length}, guardado: $savedSize)');
      }

      // Pequeña pausa para asegurar que el archivo esté completamente escrito
      await Future.delayed(const Duration(milliseconds: 500));

      // Abrir archivo
      await OpenFilex.open(filePath);

      return filePath;
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  /// Obtiene la extensión correcta según el formato
  String _getFileExtension(String format) {
    final fmt = format.toLowerCase();
    switch (fmt) {
      case 'excel':
      case 'xlsx':
        return 'xlsx';
      case 'xls':
        return 'xls';
      case 'csv':
        return 'csv';
      case 'pdf':
        return 'pdf';
      default:
        return fmt.isEmpty ? 'bin' : fmt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<String>(
        future: _fileSaveFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text(
                  'Generando y abriendo reporte...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            );
          }

          if (snapshot.hasError || (snapshot.data?.startsWith('Error:') ?? false)) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text(
                  'Error al generar reporte',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error?.toString() ?? snapshot.data ?? 'Error desconocido',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _fileSaveFuture = _saveAndOpenFile();
                    });
                  },
                  child: const Text('Intentar de nuevo'),
                ),
              ],
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
              const SizedBox(height: 16),
              const Text(
                'Reporte Generado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'El reporte fue guardado en:\n${snapshot.data}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () async {
                  if (snapshot.data != null && !snapshot.data!.startsWith('Error:')) {
                    await OpenFilex.open(snapshot.data!);
                  }
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir Reporte'),
              ),
            ],
          );
        },
      ),
    );
  }
}
