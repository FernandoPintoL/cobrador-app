import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../../datos/api_services/user_api_service.dart';

/// Campo reusable que permite buscar y seleccionar un elemento (cobrador/cliente/categoria).
/// Implementación simple: muestra un TextFormField readOnly que abre un modal con búsqueda.
class SearchSelectField extends ConsumerStatefulWidget {
  final String label;
  final String? initialValue;
  final String type; // 'cobrador' | 'cliente' | 'categoria'
  final void Function(String? id, String? label) onSelected;

  const SearchSelectField({
    required this.label,
    this.initialValue,
    required this.type,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<SearchSelectField> createState() => _SearchSelectFieldState();
}

class _SearchSelectFieldState extends ConsumerState<SearchSelectField> {
  late TextEditingController _controller;
  Timer? _debounce;
  List<Map<String, String>> _suggestions = [];
  bool _loading = false;
  int _selectedSuggestion = -1;
  late FocusNode _focusNode;
  final bool _useOverlay = false;
  bool _showInline = false;
  String? _selectedId; // Guardar el ID seleccionado
  String? _selectedLabel; // Guardar el label seleccionado

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
    _focusNode = FocusNode();

    // Si hay initialValue, intentar cargar el nombre completo
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _loadInitialValue(widget.initialValue!);
    }
  }

  @override
  void didUpdateWidget(covariant SearchSelectField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
        _loadInitialValue(widget.initialValue!);
      } else {
        _controller.text = '';
        _selectedId = null;
        _selectedLabel = null;
      }
    }
  }

  /// Carga el nombre completo cuando se inicializa con un ID
  Future<void> _loadInitialValue(String initialId) async {
    // Si no es un tipo que requiere búsqueda, solo mostrar el ID
    if (widget.type == 'categoria') {
      _controller.text = initialId;
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final svc = UserApiService();
      final resp = await svc.getUser(initialId);

      if (resp['success'] == true && resp['data'] != null) {
        final user = resp['data'] as Map<String, dynamic>;
        final name = (user['name'] ?? user['full_name'] ?? '').toString();
        final ci = (user['ci'] ?? user['document'] ?? '').toString();

        final labelParts = <String>[];
        if (ci.isNotEmpty) labelParts.add(ci);
        if (name.isNotEmpty) labelParts.add(name);
        final label = labelParts.join(' • ');

        setState(() {
          _controller.text = label.isNotEmpty ? label : initialId;
          _selectedId = initialId;
          _selectedLabel = label.isNotEmpty ? label : name;
          _loading = false;
        });
      } else {
        // Si falla, mostrar solo el ID
        setState(() {
          _controller.text = initialId;
          _selectedId = initialId;
          _selectedLabel = null;
          _loading = false;
        });
      }
    } catch (e) {
      // Si falla, mostrar solo el ID
      setState(() {
        _controller.text = initialId;
        _selectedId = initialId;
        _selectedLabel = null;
        _loading = false;
      });
    }
  }

  void _openSearch() async {
    // Para categorias y cualquier otro tipo que no sea cliente/cobrador,
    // mantener el modal existente
    if (widget.type == 'categoria') {
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

    // Para cobrador/cliente abrimos sugerencias inline
    if (_suggestions.isEmpty && _controller.text.trim().isNotEmpty) {
      await _performSearch(_controller.text.trim());
    }
  }

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  void _showOverlay() {
    if (!_useOverlay) {
      setState(() {
        _showInline = true;
      });
      return;
    }

    _overlayEntry?.remove();
    final overlay = Overlay.of(context);

    final entry = OverlayEntry(
      builder: (ctx) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _removeOverlay();
                },
              ),
            ),
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
    overlay.insert(entry);
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    if (_showInline) {
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
      child: TextFormField(
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
          _openSearch();
        },
        onChanged: (v) {
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
          _removeOverlay();
          FocusScope.of(context).unfocus();
        },
      ),
    );

    return _wrapWithInlineSuggestions(target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  List<Map<String, String>> getSuggestions() => _suggestions;

  @override
  void dispose() {
    _debounce?.cancel();
    _removeOverlay();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}

/// Modal de búsqueda para categorías
class _SearchModal extends ConsumerStatefulWidget {
  final String type;

  const _SearchModal({required this.type, Key? key}) : super(key: key);

  @override
  ConsumerState<_SearchModal> createState() => _SearchModalState();
}

class _SearchModalState extends ConsumerState<_SearchModal> {
  late TextEditingController _searchController;
  List<Map<String, String>> _filteredResults = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadCategories();
  }

  void _loadCategories() async {
    // ✅ Cargar categorías desde el backend (single source of truth)
    try {
      final svc = UserApiService();
      final resp = await svc.getClientCategories();

      if (resp['success'] == true && resp['data'] is List) {
        final List<dynamic> data = resp['data'] as List<dynamic>;
        final categories = data.map<Map<String, String>>((e) {
          final map = e as Map<String, dynamic>;
          final code = (map['code'] ?? '').toString();
          final name = (map['name'] ?? '').toString();
          final description = (map['description'] ?? '').toString();

          // Usar el código como ID y mostrar "Código - Nombre" como label
          final label = description.isNotEmpty
            ? '$code - $name ($description)'
            : '$code - $name';

          return {'id': code, 'label': label};
        }).toList();

        setState(() {
          _filteredResults = categories;
        });
      } else {
        // Fallback en caso de error
        setState(() {
          _filteredResults = [];
        });
      }
    } catch (e) {
      // Fallback en caso de error
      setState(() {
        _filteredResults = [];
      });
    }
  }

  void _filterResults(String query) {
    final q = query.toLowerCase();
    _loadCategories();
    if (query.isEmpty) return;
    setState(() {
      _filteredResults =
          _filteredResults.where((item) {
        return (item['label'] ?? '').toLowerCase().contains(q) ||
            (item['id'] ?? '').toLowerCase().contains(q);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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
          Text(
            'Seleccionar ${widget.type}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: _filterResults,
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredResults.length,
              itemBuilder: (context, index) {
                final item = _filteredResults[index];
                return ListTile(
                  title: Text(item['label'] ?? ''),
                  onTap: () {
                    Navigator.pop(context, item);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
