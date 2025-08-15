import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/contact_actions_widget.dart';
import '../manager/manager_cliente_form_screen.dart';
import '../manager/cliente_creditos_screen.dart';
import '../manager/cliente_perfil_screen.dart';
import '../manager/cliente_ubicacion_screen.dart';
import '../manager/manager_client_assignment_screen.dart';

/// Pantalla genérica para mostrar clientes
/// Se adapta según el rol del usuario:
/// - Manager: Muestra todos sus clientes o los de un cobrador específico
/// - Cobrador: Muestra solo sus clientes asignados
class ClientesScreen extends ConsumerStatefulWidget {
  final String? userRole; // 'manager' o 'cobrador'
  final Usuario?
  cobrador; // Solo se usa cuando un manager ve clientes de un cobrador específico

  const ClientesScreen({super.key, this.userRole, this.cobrador});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Variables para filtros avanzados (managers)
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
    final currentUserRole = widget.userRole ?? _getUserRole(authState.usuario);

    if (currentUserRole == 'manager') {
      final managerId = authState.usuario!.id.toString();

      // Establecer manager actual y cargar datos completos
      ref
          .read(managerProvider.notifier)
          .establecerManagerActual(authState.usuario!);

      if (widget.cobrador != null) {
        // Manager viendo clientes de un cobrador específico
        ref
            .read(managerProvider.notifier)
            .cargarClientesDelManager(widget.cobrador!.id.toString());
      } else {
        // Manager viendo todos sus clientes
        ref.read(managerProvider.notifier).cargarClientesDelManager(managerId);
      }

      // Cargar cobradores asignados para funcionalidades avanzadas
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
    } else if (currentUserRole == 'cobrador') {
      // Cobrador viendo sus propios clientes
      ref
          .read(clientProvider.notifier)
          .cargarClientes(cobradorId: authState.usuario!.id.toString());
    }
  }

  String _getUserRole(Usuario? usuario) {
    if (usuario == null || usuario.roles.isEmpty) {
      return '';
    }

    final roles = usuario.roles.map((role) => role.toLowerCase()).toList();

    // Priorizar manager sobre otros roles
    if (roles.contains('manager')) {
      return 'manager';
    } else if (roles.contains('cobrador')) {
      return 'cobrador';
    } else if (roles.contains('client')) {
      return 'client';
    }

    // Si no encuentra un rol conocido, devolver el primero
    return roles.first;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserRole = widget.userRole ?? _getUserRole(authState.usuario);

    // Obtener clientes según el rol
    final todosLosClientes = _obtenerClientesSegunRol(currentUserRole);

    // Aplicar filtros
    _aplicarFiltros(todosLosClientes, currentUserRole);

    // Escuchar cambios en el estado para managers
    if (currentUserRole == 'manager') {
      ref.listen<ManagerState>(managerProvider, (previous, next) {
        if (next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
          );
          ref.read(managerProvider.notifier).limpiarMensajes();
        }
      });
    }

    return Scaffold(
      appBar: _buildAppBar(currentUserRole),
      body: Column(
        children: [
          // Estadísticas de clientes
          _buildEstadisticasClientes(currentUserRole),

          // Barra de búsqueda
          _buildBarraBusqueda(),

          // Filtros activos (solo para managers)
          if (currentUserRole == 'manager' && _filtroActual != 'todos')
            _buildChipsFiltros(),

          // Información del usuario/cobrador
          _buildUsuarioInfo(currentUserRole),

          // Lista de clientes
          Expanded(
            child: _buildListaClientes(currentUserRole, _clientesFiltrados),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(currentUserRole),
    );
  }

  void _aplicarFiltros(List<Usuario> todosLosClientes, String currentUserRole) {
    if (currentUserRole != 'manager') {
      // Para cobradores, solo filtrar por búsqueda
      _clientesFiltrados = todosLosClientes
          .where(
            (cliente) =>
                cliente.nombre.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                cliente.email.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                cliente.telefono.contains(_searchQuery),
          )
          .toList();
      return;
    }

    // Para managers, aplicar filtros avanzados
    List<Usuario> clientesFiltrados = todosLosClientes;

    // Aplicar filtro por búsqueda
    if (_searchQuery.isNotEmpty) {
      clientesFiltrados = clientesFiltrados
          .where(
            (cliente) =>
                cliente.nombre.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                cliente.email.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                cliente.telefono.contains(_searchQuery),
          )
          .toList();
    }

    // Aplicar filtro por asignación
    switch (_filtroActual) {
      case 'asignados':
        clientesFiltrados = clientesFiltrados
            .where((cliente) => cliente.assignedCobradorId != null)
            .toList();
        break;
      case 'no_asignados':
        clientesFiltrados = clientesFiltrados
            .where((cliente) => cliente.assignedCobradorId == null)
            .toList();
        break;
      case 'todos':
      default:
        // No filtrar por asignación
        break;
    }

    _clientesFiltrados = clientesFiltrados;
  }

  PreferredSizeWidget _buildAppBar(String currentUserRole) {
    return AppBar(
      title: Text(_getTituloSegunContexto(currentUserRole)),
      backgroundColor: RoleColors.getPrimaryColor(currentUserRole),
      foregroundColor: Colors.white,
      actions: [
        if (currentUserRole == 'manager') ...[
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
        ],
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _mostrarFormularioCliente(currentUserRole),
          tooltip: 'Agregar Cliente',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            _cargarDatos();
          },
          tooltip: 'Actualizar',
        ),
      ],
    );
  }

  Widget _buildEstadisticasClientes(String currentUserRole) {
    if (currentUserRole == 'manager') {
      final managerState = ref.watch(managerProvider);
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
    } else {
      // Para cobradores, mostrar estadísticas simples
      final totalClientes = _clientesFiltrados.length;
      return Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Mis Clientes',
                '$totalClientes',
                Icons.business,
                Colors.blue,
              ),
            ],
          ),
        ),
      );
    }
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
      case 'asignados':
        return 'Clientes asignados';
      case 'no_asignados':
        return 'Clientes sin asignar';
      default:
        return 'Todos';
    }
  }

  Widget _buildFloatingActionButton(String currentUserRole) {
    return FloatingActionButton(
      onPressed: () => _mostrarFormularioCliente(currentUserRole),
      child: const Icon(Icons.add),
      tooltip: 'Crear Cliente',
    );
  }

  void _mostrarFormularioCliente(String currentUserRole) {
    // Siempre navegar a ManagerClienteFormScreen para una experiencia unificada
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ManagerClienteFormScreen(onClienteSaved: _cargarDatos),
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
              subtitle: const Text('Mostrar todos los clientes'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'asignados',
                groupValue: _filtroActual,
                onChanged: (value) {
                  setState(() {
                    _filtroActual = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: const Text('Clientes asignados'),
              subtitle: const Text('Solo clientes con cobrador asignado'),
            ),
            ListTile(
              leading: Radio<String>(
                value: 'no_asignados',
                groupValue: _filtroActual,
                onChanged: (value) {
                  setState(() {
                    _filtroActual = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              title: const Text('Clientes sin asignar'),
              subtitle: const Text('Solo clientes sin cobrador asignado'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAsignacionRapida() {
    // Implementación similar a manager_clientes_screen
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
                          // Aquí llamarías a _mostrarSeleccionClientesParaCobrador
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

  String _getTituloSegunContexto(String role) {
    if (widget.cobrador != null) {
      return 'Clientes de ${widget.cobrador!.nombre}';
    }

    switch (role) {
      case 'manager':
        return 'Mis Clientes';
      case 'cobrador':
        return 'Mis Clientes';
      default:
        return 'Clientes';
    }
  }

  List<Usuario> _obtenerClientesSegunRol(String role) {
    final authState = ref.watch(authProvider);

    if (role == 'manager') {
      final managerState = ref.watch(managerProvider);
      return managerState.clientesDelManager;
    } else if (role == 'cobrador') {
      final clientState = ref.watch(clientProvider);
      // Filtrar clientes que están asignados a este cobrador
      return clientState.clientes
          .where(
            (cliente) => cliente.assignedCobradorId == authState.usuario?.id,
          )
          .toList();
    }
    return [];
  }

  bool _estaLoading(String role) {
    if (role == 'manager') {
      final managerState = ref.watch(managerProvider);
      return managerState.isLoading;
    } else if (role == 'cobrador') {
      final clientState = ref.watch(clientProvider);
      return clientState.isLoading;
    }
    return false;
  }

  Widget _buildUsuarioInfo(String role) {
    if (widget.cobrador != null) {
      // Mostrando información del cobrador específico
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RoleColors.cobradorSecondary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: RoleColors.cobradorPrimary.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: RoleColors.cobradorPrimary,
              foregroundColor: Colors.white,
              child: Text(
                widget.cobrador!.nombre.isNotEmpty
                    ? widget.cobrador!.nombre[0].toUpperCase()
                    : 'C',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cobrador!.nombre,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Cobrador • ${widget.cobrador!.email}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
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

  Widget _buildListaClientes(String role, List<Usuario> clientes) {
    final isLoading = _estaLoading(role);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron clientes\ncon la búsqueda "$_searchQuery"'
                  : 'No hay clientes asignados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: const Text('Limpiar búsqueda'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(cliente, role);
      },
    );
  }

  Widget _buildClienteCard(Usuario cliente, String role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: RoleColors.clientePrimary,
          foregroundColor: Colors.white,
          child: Text(
            cliente.nombre.isNotEmpty ? cliente.nombre[0].toUpperCase() : 'C',
            style: const TextStyle(fontWeight: FontWeight.bold),
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
            Text(cliente.telefono),
            if (cliente.roles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RoleColors.clientePrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  cliente.roles.first.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de contacto directo
            ContactActionsWidget.buildContactButton(
              context: context,
              userName: cliente.nombre,
              phoneNumber: cliente.telefono,
              userRole: 'Cliente',
              customMessage: ContactActionsWidget.getDefaultMessage(
                'cliente',
                cliente.nombre,
              ),
              color: RoleColors.clientePrimary,
              tooltip: 'Contactar cliente',
            ),
            // Menú contextual
            PopupMenuButton<String>(
              onSelected: (value) =>
                  _manejarAccionCliente(value, cliente, role),
              itemBuilder: (context) => _buildMenuItems(cliente, role),
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(Usuario cliente, String role) {
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;
    final esClienteDirecto =
        role == 'manager' && cliente.assignedCobradorId == managerId;

    final items = <PopupMenuEntry<String>>[
      const PopupMenuItem(
        value: 'ver_creditos',
        child: ListTile(
          leading: Icon(Icons.account_balance_wallet, color: Colors.green),
          title: Text('Ver Créditos'),
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
          leading: Icon(Icons.person, color: Colors.purple),
          title: Text('Ver Perfil'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
      const PopupMenuItem(
        value: 'ubicacion',
        child: ListTile(
          leading: Icon(Icons.location_on, color: Colors.orange),
          title: Text('Ver Ubicación'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ];

    // Agregar opciones específicas del manager
    if (role == 'manager') {
      items.addAll([
        const PopupMenuDivider(),
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
            value: 'reasignar',
            child: ListTile(
              leading: Icon(Icons.swap_horiz, color: Colors.blue),
              title: Text('Reasignar Cobrador'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ]);
    }

    // Agregar opción de eliminar (disponible para ambos roles)
    items.addAll([
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'eliminar',
        child: ListTile(
          leading: Icon(Icons.delete, color: Colors.red),
          title: Text('Eliminar Cliente'),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ]);

    return items;
  }

  void _manejarAccionCliente(String accion, Usuario cliente, String role) {
    switch (accion) {
      case 'ver_creditos':
        _navegarACreditosCliente(cliente);
        break;
      case 'editar':
        // Siempre usar el formulario unificado para editar
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManagerClienteFormScreen(
              cliente: cliente,
              onClienteSaved: _cargarDatos,
            ),
          ),
        );
        break;
      case 'contactar':
        ContactActionsWidget.showContactDialog(
          context: context,
          userName: cliente.nombre,
          phoneNumber: cliente.telefono,
          userRole: 'Cliente',
          customMessage: ContactActionsWidget.getDefaultMessage(
            'cliente',
            cliente.nombre,
          ),
        );
        break;
      case 'ver_perfil':
        _navegarAPerfilCliente(cliente);
        break;
      case 'ubicacion':
        _mostrarUbicacionCliente(cliente);
        break;
      case 'asignar_cobrador':
        if (role == 'manager') {
          _mostrarDialogoAsignarCobrador(cliente);
        }
        break;
      case 'reasignar':
        if (role == 'manager') {
          _mostrarDialogoReasignar(cliente);
        }
        break;
      case 'eliminar':
        _confirmarEliminarCliente(cliente);
        break;
    }
  }

  void _navegarAPerfilCliente(Usuario cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientePerfilScreen(cliente: cliente),
      ),
    );
  }

  void _mostrarDialogoAsignarCobrador(Usuario cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ManagerClientAssignmentScreen()),
    );
  }

  void _navegarACreditosCliente(Usuario cliente) {
    // Tanto managers como cobradores pueden ver créditos de clientes
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteCreditosScreen(cliente: cliente),
      ),
    );
  }

  void _mostrarUbicacionCliente(Usuario cliente) {
    final authState = ref.read(authProvider);
    final currentUserRole = _getUserRole(authState.usuario);

    if (currentUserRole == 'manager') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClienteUbicacionScreen(cliente: cliente),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Ubicación de ${cliente.nombre}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cliente.direccion.isNotEmpty) ...[
                const Text(
                  'Dirección:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(cliente.direccion),
                const SizedBox(height: 16),
              ],
              if (cliente.latitud != null && cliente.longitud != null) ...[
                const Text(
                  'Coordenadas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text('Lat: ${cliente.latitud}'),
                Text('Lng: ${cliente.longitud}'),
              ] else ...[
                const Text(
                  'No hay información de ubicación disponible',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            if (cliente.latitud != null && cliente.longitud != null)
              TextButton(
                onPressed: () {
                  // TODO: Implementar navegación al mapa
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Abrir en mapa - En desarrollo'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                child: const Text('Ver en Mapa'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    }
  }

  void _mostrarDialogoReasignar(Usuario cliente) {
    final authState = ref.read(authProvider);
    final currentUserRole = _getUserRole(authState.usuario);

    if (currentUserRole == 'manager') {
      // Implementar la funcionalidad completa de asignación de cobradores
      final managerState = ref.read(managerProvider);
      final cobradores = managerState.cobradoresAsignados;
      final managerId = authState.usuario?.id;
      final esClienteDirecto = cliente.assignedCobradorId == managerId;

      if (cobradores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No tienes cobradores asignados para poder reasignar clientes',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reasignar ${cliente.nombre}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selecciona el nuevo cobrador para este cliente:',
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
                    title: Text(
                      '${authState.usuario?.nombre ?? 'Manager'} (Yo)',
                    ),
                    subtitle: const Text('Asignar como cliente directo'),
                    trailing: const Icon(
                      Icons.person_pin,
                      color: Colors.indigo,
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _reasignarClienteDirectamente(cliente);
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
                        ? null
                        : () {
                            Navigator.pop(context);
                            _reasignarClienteACobrador(cliente, cobrador);
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reasignar cliente ${cliente.nombre} - En desarrollo'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _reasignarClienteDirectamente(Usuario cliente) async {
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
              '${cliente.nombre} ha sido reasignado como cliente directo',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos(); // Recargar los datos
      } else {
        final error = ref.read(managerProvider).error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reasignar cliente: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reasignar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _reasignarClienteACobrador(Usuario cliente, Usuario cobrador) async {
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
              '${cliente.nombre} ha sido reasignado a ${cobrador.nombre}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        _cargarDatos(); // Recargar los datos
      } else {
        final error = ref.read(managerProvider).error ?? 'Error desconocido';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al reasignar cliente: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reasignar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Método para confirmar eliminación de cliente
  void _confirmarEliminarCliente(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que deseas eliminar el cliente?'),
            const SizedBox(height: 8),
            Text(
              'Cliente: ${cliente.nombre}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Email: ${cliente.email}'),
            Text('Teléfono: ${cliente.telefono}'),
            const SizedBox(height: 16),
            const Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  // Método para eliminar cliente
  Future<void> _eliminarCliente(Usuario cliente) async {
    final authState = ref.read(authProvider);
    final currentUserRole = _getUserRole(authState.usuario);

    try {
      if (currentUserRole == 'manager') {
        // TODO: Implementar eliminarCliente en manager provider
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Eliminar cliente ${cliente.nombre} desde manager - En desarrollo',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else if (currentUserRole == 'cobrador') {
        await ref
            .read(clientProvider.notifier)
            .eliminarCliente(
              id: cliente.id.toString(),
              cobradorId: authState.usuario!.id.toString(),
            );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente ${cliente.nombre} eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al eliminar cliente: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
