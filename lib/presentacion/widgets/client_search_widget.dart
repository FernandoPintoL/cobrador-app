import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/client_provider.dart';

/// Widget reutilizable para búsqueda de clientes tipo inputSearch
///
/// Funciona como un campo de búsqueda en tiempo real donde escribes
/// y aparecen resultados mientras buscas.
///
/// Puede usarse en dos modos:
/// 1. Inline: Búsqueda informal para registro rápido
/// 2. Dropdown: Búsqueda con validación estricta para formularios
class ClientSearchWidget extends ConsumerStatefulWidget {
  /// Modo de presentación: 'inline' o 'dropdown'
  /// Ambos usan inputSearch, la diferencia es el nivel de validación
  final String mode;

  /// Cliente actualmente seleccionado
  final Usuario? selectedClient;

  /// Callback cuando se selecciona un cliente
  final Function(Usuario?) onClientSelected;

  /// Texto placeholder para la búsqueda
  final String? hint;

  /// Si es campo requerido
  final bool isRequired;

  /// Texto de error a mostrar
  final String? errorText;

  /// Permitir crear nuevo cliente desde el buscador
  final bool allowCreate;

  /// Callback cuando se desea crear un nuevo cliente
  /// Recibe el texto de búsqueda actual como parámetro
  final Function(String)? onCreateClient;

  /// Permitir limpiar selección
  final bool allowClear;

  /// Mostrar información adicional del cliente
  final bool showClientDetails;

  const ClientSearchWidget({
    super.key,
    this.mode = 'inline', // 'inline' o 'dropdown'
    this.selectedClient,
    required this.onClientSelected,
    this.hint,
    this.isRequired = false,
    this.errorText,
    this.allowCreate = true,
    this.onCreateClient,
    this.allowClear = true,
    this.showClientDetails = true,
  });

  @override
  ConsumerState<ClientSearchWidget> createState() => _ClientSearchWidgetState();
}

class _ClientSearchWidgetState extends ConsumerState<ClientSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Usuario> _searchResults = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    // Si hay un cliente preseleccionado, mostrar su nombre
    if (widget.selectedClient != null) {
      _searchController.text = widget.selectedClient!.nombre;
    }
  }

  @override
  void didUpdateWidget(ClientSearchWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Actualizar el texto cuando cambia el cliente seleccionado desde el padre
    if (widget.selectedClient != oldWidget.selectedClient) {
      if (widget.selectedClient != null) {
        _searchController.text = widget.selectedClient!.nombre;
        setState(() {
          _searchResults = [];
          _showResults = false;
        });
      } else {
        _searchController.clear();
        setState(() {
          _searchResults = [];
          _showResults = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Busca clientes según el texto ingresado
  /// Busca en: nombre, teléfono, CI y categoría
  void _searchClients(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    final clientState = ref.read(clientProvider);
    final results = clientState.clientes.where((cliente) {
      final searchLower = query.toLowerCase();
      final nombre = cliente.nombre.toLowerCase();
      final telefono = cliente.telefono.toLowerCase();
      final ci = cliente.ci.toLowerCase();
      final email = cliente.email.toLowerCase();
      final direccion = cliente.direccion.toLowerCase();
      final categoria = (cliente.clientCategory ?? '').toLowerCase();

      return nombre.contains(searchLower) ||
          telefono.contains(searchLower) ||
          ci.contains(searchLower) ||
          email.contains(searchLower) ||
          direccion.contains(searchLower) ||
          categoria.contains(searchLower);
    }).toList();

    setState(() {
      _searchResults = results;
      _showResults = results.isNotEmpty;
    });
  }

  /// Selecciona un cliente y cierra los resultados
  void _selectClient(Usuario cliente) {
    setState(() {
      _searchController.text = cliente.nombre;
      _searchResults = [];
      _showResults = false;
    });
    _focusNode.unfocus();
    widget.onClientSelected(cliente);
  }

  /// Limpia la selección
  void _clearSelection() {
    setState(() {
      _searchController.clear();
      _searchResults = [];
      _showResults = false;
    });
    widget.onClientSelected(null);
  }

  /// Construye la información de un cliente para mostrar en la lista
  Widget _buildClientInfo(Usuario cliente, bool isDark) {
    final categoria = cliente.clientCategory?.toUpperCase() ?? 'B';

    Color categoriaColor;
    switch (categoria) {
      case 'A':
        categoriaColor = Colors.green;
        break;
      case 'C':
        categoriaColor = Colors.orange;
        break;
      default:
        categoriaColor = Colors.blue;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                cliente.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: categoriaColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: categoriaColor.withOpacity(0.5)),
              ),
              child: Text(
                'Cat. $categoria',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: categoriaColor,
                ),
              ),
            ),
          ],
        ),
        if (widget.showClientDetails) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.phone, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                cliente.telefono.isNotEmpty ? cliente.telefono : 'Sin teléfono',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
              ),
              const SizedBox(width: 12),
              Icon(Icons.credit_card, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  cliente.ci.isNotEmpty ? cliente.ci : 'Sin CI',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Renderiza el modo inline (búsqueda con resultados desplegables)
  Widget _buildInlineMode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hint ?? 'Buscar cliente por nombre, teléfono, CI...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.selectedClient != null && widget.allowClear
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            errorText: widget.errorText,
          ),
          onChanged: _searchClients,
          onTap: () {
            if (widget.selectedClient != null) {
              // Si hay un cliente seleccionado, limpiar para permitir nueva búsqueda
              _searchController.clear();
              _searchClients('');
            }
          },
        ),

        // Resultados de búsqueda
        if (_showResults && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[850] : Colors.white,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cliente = _searchResults[index];
                return ListTile(
                  dense: true,
                  title: _buildClientInfo(cliente, isDark),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _selectClient(cliente),
                );
              },
            ),
          ),
        ],

        // Botón para crear nuevo cliente (solo cuando hay búsqueda sin resultados y no hay cliente seleccionado)
        if (widget.allowCreate &&
            widget.onCreateClient != null &&
            _searchController.text.isNotEmpty &&
            _searchResults.isEmpty &&
            widget.selectedClient == null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => widget.onCreateClient!(_searchController.text),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Crear nuevo cliente'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ],
    );
  }

  /// Renderiza el modo dropdown (input con validación para formularios)
  Widget _buildDropdownMode(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.hint ?? 'Buscar cliente',
            hintText: 'Escribe para buscar...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.selectedClient != null && widget.allowClear
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSelection,
                  )
                : null,
            border: const OutlineInputBorder(),
            errorText: widget.errorText,
          ),
          onChanged: _searchClients,
          onTap: () {
            if (widget.selectedClient != null) {
              // Si hay un cliente seleccionado, limpiar para permitir nueva búsqueda
              _searchController.clear();
              _searchClients('');
            }
          },
        ),

        // Resultados de búsqueda
        if (_showResults && _searchResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: isDark ? Colors.grey[850] : Colors.white,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _searchResults.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cliente = _searchResults[index];
                return ListTile(
                  dense: true,
                  title: _buildClientInfo(cliente, isDark),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                  onTap: () => _selectClient(cliente),
                );
              },
            ),
          ),
        ],

        // Botón para crear nuevo cliente (solo cuando hay búsqueda sin resultados y no hay cliente seleccionado)
        if (widget.allowCreate &&
            widget.onCreateClient != null &&
            _searchController.text.isNotEmpty &&
            _searchResults.isEmpty &&
            widget.selectedClient == null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => widget.onCreateClient!(_searchController.text),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Crear nuevo cliente'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],

        // Mensaje de validación cuando es requerido y no hay selección
        if (widget.isRequired && widget.selectedClient == null && widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: TextStyle(
              color: Colors.red[700],
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return widget.mode == 'inline'
        ? _buildInlineMode(isDark)
        : _buildDropdownMode(isDark);
  }
}

/// Widget para mostrar información detallada del cliente seleccionado
class SelectedClientCard extends StatelessWidget {
  final Usuario cliente;
  final VoidCallback? onClear;
  final bool showActions;

  const SelectedClientCard({
    super.key,
    required this.cliente,
    this.onClear,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categoria = cliente.clientCategory?.toUpperCase() ?? 'B';

    Color categoriaColor;
    String categoriaLabel;
    switch (categoria) {
      case 'A':
        categoriaColor = Colors.green;
        categoriaLabel = 'Premium (A)';
        break;
      case 'C':
        categoriaColor = Colors.orange;
        categoriaLabel = 'Básico (C)';
        break;
      default:
        categoriaColor = Colors.blue;
        categoriaLabel = 'Estándar (B)';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Cliente Seleccionado',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              if (showActions && onClear != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onClear,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const Divider(),
          _buildInfoRow('Nombre:', cliente.nombre),
          _buildInfoRow('Categoría:', categoriaLabel, valueColor: categoriaColor),
          if (cliente.telefono.isNotEmpty)
            _buildInfoRow('Teléfono:', cliente.telefono),
          if (cliente.ci.isNotEmpty)
            _buildInfoRow('CI:', cliente.ci),
          if (cliente.email.isNotEmpty)
            _buildInfoRow('Email:', cliente.email),
          if (cliente.direccion.isNotEmpty)
            _buildInfoRow('Dirección:', cliente.direccion),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor,
                fontWeight: valueColor != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
