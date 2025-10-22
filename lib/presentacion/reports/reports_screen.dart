import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import '../../datos/api_services/user_api_service.dart';
// client_api_service no se usa directamente aquí; mantenemos solo user_api
import '../../negocio/providers/reports_provider.dart';
import '../../negocio/providers/reports_provider.dart' as rp;

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

  bool _hasDateRange(dynamic typeDef) {
    final filters = (typeDef?['filters'] as List<dynamic>?) ?? [];
    return filters.any(
      (f) => f.toString() == 'start_date' || f.toString() == 'end_date',
    );
  }

  Map<String, String> _rangeForIndex(int idx) {
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String().split('T').first;
    if (idx == 0) {
      final d = DateTime(now.year, now.month, now.day);
      return {'start': iso(d), 'end': iso(d)};
    } else if (idx == 1) {
      final d = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 1));
      return {'start': iso(d), 'end': iso(d)};
    } else if (idx == 2) {
      final end = DateTime(now.year, now.month, now.day);
      final start = end.subtract(const Duration(days: 6));
      return {'start': iso(start), 'end': iso(end)};
    } else if (idx == 3) {
      final start = DateTime(now.year, now.month, 1);
      final end = DateTime(now.year, now.month, now.day);
      return {'start': iso(start), 'end': iso(end)};
    } else {
      // Mes pasado
      final firstThis = DateTime(now.year, now.month, 1);
      final lastPrev = firstThis.subtract(const Duration(days: 1));
      final firstPrev = DateTime(lastPrev.year, lastPrev.month, 1);
      return {'start': iso(firstPrev), 'end': iso(lastPrev)};
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportTypesAsync = ref.watch(reportTypesProvider);

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
                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.insights_outlined, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Tipo de reporte',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: cs.outline.withValues(alpha: 0.2),
                              ),
                              borderRadius: BorderRadius.circular(12),
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(e.value['name'] ?? e.key),
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
                            if (_hasDateRange(types[_selectedReport!]))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Wrap(
                                  spacing: 8,
                                  children: List<Widget>.generate(6, (i) {
                                    final labels = [
                                      'Hoy',
                                      'Ayer',
                                      'Últimos 7 días',
                                      'Este mes',
                                      'Mes pasado',
                                      'Rango de fechas',
                                    ];
                                    final selected = _quickRangeIndex == i;
                                    return ChoiceChip(
                                      label: Text(labels[i]),
                                      selected: selected,
                                      labelStyle: TextStyle(
                                        color: selected
                                            ? cs.onPrimaryContainer
                                            : cs.onSurfaceVariant,
                                      ),
                                      selectedColor: cs.primaryContainer,
                                      backgroundColor: cs.surface,
                                      shape: const StadiumBorder(),
                                      side: BorderSide(
                                        color: selected
                                            ? cs.primary
                                            : cs.outline.withOpacity(0.4),
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          if (!selected) {
                                            // Destildado: limpiar fechas y quitar selección
                                            _quickRangeIndex = null;
                                            _filters.remove('start_date');
                                            _filters.remove('end_date');
                                          } else {
                                            _quickRangeIndex = i;
                                            if (i == 5) {
                                              // Modo manual: limpiar fechas para que el usuario seleccione
                                              _filters.remove('start_date');
                                              _filters.remove('end_date');
                                            } else {
                                              final range = _rangeForIndex(i);
                                              _filters['start_date'] =
                                                  range['start'];
                                              _filters['end_date'] =
                                                  range['end'];
                                            }
                                          }
                                        });
                                      },
                                    );
                                  }),
                                ),
                              ),
                            // Envolver filtros en un Flexible + SingleChildScrollView para evitar overflow
                            Flexible(
                              child: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _buildFiltersFor(
                                    types[_selectedReport!],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'Formato:',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
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
                                      icon: const Icon(Icons.clear_all),
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
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: _ReportResultView(
                        // Solo pasar la petición actual; si es null no se ejecuta la petición
                        request: _currentRequest,
                      ),
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

  List<Widget> _buildFiltersFor(dynamic typeDef) {
    final List<Widget> widgets = [];
    final filters = (typeDef?['filters'] as List<dynamic>?) ?? [];

    for (final f in filters) {
      final key = f as String;

      // Heurística simple: si el nombre del filtro contiene 'date' o 'fecha', usar date picker
      final isDate =
          key.toLowerCase().contains('date') ||
          key.toLowerCase().contains('fecha');

      // Heurística para campos que serán search-selects: cobrador, cliente, categoria
      final isCobrador = key.toLowerCase().contains('cobrador');
      final isCliente =
          key.toLowerCase().contains('client') ||
          key.toLowerCase().contains('cliente');
      final isCategoria =
          key.toLowerCase().contains('categoria') ||
          key.toLowerCase().contains('category');

      if (isDate) {
        // Mostrar inputs de fecha solo cuando el usuario seleccione "Rango de fechas"
        final isManualRange =
            _quickRangeIndex == 5; // índice 5 = Rango de fechas
        if (!isManualRange) {
          // Ocultar campos de fecha si no está seleccionado el rango manual
          continue;
        }
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _DateFilterField(
              label: key.replaceAll('_', ' ').toUpperCase(),
              value: _filters[key]?.toString(),
              onChanged: (v) {
                if (v == null || v.isEmpty) {
                  _filters.remove(key);
                } else {
                  _filters[key] = v;
                }
              },
            ),
          ),
        );
      } else if (isCobrador || isCliente || isCategoria) {
        // Usar search-select para estos campos: guardamos el id o texto seleccionado
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: _SearchSelectField(
              label: key.replaceAll('_', ' ').toUpperCase(),
              initialValue: _filters[key]?.toString(),
              // Tipo usado para decidir qué provider/endpoint usar internamente
              type: isCobrador
                  ? 'cobrador'
                  : (isCliente ? 'cliente' : 'categoria'),
              onSelected: (id, label) {
                // Guardar el id si viene, sino el label
                _filters[key] = id ?? label;
              },
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              decoration: InputDecoration(
                labelText: key.replaceAll('_', ' ').toUpperCase(),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => _filters[key] = v,
            ),
          ),
        );
      }
    }

    return widgets;
  }

  void _generateReport() {
    // Construir y fijar la petición actual; esto evita ejecuciones automáticas del provider
    setState(() {
      _currentRequest = rp.ReportRequest(
        type: _selectedReport ?? '',
        filters: Map<String, dynamic>.from(_filters),
        format: _format,
      );
    });
  }

  void _clearFilters() {
    setState(() {
      _filters.clear();
      _quickRangeIndex = null;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Filtros limpiados')));
  }
}

/// Campo de filtro de fecha: muestra un input con icono de calendario y permite limpiar
class _DateFilterField extends StatefulWidget {
  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DateFilterField({
    required this.label,
    this.value,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  State<_DateFilterField> createState() => _DateFilterFieldState();
}

class _DateFilterFieldState extends State<_DateFilterField> {
  TextEditingController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
  }

  @override
  void didUpdateWidget(covariant _DateFilterField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _controller?.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _controller!.text.isNotEmpty
        ? DateTime.tryParse(_controller!.text) ?? now
        : now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );

    if (picked != null) {
      final iso = picked.toIso8601String().split('T').first;
      _controller?.text = iso;
      widget.onChanged(iso);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _pickDate,
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _controller?.clear();
                widget.onChanged(null);
              },
            ),
          ],
        ),
      ),
      onTap: _pickDate,
    );
  }
}

/// Campo reusable que permite buscar y seleccionar un elemento (cobrador/cliente/categoria).
/// Implementación simple: muestra un TextFormField readOnly que abre un modal con búsqueda.
class _SearchSelectField extends ConsumerStatefulWidget {
  final String label;
  final String? initialValue;
  final String type; // 'cobrador' | 'cliente' | 'categoria'
  final void Function(String? id, String? label) onSelected;

  const _SearchSelectField({
    required this.label,
    this.initialValue,
    required this.type,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<_SearchSelectField> createState() => _SearchSelectFieldState();
}

class _SearchSelectFieldState extends ConsumerState<_SearchSelectField> {
  late TextEditingController _controller;
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _loading = false;
  int _selectedSuggestion = -1;
  late FocusNode _focusNode;
  late FocusNode _keyboardFocusNode;
  // Debug toggle: si false, mostramos las sugerencias inline en el árbol
  // (no usamos Overlay). Esto facilita probar si el overlay provoca
  // reparenting del FocusNode.
  bool _useOverlay = false;
  bool _showInline = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();
    _keyboardFocusNode = FocusNode();
    // Instrumentación: escuchar cambios de foco para trazar reparenting
    _focusNode.addListener(() {
      debugPrint(
        '[SearchSelectField] _focusNode listener: hasFocus=${_focusNode.hasFocus} attached=${_focusNode.context != null}',
      );
    });
    _keyboardFocusNode.addListener(() {
      debugPrint(
        '[SearchSelectField] _keyboardFocusNode listener: hasFocus=${_keyboardFocusNode.hasFocus} attached=${_keyboardFocusNode.context != null}',
      );
    });
    debugPrint(
      '[SearchSelectField] initState - created focus nodes: _focusNode=$_focusNode _keyboardFocusNode=$_keyboardFocusNode controller=$_controller',
    );
  }

  @override
  void didUpdateWidget(covariant _SearchSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue ?? '';
    }
  }

  void _openSearch() async {
    // Para categorias y cualquier otro tipo que no sea cliente/cobrador,
    // mantener el modal existente (categorias se consultan localmente en modal)
    if (widget.type == 'categoria') {
      debugPrint(
        '[SearchSelectField] _openSearch - opening modal for categoria',
      );
      final result = await showModalBottomSheet<Map<String, String>?>(
        context: context,
        isScrollControlled: true,
        builder: (ctx) {
          return _SearchModal(type: widget.type);
        },
      );

      if (result != null) {
        final id = result['id'];
        final label = result['label'];
        _controller.text = label ?? id ?? '';
        widget.onSelected(id, label);
      }
      return;
    }

    // Para cobrador/cliente abrimos sugerencias inline (no modal)
    // Si no hay sugerencias, forzamos una búsqueda rápida con el texto actual
    debugPrint(
      '[SearchSelectField] _openSearch - inline search for type=${widget.type} text="${_controller.text}" suggestions=${_suggestions.length}',
    );
    if (_suggestions.isEmpty && _controller.text.trim().isNotEmpty) {
      await _performSearch(_controller.text.trim());
    }
  }

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    debugPrint(
      '[SearchSelectField] _showOverlay - invoked useOverlay=$_useOverlay',
    );
    // Si no usamos overlay (modo debug), mostramos inline
    if (!_useOverlay) {
      setState(() {
        _showInline = true;
      });
      return;
    }

    debugPrint(
      '[SearchSelectField] _showOverlay - removing existing overlay if any',
    );
    _overlayEntry?.remove();
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) {
        // Full-screen stack to capture outside taps and position the suggestions
        return Stack(
          children: [
            // Area fuera del cuadro de sugerencias: cerrar overlay
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay();
                },
              ),
            ),
            // Position below the field
            Positioned(
              width: MediaQuery.of(context).size.width - 32,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: const Offset(0, 56),
                child: Material(
                  elevation: 4,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 240),
                    child: _buildSuggestionList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    _overlayEntry = entry;
    debugPrint(
      '[SearchSelectField] _showOverlay - inserting overlay entry suggestions=${_suggestions.length}',
    );
    overlay.insert(entry);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      debugPrint('[SearchSelectField] _removeOverlay - removing overlay');
      _overlayEntry?.remove();
      _overlayEntry = null;
    } else {
      debugPrint('[SearchSelectField] _removeOverlay - no overlay to remove');
    }
    if (_showInline) {
      debugPrint(
        '[SearchSelectField] _removeOverlay - hiding inline suggestions',
      );
      setState(() {
        _showInline = false;
      });
    }
  }

  Widget _buildSuggestionList() {
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final s = _suggestions[i];
        return Container(
          color: i == _selectedSuggestion
              ? Theme.of(context).highlightColor
              : null,
          child: ListTile(
            title: Text(s['label'] ?? ''),
            subtitle: Text('ID: ${s['id'] ?? ''}'),
            onTap: () {
              _controller.text = s['label'] ?? s['id'] ?? '';
              widget.onSelected(s['id'], s['label']);
              _removeOverlay();
              FocusScope.of(context).unfocus();
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final target = CompositedTransformTarget(
      link: _layerLink,
      child: RawKeyboardListener(
        focusNode: _keyboardFocusNode,
        onKey: (event) {
          if (event is RawKeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              setState(() {
                if (_suggestions.isNotEmpty) {
                  _selectedSuggestion =
                      (_selectedSuggestion + 1) % _suggestions.length;
                }
              });
              _showOverlay();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              setState(() {
                if (_suggestions.isNotEmpty) {
                  _selectedSuggestion = (_selectedSuggestion - 1) < 0
                      ? _suggestions.length - 1
                      : _selectedSuggestion - 1;
                }
              });
              _showOverlay();
            } else if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) {
              if (_selectedSuggestion >= 0 &&
                  _selectedSuggestion < _suggestions.length) {
                final s = _suggestions[_selectedSuggestion];
                _controller.text = s['label'] ?? s['id'] ?? '';
                widget.onSelected(s['id'], s['label']);
                _removeOverlay();
                FocusScope.of(context).unfocus();
              }
            }
          }
        },
        child: TextFormField(
          // Usamos el mismo FocusNode aquí: RawKeyboardListener lo provee,
          // y evitar envolver el TextFormField con Focus para prevenir
          // reparenting del FocusNode que causaba el assert.
          focusNode: _focusNode,
          controller: _controller,
          readOnly: false,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_loading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _openSearch,
                ),
              ],
            ),
          ),
          onTap: () {
            // Pedir foco al listener de teclado para que eventos de flecha/enter
            // sean capturados sin reparenting.
            if (!_keyboardFocusNode.hasFocus) _keyboardFocusNode.requestFocus();
            _openSearch();
          },
          onChanged: (v) {
            // Debounce user input
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () async {
              _selectedSuggestion = -1;
              await _performSearch(v);
              if (_suggestions.isNotEmpty) {
                _showOverlay();
              } else {
                _removeOverlay();
              }
            });
          },
          onEditingComplete: () {
            // If user finishes editing, hide overlay
            _removeOverlay();
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );

    // Envolvemos el CompositedTransformTarget con el helper que agrega
    // las sugerencias inline cuando _showInline es true.
    return _wrapWithInlineSuggestions(target);
  }

  // Añadir render inline justo después del CompositedTransformTarget
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // nothing for now
  }

  Widget _wrapWithInlineSuggestions(Widget child) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        if (_showInline)
          SizedBox(
            height: (_suggestions.length * 56).clamp(0, 240).toDouble(),
            child: Material(elevation: 4, child: _buildSuggestionList()),
          ),
      ],
    );
  }

  // nuevo: realiza búsqueda usando el servicio y llena _suggestions (máx 5)
  Future<void> _performSearch(String q) async {
    final query = q.trim().toUpperCase();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final svc = UserApiService();
      final resp = await svc.getUsers(
        role: widget.type == 'cobrador' ? 'cobrador' : 'client',
        search: query,
        perPage: 5,
        page: 1,
      );

      List<dynamic> items = [];
      if (resp['success'] == true) {
        if (resp['data'] is List) {
          items = resp['data'] as List<dynamic>;
        } else if (resp['data'] is Map) {
          final m = resp['data'] as Map<String, dynamic>;
          if (m['data'] is List)
            items = m['data'] as List<dynamic>;
          else if (m['users'] is List)
            items = m['users'] as List<dynamic>;
          else if (m['clients'] is List)
            items = m['clients'] as List<dynamic>;
        }
      }

      final results = items.map<Map<String, String>>((e) {
        final map = e as Map<String, dynamic>;
        final id = (map['id'] ?? map['user_id'] ?? map['client_id'] ?? '')
            .toString();
        final name = (map['name'] ?? map['full_name'] ?? '').toString();
        final ci = (map['ci'] ?? map['document'] ?? '').toString();
        final phone = (map['phone'] ?? map['telefono'] ?? '').toString();
        final labelParts = <String>[];
        if (ci.isNotEmpty) labelParts.add(ci);
        if (name.isNotEmpty) labelParts.add(name);
        if (phone.isNotEmpty) labelParts.add(phone);
        final label = labelParts.join(' • ');
        final chosenLabel = label.isNotEmpty
            ? label
            : (name.isNotEmpty ? name : (id.isNotEmpty ? id : query));
        return {'id': id.isNotEmpty ? id : query, 'label': chosenLabel};
      }).toList();

      setState(() {
        _suggestions = results.take(5).toList();
        _selectedSuggestion = -1;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
    }
  }

  // Función pública para que el padre muestre sugerencias en un overlay (si se desea)
  List<Map<String, String>> getSuggestions() => _suggestions;

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    debugPrint(
      '[SearchSelectField] dispose - disposing focus nodes and controller',
    );
    _focusNode.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }
}

class _SearchModal extends ConsumerStatefulWidget {
  final String type;
  const _SearchModal({required this.type, Key? key}) : super(key: key);

  @override
  ConsumerState<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends ConsumerState<_SearchModal> {
  final TextEditingController _q = TextEditingController();
  List<Map<String, String>> _results = [];
  bool _loading = false;

  Future<void> _doSearch(String q) async {
    setState(() {
      _loading = true;
    });
    try {
      // Normalizar query
      // Convertir a mayúsculas para mejor filtrado por backend
      final query = q.trim().toUpperCase();

      if (query.isEmpty) {
        setState(() {
          _results = [];
          _loading = false;
        });
        return;
      }

      // Usar servicios según el tipo solicitado
      if (widget.type == 'cobrador') {
        final svc = UserApiService();
        final resp = await svc.getUsers(
          role: 'cobrador',
          search: query,
          perPage: 50,
        );

        List<dynamic> items = [];
        if (resp['success'] == true) {
          if (resp['data'] is List) {
            items = resp['data'] as List<dynamic>;
          } else if (resp['data'] is Map) {
            final m = resp['data'] as Map<String, dynamic>;
            if (m['data'] is List)
              items = m['data'] as List<dynamic>;
            else if (m['users'] is List)
              items = m['users'] as List<dynamic>;
          }
        }

        setState(() {
          _results = items.map<Map<String, String>>((e) {
            final map = e as Map<String, dynamic>;
            final id = (map['id'] ?? map['user_id'] ?? '').toString();
            final name = (map['name'] ?? map['full_name'] ?? '').toString();
            final ci = (map['ci'] ?? map['document'] ?? '').toString();
            final phone = (map['phone'] ?? map['telefono'] ?? '').toString();
            final labelParts = <String>[];
            if (ci.isNotEmpty) labelParts.add(ci);
            if (name.isNotEmpty) labelParts.add(name);
            if (phone.isNotEmpty) labelParts.add(phone);
            final label = labelParts.join(' • ');
            final chosenLabel = label.isNotEmpty
                ? label
                : (name.isNotEmpty ? name : (id.isNotEmpty ? id : query));
            return {'id': id.isNotEmpty ? id : query, 'label': chosenLabel};
          }).toList();
          _loading = false;
        });
        return;
      } else if (widget.type == 'cliente') {
        // Intentar buscar por clients via UserApiService role 'client'
        final svc = UserApiService();
        final resp = await svc.getUsers(
          role: 'client',
          search: query,
          perPage: 50,
        );

        List<dynamic> items = [];
        if (resp['success'] == true) {
          if (resp['data'] is List) {
            items = resp['data'] as List<dynamic>;
          } else if (resp['data'] is Map) {
            final m = resp['data'] as Map<String, dynamic>;
            if (m['data'] is List)
              items = m['data'] as List<dynamic>;
            else if (m['clients'] is List)
              items = m['clients'] as List<dynamic>;
          }
        }

        setState(() {
          _results = items.map<Map<String, String>>((e) {
            final map = e as Map<String, dynamic>;
            final id = (map['id'] ?? map['client_id'] ?? '').toString();
            final name = (map['name'] ?? map['full_name'] ?? '').toString();
            final ci = (map['ci'] ?? map['document'] ?? '').toString();
            final phone = (map['phone'] ?? map['telefono'] ?? '').toString();
            final labelParts = <String>[];
            if (ci.isNotEmpty) labelParts.add(ci);
            if (name.isNotEmpty) labelParts.add(name);
            if (phone.isNotEmpty) labelParts.add(phone);
            final label = labelParts.join(' • ');
            final chosenLabel = label.isNotEmpty
                ? label
                : (name.isNotEmpty ? name : (id.isNotEmpty ? id : query));
            return {'id': id.isNotEmpty ? id : query, 'label': chosenLabel};
          }).toList();
          _loading = false;
        });
        return;
      } else if (widget.type == 'categoria') {
        // Para categorías reutilizar UserApiService extension
        final svc = UserApiService();
        final resp = await svc.getClientCategories();
        List<dynamic> items = [];
        if (resp['success'] == true) {
          if (resp['data'] is List)
            items = resp['data'] as List<dynamic>;
          else if (resp['categories'] is List)
            items = resp['categories'] as List<dynamic>;
        }

        // Filtrar por query en label
        final filtered = items.where((e) {
          final m = e as Map<String, dynamic>;
          final name = (m['name'] ?? m['label'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();

        setState(() {
          _results = filtered.map<Map<String, String>>((e) {
            final m = e as Map<String, dynamic>;
            final id = (m['id'] ?? m['code'] ?? '').toString();
            final label = (m['name'] ?? m['label'] ?? id).toString();
            return {'id': id, 'label': label};
          }).toList();
          _loading = false;
        });
        return;
      }

      // Fallback: si no se reconoce el tipo, devolver resultado vacío
      setState(() {
        _results = [];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _results = [];
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _q,
                  decoration: InputDecoration(
                    hintText: 'Buscar ${widget.type}...',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _doSearch(_q.text.trim()),
                    ),
                  ),
                  onFieldSubmitted: (v) => _doSearch(v.trim()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading) const LinearProgressIndicator(),
          if (!_loading && _results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Text(
                'No se encontraron resultados. Escribe y presiona buscar.',
              ),
            ),
          if (_results.isNotEmpty)
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemBuilder: (ctx, i) {
                  final r = _results[i];
                  return ListTile(
                    title: Text(r['label'] ?? r['id'] ?? ''),
                    subtitle: Text('ID: ${r['id'] ?? ''}'),
                    onTap: () => Navigator.of(context).pop(r),
                  );
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: _results.length,
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

Widget _buildTableFromJson(
  List<Map<String, dynamic>> rows, {
  List<String>? columnOrder,
}) {
  // Determinar conjunto de columnas (union de claves) y respetar orden preferido
  final keys = <String>{};
  for (final r in rows) {
    keys.addAll(r.keys.map((k) => k.toString()));
  }

  List<String> columns;
  if (columnOrder != null && columnOrder.isNotEmpty) {
    // Mantener sólo las columnas que existen en los datos, en el orden pedido
    columns = columnOrder.where((c) => keys.contains(c)).toList();
    // Añadir columnas extra (no solicitadas) al final, ordenadas alfabeticamente
    final extras = keys.difference(columns.toSet()).toList()..sort();
    columns.addAll(extras);
  } else {
    columns = keys.toList()..sort();
  }

  // Definir anchos de columna (por índice) con heurística simple
  final columnWidths = <int, TableColumnWidth>{};
  for (int i = 0; i < columns.length; i++) {
    final name = columns[i].toLowerCase();
    if (name == 'id') {
      columnWidths[i] = const FixedColumnWidth(70);
    } else if (name.contains('fecha') || name.contains('date')) {
      columnWidths[i] = const FixedColumnWidth(130);
    } else if (name.contains('monto') || name.contains('amount')) {
      columnWidths[i] = const FixedColumnWidth(120);
    } else {
      columnWidths[i] = const IntrinsicColumnWidth();
    }
  }

  return Table(
    columnWidths: columnWidths,
    border: TableBorder.all(color: Colors.grey.shade300),
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      // Fila de encabezado
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: columns
            .map(
              (c) => TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    c,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
            .toList(),
      ),
      // Filas de datos
      ...rows
          .map(
            (r) => TableRow(
              children: columns
                  .map(
                    (c) => TableCell(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          r[c]?.toString() ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    ],
  );
}

Widget _buildTableFromMap(Map<String, dynamic> map) {
  final entries = map.entries.toList();

  return Table(
    columnWidths: const {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
    border: TableBorder.all(color: Colors.grey.shade300),
    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade100),
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Campo',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Valor',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      ...entries
          .map(
            (e) => TableRow(
              children: [
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      e.key,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      e.value?.toString() ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          )
          .toList(),
    ],
  );
}

String _formatDate(dynamic val) {
  if (val == null) return '';
  try {
    final dt = DateTime.tryParse(val.toString());
    if (dt == null) return val.toString();
    // Formato dd/MM/yyyy
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  } catch (e) {
    return val.toString();
  }
}

String _formatCurrency(dynamic val) {
  if (val == null) return '';
  try {
    final d = double.tryParse(val.toString()) ?? 0.0;
    return '\$${d.toStringAsFixed(2)}';
  } catch (e) {
    return val.toString();
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular un ancho responsivo para que quepan 2 cards por fila en móviles.
    // Suponemos ~16 px de padding a los lados y 8 px de separación entre cards
    // (coincide con los Wrap(spacing: 8) usados en esta pantalla).
    final screenW = MediaQuery.of(context).size.width;
    const sidePaddingGuess = 32.0; // 16 a cada lado
    const spacingBetween = 8.0; // Wrap spacing
    final twoColWidth = (screenW - sidePaddingGuess - spacingBetween) / 2;
    final cardWidth = twoColWidth.clamp(140.0, 220.0);

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                foregroundColor: color,
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                          (Theme.of(context).textTheme.labelLarge ??
                                  const TextStyle())
                              .copyWith(color: Colors.grey[700], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style:
                          (Theme.of(context).textTheme.titleLarge ??
                                  const TextStyle(fontSize: 18))
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================
// Vista de Créditos: helpers y cards (movidas arriba para evitar referencias hacia adelante)
// ==========================
Color _colorForCreditStatus(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'pending_approval':
      return Colors.amber;
    case 'waiting_delivery':
      return Colors.deepOrange;
    case 'active':
      return Colors.blue;
    case 'completed':
      return Colors.green;
    default:
      return Colors.blueGrey;
  }
}

Color _colorForFrequency(String? freq) {
  switch ((freq ?? '').toLowerCase()) {
    case 'daily':
      return Colors.purple;
    case 'weekly':
      return Colors.teal;
    case 'monthly':
      return Colors.indigo;
    default:
      return Colors.grey;
  }
}

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  return double.tryParse(val.toString()) ?? 0.0;
}

String _extractCreditClientName(Map<String, dynamic> cr) {
  try {
    if (cr['client'] is Map && cr['client']['name'] != null) {
      return cr['client']['name'].toString();
    }
    if (cr['client_name'] != null) return cr['client_name'].toString();
  } catch (_) {}
  return 'Cliente';
}

String _extractCreditCobradorName(Map<String, dynamic> cr) {
  try {
    if (cr['cobrador'] is Map && cr['cobrador']['name'] != null) {
      return cr['cobrador']['name'].toString();
    }
    if (cr['cobrador_name'] != null) return cr['cobrador_name'].toString();
  } catch (_) {}
  return '';
}

Widget _buildCreditsList(
  List<Map<String, dynamic>> credits,
  BuildContext context,
) {
  double _sumTotalAmount() {
    double total = 0.0;
    for (final cr in credits) {
      total += _toDouble(cr['total_amount']);
    }
    return total;
  }

  final total = _sumTotalAmount();
  final totalStr = _formatCurrency(total);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.assignment, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            'Créditos',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('${credits.length}'),
            backgroundColor: Colors.indigo.withOpacity(0.08),
            side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
          ),
          const Spacer(),
          Text(
            totalStr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: credits.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final cr = credits[i];
          final clientName = _extractCreditClientName(cr);
          final cobradorName = _extractCreditCobradorName(cr);
          final status = cr['status']?.toString();
          final freq = cr['frequency']?.toString();
          final totalAmount = _toDouble(cr['total_amount']);
          final balance = _toDouble(cr['balance']);
          final paid = (totalAmount - balance).clamp(0, totalAmount);
          final pct = totalAmount > 0 ? (paid / totalAmount) : 0.0;
          final statusColor = _colorForCreditStatus(status);
          final freqColor = _colorForFrequency(freq);

          return Card(
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.12),
                foregroundColor: statusColor,
                child: const Icon(Icons.account_balance_wallet),
              ),
              title: Text(
                clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text((status ?? '').toUpperCase()),
                          backgroundColor: statusColor.withOpacity(0.08),
                          side: BorderSide(color: statusColor.withOpacity(0.2)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                        if (freq != null && freq.isNotEmpty)
                          Chip(
                            label: Text((freq).toUpperCase()),
                            backgroundColor: freqColor.withOpacity(0.08),
                            side: BorderSide(color: freqColor.withOpacity(0.2)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (cr['created_at'] != null)
                          Chip(
                            avatar: const Icon(Icons.event, size: 16),
                            label: Text(_formatDate(cr['created_at'])),
                            backgroundColor: Colors.grey.withOpacity(0.08),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (cr['end_date'] != null)
                          Chip(
                            avatar: const Icon(Icons.flag, size: 16),
                            label: Text(_formatDate(cr['end_date'])),
                            backgroundColor: Colors.grey.withOpacity(0.08),
                            side: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(balance),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Saldo',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Total: ${_formatCurrency(totalAmount)}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  if (cobradorName.isNotEmpty)
                    SizedBox(
                      width: 140,
                      child: Text(
                        cobradorName,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

// ==========================
// Vista de Balances: helpers y cards
// ==========================
Color _diffColor(double diff) {
  final ad = diff.abs();
  if (ad < 0.01) return Colors.blueGrey; // casi cero
  return diff >= 0 ? Colors.green : Colors.red;
}

double _numVal(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

String _extractBalanceCobradorName(Map<String, dynamic> b) {
  try {
    if (b['cobrador'] is Map && (b['cobrador'] as Map)['name'] != null) {
      return (b['cobrador'] as Map)['name'].toString();
    }
    if (b['user'] is Map && (b['user'] as Map)['name'] != null) {
      return (b['user'] as Map)['name'].toString();
    }
    if (b['cobrador_name'] != null) return b['cobrador_name'].toString();
    if (b['user_name'] != null) return b['user_name'].toString();
  } catch (_) {}
  return '';
}

String _extractBalanceDate(Map<String, dynamic> b) {
  final candidates = ['date', 'balance_date', 'created_at', 'updated_at'];
  for (final k in candidates) {
    if (b[k] != null) return _formatDate(b[k]);
  }
  return '';
}

// Obtiene un valor numérico usando múltiples posibles nombres de campo
double _pickAmount(Map<String, dynamic> b, List<String> keys) {
  for (final k in keys) {
    if (b.containsKey(k) && b[k] != null) return _numVal(b[k]);
  }
  return 0.0;
}

// Intenta obtener diferencia; si no existe, la estima: final - (initial + collected - lent)
double _computeBalanceDiff(Map<String, dynamic> b) {
  if (b['difference'] != null) return _numVal(b['difference']);
  if (b['diff'] != null) return _numVal(b['diff']);
  final initial = _pickAmount(b, [
    'initial',
    'initial_amount',
    'start',
    'opening',
    'initial_cash',
  ]);
  final collected = _pickAmount(b, [
    'collected',
    'collected_amount',
    'income',
    'in',
  ]);
  final lent = _pickAmount(b, ['lent', 'lent_amount', 'loaned', 'out']);
  final finalVal = _pickAmount(b, ['final', 'final_amount', 'closing', 'end']);
  return finalVal - (initial + collected - lent);
}

Widget _buildBalancesList(
  List<Map<String, dynamic>> balances,
  BuildContext context,
) {
  double _sumFinal() {
    double total = 0.0;
    for (final b in balances) {
      total += _pickAmount(b, ['final', 'final_amount', 'closing', 'end']);
    }
    return total;
  }

  final totalFinal = _sumFinal();
  final totalFinalStr = _formatCurrency(totalFinal);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.account_balance, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            'Balances de caja',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('${balances.length}'),
            backgroundColor: Colors.indigo.withOpacity(0.08),
            side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
          ),
          const Spacer(),
          Text(
            totalFinalStr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: balances.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final b = balances[i];
          final cobrador = _extractBalanceCobradorName(b);
          final dateStr = _extractBalanceDate(b);
          final initial = _pickAmount(b, [
            'initial',
            'initial_amount',
            'opening',
          ]);
          final collected = _pickAmount(b, [
            'collected',
            'collected_amount',
            'income',
          ]);
          final lent = _pickAmount(b, ['lent', 'lent_amount', 'loaned']);
          final finalVal = _pickAmount(b, ['final', 'final_amount', 'closing']);
          final diff = _computeBalanceDiff(b);
          final diffClr = _diffColor(diff);

          return Card(
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: diffClr.withOpacity(0.12),
                foregroundColor: diffClr,
                child: const Icon(Icons.calculate),
              ),
              title: Text(
                dateStr.isNotEmpty ? dateStr : 'Balance',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.start, size: 16),
                      label: Text(_formatCurrency(initial)),
                      backgroundColor: Colors.blueGrey.withOpacity(0.08),
                      side: BorderSide(color: Colors.blueGrey.withOpacity(0.2)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      avatar: const Icon(Icons.call_received, size: 16),
                      label: Text('Recaudado ${_formatCurrency(collected)}'),
                      backgroundColor: Colors.green.withOpacity(0.08),
                      side: BorderSide(color: Colors.green.withOpacity(0.2)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      avatar: const Icon(Icons.call_made, size: 16),
                      label: Text('Prestado ${_formatCurrency(lent)}'),
                      backgroundColor: Colors.orange.withOpacity(0.08),
                      side: BorderSide(color: Colors.orange.withOpacity(0.2)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (cobrador.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: Text(cobrador),
                        backgroundColor: Colors.grey.withOpacity(0.08),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(finalVal),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Final',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 140,
                    child: Text(
                      'Dif: ${_formatCurrency(diff)}',
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: diffClr),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
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

    final asyncVal = ref.watch(generateReportProvider(req));

    return asyncVal.when(
      data: (value) {
        if (req.format == 'json') {
          // Intentar mostrar JSON como tabla si es una lista de objetos o tiene 'data' con lista
          final dynamic payload = value is Map && value.containsKey('data')
              ? value['data']
              : value;

          if (payload is Map && payload.containsKey('payments')) {
            final payments = payload['payments'];
            if (payments is List &&
                payments.isNotEmpty &&
                payments.first is Map) {
              // Aplanar y formatear cada payment a un Map con columnas legibles
              final List<Map<String, dynamic>> rows = payments
                  .map<Map<String, dynamic>>((p) {
                    final Map<String, dynamic> pm = Map<String, dynamic>.from(
                      p as Map,
                    );
                    final cobrador = pm['cobrador'] is Map
                        ? pm['cobrador']['name']
                        : pm['cobrador']?.toString();

                    // Extraer nombre del cliente desde varios posibles lugares
                    String? clientName;
                    if (pm['client'] is Map && pm['client']['name'] != null) {
                      clientName = pm['client']['name'].toString();
                    } else if (pm['credit'] is Map) {
                      final credit = pm['credit'] as Map;
                      if (credit['client'] is Map &&
                          credit['client']['name'] != null) {
                        clientName = credit['client']['name'].toString();
                      } else if (credit['client_name'] != null) {
                        clientName = credit['client_name'].toString();
                      }
                    } else if (pm['client_name'] != null) {
                      clientName = pm['client_name'].toString();
                    }

                    final cuota = pm['installment_number']?.toString() ?? '';

                    return {
                      'ID': pm['id']?.toString() ?? '',
                      'Fecha': _formatDate(pm['payment_date']),
                      'Cobrador': cobrador?.toString() ?? '',
                      'Cliente': clientName ?? '',
                      'Monto': _formatCurrency(pm['amount']),
                      'Cuota': cuota,
                      'Tipo': pm['payment_method']?.toString() ?? '',
                      'Notas': pm['status']?.toString() ?? '',
                    };
                  })
                  .toList();

              final columnsOrder = [
                'ID',
                'Fecha',
                'Cuota',
                'Cobrador',
                'Cliente',
                'Monto',
                'Tipo',
                'Notas',
              ];

              final Map<String, dynamic> summary = (payload['summary'] is Map)
                  ? Map<String, dynamic>.from(payload['summary'] as Map)
                  : <String, dynamic>{};

              // Detectar si el rango corresponde a HOY (para vista especial)
              final String _todayStr = DateTime.now()
                  .toIso8601String()
                  .split('T')
                  .first;
              final String? _fStart = req.filters?['start_date']?.toString();
              final String? _fEnd = req.filters?['end_date']?.toString();
              final bool isTodayRange =
                  (_fStart == _todayStr && _fEnd == _todayStr) ||
                  ((summary['date_range'] is Map) &&
                      (summary['date_range']['start']?.toString() ==
                          _todayStr) &&
                      (summary['date_range']['end']?.toString() == _todayStr));
              final List<Map<String, dynamic>> typedPayments =
                  (payments is List)
                  ? (payments as List)
                        .whereType<Map>()
                        .map<Map<String, dynamic>>(
                          (e) => Map<String, dynamic>.from(e as Map),
                        )
                        .toList()
                  : <Map<String, dynamic>>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Acciones rápidas de descarga
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final bytes = await ref
                                        .read(rp.reportsApiProvider)
                                        .generateReport(
                                          req.type,
                                          filters: req.filters,
                                          format: 'excel',
                                        );
                                    if (bytes is List<int>) {
                                      final dir =
                                          await getApplicationDocumentsDirectory();
                                      final ts = DateTime.now()
                                          .toIso8601String()
                                          .replaceAll(':', '-');
                                      final fileName =
                                          'reporte_${req.type}_$ts.xlsx';
                                      final file = File(
                                        '${dir.path}/$fileName',
                                      );
                                      await file.writeAsBytes(bytes);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reporte guardado: $fileName',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Abrir',
                                            onPressed: () {
                                              OpenFilex.open(file.path);
                                            },
                                          ),
                                        ),
                                      );
                                      try {
                                        await OpenFilex.open(file.path);
                                      } catch (_) {}
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al descargar Excel: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.grid_on),
                                label: const Text('Excel'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    final bytes = await ref
                                        .read(rp.reportsApiProvider)
                                        .generateReport(
                                          req.type,
                                          filters: req.filters,
                                          format: 'pdf',
                                        );
                                    if (bytes is List<int>) {
                                      final dir =
                                          await getApplicationDocumentsDirectory();
                                      final ts = DateTime.now()
                                          .toIso8601String()
                                          .replaceAll(':', '-');
                                      final fileName =
                                          'reporte_${req.type}_$ts.pdf';
                                      final file = File(
                                        '${dir.path}/$fileName',
                                      );
                                      await file.writeAsBytes(bytes);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Reporte guardado: $fileName',
                                          ),
                                          action: SnackBarAction(
                                            label: 'Abrir',
                                            onPressed: () {
                                              OpenFilex.open(file.path);
                                            },
                                          ),
                                        ),
                                      );
                                      try {
                                        await OpenFilex.open(file.path);
                                      } catch (_) {}
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Error al descargar PDF: $e',
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.picture_as_pdf),
                                label: const Text('PDF'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child:
                                (payload['generated_by'] != null ||
                                    payload['generated_at'] != null)
                                ? Text(
                                    'Generado' +
                                        (payload['generated_by'] != null
                                            ? ' por ${payload['generated_by']}'
                                            : '') +
                                        (payload['generated_at'] != null
                                            ? ' • ${_formatDate(payload['generated_at'])}'
                                            : ''),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Pagos',
                            value: '${summary['total_payments'] ?? 0}',
                            icon: Icons.receipt_long,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Monto total',
                            value: _formatCurrency(
                              summary['total_amount'] ?? 0,
                            ),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Promedio',
                            value: _formatCurrency(
                              summary['average_payment'] ?? 0,
                            ),
                            icon: Icons.calculate,
                            color: Colors.orange,
                          ),
                          if (summary['date_range'] is Map)
                            _MiniStatCard(
                              title: 'Rango',
                              value:
                                  '${summary['date_range']['start'] ?? ''} → ${summary['date_range']['end'] ?? ''}',
                              icon: Icons.date_range,
                              color: Colors.blueGrey,
                            ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (isTodayRange && typedPayments.isNotEmpty) ...[
                      _todayPaymentsList(typedPayments, context),
                      const SizedBox(height: 12),
                    ],
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(
                        rows,
                        columnOrder: columnsOrder,
                      ),
                    ),
                  ],
                ),
              );
            }
          } else if (payload is Map && payload.containsKey('credits')) {
            final credits = payload['credits'];
            if (credits is List && credits.isNotEmpty && credits.first is Map) {
              // Aplanar y formatear cada crédito a un Map con columnas legibles
              final List<Map<String, dynamic>> rows = credits
                  .map<Map<String, dynamic>>((c) {
                    final Map<String, dynamic> cr = Map<String, dynamic>.from(
                      c as Map,
                    );

                    String clientName = '';
                    try {
                      if (cr['client'] is Map && cr['client']['name'] != null) {
                        clientName = cr['client']['name'].toString();
                      } else if (cr['client_name'] != null) {
                        clientName = cr['client_name'].toString();
                      }
                    } catch (_) {}

                    String cobradorName = '';
                    try {
                      if (cr['cobrador'] is Map &&
                          cr['cobrador']['name'] != null) {
                        cobradorName = cr['cobrador']['name'].toString();
                      } else if (cr['cobrador_name'] != null) {
                        cobradorName = cr['cobrador_name'].toString();
                      }
                    } catch (_) {}

                    return {
                      'ID': cr['id']?.toString() ?? '',
                      'Cliente': clientName,
                      'Cobrador': cobradorName,
                      'Estado': cr['status']?.toString() ?? '',
                      'Frecuencia': cr['frequency']?.toString() ?? '',
                      'Monto': _formatCurrency(cr['amount']),
                      'Total': _formatCurrency(cr['total_amount']),
                      'Saldo': _formatCurrency(cr['balance']),
                      'Creación': _formatDate(cr['created_at']),
                      'Vencimiento': _formatDate(cr['end_date']),
                    };
                  })
                  .toList();

              final columnsOrder = [
                'ID',
                'Cliente',
                'Cobrador',
                'Estado',
                'Frecuencia',
                'Monto',
                'Total',
                'Saldo',
                'Creación',
                'Vencimiento',
              ];

              final Map<String, dynamic> summary = (payload['summary'] is Map)
                  ? Map<String, dynamic>.from(payload['summary'] as Map)
                  : <String, dynamic>{};

              final List<Map<String, dynamic>> typedCredits = (credits is List)
                  ? (credits as List)
                        .whereType<Map>()
                        .map<Map<String, dynamic>>(
                          (e) => Map<String, dynamic>.from(e as Map),
                        )
                        .toList()
                  : <Map<String, dynamic>>[];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Acciones rápidas de descarga
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'excel',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName = 'reporte_${req.type}_$ts.xlsx';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reporte guardado: $fileName',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Abrir',
                                      onPressed: () {
                                        OpenFilex.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar Excel: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.grid_on),
                          label: const Text('Excel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'pdf',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName = 'reporte_${req.type}_$ts.pdf';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reporte guardado: $fileName',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Abrir',
                                      onPressed: () {
                                        OpenFilex.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar PDF: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child:
                                (payload['generated_by'] != null ||
                                    payload['generated_at'] != null)
                                ? Text(
                                    'Generado' +
                                        (payload['generated_by'] != null
                                            ? ' por ${payload['generated_by']}'
                                            : '') +
                                        (payload['generated_at'] != null
                                            ? ' • ${_formatDate(payload['generated_at'])}'
                                            : ''),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Créditos',
                            value: '${summary['total_credits'] ?? 0}',
                            icon: Icons.assignment,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Monto total',
                            value: _formatCurrency(
                              summary['total_amount'] ?? 0,
                            ),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Activos',
                            value: '${summary['active_credits'] ?? 0}',
                            icon: Icons.play_circle_fill,
                            color: Colors.blue,
                          ),
                          _MiniStatCard(
                            title: 'Completados',
                            value: '${summary['completed_credits'] ?? 0}',
                            icon: Icons.check_circle,
                            color: Colors.teal,
                          ),
                          _MiniStatCard(
                            title: 'Saldo total',
                            value: _formatCurrency(
                              summary['total_balance'] ?? 0,
                            ),
                            icon: Icons.account_balance_wallet,
                            color: Colors.orange,
                          ),
                          _MiniStatCard(
                            title: 'Pendiente',
                            value: _formatCurrency(
                              summary['pending_amount'] ?? 0,
                            ),
                            icon: Icons.warning,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (typedCredits.isNotEmpty) ...[
                      _buildCreditsList(typedCredits, context),
                      const SizedBox(height: 12),
                    ],
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(
                        rows,
                        columnOrder: columnsOrder,
                      ),
                    ),
                  ],
                ),
              );
            }
          } else if (payload is Map && payload.containsKey('balances')) {
            final balances = payload['balances'];
            if (balances is List &&
                balances.isNotEmpty &&
                balances.first is Map) {
              final List<Map<String, dynamic>> typedBalances =
                  (balances as List)
                      .whereType<Map>()
                      .map<Map<String, dynamic>>(
                        (e) => Map<String, dynamic>.from(e as Map),
                      )
                      .toList();

              // Construir filas legibles para la tabla
              final List<Map<String, dynamic>> rows = typedBalances.map((b) {
                final cobrador = _extractBalanceCobradorName(b);
                final fecha = _extractBalanceDate(b);
                final inicial = _pickAmount(b, [
                  'initial',
                  'initial_amount',
                  'opening',
                ]);
                final recaudado = _pickAmount(b, [
                  'collected',
                  'collected_amount',
                  'income',
                ]);
                final prestado = _pickAmount(b, [
                  'lent',
                  'lent_amount',
                  'loaned',
                ]);
                final finalVal = _pickAmount(b, [
                  'final',
                  'final_amount',
                  'closing',
                ]);
                final diferencia = _computeBalanceDiff(b);
                final notas = (b['notes'] ?? b['description'] ?? '').toString();

                return {
                  'Fecha': fecha,
                  'Cobrador': cobrador,
                  'Inicial': _formatCurrency(inicial),
                  'Recaudado': _formatCurrency(recaudado),
                  'Prestado': _formatCurrency(prestado),
                  'Final': _formatCurrency(finalVal),
                  'Diferencia': _formatCurrency(diferencia),
                  'Notas': notas,
                };
              }).toList();

              final columnsOrder = [
                'Fecha',
                'Cobrador',
                'Inicial',
                'Recaudado',
                'Prestado',
                'Final',
                'Diferencia',
                'Notas',
              ];

              final Map<String, dynamic> summary = (payload['summary'] is Map)
                  ? Map<String, dynamic>.from(payload['summary'] as Map)
                  : <String, dynamic>{};

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Acciones rápidas de descarga
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'excel',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName = 'reporte_${req.type}_$ts.xlsx';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reporte guardado: $fileName',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Abrir',
                                      onPressed: () {
                                        OpenFilex.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar Excel: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.grid_on),
                          label: const Text('Excel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'pdf',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName = 'reporte_${req.type}_$ts.pdf';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reporte guardado: $fileName',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Abrir',
                                      onPressed: () {
                                        OpenFilex.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar PDF: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child:
                                (payload['generated_by'] != null ||
                                    payload['generated_at'] != null)
                                ? Text(
                                    'Generado' +
                                        (payload['generated_by'] != null
                                            ? ' por ${payload['generated_by']}'
                                            : '') +
                                        (payload['generated_at'] != null
                                            ? ' • ${_formatDate(payload['generated_at'])}'
                                            : ''),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Registros',
                            value: '${summary['total_records'] ?? 0}',
                            icon: Icons.list_alt,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Inicial',
                            value: _formatCurrency(
                              summary['total_initial'] ?? 0,
                            ),
                            icon: Icons.start,
                            color: Colors.blueGrey,
                          ),
                          _MiniStatCard(
                            title: 'Recaudado',
                            value: _formatCurrency(
                              summary['total_collected'] ?? 0,
                            ),
                            icon: Icons.call_received,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Prestado',
                            value: _formatCurrency(summary['total_lent'] ?? 0),
                            icon: Icons.call_made,
                            color: Colors.orange,
                          ),
                          _MiniStatCard(
                            title: 'Final',
                            value: _formatCurrency(summary['total_final'] ?? 0),
                            icon: Icons.summarize,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Dif. promedio',
                            value: _formatCurrency(
                              summary['average_difference'] ?? 0,
                            ),
                            icon: Icons.calculate,
                            color: Colors.deepPurple,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    if (typedBalances.isNotEmpty) ...[
                      _buildBalancesList(typedBalances, context),
                      const SizedBox(height: 12),
                    ] else ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: const [
                              Icon(Icons.inbox, color: Colors.grey),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'No hay balances para los filtros seleccionados.',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(
                        rows,
                        columnOrder: columnsOrder,
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // No hay balances, pero mostrar resumen y acciones si existen
              final Map<String, dynamic> summary = (payload['summary'] is Map)
                  ? Map<String, dynamic>.from(payload['summary'] as Map)
                  : <String, dynamic>{};
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'excel',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final file = File(
                                  '${dir.path}/reporte_${req.type}_$ts.xlsx',
                                );
                                await file.writeAsBytes(bytes);
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Excel descargado'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar Excel: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.grid_on),
                          label: const Text('Excel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'pdf',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final file = File(
                                  '${dir.path}/reporte_${req.type}_$ts.pdf',
                                );
                                await file.writeAsBytes(bytes);
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('PDF descargado'),
                                  ),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar PDF: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child:
                                (payload['generated_by'] != null ||
                                    payload['generated_at'] != null)
                                ? Text(
                                    'Generado' +
                                        (payload['generated_by'] != null
                                            ? ' por ${payload['generated_by']}'
                                            : '') +
                                        (payload['generated_at'] != null
                                            ? ' • ${_formatDate(payload['generated_at'])}'
                                            : ''),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Registros',
                            value: '${summary['total_records'] ?? 0}',
                            icon: Icons.list_alt,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Inicial',
                            value: _formatCurrency(
                              summary['total_initial'] ?? 0,
                            ),
                            icon: Icons.start,
                            color: Colors.blueGrey,
                          ),
                          _MiniStatCard(
                            title: 'Recaudado',
                            value: _formatCurrency(
                              summary['total_collected'] ?? 0,
                            ),
                            icon: Icons.call_received,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Prestado',
                            value: _formatCurrency(summary['total_lent'] ?? 0),
                            icon: Icons.call_made,
                            color: Colors.orange,
                          ),
                          _MiniStatCard(
                            title: 'Final',
                            value: _formatCurrency(summary['total_final'] ?? 0),
                            icon: Icons.summarize,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Dif. promedio',
                            value: _formatCurrency(
                              summary['average_difference'] ?? 0,
                            ),
                            icon: Icons.calculate,
                            color: Colors.deepPurple,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: const [
                            Icon(Icons.inbox, color: Colors.grey),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No hay balances para los filtros seleccionados.',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          } else if (payload is Map && payload.containsKey('credits')) {
            // Detectar si es reporte de MORA (overdue) verificando campos específicos
            final credits = payload['credits'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            // Es reporte de mora si el summary tiene campos específicos de overdue
            final bool isOverdueReport =
                summary.containsKey('total_overdue_credits') ||
                summary.containsKey('average_days_overdue') ||
                summary.containsKey('by_severity');

            if (isOverdueReport &&
                credits is List &&
                credits.isNotEmpty &&
                credits.first is Map) {
              // REPORTE DE MORA (OVERDUE)
              final List<Map<String, dynamic>>
              rows = credits.map<Map<String, dynamic>>((c) {
                final Map<String, dynamic> cr = Map<String, dynamic>.from(
                  c as Map,
                );

                String clientName = '';
                String clientCategory = '';
                try {
                  if (cr['client'] is Map) {
                    clientName = cr['client']['name']?.toString() ?? '';
                    clientCategory =
                        cr['client']['client_category']?.toString() ?? '';
                  }
                } catch (_) {}

                String cobradorName = '';
                try {
                  if (cr['deliveredBy'] is Map) {
                    cobradorName = cr['deliveredBy']['name']?.toString() ?? '';
                  } else if (cr['cobrador'] is Map) {
                    cobradorName = cr['cobrador']['name']?.toString() ?? '';
                  }
                } catch (_) {}

                final daysOverdue = cr['days_overdue']?.toString() ?? '0';
                final overdueAmount = _formatCurrency(cr['overdue_amount']);
                final balance = _formatCurrency(cr['balance']);
                final completionRate = cr['completion_rate']?.toString() ?? '0';

                // Determinar gravedad
                String severity = 'Ligera';
                Color severityColor = Colors.orange;
                final days = int.tryParse(daysOverdue) ?? 0;
                if (days > 30) {
                  severity = 'Severa';
                  severityColor = Colors.red;
                } else if (days > 7) {
                  severity = 'Moderada';
                  severityColor = Colors.deepOrange;
                }

                return {
                  'ID': cr['id']?.toString() ?? '',
                  'Cliente': clientName,
                  'Categoría': clientCategory,
                  'Cobrador': cobradorName,
                  'Días Mora': daysOverdue,
                  'Gravedad': severity,
                  'Monto Vencido': overdueAmount,
                  'Balance Total': balance,
                  'Avance': '$completionRate%',
                  '_days_raw': days,
                  '_severity_color': severityColor,
                };
              }).toList();

              final columnsOrder = [
                'ID',
                'Cliente',
                'Categoría',
                'Cobrador',
                'Días Mora',
                'Gravedad',
                'Monto Vencido',
                'Balance Total',
                'Avance',
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Acciones rápidas de descarga
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'excel',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName = 'reporte_${req.type}_$ts.xlsx';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reporte guardado: $fileName',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Abrir',
                                      onPressed: () {
                                        OpenFilex.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar Excel: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.grid_on),
                          label: const Text('Excel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bytes = await ref
                                  .read(rp.reportsApiProvider)
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'pdf',
                                  );
                              if (bytes is List<int>) {
                                final dir =
                                    await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName = 'reporte_${req.type}_$ts.pdf';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Reporte guardado: $fileName',
                                    ),
                                    action: SnackBarAction(
                                      label: 'Abrir',
                                      onPressed: () {
                                        OpenFilex.open(file.path);
                                      },
                                    ),
                                  ),
                                );
                                try {
                                  await OpenFilex.open(file.path);
                                } catch (_) {}
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al descargar PDF: $e'),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child:
                                (payload['generated_by'] != null ||
                                    payload['generated_at'] != null)
                                ? Text(
                                    'Generado' +
                                        (payload['generated_by'] != null
                                            ? ' por ${payload['generated_by']}'
                                            : '') +
                                        (payload['generated_at'] != null
                                            ? ' • ${_formatDate(payload['generated_at'])}'
                                            : ''),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cards de métricas principales
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Créditos en Mora',
                            value: '${summary['total_overdue_credits'] ?? 0}',
                            icon: Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                          _MiniStatCard(
                            title: 'Monto Vencido',
                            value: _formatCurrency(
                              summary['total_overdue_amount'] ?? 0,
                            ),
                            icon: Icons.attach_money,
                            color: Colors.deepOrange,
                          ),
                          _MiniStatCard(
                            title: 'Balance Total',
                            value: _formatCurrency(
                              summary['total_balance_overdue'] ?? 0,
                            ),
                            icon: Icons.account_balance_wallet,
                            color: Colors.orange,
                          ),
                          _MiniStatCard(
                            title: 'Días Promedio',
                            value:
                                '${(summary['average_days_overdue'] ?? 0).toStringAsFixed(1)} días',
                            icon: Icons.calendar_today,
                            color: Colors.blueGrey,
                          ),
                          _MiniStatCard(
                            title: 'Rango Días',
                            value:
                                '${summary['min_days_overdue'] ?? 0} - ${summary['max_days_overdue'] ?? 0}',
                            icon: Icons.straighten,
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Distribución por gravedad
                    if (summary['by_severity'] is Map) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.pie_chart, color: Colors.indigo),
                                  SizedBox(width: 8),
                                  Text(
                                    'Distribución por Gravedad',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildSeverityDistribution(
                                summary['by_severity'] as Map,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Top 10 deudores
                    if (summary['top_debtors'] is List &&
                        (summary['top_debtors'] as List).isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.emoji_events, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    'Top 10 Deudores',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTopDebtorsList(
                                summary['top_debtors'] as List,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Análisis por cobrador
                    if (summary['by_cobrador'] is Map &&
                        (summary['by_cobrador'] as Map).isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.person, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Análisis por Cobrador',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildCobradorAnalysis(
                                summary['by_cobrador'] as Map,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Análisis por categoría
                    if (summary['by_client_category'] is Map &&
                        (summary['by_client_category'] as Map).isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.category, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Text(
                                    'Análisis por Categoría de Cliente',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildCategoryAnalysis(
                                summary['by_client_category'] as Map,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Tabla de créditos en mora
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(
                        rows,
                        columnOrder: columnsOrder,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ========== REPORTE DE RENDIMIENTO (PERFORMANCE) ==========
          } else if (payload is Map && payload.containsKey('performance')) {
            final performance = payload['performance'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            if (performance is List &&
                performance.isNotEmpty &&
                performance.first is Map) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones de descarga
                    _buildDownloadButtons(context, ref, req, payload),
                    const SizedBox(height: 12),

                    // Métricas resumen
                    if (summary.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Cobradores',
                            value: '${summary['total_cobradores'] ?? 0}',
                            icon: Icons.people,
                            color: Colors.indigo,
                          ),
                          if (summary['totals'] is Map) ...[
                            _MiniStatCard(
                              title: 'Créditos Entregados',
                              value:
                                  '${summary['totals']['credits_delivered'] ?? 0}',
                              icon: Icons.assignment_turned_in,
                              color: Colors.blue,
                            ),
                            _MiniStatCard(
                              title: 'Monto Prestado',
                              value: _formatCurrency(
                                summary['totals']['amount_lent'] ?? 0,
                              ),
                              icon: Icons.trending_up,
                              color: Colors.green,
                            ),
                            _MiniStatCard(
                              title: 'Monto Cobrado',
                              value: _formatCurrency(
                                summary['totals']['amount_collected'] ?? 0,
                              ),
                              icon: Icons.payments,
                              color: Colors.teal,
                            ),
                          ],
                          if (summary['averages'] is Map) ...[
                            _MiniStatCard(
                              title: 'Tasa Cobranza Prom.',
                              value:
                                  '${summary['averages']['collection_rate']?.toStringAsFixed(1) ?? 0}%',
                              icon: Icons.percent,
                              color: Colors.orange,
                            ),
                            _MiniStatCard(
                              title: 'Calidad Cartera Prom.',
                              value:
                                  '${summary['averages']['portfolio_quality']?.toStringAsFixed(1) ?? 0}%',
                              icon: Icons.star,
                              color: Colors.amber,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Top Performers
                    if (summary['top_performers'] is List &&
                        (summary['top_performers'] as List).isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.emoji_events, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mejores Cobradores',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTopPerformersList(
                                summary['top_performers'] as List,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Lista de performance por cobrador
                    _buildPerformanceList(performance as List, context),
                  ],
                ),
              );
            }

            // ========== REPORTE DE ACTIVIDAD DIARIA (DAILY ACTIVITY) ==========
          } else if (payload is Map && payload.containsKey('activities')) {
            final activities = payload['activities'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            if (activities is List &&
                activities.isNotEmpty &&
                activities.first is Map) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones de descarga
                    _buildDownloadButtons(context, ref, req, payload),
                    const SizedBox(height: 12),

                    // Resumen del día
                    if (summary.isNotEmpty) ...[
                      Card(
                        color: Colors.indigo.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.today,
                                    color: Colors.indigo,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Actividad del ${summary['date'] ?? ''} (${summary['day_name'] ?? ''})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (summary['totals'] is Map)
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MiniStatCard(
                                      title: 'Créditos Entregados',
                                      value:
                                          '${summary['totals']['credits_delivered'] ?? 0}',
                                      icon: Icons.local_shipping,
                                      color: Colors.blue,
                                    ),
                                    _MiniStatCard(
                                      title: 'Monto Prestado',
                                      value: _formatCurrency(
                                        summary['totals']['amount_lent'] ?? 0,
                                      ),
                                      icon: Icons.trending_up,
                                      color: Colors.green,
                                    ),
                                    _MiniStatCard(
                                      title: 'Pagos Cobrados',
                                      value:
                                          '${summary['totals']['payments_collected'] ?? 0}',
                                      icon: Icons.payment,
                                      color: Colors.teal,
                                    ),
                                    _MiniStatCard(
                                      title: 'Monto Cobrado',
                                      value: _formatCurrency(
                                        summary['totals']['amount_collected'] ??
                                            0,
                                      ),
                                      icon: Icons.attach_money,
                                      color: Colors.green[700]!,
                                    ),
                                    _MiniStatCard(
                                      title: 'Eficiencia General',
                                      value:
                                          '${summary['overall_efficiency']?.toStringAsFixed(1) ?? 0}%',
                                      icon: Icons.speed,
                                      color: Colors.orange,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Actividades por cobrador
                    _buildDailyActivitiesList(activities as List, context),
                  ],
                ),
              );
            }

            // ========== REPORTE DE PROYECCIÓN DE FLUJO (CASH FLOW FORECAST) ==========
          } else if (payload is Map && payload.containsKey('projections')) {
            final projections = payload['projections'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            if (projections is List &&
                projections.isNotEmpty &&
                projections.first is Map) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones de descarga
                    _buildDownloadButtons(context, ref, req, payload),
                    const SizedBox(height: 12),

                    // Resumen de proyección
                    if (summary.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Créditos Activos',
                            value: '${summary['total_active_credits'] ?? 0}',
                            icon: Icons.credit_card,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Pagos Proyectados',
                            value:
                                '${summary['total_projected_payments'] ?? 0}',
                            icon: Icons.event,
                            color: Colors.blue,
                          ),
                          _MiniStatCard(
                            title: 'Monto Proyectado',
                            value: _formatCurrency(
                              summary['total_projected_amount'] ?? 0,
                            ),
                            icon: Icons.account_balance_wallet,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Monto Vencido',
                            value: _formatCurrency(
                              summary['overdue_amount'] ?? 0,
                            ),
                            icon: Icons.warning,
                            color: Colors.red,
                          ),
                          _MiniStatCard(
                            title: 'Monto Pendiente',
                            value: _formatCurrency(
                              summary['pending_amount'] ?? 0,
                            ),
                            icon: Icons.schedule,
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Distribución por frecuencia
                    if (summary['by_frequency'] is Map) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.sync, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Text(
                                    'Distribución por Frecuencia',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildFrequencyDistribution(
                                summary['by_frequency'] as Map,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Proyecciones por período
                    _buildProjectionsList(projections as List, context),
                  ],
                ),
              );
            }

            // ========== REPORTE DE CARTERA (PORTFOLIO) ==========
          } else if (payload is Map &&
              payload.containsKey('portfolio_by_cobrador')) {
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botones de descarga
                  _buildDownloadButtons(context, ref, req, payload),
                  const SizedBox(height: 12),

                  // Resumen general
                  if (summary.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniStatCard(
                          title: 'Créditos Totales',
                          value: '${summary['total_credits'] ?? 0}',
                          icon: Icons.assignment,
                          color: Colors.indigo,
                        ),
                        _MiniStatCard(
                          title: 'Créditos Activos',
                          value: '${summary['active_credits'] ?? 0}',
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ),
                        _MiniStatCard(
                          title: 'Total Prestado',
                          value: _formatCurrency(summary['total_lent'] ?? 0),
                          icon: Icons.monetization_on,
                          color: Colors.green,
                        ),
                        _MiniStatCard(
                          title: 'Total Cobrado',
                          value: _formatCurrency(
                            summary['total_collected'] ?? 0,
                          ),
                          icon: Icons.account_balance,
                          color: Colors.teal,
                        ),
                        _MiniStatCard(
                          title: 'Balance Activo',
                          value: _formatCurrency(
                            summary['active_balance'] ?? 0,
                          ),
                          icon: Icons.account_balance_wallet,
                          color: Colors.orange,
                        ),
                        _MiniStatCard(
                          title: 'Calidad Cartera',
                          value:
                              '${summary['portfolio_quality']?.toStringAsFixed(1) ?? 0}%',
                          icon: Icons.star,
                          color: Colors.amber,
                        ),
                        _MiniStatCard(
                          title: 'Tasa Recuperación',
                          value:
                              '${summary['collection_rate']?.toStringAsFixed(1) ?? 0}%',
                          icon: Icons.trending_up,
                          color: Colors.green[700]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Top clientes por balance
                  if (payload['top_clients_by_balance'] is List &&
                      (payload['top_clients_by_balance'] as List)
                          .isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person_pin, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Top Clientes por Balance',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildTopClientsList(
                              payload['top_clients_by_balance'] as List,
                              context,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Cartera por cobrador
                  if (payload['portfolio_by_cobrador'] is Map) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.people, color: Colors.indigo),
                                SizedBox(width: 8),
                                Text(
                                  'Cartera por Cobrador',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPortfolioByCobrador(
                              payload['portfolio_by_cobrador'] as Map,
                              context,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Distribución por categoría
                  if (payload['portfolio_by_category'] is Map) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.category, color: Colors.purple),
                                SizedBox(width: 8),
                                Text(
                                  'Cartera por Categoría',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildPortfolioByCategory(
                              payload['portfolio_by_category'] as Map,
                              context,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );

            // ========== REPORTE DE LISTA DE ESPERA (WAITING LIST) ==========
          } else if (payload is Map && payload.containsKey('credits')) {
            final credits = payload['credits'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            // Verificar si es reporte de waiting list
            final bool isWaitingListReport = summary.containsKey(
              'total_in_waiting_list',
            );

            if (isWaitingListReport &&
                credits is List &&
                credits.isNotEmpty &&
                credits.first is Map) {
              final List<Map<String, dynamic>> rows = credits
                  .map<Map<String, dynamic>>((c) {
                    final Map<String, dynamic> cr = Map<String, dynamic>.from(
                      c as Map,
                    );
                    String clientName = '';
                    String creatorName = '';

                    if (cr['client'] is Map)
                      clientName = cr['client']['name']?.toString() ?? '';
                    if (cr['createdBy'] is Map)
                      creatorName = cr['createdBy']['name']?.toString() ?? '';

                    return {
                      'ID': cr['id']?.toString() ?? '',
                      'Cliente': clientName,
                      'Creado por': creatorName,
                      'Monto': _formatCurrency(cr['amount']),
                      'Estado':
                          cr['status_label']?.toString() ??
                          cr['status']?.toString() ??
                          '',
                      'Días Esperando': cr['days_waiting']?.toString() ?? '0',
                      'Entrega Programada': _formatDate(
                        cr['scheduled_delivery_date'],
                      ),
                      'Vencido': (cr['is_overdue_delivery'] == true)
                          ? 'Sí'
                          : 'No',
                    };
                  })
                  .toList();

              final columnsOrder = [
                'ID',
                'Cliente',
                'Creado por',
                'Monto',
                'Estado',
                'Días Esperando',
                'Entrega Programada',
                'Vencido',
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones de descarga
                    _buildDownloadButtons(context, ref, req, payload),
                    const SizedBox(height: 12),

                    // Resumen
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Total en Espera',
                            value: '${summary['total_in_waiting_list'] ?? 0}',
                            icon: Icons.hourglass_empty,
                            color: Colors.orange,
                          ),
                          _MiniStatCard(
                            title: 'Pendiente Aprobación',
                            value: '${summary['pending_approval'] ?? 0}',
                            icon: Icons.pending_actions,
                            color: Colors.amber,
                          ),
                          _MiniStatCard(
                            title: 'Esperando Entrega',
                            value: '${summary['waiting_delivery'] ?? 0}',
                            icon: Icons.local_shipping,
                            color: Colors.blue,
                          ),
                          _MiniStatCard(
                            title: 'Vencidos Entrega',
                            value: '${summary['overdue_for_delivery'] ?? 0}',
                            icon: Icons.warning,
                            color: Colors.red,
                          ),
                          _MiniStatCard(
                            title: 'Monto Total',
                            value: _formatCurrency(
                              summary['total_amount_pending'] ?? 0,
                            ),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Días Prom. Espera',
                            value:
                                '${summary['avg_days_waiting']?.toStringAsFixed(1) ?? 0}',
                            icon: Icons.schedule,
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Tabla
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(
                        rows,
                        columnOrder: columnsOrder,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ========== REPORTE DE COMISIONES (COMMISSIONS) ==========
          } else if (payload is Map && payload.containsKey('commissions')) {
            final commissions = payload['commissions'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            if (commissions is List &&
                commissions.isNotEmpty &&
                commissions.first is Map) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones de descarga
                    _buildDownloadButtons(context, ref, req, payload),
                    const SizedBox(height: 12),

                    // Resumen
                    if (summary.isNotEmpty) ...[
                      Card(
                        color: Colors.green.withOpacity(0.05),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.monetization_on,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  if (summary['period'] is Map)
                                    Text(
                                      'Comisiones ${summary['period']['start']} - ${summary['period']['end']}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _MiniStatCard(
                                    title: 'Tasa Comisión',
                                    value:
                                        '${summary['commission_rate']?.toStringAsFixed(1) ?? 0}%',
                                    icon: Icons.percent,
                                    color: Colors.indigo,
                                  ),
                                  _MiniStatCard(
                                    title: 'Cobradores',
                                    value:
                                        '${summary['total_cobradores'] ?? 0}',
                                    icon: Icons.people,
                                    color: Colors.blue,
                                  ),
                                  if (summary['totals'] is Map) ...[
                                    _MiniStatCard(
                                      title: 'Total Cobrado',
                                      value: _formatCurrency(
                                        summary['totals']['collected'] ?? 0,
                                      ),
                                      icon: Icons.attach_money,
                                      color: Colors.green,
                                    ),
                                    _MiniStatCard(
                                      title: 'Total Comisiones',
                                      value: _formatCurrency(
                                        summary['totals']['commissions'] ?? 0,
                                      ),
                                      icon: Icons.account_balance_wallet,
                                      color: Colors.teal,
                                    ),
                                    _MiniStatCard(
                                      title: 'Total Bonos',
                                      value: _formatCurrency(
                                        summary['totals']['bonuses'] ?? 0,
                                      ),
                                      icon: Icons.card_giftcard,
                                      color: Colors.amber,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Top earners
                    if (summary['top_earners'] is List &&
                        (summary['top_earners'] as List).isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.emoji_events, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text(
                                    'Mayores Comisiones',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildTopEarnersList(
                                summary['top_earners'] as List,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Lista de comisiones
                    _buildCommissionsList(commissions as List, context),
                  ],
                ),
              );
            }

            // ========== REPORTE DE USUARIOS (USERS) ==========
          } else if (payload is Map && payload.containsKey('users')) {
            final users = payload['users'];
            final summary = (payload['summary'] is Map)
                ? Map<String, dynamic>.from(payload['summary'] as Map)
                : <String, dynamic>{};

            if (users is List && users.isNotEmpty && users.first is Map) {
              final List<Map<String, dynamic>> rows = users
                  .map<Map<String, dynamic>>((u) {
                    final Map<String, dynamic> user = Map<String, dynamic>.from(
                      u as Map,
                    );
                    final roles = (user['roles'] is List)
                        ? (user['roles'] as List).join(', ')
                        : '';

                    return {
                      'ID': user['id']?.toString() ?? '',
                      'Nombre':
                          user['nombre']?.toString() ??
                          user['name']?.toString() ??
                          '',
                      'CI': user['ci']?.toString() ?? '',
                      'Email': user['email']?.toString() ?? '',
                      'Teléfono':
                          user['telefono']?.toString() ??
                          user['phone']?.toString() ??
                          '',
                      'Roles': roles,
                      'Categoría': user['client_category']?.toString() ?? '-',
                    };
                  })
                  .toList();

              final columnsOrder = [
                'ID',
                'Nombre',
                'CI',
                'Email',
                'Teléfono',
                'Roles',
                'Categoría',
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Botones de descarga
                    _buildDownloadButtons(context, ref, req, payload),
                    const SizedBox(height: 12),

                    // Resumen
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(
                            title: 'Total Usuarios',
                            value: '${summary['total_users'] ?? 0}',
                            icon: Icons.people,
                            color: Colors.indigo,
                          ),
                          if (summary['by_role'] is Map) ...[
                            if (summary['by_role']['admin'] != null)
                              _MiniStatCard(
                                title: 'Admins',
                                value: '${summary['by_role']['admin'] ?? 0}',
                                icon: Icons.admin_panel_settings,
                                color: Colors.red,
                              ),
                            if (summary['by_role']['manager'] != null)
                              _MiniStatCard(
                                title: 'Managers',
                                value: '${summary['by_role']['manager'] ?? 0}',
                                icon: Icons.business,
                                color: Colors.blue,
                              ),
                            if (summary['by_role']['cobrador'] != null)
                              _MiniStatCard(
                                title: 'Cobradores',
                                value: '${summary['by_role']['cobrador'] ?? 0}',
                                icon: Icons.person,
                                color: Colors.green,
                              ),
                            if (summary['by_role']['client'] != null)
                              _MiniStatCard(
                                title: 'Clientes',
                                value: '${summary['by_role']['client'] ?? 0}',
                                icon: Icons.person_outline,
                                color: Colors.orange,
                              ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 12),

                    // Distribución por categoría
                    if (summary['by_category'] is Map &&
                        (summary['by_category'] as Map).isNotEmpty) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.category, color: Colors.purple),
                                  SizedBox(width: 8),
                                  Text(
                                    'Clientes por Categoría',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildUsersCategoryDistribution(
                                summary['by_category'] as Map,
                                context,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Tabla
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(
                        rows,
                        columnOrder: columnsOrder,
                      ),
                    ),
                  ],
                ),
              );
            }
          } else if (payload is List &&
              payload.isNotEmpty &&
              payload.first is Map) {
            // Si es una lista genérica de maps, intentar formatear similarmente (flatten de campos simples)
            final genericRows = List<Map<String, dynamic>>.from(payload);
            // Convertir valores simples a strings
            final formatted = genericRows
                .map((g) => g.map((k, v) => MapEntry(k.toString(), v)))
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildTableFromJson(formatted),
              ),
            );
          } else if (payload is Map) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(8.0),
              scrollDirection: Axis.horizontal,
              child: _buildTableFromMap(payload as Map<String, dynamic>),
            );
          }

          // Fallback: mostrar JSON crudo
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Text(value.toString()),
          );
        }

        final filters = req.filters ?? {};

        // Para binarios ofrecer descarga
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reporte binario listo.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Descargar'),
                onPressed: () async {
                  try {
                    if (value is List<int>) {
                      final dir = await getApplicationDocumentsDirectory();

                      // Construir nombre con timestamp y filtros resumidos
                      final ts = DateTime.now().toIso8601String().replaceAll(
                        ':',
                        '-',
                      );
                      String filterTag = '';
                      if (filters.isNotEmpty) {
                        final parts = filters.entries
                            .where(
                              (e) =>
                                  e.value != null &&
                                  e.value.toString().isNotEmpty,
                            )
                            .map((e) => '${e.key}=${e.value}')
                            .toList();
                        if (parts.isNotEmpty) {
                          filterTag =
                              '_' + parts.join('_').replaceAll(' ', '-');
                        }
                      }

                      final safeReportKey = req.type.replaceAll(
                        RegExp(r'[^a-zA-Z0-9_]'),
                        '_',
                      );
                      final fileName =
                          'reporte_${safeReportKey}${filterTag}_$ts.${req.format}';
                      final filePath = '${dir.path}/$fileName';
                      final file = File(filePath);
                      await file.writeAsBytes(value);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reporte guardado: $fileName'),
                          action: SnackBarAction(
                            label: 'Abrir',
                            onPressed: () {
                              OpenFilex.open(file.path);
                            },
                          ),
                        ),
                      );

                      // Abrir automáticamente (intento silencioso)
                      try {
                        await OpenFilex.open(file.path);
                      } catch (_) {}

                      // Ofrecer compartir
                      showModalBottomSheet(
                        context: context,
                        builder: (ctx) => SafeArea(
                          child: Wrap(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.share),
                                title: const Text('Compartir'),
                                onTap: () async {
                                  Navigator.of(ctx).pop();
                                  await Share.shareXFiles([
                                    XFile(file.path),
                                  ], text: 'Reporte $fileName');
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.open_in_new),
                                title: const Text('Abrir'),
                                onTap: () {
                                  Navigator.of(ctx).pop();
                                  OpenFilex.open(file.path);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.close),
                                title: const Text('Cerrar'),
                                onTap: () => Navigator.of(ctx).pop(),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Respuesta inesperada: no son bytes'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error guardando archivo: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error generando reporte: $e')),
    );
  }
}

// ==========================
// Vista especial: Pagos de Hoy
// ==========================
String _formatTime(dynamic val) {
  if (val == null) return '';
  try {
    DateTime? dt;
    if (val is DateTime) {
      dt = val;
    } else {
      dt = DateTime.tryParse(val.toString());
    }
    if (dt == null) return '';
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  } catch (_) {
    return '';
  }
}

IconData _iconForPaymentMethod(String? method) {
  switch ((method ?? '').toLowerCase()) {
    case 'cash':
      return Icons.payments;
    case 'transfer':
      return Icons.wallet;
    case 'card':
      return Icons.credit_card;
    case 'mobile_payment':
      return Icons.phone_iphone;
    default:
      return Icons.attach_money;
  }
}

Color _colorForPaymentMethod(String? method) {
  switch ((method ?? '').toLowerCase()) {
    case 'cash':
      return Colors.green;
    case 'transfer':
      return Colors.blue;
    case 'card':
      return Colors.purple;
    case 'mobile_payment':
      return Colors.teal;
    default:
      return Colors.grey;
  }
}

Color _colorForStatus(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'completed':
      return Colors.green;
    case 'pending':
      return Colors.amber;
    case 'failed':
      return Colors.red;
    case 'cancelled':
      return Colors.grey;
    case 'partial':
      return Colors.blueGrey;
    default:
      return Colors.blueGrey;
  }
}

Widget _todayPaymentsList(
  List<Map<String, dynamic>> payments,
  BuildContext context,
) {
  String _extractClientName(Map<String, dynamic> pm) {
    try {
      if (pm['client'] is Map && pm['client']['name'] != null) {
        return pm['client']['name'].toString();
      }
      if (pm['credit'] is Map) {
        final credit = pm['credit'] as Map;
        if (credit['client'] is Map && credit['client']['name'] != null) {
          return credit['client']['name'].toString();
        }
        if (credit['client_name'] != null) {
          return credit['client_name'].toString();
        }
      }
      if (pm['client_name'] != null) return pm['client_name'].toString();
    } catch (_) {}
    return 'Cliente';
  }

  String _extractCobradorName(Map<String, dynamic> pm) {
    try {
      if (pm['cobrador'] is Map && pm['cobrador']['name'] != null) {
        return pm['cobrador']['name'].toString();
      }
      if (pm['cobrador_name'] != null) return pm['cobrador_name'].toString();
    } catch (_) {}
    return '';
  }

  double _sumAmounts() {
    double total = 0.0;
    for (final pm in payments) {
      final raw = pm['amount'];
      final d = double.tryParse(raw?.toString() ?? '0') ?? 0.0;
      total += d;
    }
    return total;
  }

  final total = _sumAmounts();
  final totalStr = _formatCurrency(total);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          const Icon(Icons.today, color: Colors.indigo),
          const SizedBox(width: 8),
          Text(
            'Pagos de hoy',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Chip(
            label: Text('${payments.length}'),
            backgroundColor: Colors.indigo.withOpacity(0.08),
            side: BorderSide(color: Colors.indigo.withOpacity(0.2)),
          ),
          const Spacer(),
          Text(
            totalStr,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: payments.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final pm = payments[i];
          final clientName = _extractClientName(pm);
          final cobradorName = _extractCobradorName(pm);
          final method = pm['payment_method']?.toString();
          final status = pm['status']?.toString();
          final cuota = pm['installment_number']?.toString();
          final amountStr = _formatCurrency(pm['amount']);
          final timeStr = _formatTime(pm['payment_date']);
          final colorMethod = _colorForPaymentMethod(method);
          final iconMethod = _iconForPaymentMethod(method);
          final statusColor = _colorForStatus(status);

          return Card(
            elevation: 1,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: colorMethod.withOpacity(0.12),
                foregroundColor: colorMethod,
                child: Icon(iconMethod),
              ),
              title: Text(
                clientName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Chip(
                      label: Text((method ?? '').toUpperCase()),
                      backgroundColor: colorMethod.withOpacity(0.08),
                      side: BorderSide(color: colorMethod.withOpacity(0.2)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    if (cuota != null && cuota.isNotEmpty)
                      Chip(
                        label: Text('Cuota $cuota'),
                        backgroundColor: Theme.of(
                          context,
                        ).primaryColor.withOpacity(0.08),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.2),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    Chip(
                      avatar: const Icon(Icons.schedule, size: 16),
                      label: Text(timeStr),
                      backgroundColor: Colors.grey.withOpacity(0.08),
                      side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    Chip(
                      label: Text((status ?? '').toUpperCase()),
                      backgroundColor: statusColor.withOpacity(0.08),
                      side: BorderSide(color: statusColor.withOpacity(0.2)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountStr,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (cobradorName.isNotEmpty)
                    SizedBox(
                      width: 120,
                      child: Text(
                        cobradorName,
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ],
  );
}

// Widget para mostrar distribución por gravedad (Overdue Report)
Widget _buildSeverityDistribution(Map severityMap, BuildContext context) {
  final light = severityMap['light'] ?? 0;
  final moderate = severityMap['moderate'] ?? 0;
  final severe = severityMap['severe'] ?? 0;
  final total = light + moderate + severe;

  if (total == 0) {
    return const Text('No hay datos de gravedad disponibles');
  }

  double lightPercent = (light / total) * 100;
  double moderatePercent = (moderate / total) * 100;
  double severePercent = (severe / total) * 100;

  return Column(
    children: [
      // Barras de progreso con porcentajes
      _buildSeverityBar(
        context,
        'Ligera (1-7 días)',
        light,
        lightPercent,
        Colors.orange,
      ),
      const SizedBox(height: 12),
      _buildSeverityBar(
        context,
        'Moderada (8-30 días)',
        moderate,
        moderatePercent,
        Colors.deepOrange,
      ),
      const SizedBox(height: 12),
      _buildSeverityBar(
        context,
        'Severa (>30 días)',
        severe,
        severePercent,
        Colors.red,
      ),
    ],
  );
}

Widget _buildSeverityBar(
  BuildContext context,
  String label,
  int count,
  double percent,
  Color color,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(
            children: [
              Text(
                '$count',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.toStringAsFixed(1)}%',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ),
    ],
  );
}

// Widget para mostrar Top 10 deudores (Overdue Report)
Widget _buildTopDebtorsList(List topDebtors, BuildContext context) {
  if (topDebtors.isEmpty) {
    return const Text('No hay datos de deudores disponibles');
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: topDebtors.length > 10 ? 10 : topDebtors.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final debtor = topDebtors[i] as Map;
      final clientName = debtor['client_name']?.toString() ?? 'Cliente';
      final creditId = debtor['credit_id']?.toString() ?? '';
      final daysOverdue = debtor['days_overdue']?.toString() ?? '0';
      final overdueAmount = debtor['overdue_amount'];
      final totalBalance = debtor['total_balance'];

      // Determinar color según posición
      Color rankColor = Colors.grey;
      if (i == 0)
        rankColor = Colors.amber[700]!;
      else if (i == 1)
        rankColor = Colors.grey[400]!;
      else if (i == 2)
        rankColor = Colors.brown[300]!;

      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: rankColor.withOpacity(0.15),
          foregroundColor: rankColor,
          radius: 18,
          child: Text(
            '${i + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          clientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('Crédito #$creditId • $daysOverdue días de mora'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(overdueAmount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontSize: 14,
              ),
            ),
            Text(
              'Balance: ${_formatCurrency(totalBalance)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    },
  );
}

// Widget para análisis por cobrador (Overdue Report)
Widget _buildCobradorAnalysis(Map cobradorMap, BuildContext context) {
  if (cobradorMap.isEmpty) {
    return const Text('No hay datos por cobrador disponibles');
  }

  final cobradores = cobradorMap.entries.toList();

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: cobradores.length,
    separatorBuilder: (_, __) => const Divider(height: 16),
    itemBuilder: (ctx, i) {
      final entry = cobradores[i];
      final cobradorName = entry.key;
      final data = entry.value as Map;
      final count = data['count'] ?? 0;
      final totalAmount = data['total_amount'] ?? 0;
      final avgDays = data['avg_days'] ?? 0.0;

      return Card(
        elevation: 0,
        color: Colors.blue.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cobradorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCobradorStat('Créditos', '$count', Icons.receipt),
                  _buildCobradorStat(
                    'Monto',
                    _formatCurrency(totalAmount),
                    Icons.attach_money,
                  ),
                  _buildCobradorStat(
                    'Promedio',
                    '${avgDays.toStringAsFixed(1)} días',
                    Icons.calendar_today,
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildCobradorStat(String label, String value, IconData icon) {
  return Column(
    children: [
      Icon(icon, size: 18, color: Colors.blue[700]),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );
}

// Widget para análisis por categoría de cliente (Overdue Report)
Widget _buildCategoryAnalysis(Map categoryMap, BuildContext context) {
  if (categoryMap.isEmpty) {
    return const Text('No hay datos por categoría disponibles');
  }

  final categories = categoryMap.entries.toList();

  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: categories.map((entry) {
      final category = entry.key;
      final data = entry.value as Map;
      final count = data['count'] ?? 0;
      final totalAmount = data['total_amount'] ?? 0;

      Color categoryColor = Colors.purple;
      if (category == 'A') {
        categoryColor = Colors.green;
      } else if (category == 'B') {
        categoryColor = Colors.blue;
      } else if (category == 'C') {
        categoryColor = Colors.orange;
      }

      return SizedBox(
        width: 160,
        child: Card(
          elevation: 0,
          color: categoryColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: categoryColor.withOpacity(0.2),
                      foregroundColor: categoryColor,
                      radius: 16,
                      child: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Categoría $category',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Créditos:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monto:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      _formatCurrency(totalAmount),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}

// Helper para botones de descarga reutilizable
Widget _buildDownloadButtons(
  BuildContext context,
  WidgetRef ref,
  rp.ReportRequest req,
  Map payload,
) {
  return Row(
    children: [
      ElevatedButton.icon(
        onPressed: () async {
          try {
            final bytes = await ref
                .read(rp.reportsApiProvider)
                .generateReport(
                  req.type,
                  filters: req.filters,
                  format: 'excel',
                );
            if (bytes is List<int>) {
              final dir = await getApplicationDocumentsDirectory();
              final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
              final fileName = 'reporte_${req.type}_$ts.xlsx';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reporte guardado: $fileName'),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () {
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
              );
              try {
                await OpenFilex.open(file.path);
              } catch (_) {}
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al descargar Excel: $e')),
            );
          }
        },
        icon: const Icon(Icons.grid_on),
        label: const Text('Excel'),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () async {
          try {
            final bytes = await ref
                .read(rp.reportsApiProvider)
                .generateReport(req.type, filters: req.filters, format: 'pdf');
            if (bytes is List<int>) {
              final dir = await getApplicationDocumentsDirectory();
              final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
              final fileName = 'reporte_${req.type}_$ts.pdf';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reporte guardado: $fileName'),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () {
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
              );
              try {
                await OpenFilex.open(file.path);
              } catch (_) {}
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al descargar PDF: $e')),
            );
          }
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child:
              (payload['generated_by'] != null ||
                  payload['generated_at'] != null)
              ? Text(
                  'Generado' +
                      (payload['generated_by'] != null
                          ? ' por ${payload['generated_by']}'
                          : '') +
                      (payload['generated_at'] != null
                          ? ' • ${_formatDate(payload['generated_at'])}'
                          : ''),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : const SizedBox.shrink(),
        ),
      ),
    ],
  );
}

// === WIDGETS PARA PERFORMANCE REPORT ===

Widget _buildTopPerformersList(List performers, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: performers.length > 5 ? 5 : performers.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final performer = performers[i] as Map;
      final name = performer['name']?.toString() ?? 'Cobrador';
      final collectionRate = performer['collection_rate'] ?? 0;
      final portfolioQuality = performer['portfolio_quality'] ?? 0;

      Color rankColor = Colors.grey;
      if (i == 0)
        rankColor = Colors.amber[700]!;
      else if (i == 1)
        rankColor = Colors.grey[400]!;
      else if (i == 2)
        rankColor = Colors.brown[300]!;

      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: rankColor.withOpacity(0.15),
          foregroundColor: rankColor,
          radius: 18,
          child: Text(
            '${i + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Cobranza: ${collectionRate.toStringAsFixed(1)}% • Calidad: ${portfolioQuality.toStringAsFixed(1)}%',
        ),
        trailing: const Icon(Icons.star, color: Colors.amber),
      );
    },
  );
}

Widget _buildPerformanceList(List performance, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: performance.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final p = performance[i] as Map;
      final cobradorName = p['cobrador_name']?.toString() ?? 'Cobrador';
      final managerName = p['manager_name']?.toString() ?? '';
      final metrics = p['metrics'] is Map ? p['metrics'] as Map : {};

      final creditsDelivered = metrics['credits_delivered'] ?? 0;
      final totalLent = metrics['total_amount_lent'] ?? 0;
      final totalCollected = metrics['total_amount_collected'] ?? 0;
      final collectionRate = metrics['collection_rate'] ?? 0;
      final portfolioQuality = metrics['portfolio_quality'] ?? 0;
      final efficiencyScore = metrics['efficiency_score'] ?? 0;
      final activeCredits = metrics['active_credits'] ?? 0;
      final overdueCredits = metrics['overdue_credits'] ?? 0;

      Color performanceColor = Colors.green;
      if (collectionRate < 60)
        performanceColor = Colors.red;
      else if (collectionRate < 75)
        performanceColor = Colors.orange;

      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: performanceColor.withOpacity(0.15),
                    foregroundColor: performanceColor,
                    child: Text('${i + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cobradorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (managerName.isNotEmpty)
                          Text(
                            'Manager: $managerName',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            efficiencyScore.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        'Eficiencia',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPerformanceStat(
                    'Entregados',
                    '$creditsDelivered',
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                  _buildPerformanceStat(
                    'Prestado',
                    _formatCurrency(totalLent),
                    Icons.trending_up,
                    Colors.green,
                  ),
                  _buildPerformanceStat(
                    'Cobrado',
                    _formatCurrency(totalCollected),
                    Icons.payments,
                    Colors.teal,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPerformanceStat(
                    'Tasa Cobranza',
                    '${collectionRate.toStringAsFixed(1)}%',
                    Icons.percent,
                    performanceColor,
                  ),
                  _buildPerformanceStat(
                    'Calidad Cartera',
                    '${portfolioQuality.toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildPerformanceStat(
                    'Activos',
                    '$activeCredits',
                    Icons.trending_up,
                    Colors.indigo,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (overdueCredits > 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '$overdueCredits créditos en mora',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPerformanceStat(
  String label,
  String value,
  IconData icon,
  Color color,
) {
  return Column(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

// === WIDGETS PARA DAILY ACTIVITY REPORT ===

Widget _buildDailyActivitiesList(List activities, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: activities.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final activity = activities[i] as Map;
      final cobradorName = activity['cobrador_name']?.toString() ?? 'Cobrador';
      final cashBalance = activity['cash_balance'] is Map
          ? activity['cash_balance'] as Map
          : {};
      final creditsDelivered = activity['credits_delivered'] is Map
          ? activity['credits_delivered'] as Map
          : {};
      final paymentsCollected = activity['payments_collected'] is Map
          ? activity['payments_collected'] as Map
          : {};
      final expectedPayments = activity['expected_payments'] is Map
          ? activity['expected_payments'] as Map
          : {};

      final balanceStatus = cashBalance['status']?.toString() ?? 'not_opened';
      final efficiency = expectedPayments['efficiency'] ?? 0;

      Color statusColor = Colors.grey;
      String statusLabel = 'No abierta';
      if (balanceStatus == 'open') {
        statusColor = Colors.blue;
        statusLabel = 'Abierta';
      } else if (balanceStatus == 'closed') {
        statusColor = Colors.green;
        statusLabel = 'Cerrada';
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cobradorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(statusLabel),
                    backgroundColor: statusColor.withOpacity(0.1),
                    side: BorderSide(color: statusColor),
                    avatar: Icon(Icons.circle, size: 12, color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Caja
              if (cashBalance.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      size: 20,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Caja:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildDailyStat(
                      'Inicial',
                      _formatCurrency(cashBalance['initial_amount'] ?? 0),
                    ),
                    _buildDailyStat(
                      'Recaudado',
                      _formatCurrency(cashBalance['collected_amount'] ?? 0),
                    ),
                    _buildDailyStat(
                      'Prestado',
                      _formatCurrency(cashBalance['lent_amount'] ?? 0),
                    ),
                    _buildDailyStat(
                      'Final',
                      _formatCurrency(cashBalance['final_amount'] ?? 0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              // Créditos entregados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Créditos entregados: ${creditsDelivered['count'] ?? 0}',
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(creditsDelivered['total_amount'] ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Pagos cobrados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, size: 20, color: Colors.teal),
                      const SizedBox(width: 8),
                      Text(
                        'Pagos cobrados: ${paymentsCollected['count'] ?? 0}',
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(paymentsCollected['total_amount'] ?? 0),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Eficiencia
              if (expectedPayments.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.speed, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Text('Eficiencia: '),
                    Text(
                      '${expectedPayments['collected'] ?? 0}/${expectedPayments['count'] ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '(${efficiency.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: efficiency >= 80
                            ? Colors.green
                            : (efficiency >= 60 ? Colors.orange : Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildDailyStat(String label, String value) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    ],
  );
}

// === WIDGETS PARA CASH FLOW FORECAST REPORT ===

Widget _buildFrequencyDistribution(Map frequencies, BuildContext context) {
  final daily = frequencies['daily'] is Map ? frequencies['daily'] as Map : {};
  final weekly = frequencies['weekly'] is Map
      ? frequencies['weekly'] as Map
      : {};
  final biweekly = frequencies['biweekly'] is Map
      ? frequencies['biweekly'] as Map
      : {};
  final monthly = frequencies['monthly'] is Map
      ? frequencies['monthly'] as Map
      : {};

  return Column(
    children: [
      _buildFrequencyRow(
        'Diario',
        daily['count'] ?? 0,
        daily['amount'] ?? 0,
        Colors.blue,
      ),
      const SizedBox(height: 8),
      _buildFrequencyRow(
        'Semanal',
        weekly['count'] ?? 0,
        weekly['amount'] ?? 0,
        Colors.green,
      ),
      const SizedBox(height: 8),
      _buildFrequencyRow(
        'Quincenal',
        biweekly['count'] ?? 0,
        biweekly['amount'] ?? 0,
        Colors.orange,
      ),
      const SizedBox(height: 8),
      _buildFrequencyRow(
        'Mensual',
        monthly['count'] ?? 0,
        monthly['amount'] ?? 0,
        Colors.purple,
      ),
    ],
  );
}

Widget _buildFrequencyRow(String label, int count, num amount, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      Row(
        children: [
          Text('$count pagos', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(amount),
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    ],
  );
}

Widget _buildProjectionsList(List projections, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: projections.length > 30 ? 30 : projections.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final proj = projections[i] as Map;
      final period = proj['period_label']?.toString() ?? '';
      final count = proj['count'] ?? 0;
      final totalAmount = proj['total_amount'] ?? 0;
      final overdueCount = proj['overdue_count'] ?? 0;
      final pendingCount = proj['pending_count'] ?? 0;

      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: Colors.indigo.withOpacity(0.1),
          foregroundColor: Colors.indigo,
          child: Text('$count'),
        ),
        title: Text(
          period,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            if (overdueCount > 0) ...[
              Icon(Icons.warning, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                '$overdueCount vencidos',
                style: const TextStyle(color: Colors.red, fontSize: 11),
              ),
              const SizedBox(width: 12),
            ],
            Icon(Icons.schedule, size: 14, color: Colors.orange),
            const SizedBox(width: 4),
            Text(
              '$pendingCount pendientes',
              style: TextStyle(color: Colors.grey[600], fontSize: 11),
            ),
          ],
        ),
        trailing: Text(
          _formatCurrency(totalAmount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: Colors.green,
          ),
        ),
      );
    },
  );
}

// === WIDGETS PARA PORTFOLIO REPORT ===

Widget _buildTopClientsList(List clients, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: clients.length > 10 ? 10 : clients.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final client = clients[i] as Map;
      final clientName = client['client_name']?.toString() ?? 'Cliente';
      final clientCategory = client['client_category']?.toString() ?? '';
      final creditId = client['credit_id']?.toString() ?? '';
      final balance = client['balance'] ?? 0;
      final totalAmount = client['total_amount'] ?? 0;
      final completionRate = client['completion_rate'] ?? 0;

      Color categoryColor = Colors.purple;
      if (clientCategory == 'A')
        categoryColor = Colors.green;
      else if (clientCategory == 'B')
        categoryColor = Colors.blue;
      else if (clientCategory == 'C')
        categoryColor = Colors.orange;

      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: categoryColor.withOpacity(0.15),
          foregroundColor: categoryColor,
          child: Text(clientCategory.isNotEmpty ? clientCategory : '?'),
        ),
        title: Text(
          clientName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Crédito #$creditId • ${completionRate.toStringAsFixed(0)}% completado',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatCurrency(balance),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
                fontSize: 14,
              ),
            ),
            Text(
              'de ${_formatCurrency(totalAmount)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildPortfolioByCobrador(Map portfolioMap, BuildContext context) {
  final cobradores = portfolioMap.entries.toList();

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: cobradores.length,
    separatorBuilder: (_, __) => const Divider(height: 16),
    itemBuilder: (ctx, i) {
      final entry = cobradores[i];
      final cobradorName = entry.key;
      final data = entry.value as Map;

      final totalCredits = data['total_credits'] ?? 0;
      final activeCredits = data['active_credits'] ?? 0;
      final totalBalance = data['total_balance'] ?? 0;
      final totalLent = data['total_lent'] ?? 0;
      final portfolioQuality = data['portfolio_quality'] ?? 0;
      final overdueCredits = data['overdue_credits'] ?? 0;

      Color qualityColor = Colors.green;
      if (portfolioQuality < 60)
        qualityColor = Colors.red;
      else if (portfolioQuality < 75)
        qualityColor = Colors.orange;

      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      cobradorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: qualityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: qualityColor),
                    ),
                    child: Text(
                      '${portfolioQuality.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: qualityColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPortfolioStat(
                    'Total',
                    '$totalCredits',
                    Icons.assignment,
                  ),
                  _buildPortfolioStat(
                    'Activos',
                    '$activeCredits',
                    Icons.trending_up,
                  ),
                  if (overdueCredits > 0)
                    _buildPortfolioStat(
                      'Mora',
                      '$overdueCredits',
                      Icons.warning,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Prestado:', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    _formatCurrency(totalLent),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Balance:', style: TextStyle(color: Colors.grey[600])),
                  Text(
                    _formatCurrency(totalBalance),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildPortfolioStat(String label, String value, IconData icon) {
  return Column(
    children: [
      Icon(icon, size: 18, color: Colors.indigo),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );
}

Widget _buildPortfolioByCategory(Map categoryMap, BuildContext context) {
  final categories = categoryMap.entries.toList();

  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: categories.map((entry) {
      final category = entry.key;
      final data = entry.value as Map;
      final totalCredits = data['total_credits'] ?? 0;
      final activeBalance = data['active_balance'] ?? 0;

      Color categoryColor = Colors.purple;
      if (category == 'A')
        categoryColor = Colors.green;
      else if (category == 'B')
        categoryColor = Colors.blue;
      else if (category == 'C')
        categoryColor = Colors.orange;

      return SizedBox(
        width: 160,
        child: Card(
          elevation: 0,
          color: categoryColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: categoryColor.withOpacity(0.2),
                      foregroundColor: categoryColor,
                      radius: 16,
                      child: Text(
                        category,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Cat. $category',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Créditos:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      '$totalCredits',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Balance:',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    Text(
                      _formatCurrency(activeBalance),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: categoryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}

// === WIDGETS PARA COMMISSIONS REPORT ===

Widget _buildTopEarnersList(List earners, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: earners.length > 5 ? 5 : earners.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final earner = earners[i] as Map;
      final name = earner['name']?.toString() ?? 'Cobrador';
      final commission = earner['commission'] ?? 0;
      final collectionPercentage = earner['collection_percentage'] ?? 0;

      Color rankColor = Colors.grey;
      if (i == 0)
        rankColor = Colors.amber[700]!;
      else if (i == 1)
        rankColor = Colors.grey[400]!;
      else if (i == 2)
        rankColor = Colors.brown[300]!;

      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: rankColor.withOpacity(0.15),
          foregroundColor: rankColor,
          radius: 18,
          child: Text(
            '${i + 1}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Cobranza: ${collectionPercentage.toStringAsFixed(1)}%'),
        trailing: Text(
          _formatCurrency(commission),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 15,
          ),
        ),
      );
    },
  );
}

Widget _buildCommissionsList(List commissions, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: commissions.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final comm = commissions[i] as Map;
      final cobradorName = comm['cobrador_name']?.toString() ?? 'Cobrador';
      final paymentsCollected = comm['payments_collected'] is Map
          ? comm['payments_collected'] as Map
          : {};
      final creditsDelivered = comm['credits_delivered'] is Map
          ? comm['credits_delivered'] as Map
          : {};
      final commission = comm['commission'] is Map
          ? comm['commission'] as Map
          : {};
      final performance = comm['performance'] is Map
          ? comm['performance'] as Map
          : {};

      final commissionTotal = commission['total'] ?? 0;
      final commissionBase = commission['on_collection'] ?? 0;
      final bonus = commission['bonus'] ?? 0;
      final collectionPercentage = performance['collection_percentage'] ?? 0;

      final hasBonus = bonus > 0;

      return Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cobradorName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (hasBonus)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.star, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text(
                            'Bonus',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCommissionStat(
                    'Cobrado',
                    _formatCurrency(paymentsCollected['total_amount'] ?? 0),
                    Icons.attach_money,
                  ),
                  _buildCommissionStat(
                    'Prestado',
                    _formatCurrency(creditsDelivered['total_amount'] ?? 0),
                    Icons.trending_up,
                  ),
                  _buildCommissionStat(
                    'Cobranza',
                    '${collectionPercentage.toStringAsFixed(0)}%',
                    Icons.percent,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Comisión base:',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  Text(
                    _formatCurrency(commissionBase),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              if (hasBonus) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.card_giftcard,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bonus:',
                          style: TextStyle(color: Colors.amber[700]),
                        ),
                      ],
                    ),
                    Text(
                      _formatCurrency(bonus),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[700],
                      ),
                    ),
                  ],
                ),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _formatCurrency(commissionTotal),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildCommissionStat(String label, String value, IconData icon) {
  return Column(
    children: [
      Icon(icon, size: 18, color: Colors.green),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );
}

// === WIDGETS PARA USERS REPORT ===

Widget _buildUsersCategoryDistribution(Map categories, BuildContext context) {
  final categoryList = categories.entries.toList();

  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: categoryList.map((entry) {
      final category = entry.key;
      final count = entry.value ?? 0;

      Color categoryColor = Colors.purple;
      if (category == 'A')
        categoryColor = Colors.green;
      else if (category == 'B')
        categoryColor = Colors.blue;
      else if (category == 'C')
        categoryColor = Colors.orange;

      return SizedBox(
        width: 120,
        child: Card(
          elevation: 0,
          color: categoryColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: categoryColor.withOpacity(0.2),
                  foregroundColor: categoryColor,
                  radius: 24,
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: categoryColor,
                  ),
                ),
                Text(
                  'clientes',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
