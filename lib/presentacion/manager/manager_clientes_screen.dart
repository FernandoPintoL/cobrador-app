import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';
import 'cliente_creditos_screen.dart';
import 'cliente_perfil_screen.dart';
import 'cliente_ubicacion_screen.dart';
import 'manager_cliente_form_screen.dart';

class ManagerClientesScreen extends ConsumerStatefulWidget {
  const ManagerClientesScreen({super.key});

  @override
  ConsumerState<ManagerClientesScreen> createState() =>
      _ManagerClientesScreenState();
}

class _ManagerClientesScreenState extends ConsumerState<ManagerClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroActual =
      'todos'; // 'todos', 'por_cobrador', 'directos', 'cobradores'
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
      appBar: RoleAppBar(
        title: _obtenerTituloAppBar(),
        role: 'manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () => _mostrarAsignacionRapida(),
            tooltip: 'Asignación Rápida',
          ),
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

    // Separar clientes directos de clientes de cobradores
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;

    final clientesDirectos = managerState.clientesDelManager
        .where((cliente) => cliente.assignedCobradorId == managerId)
        .length;

    final clientesDeCobradores = managerState.clientesDelManager
        .where(
          (cliente) =>
              cliente.assignedCobradorId != managerId &&
              cliente.assignedCobradorId != null,
        )
        .length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
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
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Clientes Directos',
                  '$clientesDirectos',
                  Icons.person_pin,
                  Colors.indigo,
                ),
                _buildStatItem(
                  'De Cobradores',
                  '$clientesDeCobradores',
                  Icons.group,
                  Colors.orange,
                ),
              ],
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
      case 'directos':
        return 'Solo clientes directos';
      case 'cobradores':
        return 'Solo clientes de cobradores';
      default:
        return 'Todos';
    }
  }

  String _obtenerTituloAppBar() {
    switch (_filtroActual) {
      case 'directos':
        return 'Mis Clientes Directos';
      case 'cobradores':
        return 'Clientes de Cobradores';
      case 'por_cobrador':
        return 'Clientes por Cobrador';
      default:
        return 'Gestión de Clientes';
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
        final cobradorList = managerState.cobradoresAsignados.where(
          (c) => c.id.toString() == cobradorId,
        );
        final cobrador = cobradorList.isNotEmpty ? cobradorList.first : null;

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
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;
    final esClienteDirecto = cliente.assignedCobradorId == managerId;

    return Card(
      margin: esEnGrupo
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: esClienteDirecto ? Colors.indigo : Colors.green,
              child: Text(
                cliente.nombre.isNotEmpty
                    ? cliente.nombre[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (esClienteDirecto)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_pin,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                cliente.nombre,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (esClienteDirecto)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Directo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cliente.email),
            if (cliente.telefono.isNotEmpty)
              Text(cliente.telefono, style: TextStyle(color: Colors.grey[600])),
            if (!esEnGrupo &&
                !esClienteDirecto &&
                cliente.assignedCobradorId != null)
              Text(
                'Cobrador: ${_obtenerNombreCobrador(cliente.assignedCobradorId!)}',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de contacto rápido
            if (cliente.telefono.isNotEmpty)
              ContactActionsWidget.buildContactButton(
                context: context,
                userName: cliente.nombre,
                phoneNumber: cliente.telefono,
                userRole: 'cliente',
                customMessage: ContactActionsWidget.getDefaultMessage(
                  'cliente',
                  cliente.nombre,
                ),
                color: RoleColors.clientePrimary,
                tooltip: 'Contactar cliente',
              ),
            // Menú contextual
            PopupMenuButton<String>(
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
                ContactActionsWidget.buildContactMenuItem(
                  phoneNumber: cliente.telefono,
                  value: 'contactar',
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  label: 'Llamar / WhatsApp',
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
                if (esClienteDirecto) ...[
                  const PopupMenuItem(
                    value: 'asignar_cobrador',
                    child: ListTile(
                      leading: Icon(Icons.person_add, color: Colors.orange),
                      title: Text('Asignar a Cobrador'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ] else if (cliente.assignedCobradorId != null) ...[
                  const PopupMenuItem(
                    value: 'asignar_cobrador',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz, color: Colors.purple),
                      title: Text('Reasignar Cobrador'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
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
          ],
        ),
      ),
    );
  }

  String _obtenerNombreCobrador(BigInt cobradorId) {
    final managerState = ref.read(managerProvider);
    final cobradorList = managerState.cobradoresAsignados.where(
      (c) => c.id == cobradorId,
    );
    final cobrador = cobradorList.isNotEmpty ? cobradorList.first : null;
    return cobrador?.nombre ?? 'Desconocido';
  }

  void _aplicarFiltros(List<Usuario> clientes) {
    String query = _searchController.text.toLowerCase();
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;

    _clientesFiltrados = clientes.where((cliente) {
      bool coincideBusqueda = true;
      bool cumpleFiltroTipo = true;

      // Filtro de búsqueda
      if (query.isNotEmpty) {
        coincideBusqueda =
            cliente.nombre.toLowerCase().contains(query) ||
            cliente.email.toLowerCase().contains(query) ||
            cliente.telefono.contains(query);
      }

      // Filtro por tipo de cliente
      switch (_filtroActual) {
        case 'directos':
          cumpleFiltroTipo = cliente.assignedCobradorId == managerId;
          break;
        case 'cobradores':
          cumpleFiltroTipo =
              cliente.assignedCobradorId != managerId &&
              cliente.assignedCobradorId != null;
          break;
        case 'todos':
        case 'por_cobrador':
        default:
          cumpleFiltroTipo = true;
          break;
      }

      return coincideBusqueda && cumpleFiltroTipo;
    }).toList();
  }

  void _manejarAccionCliente(String accion, Usuario cliente) {
    switch (accion) {
      case 'ver_creditos':
        _navegarACreditosCliente(cliente);
        break;
      case 'contactar':
        ContactActionsWidget.showContactDialog(
          context: context,
          userName: cliente.nombre,
          phoneNumber: cliente.telefono,
          userRole: 'cliente',
          customMessage: ContactActionsWidget.getDefaultMessage(
            'cliente',
            cliente.nombre,
          ),
        );
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
      case 'asignar_cobrador':
        _mostrarDialogoAsignarCobrador(cliente);
        break;
      case 'eliminar':
        _confirmarEliminarCliente(cliente);
        break;
    }
  }

  void _navegarACreditosCliente(Usuario cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteCreditosScreen(cliente: cliente),
      ),
    );
  }

  void _navegarAPerfilCliente(Usuario cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientePerfilScreen(cliente: cliente),
      ),
    );
  }

  void _navegarAUbicacionCliente(Usuario cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteUbicacionScreen(cliente: cliente),
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
              title: const Text('Todos los clientes'),
              subtitle: const Text('Mostrar todos los clientes en una lista'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'directos',
                groupValue: _filtroActual,
                onChanged: (value) {
                  setState(() {
                    _filtroActual = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: const Text('Clientes directos'),
              subtitle: const Text('Solo clientes asignados directamente a ti'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'cobradores',
                groupValue: _filtroActual,
                onChanged: (value) {
                  setState(() {
                    _filtroActual = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: const Text('Clientes de cobradores'),
              subtitle: const Text('Solo clientes asignados a tus cobradores'),
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

  void _mostrarAsignacionRapida() {
    final managerState = ref.read(managerProvider);
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;

    // Obtener clientes directos sin asignar
    final clientesDirectos = managerState.clientesDelManager
        .where((cliente) => cliente.assignedCobradorId == managerId)
        .toList();

    // Obtener cobradores disponibles
    final cobradores = managerState.cobradoresAsignados;

    if (cobradores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes cobradores asignados'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (clientesDirectos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes clientes directos para asignar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Asignación Rápida'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tienes ${clientesDirectos.length} clientes directos que puedes asignar a tus ${cobradores.length} cobradores.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: cobradores.length,
                  itemBuilder: (context, index) {
                    final cobrador = cobradores[index];
                    final clientesDelCobrador = managerState.clientesDelManager
                        .where((c) => c.assignedCobradorId == cobrador.id)
                        .length;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          cobrador.nombre.isNotEmpty
                              ? cobrador.nombre[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        cobrador.nombre,
                        style: const TextStyle(fontSize: 14),
                      ),
                      subtitle: Text(
                        '$clientesDelCobrador clientes asignados',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _mostrarSeleccionClientesParaCobrador(cobrador);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        child: const Text(
                          'Asignar',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _mostrarSeleccionClientesParaCobrador(Usuario cobrador) {
    final managerState = ref.read(managerProvider);
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;

    // Obtener solo clientes directos
    final clientesDirectos = managerState.clientesDelManager
        .where((cliente) => cliente.assignedCobradorId == managerId)
        .toList();

    if (clientesDirectos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay clientes directos para asignar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<Usuario> clientesSeleccionados = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Asignar clientes a ${cobrador.nombre}'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: Column(
              children: [
                Text(
                  'Selecciona los clientes que quieres asignar:',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: clientesDirectos.length,
                    itemBuilder: (context, index) {
                      final cliente = clientesDirectos[index];
                      final isSelected = clientesSeleccionados.contains(
                        cliente,
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              clientesSeleccionados.add(cliente);
                            } else {
                              clientesSeleccionados.remove(cliente);
                            }
                          });
                        },
                        title: Text(
                          cliente.nombre,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          cliente.email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        secondary: CircleAvatar(
                          backgroundColor: Colors.indigo,
                          radius: 20,
                          child: Text(
                            cliente.nombre.isNotEmpty
                                ? cliente.nombre[0].toUpperCase()
                                : 'C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: clientesSeleccionados.isEmpty
                  ? null
                  : () {
                      Navigator.pop(context);
                      _asignarClientesSeleccionados(
                        clientesSeleccionados,
                        cobrador,
                      );
                    },
              child: Text('Asignar ${clientesSeleccionados.length} cliente(s)'),
            ),
          ],
        ),
      ),
    );
  }

  void _asignarClientesSeleccionados(
    List<Usuario> clientes,
    Usuario cobrador,
  ) async {
    try {
      for (final cliente in clientes) {
        await ref
            .read(managerProvider.notifier)
            .asignarClienteACobrador(
              cliente.id.toString(),
              cobrador.id.toString(),
            );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${clientes.length} cliente(s) asignado(s) a ${cobrador.nombre}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _cargarDatos(); // Recargar los datos
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  void _mostrarDialogoAsignarCobrador(Usuario cliente) {
    final managerState = ref.read(managerProvider);
    final cobradores = managerState.cobradoresAsignados;
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;
    final esClienteDirecto = cliente.assignedCobradorId == managerId;

    if (cobradores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No tienes cobradores asignados para poder asignar clientes',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Asignar ${cliente.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!esClienteDirecto && cliente.assignedCobradorId != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este cliente ya está asignado a ${_obtenerNombreCobrador(cliente.assignedCobradorId!)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                esClienteDirecto
                    ? 'Selecciona el cobrador al que quieres asignar este cliente:'
                    : 'Selecciona el nuevo cobrador para este cliente:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Opción para asignar directamente al manager
              if (!esClienteDirecto)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo,
                    child: Text(
                      authState.usuario?.nombre.isNotEmpty == true
                          ? authState.usuario!.nombre[0].toUpperCase()
                          : 'M',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text('${authState.usuario?.nombre ?? 'Manager'} (Yo)'),
                  subtitle: const Text('Asignar como cliente directo'),
                  trailing: const Icon(Icons.person_pin, color: Colors.indigo),
                  onTap: () {
                    Navigator.pop(context);
                    _asignarClienteDirectamente(cliente);
                  },
                ),

              if (!esClienteDirecto) const Divider(),

              // Lista de cobradores
              ...cobradores.map(
                (cobrador) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
                      cobrador.nombre.isNotEmpty
                          ? cobrador.nombre[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(cobrador.nombre),
                  subtitle: Text(cobrador.email),
                  trailing: cliente.assignedCobradorId == cobrador.id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: cliente.assignedCobradorId == cobrador.id
                      ? null // Desactivar si ya está asignado a este cobrador
                      : () {
                          Navigator.pop(context);
                          _asignarClienteACobrador(cliente, cobrador);
                        },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _asignarClienteACobrador(Usuario cliente, Usuario cobrador) async {
    try {
      final success = await ref
          .read(managerProvider.notifier)
          .asignarClienteACobrador(
            cliente.id.toString(),
            cobrador.id.toString(),
          );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${cliente.nombre} ha sido asignado a ${cobrador.nombre}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos(); // Recargar los datos
      } else {
        final error = ref.read(managerProvider).error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar cliente: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _asignarClienteDirectamente(Usuario cliente) async {
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;

    if (managerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo obtener la información del manager'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await ref
          .read(managerProvider.notifier)
          .asignarClienteACobrador(cliente.id.toString(), managerId.toString());

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${cliente.nombre} ha sido asignado como cliente directo',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos(); // Recargar los datos
      } else {
        final error = ref.read(managerProvider).error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar cliente: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
