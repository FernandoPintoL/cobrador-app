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
    return filters.any((f) => f.toString() == 'start_date' || f.toString() == 'end_date');
  }

  Map<String, String> _rangeForIndex(int idx) {
    final now = DateTime.now();
    String iso(DateTime d) => d.toIso8601String().split('T').first;
    if (idx == 0) {
      final d = DateTime(now.year, now.month, now.day);
      return {'start': iso(d), 'end': iso(d)};
    } else if (idx == 1) {
      final d = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
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
                  Text('Seleccione un tipo de reporte, configure filtros y genere resultados en JSON, Excel o PDF.'),
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
                        DropdownButtonFormField<String>(
                          value: _selectedReport,
                          items: entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value['name'] ?? e.key),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedReport = v;
                            _quickRangeIndex = null;
                            _filters.remove('start_date');
                            _filters.remove('end_date');
                          }),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: cs.surfaceVariant.withOpacity(0.4),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: cs.primary, width: 2),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                  final labels = ['Hoy', 'Ayer', 'Últimos 7 días', 'Este mes', 'Mes pasado', 'Rango de fechas'];
                                  final selected = _quickRangeIndex == i;
                                  return ChoiceChip(
                                    label: Text(labels[i]),
                                    selected: selected,
                                    labelStyle: TextStyle(color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant),
                                    selectedColor: cs.primaryContainer,
                                    backgroundColor: cs.surface,
                                    shape: const StadiumBorder(),
                                    side: BorderSide(color: selected ? cs.primary : cs.outline.withOpacity(0.4)),
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
                                            _filters['start_date'] = range['start'];
                                            _filters['end_date'] = range['end'];
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
                                children: _buildFiltersFor(types[_selectedReport!]),
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
                                  Text('Formato:', style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
                                  DropdownButton<String>(
                                    value: _format,
                                    items: ((types[_selectedReport]?['formats'] as List<dynamic>?) ?? ['json'])
                                        .map((f) => DropdownMenuItem(
                                              value: f as String,
                                              child: Text(f.toString().toUpperCase()),
                                            ))
                                        .toList(),
                                    onChanged: (v) => setState(() => _format = v ?? 'json'),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _filters.clear();
                                        _quickRangeIndex = null;
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Filtros limpiados')),
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
                              onPressed: _selectedReport == null ? null : _generateReport,
                              icon: const Icon(Icons.play_arrow_rounded),
                              label: const Text('Generar'),
                            ),
                          ],
                        ),
                      ],
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
        error: (e, st) => Center(child: Text('Error cargando tipos de reportes: $e')),
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
        final isManualRange = _quickRangeIndex == 5; // índice 5 = Rango de fechas
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filtros limpiados')),
    );
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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
                    child: Text(e.key, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
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
                      style: (Theme.of(context).textTheme.labelLarge ?? const TextStyle())
                          .copyWith(color: Colors.grey[700], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle(fontSize: 18))
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 18),
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

Widget _buildCreditsList(List<Map<String, dynamic>> credits, BuildContext context) {
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
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
                            side:
                                BorderSide(color: freqColor.withOpacity(0.2)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (cr['created_at'] != null)
                          Chip(
                            avatar: const Icon(Icons.event, size: 16),
                            label: Text(_formatDate(cr['created_at'])),
                            backgroundColor: Colors.grey.withOpacity(0.08),
                            side:
                                BorderSide(color: Colors.grey.withOpacity(0.2)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        if (cr['end_date'] != null)
                          Chip(
                            avatar: const Icon(Icons.flag, size: 16),
                            label: Text(_formatDate(cr['end_date'])),
                            backgroundColor: Colors.grey.withOpacity(0.08),
                            side:
                                BorderSide(color: Colors.grey.withOpacity(0.2)),
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
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
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
                      style:
                          const TextStyle(fontSize: 11, color: Colors.grey),
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
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey),
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
  final initial = _pickAmount(b, ['initial', 'initial_amount', 'start', 'opening', 'initial_cash']);
  final collected = _pickAmount(b, ['collected', 'collected_amount', 'income', 'in']);
  final lent = _pickAmount(b, ['lent', 'lent_amount', 'loaned', 'out']);
  final finalVal = _pickAmount(b, ['final', 'final_amount', 'closing', 'end']);
  return finalVal - (initial + collected - lent);
}

Widget _buildBalancesList(List<Map<String, dynamic>> balances, BuildContext context) {
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
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
          final initial = _pickAmount(b, ['initial', 'initial_amount', 'opening']);
          final collected = _pickAmount(b, ['collected', 'collected_amount', 'income']);
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

              final Map<String, dynamic> summary =
                  (payload['summary'] is Map)
                      ? Map<String, dynamic>.from(payload['summary'] as Map)
                      : <String, dynamic>{};

              // Detectar si el rango corresponde a HOY (para vista especial)
              final String _todayStr = DateTime.now().toIso8601String().split('T').first;
              final String? _fStart = req.filters?['start_date']?.toString();
              final String? _fEnd = req.filters?['end_date']?.toString();
              final bool isTodayRange = (_fStart == _todayStr && _fEnd == _todayStr) ||
                  ((summary['date_range'] is Map) &&
                      (summary['date_range']['start']?.toString() == _todayStr) &&
                      (summary['date_range']['end']?.toString() == _todayStr));
              final List<Map<String, dynamic>> typedPayments = (payments is List)
                  ? (payments as List)
                      .whereType<Map>()
                      .map<Map<String, dynamic>>(
                          (e) => Map<String, dynamic>.from(e as Map))
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
                                      final dir = await getApplicationDocumentsDirectory();
                                      final ts = DateTime.now()
                                          .toIso8601String()
                                          .replaceAll(':', '-');
                                      final fileName =
                                          'reporte_${req.type}_$ts.xlsx';
                                      final file = File('${dir.path}/$fileName');
                                      await file.writeAsBytes(bytes);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Reporte guardado: $fileName'),
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
                                            'Error al descargar Excel: $e'),
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
                                      final dir = await getApplicationDocumentsDirectory();
                                      final ts = DateTime.now()
                                          .toIso8601String()
                                          .replaceAll(':', '-');
                                      final fileName =
                                          'reporte_${req.type}_$ts.pdf';
                                      final file = File('${dir.path}/$fileName');
                                      await file.writeAsBytes(bytes);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content:
                                              Text('Reporte guardado: $fileName'),
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
                                        content:
                                            Text('Error al descargar PDF: $e'),
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
                            child: (payload['generated_by'] != null || payload['generated_at'] != null)
                                ? Text(
                                    'Generado' +
                                        (payload['generated_by'] != null ? ' por ${payload['generated_by']}' : '') +
                                        (payload['generated_at'] != null ? ' • ${_formatDate(payload['generated_at'])}' : ''),
                                    style: Theme.of(context).textTheme.bodySmall,
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
                            value:
                                '${summary['total_payments'] ?? 0}',
                            icon: Icons.receipt_long,
                            color: Colors.indigo,
                          ),
                          _MiniStatCard(
                            title: 'Monto total',
                            value: _formatCurrency(
                                summary['total_amount'] ?? 0),
                            icon: Icons.attach_money,
                            color: Colors.green,
                          ),
                          _MiniStatCard(
                            title: 'Promedio',
                            value: _formatCurrency(
                                summary['average_payment'] ?? 0),
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
                      child:
                          _buildTableFromJson(rows, columnOrder: columnsOrder),
                    ),
                  ],
                ),
              );
            }
          } else if (payload is Map && payload.containsKey('credits')) {
            final credits = payload['credits'];
            if (credits is List &&
                credits.isNotEmpty &&
                credits.first is Map) {
              // Aplanar y formatear cada crédito a un Map con columnas legibles
              final List<Map<String, dynamic>> rows = credits
                  .map<Map<String, dynamic>>((c) {
                    final Map<String, dynamic> cr =
                        Map<String, dynamic>.from(c as Map);

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

              final Map<String, dynamic> summary =
                  (payload['summary'] is Map)
                      ? Map<String, dynamic>.from(payload['summary'] as Map)
                      : <String, dynamic>{};

              final List<Map<String, dynamic>> typedCredits = (credits is List)
                  ? (credits as List)
                      .whereType<Map>()
                      .map<Map<String, dynamic>>(
                          (e) => Map<String, dynamic>.from(e as Map))
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
                                final dir = await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName =
                                    'reporte_${req.type}_$ts.xlsx';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Reporte guardado: $fileName'),
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
                                      'Error al descargar Excel: $e'),
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
                                final dir = await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
                                final fileName =
                                    'reporte_${req.type}_$ts.pdf';
                                final file = File('${dir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Reporte guardado: $fileName'),
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
                                  content:
                                      Text('Error al descargar PDF: $e'),
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
                            child: (payload['generated_by'] != null ||
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
                            value:
                                _formatCurrency(summary['total_amount'] ?? 0),
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
                            value:
                                _formatCurrency(summary['total_balance'] ?? 0),
                            icon: Icons.account_balance_wallet,
                            color: Colors.orange,
                          ),
                          _MiniStatCard(
                            title: 'Pendiente',
                            value:
                                _formatCurrency(summary['pending_amount'] ?? 0),
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
                      child: _buildTableFromJson(rows, columnOrder: columnsOrder),
                    ),
                  ],
                ),
              );
            }
          } else if (payload is Map && payload.containsKey('balances')) {
            final balances = payload['balances'];
            if (balances is List && balances.isNotEmpty && balances.first is Map) {
              final List<Map<String, dynamic>> typedBalances = (balances as List)
                  .whereType<Map>()
                  .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

              // Construir filas legibles para la tabla
              final List<Map<String, dynamic>> rows = typedBalances.map((b) {
                final cobrador = _extractBalanceCobradorName(b);
                final fecha = _extractBalanceDate(b);
                final inicial = _pickAmount(b, ['initial', 'initial_amount', 'opening']);
                final recaudado = _pickAmount(b, ['collected', 'collected_amount', 'income']);
                final prestado = _pickAmount(b, ['lent', 'lent_amount', 'loaned']);
                final finalVal = _pickAmount(b, ['final', 'final_amount', 'closing']);
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
                                final dir = await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
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
                                final dir = await getApplicationDocumentsDirectory();
                                final ts = DateTime.now()
                                    .toIso8601String()
                                    .replaceAll(':', '-');
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
                            child: (payload['generated_by'] != null || payload['generated_at'] != null)
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
                            value: _formatCurrency(summary['total_initial'] ?? 0),
                            icon: Icons.start,
                            color: Colors.blueGrey,
                          ),
                          _MiniStatCard(
                            title: 'Recaudado',
                            value: _formatCurrency(summary['total_collected'] ?? 0),
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
                            value: _formatCurrency(summary['average_difference'] ?? 0),
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
                                child: Text('No hay balances para los filtros seleccionados.'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: _buildTableFromJson(rows, columnOrder: columnsOrder),
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
                                final dir = await getApplicationDocumentsDirectory();
                                final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
                                final file = File('${dir.path}/reporte_${req.type}_$ts.xlsx');
                                await file.writeAsBytes(bytes);
                                try { await OpenFilex.open(file.path); } catch (_) {}
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Excel descargado')),
                                );
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
                                  .generateReport(
                                    req.type,
                                    filters: req.filters,
                                    format: 'pdf',
                                  );
                              if (bytes is List<int>) {
                                final dir = await getApplicationDocumentsDirectory();
                                final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
                                final file = File('${dir.path}/reporte_${req.type}_$ts.pdf');
                                await file.writeAsBytes(bytes);
                                try { await OpenFilex.open(file.path); } catch (_) {}
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PDF descargado')),
                                );
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
                            child: (payload['generated_by'] != null || payload['generated_at'] != null)
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
                    ),
                    const SizedBox(height: 12),
                    if (summary.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MiniStatCard(title: 'Registros', value: '${summary['total_records'] ?? 0}', icon: Icons.list_alt, color: Colors.indigo),
                          _MiniStatCard(title: 'Inicial', value: _formatCurrency(summary['total_initial'] ?? 0), icon: Icons.start, color: Colors.blueGrey),
                          _MiniStatCard(title: 'Recaudado', value: _formatCurrency(summary['total_collected'] ?? 0), icon: Icons.call_received, color: Colors.green),
                          _MiniStatCard(title: 'Prestado', value: _formatCurrency(summary['total_lent'] ?? 0), icon: Icons.call_made, color: Colors.orange),
                          _MiniStatCard(title: 'Final', value: _formatCurrency(summary['total_final'] ?? 0), icon: Icons.summarize, color: Colors.indigo),
                          _MiniStatCard(title: 'Dif. promedio', value: _formatCurrency(summary['average_difference'] ?? 0), icon: Icons.calculate, color: Colors.deepPurple),
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
                            Expanded(child: Text('No hay balances para los filtros seleccionados.')),
                          ],
                        ),
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



Widget _todayPaymentsList(List<Map<String, dynamic>> payments, BuildContext context) {
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
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
                        backgroundColor:
                            Theme.of(context).primaryColor.withOpacity(0.08),
                        side: BorderSide(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.2),
                        ),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
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
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
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

