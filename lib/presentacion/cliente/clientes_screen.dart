import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/contact_actions_widget.dart';
import '../widgets/role_widgets.dart';
import '../widgets/profile_image_widget.dart';
import '../../ui/widgets/client_category_chip.dart';
import 'cliente_form_screen.dart';
import 'cliente_creditos_screen.dart';
import 'cliente_perfil_screen.dart';
import 'location_picker_screen.dart';
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
      'todos'; // 'todos', 'asignados', 'no_asignados'
  List<Usuario> _clientesFiltrados = [];

  // Nuevas variables para búsqueda avanzada
  bool _mostrarFiltrosAvanzados = false;
  String _tipoFiltroActual = 'busqueda_general'; // 'busqueda_general', 'nombre', 'email', 'telefono', 'ci', 'categoria'
  final TextEditingController _filtroNombreController = TextEditingController();
  final TextEditingController _filtroEmailController = TextEditingController();
  final TextEditingController _filtroTelefonoController = TextEditingController();
  final TextEditingController _filtroCiController = TextEditingController();
  String _filtroCategoriaSeleccionada = '';

  // Obtener color según categoría del cliente
  Color _getCategoryColor(String? category) {
    final cat = (category ?? 'B').toUpperCase();
    switch (cat) {
      case 'A':
        return Colors.amber;
      case 'C':
        return Colors.deepOrange;
      case 'B':
      default:
        return RoleColors.clientePrimary;
    }
  }

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
        // Manager viendo clientes de un cobrador específico - USAR ENDPOINT CORRECTO
        // Usa GET /api/users/{cobradorId}/clients
        ref
            .read(managerProvider.notifier)
            .cargarClientesDelCobrador(widget.cobrador!.id.toString());
      } else {
        // Manager viendo todos sus clientes (directos + de cobradores)
        // Usa GET /api/users/{managerId}/manager-clients
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

    // Escuchar cambios en el estado para managers - CORREGIDO para evitar ciclo infinito
    if (currentUserRole == 'manager') {
      ref.listen<ManagerState>(managerProvider, (previous, next) {
        // Solo procesar si realmente cambió el error o successMessage
        if (previous?.error != next.error && next.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
          );
          // Usar Future.microtask para evitar modificar el estado durante el build
          Future.microtask(() => ref.read(managerProvider.notifier).limpiarMensajes());
        }

        if (previous?.successMessage != next.successMessage && next.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
          );
          // Usar Future.microtask para evitar modificar el estado durante el build
          Future.microtask(() => ref.read(managerProvider.notifier).limpiarMensajes());
        }
      });
    }

    return Scaffold(
      appBar: _buildAppBar(currentUserRole),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Estadísticas de clientes
          // _buildEstadisticasClientes(currentUserRole),

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
    _searchQuery = _searchController.text;

    // Lógica unificada para todos los roles
    List<Usuario> clientesFiltrados = todosLosClientes;

    // Aplicar búsqueda avanzada basada en el tipo de filtro
    if (_mostrarFiltrosAvanzados) {
      // Usar filtros específicos por campo
      switch (_tipoFiltroActual) {
        case 'nombre':
          final nombreQuery = _filtroNombreController.text;
          if (nombreQuery.isNotEmpty) {
            clientesFiltrados = clientesFiltrados
                .where((cliente) => cliente.nombre.toLowerCase().contains(
                      nombreQuery.toLowerCase(),
                    ))
                .toList();
          }
          break;
        case 'email':
          final emailQuery = _filtroEmailController.text;
          if (emailQuery.isNotEmpty) {
            clientesFiltrados = clientesFiltrados
                .where((cliente) => cliente.email.toLowerCase().contains(
                      emailQuery.toLowerCase(),
                    ))
                .toList();
          }
          break;
        case 'telefono':
          final telefonoQuery = _filtroTelefonoController.text;
          if (telefonoQuery.isNotEmpty) {
            clientesFiltrados = clientesFiltrados
                .where((cliente) => cliente.telefono.contains(telefonoQuery))
                .toList();
          }
          break;
        case 'ci':
          final ciQuery = _filtroCiController.text;
          if (ciQuery.isNotEmpty) {
            clientesFiltrados = clientesFiltrados
                .where((cliente) => cliente.ci.toLowerCase().contains(
                      ciQuery.toLowerCase(),
                    ))
                .toList();
          }
          break;
        case 'categoria':
          if (_filtroCategoriaSeleccionada.isNotEmpty) {
            clientesFiltrados = clientesFiltrados
                .where((cliente) =>
                    (cliente.clientCategory?.toLowerCase() ?? '') ==
                    _filtroCategoriaSeleccionada.toLowerCase())
                .toList();
          }
          break;
        case 'busqueda_general':
        default:
          // Búsqueda general en todos los campos (comportamiento por defecto)
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
                      cliente.telefono.contains(_searchQuery) ||
                      cliente.ci.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      cliente.id.toString().contains(_searchQuery) ||
                      (cliente.clientCategory?.toLowerCase() ?? '').contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
          }
          break;
      }
    } else {
      // Búsqueda general tradicional mejorada para todos los roles
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
                  cliente.telefono.contains(_searchQuery) ||
                  cliente.ci.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  cliente.id.toString().contains(_searchQuery) ||
                  (cliente.clientCategory?.toLowerCase() ?? '').contains(
                    _searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }
    }

    // Aplicar filtros específicos del manager (solo para managers)
    if (currentUserRole == 'manager') {
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
            ClienteFormScreen(onClienteSaved: _cargarDatos),
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
            ProfileAvatarWidget(
              role: 'cobrador',
              userName: widget.cobrador!.nombre,
              profileImagePath: widget.cobrador!.profileImage,
              radius: 25,
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
    final authState = ref.read(authProvider);
    final currentUserRole = widget.userRole ?? _getUserRole(authState.usuario);

    return Column(
      children: [
        // Barra de búsqueda principal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _mostrarFiltrosAvanzados
                  ? 'Use los filtros específicos abajo...'
                  : 'Buscar por nombre, email, teléfono, CI, ID o categoría...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  // Filtros avanzados disponibles para todos los roles
                  IconButton(
                    icon: AnimatedRotation(
                      turns: _mostrarFiltrosAvanzados ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.tune,
                        color: _mostrarFiltrosAvanzados
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _mostrarFiltrosAvanzados = !_mostrarFiltrosAvanzados;
                        if (!_mostrarFiltrosAvanzados) {
                          // Limpiar filtros específicos cuando se desactiva el modo avanzado
                          _limpiarFiltrosEspecificos();
                        }
                      });
                    },
                    tooltip: _mostrarFiltrosAvanzados ? 'Ocultar filtros avanzados' : 'Mostrar filtros avanzados',
                  ),
                ],
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            enabled: !_mostrarFiltrosAvanzados,
            onChanged: (value) => setState(() {}),
          ),
        ),

        // Filtros avanzados con animación (disponible para todos los roles)
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _mostrarFiltrosAvanzados
              ? _buildFiltrosAvanzados()
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildFiltrosAvanzados() {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode
              ? theme.colorScheme.outline.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y botón de cerrar
              Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Filtros Específicos',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      setState(() {
                        _mostrarFiltrosAvanzados = false;
                        _limpiarFiltrosEspecificos();
                      });
                    },
                    tooltip: 'Cerrar filtros',
                    style: IconButton.styleFrom(
                      minimumSize: const Size(32, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Selector de tipo de filtro con mejor diseño
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                      : theme.colorScheme.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFiltroChip('busqueda_general', 'General', Icons.search),
                    _buildFiltroChip('nombre', 'Nombre', Icons.person),
                    _buildFiltroChip('email', 'Email', Icons.email),
                    _buildFiltroChip('telefono', 'Teléfono', Icons.phone),
                    _buildFiltroChip('ci', 'CI', Icons.badge),
                    _buildFiltroChip('categoria', 'Categoría', Icons.category),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo de entrada específico según el tipo seleccionado
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(0.3, 0.0), end: Offset.zero)
                          .chain(CurveTween(curve: Curves.easeOut)),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Container(
                  key: ValueKey(_tipoFiltroActual),
                  child: _buildCampoFiltroEspecifico(),
                ),
              ),
            ],
          ),
        ),
      ));
  }

  Widget _buildFiltroChip(String tipo, String label, IconData icon) {
    final theme = Theme.of(context);
    final isSelected = _tipoFiltroActual == tipo;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: FilterChip(
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _tipoFiltroActual = tipo;
            _limpiarFiltrosEspecificos();
          });
        },
        selectedColor: theme.colorScheme.primary,
        backgroundColor: theme.colorScheme.surface,
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withOpacity(0.3),
        ),
        elevation: isSelected ? 2 : 0,
        pressElevation: 4,
      ),
    );
  }

  Widget _buildCampoFiltroEspecifico() {
    switch (_tipoFiltroActual) {
      case 'nombre':
        return TextField(
          controller: _filtroNombreController,
          decoration: const InputDecoration(
            labelText: 'Buscar por nombre',
            hintText: 'Ingrese el nombre del cliente',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() {}),
        );
      case 'email':
        return TextField(
          controller: _filtroEmailController,
          decoration: const InputDecoration(
            labelText: 'Buscar por email',
            hintText: 'Ingrese el email del cliente',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (value) => setState(() {}),
        );
      case 'telefono':
        return TextField(
          controller: _filtroTelefonoController,
          decoration: const InputDecoration(
            labelText: 'Buscar por teléfono',
            hintText: 'Ingrese el número de teléfono',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => setState(() {}),
        );
      case 'ci':
        return TextField(
          controller: _filtroCiController,
          decoration: const InputDecoration(
            labelText: 'Buscar por CI',
            hintText: 'Ingrese la cédula de identidad',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() {}),
        );
      case 'categoria':
        return DropdownButtonFormField<String>(
          value: _filtroCategoriaSeleccionada.isEmpty ? null : _filtroCategoriaSeleccionada,
          decoration: const InputDecoration(
            labelText: 'Buscar por categoría',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: ['A', 'B', 'C'].map((categoria) {
            return DropdownMenuItem(
              value: categoria,
              child: Text('Categoría $categoria'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _filtroCategoriaSeleccionada = value ?? '';
            });
          },
        );
      case 'busqueda_general':
      default:
        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? theme.colorScheme.primary.withOpacity(0.3)
                  : Colors.blue[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info,
                color: isDarkMode
                    ? theme.colorScheme.primary
                    : Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Use la barra de búsqueda principal para buscar en todos los campos a la vez.',
                  style: TextStyle(
                    color: isDarkMode
                        ? theme.colorScheme.onPrimaryContainer
                        : Colors.blue[800],
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  void _limpiarFiltrosEspecificos() {
    _filtroNombreController.clear();
    _filtroEmailController.clear();
    _filtroTelefonoController.clear();
    _filtroCiController.clear();
    _filtroCategoriaSeleccionada = '';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;
    final esClienteDirecto = role == 'manager' && cliente.assignedCobradorId == managerId;
    final categoryColor = _getCategoryColor(cliente.clientCategory);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: categoryColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _navegarAPerfilCliente(cliente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto de perfil con indicador de cliente directo
              Stack(
                children: [
                  ProfileImageWidget(
                    profileImage: cliente.profileImage,
                    size: 56,
                  ),
                  if (esClienteDirecto)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardColor,
                            width: 2,
                          ),
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
              const SizedBox(width: 12),

              // Información del cliente
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre + chip de categoría
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            cliente.nombre,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ClientCategoryChip(
                          category: cliente.clientCategory,
                          compact: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Teléfono con icono
                    if (cliente.telefono.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cliente.telefono,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Badge "Directo" si aplica
                    if (esClienteDirecto) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(alpha: isDark ? 0.3 : 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person_pin,
                              size: 12,
                              color: Colors.indigo,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cliente Directo',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.indigo,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botones de acción
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón ver créditos
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.account_balance_wallet, size: 20),
                      color: Colors.green,
                      onPressed: () => _navegarACreditosCliente(cliente),
                      tooltip: 'Ver créditos',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Menú de más opciones
                  PopupMenuButton<String>(
                    onSelected: (value) => _manejarAccionCliente(value, cliente, role),
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    itemBuilder: (context) => _buildMenuItems(cliente, role),
                  ),
                ],
              ),
            ],
          ),
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
            builder: (context) => ClienteFormScreen(
              cliente: cliente,
              onClienteSaved: _cargarDatos,
            ),
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
      // Verificar que el cliente tiene coordenadas antes de crear el marcador
      if (cliente.latitud != null && cliente.longitud != null) {
        // Crear marcador para la ubicación del cliente
        final clienteMarker = Marker(
          markerId: MarkerId('cliente_${cliente.id}'),
          position: LatLng(cliente.latitud!, cliente.longitud!),
          infoWindow: InfoWindow(
            title: cliente.nombre,
            snippet: 'Cliente ${cliente.clientCategory ?? 'B'} - ${cliente.telefono}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocationPickerScreen(
              allowSelection: false, // Modo solo visualización
              extraMarkers: {clienteMarker},
              customTitle: 'Ubicación de ${cliente.nombre}',
            ),
          ),
        );
      } else {
        // Mostrar mensaje cuando no hay ubicación GPS
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Este cliente no tiene ubicación GPS registrada'),
            backgroundColor: Colors.orange,
          ),
        );
      }
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
                  'No hay informaci��n de ubicación disponible',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          actions: [
            if (cliente.latitud != null && cliente.longitud != null)
              TextButton(
                onPressed: () {
                  // Usar LocationPickerScreen en modo vista para cobradores también
                  Navigator.of(context).pop();

                  final clienteMarker = Marker(
                    markerId: MarkerId('cliente_${cliente.id}'),
                    position: LatLng(cliente.latitud!, cliente.longitud!),
                    infoWindow: InfoWindow(
                      title: cliente.nombre,
                      snippet: 'Cliente ${cliente.clientCategory ?? 'B'} - ${cliente.telefono}',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LocationPickerScreen(
                        allowSelection: false,
                        extraMarkers: {clienteMarker},
                        customTitle: 'Ubicación de ${cliente.nombre}',
                      ),
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
    _filtroNombreController.dispose();
    _filtroEmailController.dispose();
    _filtroTelefonoController.dispose();
    _filtroCiController.dispose();
    super.dispose();
  }
}
