import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import 'manager_cliente_form_screen.dart';

class ManagerClientesScreen extends ConsumerStatefulWidget {
  const ManagerClientesScreen({super.key});

  @override
  ConsumerState<ManagerClientesScreen> createState() =>
      _ManagerClientesScreenState();
}

class _ManagerClientesScreenState extends ConsumerState<ManagerClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroActual = 'todos'; // 'todos', 'por_cobrador'
  List<Usuario> _clientesFiltrados = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();
      ref
          .read(managerProvider.notifier)
          .establecerManagerActual(authState.usuario!);
      ref.read(managerProvider.notifier).cargarClientesDelManager(managerId);
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    // Aplicar filtros a los clientes
    _aplicarFiltros(managerState.clientesDelManager);

    // Escuchar cambios en el estado
    ref.listen<ManagerState>(managerProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(managerProvider.notifier).limpiarMensajes();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes del Equipo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _mostrarMenuFiltros(),
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas rápidas
          _buildEstadisticasCard(managerState),

          // Barra de búsqueda
          _buildBarraBusqueda(),

          // Filtros activos
          if (_filtroActual != 'todos') _buildChipsFiltros(),

          // Lista de clientes
          Expanded(child: _buildListaClientes(managerState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navegarCrearCliente,
        child: const Icon(Icons.add),
        tooltip: 'Crear Cliente',
      ),
    );
  }

  Widget _buildEstadisticasCard(ManagerState managerState) {
    final totalClientes = managerState.clientesDelManager.length;
    final totalCobradores = managerState.cobradoresAsignados.length;
    final clientesPorCobrador = totalCobradores > 0
        ? (totalClientes / totalCobradores).toStringAsFixed(1)
        : '0';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total Clientes',
              '$totalClientes',
              Icons.business,
              Colors.blue,
            ),
            _buildStatItem(
              'Cobradores',
              '$totalCobradores',
              Icons.person,
              Colors.green,
            ),
            _buildStatItem(
              'Promedio',
              '$clientesPorCobrador/cobrador',
              Icons.analytics,
              Colors.orange,
            ),
          ],
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
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar clientes...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildChipsFiltros() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filtros activos: '),
          Chip(
            label: Text(_obtenerTextoFiltro()),
            onDeleted: () {
              setState(() {
                _filtroActual = 'todos';
              });
            },
          ),
        ],
      ),
    );
  }

  String _obtenerTextoFiltro() {
    switch (_filtroActual) {
      case 'por_cobrador':
        return 'Agrupados por cobrador';
      default:
        return 'Todos';
    }
  }

  Widget _buildListaClientes(ManagerState managerState) {
    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clientesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              managerState.clientesDelManager.isEmpty
                  ? 'No hay clientes en tu equipo'
                  : 'No se encontraron clientes',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            if (managerState.clientesDelManager.isEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Los clientes aparecerán aquí cuando tus cobradores tengan clientes asignados',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    if (_filtroActual == 'por_cobrador') {
      return _buildListaAgrupadaPorCobrador(managerState);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clientesFiltrados.length,
      itemBuilder: (context, index) {
        final cliente = _clientesFiltrados[index];
        return _buildClienteCard(cliente);
      },
    );
  }

  Widget _buildListaAgrupadaPorCobrador(ManagerState managerState) {
    // Agrupar clientes por cobrador
    final Map<String, List<Usuario>> clientesPorCobrador = {};

    for (final cliente in _clientesFiltrados) {
      final cobradorId =
          cliente.assignedCobradorId?.toString() ?? 'sin_asignar';
      if (!clientesPorCobrador.containsKey(cobradorId)) {
        clientesPorCobrador[cobradorId] = [];
      }
      clientesPorCobrador[cobradorId]!.add(cliente);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientesPorCobrador.keys.length,
      itemBuilder: (context, index) {
        final cobradorId = clientesPorCobrador.keys.elementAt(index);
        final clientes = clientesPorCobrador[cobradorId]!;

        // Buscar información del cobrador
        final cobrador = managerState.cobradoresAsignados
            .where((c) => c.id.toString() == cobradorId)
            .firstOrNull;

        return _buildGrupoCobrador(cobrador, clientes);
      },
    );
  }

  Widget _buildGrupoCobrador(Usuario? cobrador, List<Usuario> clientes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            cobrador?.nombre.isNotEmpty == true
                ? cobrador!.nombre[0].toUpperCase()
                : 'S',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cobrador?.nombre ?? 'Sin cobrador asignado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${clientes.length} cliente${clientes.length != 1 ? 's' : ''}',
        ),
        children: clientes
            .map((cliente) => _buildClienteCard(cliente, esEnGrupo: true))
            .toList(),
      ),
    );
  }

  Widget _buildClienteCard(Usuario cliente, {bool esEnGrupo = false}) {
    return Card(
      margin: esEnGrupo
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Text(
            cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : 'C',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cliente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cliente.email),
            if (cliente.telefono.isNotEmpty)
              Text(cliente.telefono, style: TextStyle(color: Colors.grey[600])),
            if (!esEnGrupo && cliente.assignedCobradorId != null)
              Text(
                'Cobrador: ${_obtenerNombreCobrador(cliente.assignedCobradorId!)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _manejarAccionCliente(value, cliente),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ver_creditos',
              child: ListTile(
                leading: Icon(Icons.account_balance_wallet),
                title: Text('Ver Créditos'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'ver_perfil',
              child: ListTile(
                leading: Icon(Icons.person),
                title: Text('Ver Perfil'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'ver_ubicacion',
              child: ListTile(
                leading: Icon(Icons.location_on),
                title: Text('Ver Ubicación'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.blue),
                title: Text('Editar Cliente'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Eliminar Cliente'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerNombreCobrador(BigInt cobradorId) {
    final managerState = ref.read(managerProvider);
    final cobrador = managerState.cobradoresAsignados
        .where((c) => c.id == cobradorId)
        .firstOrNull;
    return cobrador?.nombre ?? 'Desconocido';
  }

  void _aplicarFiltros(List<Usuario> clientes) {
    String query = _searchController.text.toLowerCase();

    _clientesFiltrados = clientes.where((cliente) {
      bool coincideBusqueda = true;

      if (query.isNotEmpty) {
        coincideBusqueda =
            cliente.nombre.toLowerCase().contains(query) ||
            cliente.email.toLowerCase().contains(query) ||
            cliente.telefono.contains(query);
      }

      return coincideBusqueda;
    }).toList();
  }

  void _manejarAccionCliente(String accion, Usuario cliente) {
    switch (accion) {
      case 'ver_creditos':
        _navegarACreditosCliente(cliente);
        break;
      case 'ver_perfil':
        _navegarAPerfilCliente(cliente);
        break;
      case 'ver_ubicacion':
        _navegarAUbicacionCliente(cliente);
        break;
      case 'editar':
        _navegarEditarCliente(cliente);
        break;
      case 'eliminar':
        _confirmarEliminarCliente(cliente);
        break;
    }
  }

  void _navegarACreditosCliente(Usuario cliente) {
    // TODO: Implementar navegación a créditos del cliente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver créditos de ${cliente.nombre} - En desarrollo'),
      ),
    );
  }

  void _navegarAPerfilCliente(Usuario cliente) {
    // TODO: Implementar navegación al perfil del cliente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver perfil de ${cliente.nombre} - En desarrollo'),
      ),
    );
  }

  void _navegarAUbicacionCliente(Usuario cliente) {
    // TODO: Implementar navegación a la ubicación del cliente
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver ubicación de ${cliente.nombre} - En desarrollo'),
      ),
    );
  }

  void _mostrarMenuFiltros() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros de visualización',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Radio<String>(
                value: 'todos',
                groupValue: _filtroActual,
                onChanged: (value) {
                  setState(() {
                    _filtroActual = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: const Text('Lista completa'),
              subtitle: const Text('Mostrar todos los clientes en una lista'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'por_cobrador',
                groupValue: _filtroActual,
                onChanged: (value) {
                  setState(() {
                    _filtroActual = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: const Text('Agrupados por cobrador'),
              subtitle: const Text(
                'Organizar clientes por su cobrador asignado',
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarCrearCliente() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ManagerClienteFormScreen(onClienteSaved: _cargarDatos),
      ),
    );
  }

  void _navegarEditarCliente(Usuario cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagerClienteFormScreen(
          cliente: cliente,
          onClienteSaved: _cargarDatos,
        ),
      ),
    );
  }

  void _confirmarEliminarCliente(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente a ${cliente.nombre}?\n\n'
          'Esta acción no se puede deshacer y el cliente será eliminado del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _eliminarCliente(cliente);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _eliminarCliente(Usuario cliente) async {
    try {
      await ref
          .read(userManagementProvider.notifier)
          .eliminarUsuario(cliente.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente ${cliente.nombre} eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos(); // Recargar la lista
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
