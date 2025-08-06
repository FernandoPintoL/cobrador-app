import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/usuario.dart';

class ManagerDirectClientsScreen extends ConsumerStatefulWidget {
  const ManagerDirectClientsScreen({super.key});

  @override
  ConsumerState<ManagerDirectClientsScreen> createState() =>
      _ManagerDirectClientsScreenState();
}

class _ManagerDirectClientsScreenState
    extends ConsumerState<ManagerDirectClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    if (_hasLoadedInitialData) return;

    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      _hasLoadedInitialData = true;
      final managerId = authState.usuario!.id.toString();

      // Cargar clientes directos del manager
      await ref
          .read(clientProvider.notifier)
          .cargarClientesDirectosManager(managerId);

      // Cargar clientes sin asignar para poder asignar nuevos
      await ref.read(clientProvider.notifier).cargarClientesSinAsignar();
    }
  }

  Future<void> _recargarDatos() async {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();
      await ref
          .read(clientProvider.notifier)
          .cargarClientesDirectosManager(managerId);
      await ref.read(clientProvider.notifier).cargarClientesSinAsignar();
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);

    // Escuchar cambios para mostrar mensajes
    ref.listen<ClientState>(clientProvider, (previous, next) {
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Clientes Directos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _mostrarDialogoAsignarClientes(),
            tooltip: 'Asignar Clientes Directos',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Panel de estadísticas
          _buildStatsPanel(clientState),

          // Barra de búsqueda
          _buildSearchBar(),

          // Lista de clientes directos
          Expanded(child: _buildClientesList(clientState)),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(ClientState clientState) {
    final totalClientes = clientState.clientesDirectosManager.length;
    final clientesSinAsignar = clientState.clientesSinAsignar.length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Clientes Directos',
                totalClientes.toString(),
                Icons.business,
                Colors.blue,
              ),
              _buildStatItem(
                'Disponibles',
                clientesSinAsignar.toString(),
                Icons.person_add,
                Colors.green,
              ),
              _buildStatItem(
                'Total Gestionados',
                (totalClientes).toString(),
                Icons.groups,
                Colors.purple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
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

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar clientes directos...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _buscarClientes('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: _buscarClientes,
      ),
    );
  }

  Widget _buildClientesList(ClientState clientState) {
    if (clientState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final clientesDirectos = clientState.clientesDirectosManager;

    if (clientesDirectos.isEmpty) {
      return _buildEmptyState();
    }

    // Filtrar clientes por búsqueda
    final clientesFiltrados = _searchController.text.isEmpty
        ? clientesDirectos
        : clientesDirectos.where((cliente) {
            final searchLower = _searchController.text.toLowerCase();
            return cliente.nombre.toLowerCase().contains(searchLower) ||
                cliente.email.toLowerCase().contains(searchLower) ||
                (cliente.telefono.toLowerCase().contains(searchLower));
          }).toList();

    if (clientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No se encontraron clientes',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _recargarDatos,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: clientesFiltrados.length,
        itemBuilder: (context, index) {
          final cliente = clientesFiltrados[index];
          return _buildClienteCard(cliente);
        },
      ),
    );
  }

  Widget _buildClienteCard(Usuario cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  radius: 24,
                  child: Text(
                    cliente.nombre.isNotEmpty
                        ? cliente.nombre[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.email,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (cliente.telefono.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              cliente.telefono,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _manejarAccionCliente(value, cliente),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'ver_detalle',
                      child: ListTile(
                        leading: Icon(Icons.visibility, color: Colors.blue),
                        title: Text('Ver Detalle'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'editar',
                      child: ListTile(
                        leading: Icon(Icons.edit, color: Colors.green),
                        title: Text('Editar Cliente'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'remover',
                      child: ListTile(
                        leading: Icon(
                          Icons.remove_circle,
                          color: Colors.orange,
                        ),
                        title: Text('Remover Asignación'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Información adicional
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Cliente Directo',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'ACTIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No tienes clientes directos',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Asigna clientes directamente para gestionarlos',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _mostrarDialogoAsignarClientes(),
            icon: const Icon(Icons.person_add),
            label: const Text('Asignar Clientes Directos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _buscarClientes(String query) {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();
      ref
          .read(clientProvider.notifier)
          .cargarClientesDirectosManager(
            managerId,
            search: query.isEmpty ? null : query,
          );
    }
  }

  void _manejarAccionCliente(String accion, Usuario cliente) {
    switch (accion) {
      case 'ver_detalle':
        _verDetalleCliente(cliente);
        break;
      case 'editar':
        _editarCliente(cliente);
        break;
      case 'remover':
        _confirmarRemoverCliente(cliente);
        break;
    }
  }

  void _verDetalleCliente(Usuario cliente) {
    // TODO: Implementar navegación a detalle del cliente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver detalle de ${cliente.nombre} - En desarrollo'),
      ),
    );
  }

  void _editarCliente(Usuario cliente) {
    // TODO: Implementar navegación a edición del cliente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar ${cliente.nombre} - En desarrollo')),
    );
  }

  void _confirmarRemoverCliente(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoción'),
        content: Text(
          '¿Estás seguro de que deseas remover a ${cliente.nombre} de tus clientes directos?\n\n'
          'El cliente quedará sin asignar y disponible para otros managers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removerCliente(cliente);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _removerCliente(Usuario cliente) async {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();

      final success = await ref
          .read(clientProvider.notifier)
          .removerClienteDirectoDelManager(managerId, cliente.id.toString());

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${cliente.nombre} removido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _mostrarDialogoAsignarClientes() {
    showDialog(
      context: context,
      builder: (context) => _AsignarClientesDirectosDialog(),
    );
  }
}

// Dialog para asignar clientes directos
class _AsignarClientesDirectosDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_AsignarClientesDirectosDialog> createState() =>
      _AsignarClientesDirectosDialogState();
}

class _AsignarClientesDirectosDialogState
    extends ConsumerState<_AsignarClientesDirectosDialog> {
  final Set<String> _clientesSeleccionados = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);
    final clientesSinAsignar = clientState.clientesSinAsignar;

    // Filtrar clientes por búsqueda
    final clientesFiltrados = _searchController.text.isEmpty
        ? clientesSinAsignar
        : clientesSinAsignar.where((cliente) {
            final searchLower = _searchController.text.toLowerCase();
            return cliente.nombre.toLowerCase().contains(searchLower) ||
                cliente.email.toLowerCase().contains(searchLower);
          }).toList();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Asignar Clientes Directos',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Estadísticas rápidas
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '${clientesSinAsignar.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text('Disponibles', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        '${_clientesSeleccionados.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'Seleccionados',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes disponibles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Lista de clientes disponibles
            Expanded(
              child: clientesFiltrados.isEmpty
                  ? const Center(
                      child: Text('No hay clientes disponibles para asignar'),
                    )
                  : ListView.builder(
                      itemCount: clientesFiltrados.length,
                      itemBuilder: (context, index) {
                        final cliente = clientesFiltrados[index];
                        final isSelected = _clientesSeleccionados.contains(
                          cliente.id.toString(),
                        );

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _clientesSeleccionados.add(
                                  cliente.id.toString(),
                                );
                              } else {
                                _clientesSeleccionados.remove(
                                  cliente.id.toString(),
                                );
                              }
                            });
                          },
                          title: Text(cliente.nombre),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cliente.email),
                              if (cliente.telefono.isNotEmpty)
                                Text(cliente.telefono),
                            ],
                          ),
                          secondary: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              cliente.nombre.isNotEmpty
                                  ? cliente.nombre[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Botones de acción
            Row(
              children: [
                Text('${_clientesSeleccionados.length} seleccionados'),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _clientesSeleccionados.isEmpty
                      ? null
                      : () => _asignarClientesSeleccionados(),
                  child: const Text('Asignar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _asignarClientesSeleccionados() async {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();

      final success = await ref
          .read(clientProvider.notifier)
          .asignarClientesDirectamenteAManager(
            managerId,
            _clientesSeleccionados.toList(),
          );

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_clientesSeleccionados.length} clientes asignados exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
