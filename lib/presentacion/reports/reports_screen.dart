import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/reports_provider.dart' as rp;
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/services/report_authorization_service.dart';
import 'utils/report_state_helper.dart';
import 'utils/format_labels.dart';
import 'views/report_view_factory.dart';
import 'widgets/role_aware_filter_builder.dart';
import 'services/report_defaults_service.dart';
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

  // 🎨 Emojis para cada tipo de reporte
  static const Map<String, String> _reportEmojis = {
    'credits': '💳',
    'payments': '💵',
    'balances': '💰',
    'overdue': '⏰',
    'daily-activity': '📅',
    'users': '👥',
    'performance': '📊',
    'portfolio': '💼',
    'commissions': '💎',
    'cash-flow-forecast': '📈',
    'waiting-list': '⏳',
  };

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
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
                    'Seleccione un tipo de reporte, configure filtros y genere una vista previa o descargue en PDF/Excel.',
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
          // Filtrar reportes según el rol del usuario
          List<MapEntry<String, dynamic>> entries = types.entries.toList();

          if (usuario != null) {
            entries = entries
                .where((e) {
                  // Usar el nombre del reporte tal como viene del backend
                  // (puede ser 'balances', 'daily-activity', etc.)
                  return ReportAuthorizationService.hasReportAccess(e.key, usuario);
                })
                .toList();
          }

          final theme = Theme.of(context);
          final cs = theme.colorScheme;

          return LayoutBuilder(
            builder: (context, constraints) {
              // 📱 Calcular altura máxima responsiva para filtros
              // Dejar al menos 320px para el contenido de resultados + padding extra
              final maxFilterHeight = (constraints.maxHeight - 320).clamp(180.0, 320.0);

              return Column(
                children: [
                  // 🎯 BARRA DE FILTROS COMPACTA EN LA PARTE SUPERIOR
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
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
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Icon(
                              _showFilters
                                  ? Icons.filter_alt
                                  : Icons.filter_alt_off,
                              color: cs.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Filtros de búsqueda',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.primary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            // 🎯 Badge de conteo de filtros activos
                            if (_filters.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: cs.primary.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '${_filters.length}',
                                  style: TextStyle(
                                    color: cs.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            AnimatedRotation(
                              turns: _showFilters ? 0 : 0.5,
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                Icons.expand_more,
                                color: cs.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 🎯 Chips de filtros activos cuando está colapsado
                    if (!_showFilters && _filters.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _filters.entries.map((entry) {
                            final emoji = _getFilterEmoji(entry.key);
                            final displayValue = _formatFilterValue(entry.key, entry.value);

                            return Chip(
                              avatar: Text(
                                emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                              label: Text(
                                '${_getFilterLabel(entry.key)}: $displayValue',
                                style: const TextStyle(fontSize: 11),
                              ),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _filters.remove(entry.key);
                                });
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              backgroundColor: cs.secondaryContainer,
                              labelStyle: TextStyle(color: cs.onSecondaryContainer),
                            );
                          }).toList(),
                        ),
                      ),
                    // Contenido colapsable
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showFilters
                          ? Container(
                              constraints: BoxConstraints(
                                maxHeight: maxFilterHeight,  // 📱 Altura responsiva calculada dinámicamente
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(8, 8, 8, 8),  // 📱 Reducido padding
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
                                      const SizedBox(height: 6),
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: cs.outline.withValues(
                                              alpha: 0.2,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
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
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          _reportEmojis[e.key] ?? '📄',
                                                          style: const TextStyle(fontSize: 20),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            e.value['label'] ??
                                                                e.value['name'] ??
                                                                e.key,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: (v) {
                                            if (v == null) return;

                                            setState(() {
                                              _selectedReport = v;

                                              // ✅ Aplicar defaults inteligentes al seleccionar reporte
                                              final usuario = ref.read(authProvider).usuario;
                                              _filters = ReportDefaultsService.getDefaultFilters(
                                                reportType: v,
                                                usuario: usuario,
                                              );

                                              // ✅ Pre-seleccionar chip de rango rápido correspondiente
                                              _quickRangeIndex = ReportDefaultsService.getDefaultQuickRangeIndex(v);
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 8),
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
                                        // ✅ Banner informativo de defaults aplicados
                                        if (_filters.isNotEmpty)
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),  // 📱 Reducido más
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),  // 📱 Más compacto
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.blue.withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.auto_awesome,
                                                  size: 16,
                                                  color: Colors.blue[700],
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Filtros aplicados: ${ReportDefaultsService.getFiltersDescription(_filters, _selectedReport!)}',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: Colors.blue[700],
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Filtros dinámicos con soporte para roles
                                        if (usuario != null)
                                          Padding(
                                            padding: const EdgeInsets.all(8),
                                            child: RoleAwareFilterBuilder(
                                              reportType: _selectedReport ?? '',
                                              currentFilters: _filters,
                                              onFilterChanged: (key, value) {
                                                setState(() {
                                                  if (value == null) {
                                                    _filters.remove(key);
                                                  } else {
                                                    _filters[key] = value;
                                                  }
                                                });
                                              },
                                            ),
                                          )
                                        else
                                          const Padding(
                                            padding: EdgeInsets.all(16),
                                            child: Text('Usuario no autenticado'),
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
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Formato:',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                                Tooltip(
                                  message: FormatLabels.getTechnicalHint(_format),
                                  child: DropdownButton<String>(
                                    value: _format,
                                    isDense: true,
                                    items: ((types[_selectedReport]?['formats']
                                                as List<dynamic>?) ??
                                            ['json'])
                                        .map(
                                          (f) {
                                            final format = f as String;
                                            return DropdownMenuItem(
                                              value: format,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    FormatLabels.getIcon(format),
                                                    size: 16,
                                                    color: cs.primary,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    FormatLabels.getLabel(format),
                                                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        )
                                        .toList(),
                                    onChanged: (v) => setState(
                                      () => _format = v ?? 'json',
                                    ),
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
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.clear_all, size: 16),
                                  label: const Text('Limpiar', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // ✅ Botón con descripción de filtros
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FilledButton.icon(
                                  onPressed: _selectedReport == null
                                      ? null
                                      : _generateReport,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                                  label: const Text('Generar', style: TextStyle(fontSize: 12)),
                                ),
                                // ✅ Badge con descripción de filtros aplicados
                                if (_selectedReport != null && _filters.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4, right: 4),
                                    child: Text(
                                      ReportDefaultsService.getFiltersDescription(
                                        _filters,
                                        _selectedReport!,
                                      ),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                        fontSize: 9,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),  // Container
              // 📊 CONTENIDO DE RESULTADOS - OCUPA MÁXIMO ESPACIO
              Expanded(
                child: Container(
                  color: cs.brightness == Brightness.dark
                      ? cs.surface
                      : const Color(0xFFF5F7FB),
                  padding: const EdgeInsets.all(3),
                  child: _ReportResultView(request: _currentRequest),
                ),
              ),
            ],
          );
            },
          );  // LayoutBuilder
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text('Error cargando tipos de reportes: $e')),
      ),
    );
  }

  // 🎨 Obtiene el emoji para un filtro
  String _getFilterEmoji(String filterKey) {
    const emojis = {
      'start_date': '📅',
      'end_date': '📆',
      'status': '🏷️',
      'cobrador_id': '👤',
      'client_id': '👥',
      'created_by': '✍️',
      'delivered_by': '🚚',
      'amount': '💵',
      'role': '🎭',
      'client_category': '⭐',
    };
    return emojis[filterKey] ?? '📋';
  }

  // 📝 Obtiene el label legible para un filtro
  String _getFilterLabel(String filterKey) {
    const labels = {
      'start_date': 'Desde',
      'end_date': 'Hasta',
      'status': 'Estado',
      'cobrador_id': 'Cobrador',
      'client_id': 'Cliente',
      'created_by': 'Creado por',
      'delivered_by': 'Entregado por',
      'amount': 'Monto',
      'role': 'Rol',
      'client_category': 'Categoría',
    };
    return labels[filterKey] ?? filterKey;
  }

  // 🔤 Formatea el valor del filtro para mostrar
  String _formatFilterValue(String filterKey, dynamic value) {
    if (value == null) return 'N/A';

    // Fechas
    if (filterKey.contains('date') && value is DateTime) {
      return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
    }

    // Valores largos (truncar)
    final stringValue = value.toString();
    if (stringValue.length > 15) {
      return '${stringValue.substring(0, 12)}...';
    }

    return stringValue;
  }

  void _generateReport() {
    if (!ReportStateHelper.canGenerateReport(_selectedReport)) {
      return;
    }

    setState(() {
      // ⭐ Auto-colapsar filtros al generar para mejor visualización del reporte
      _showFilters = false;

      // Usar el nombre del reporte tal como viene del backend
      // El backend usa 'balances' (plural), 'daily-activity', etc.
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
