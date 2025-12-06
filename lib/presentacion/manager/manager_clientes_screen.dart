import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';
import '../widgets/profile_image_widget.dart';
import '../../ui/widgets/client_category_chip.dart';
import '../cliente/cliente_creditos_screen.dart';
import '../cliente/cliente_perfil_screen.dart';
import '../cliente/location_picker_screen.dart';
import '../cliente/cliente_form_screen.dart';

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
        tooltip: 'Crear Cliente',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEstadisticasCard(ManagerState managerState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceAround,
          children: [
            _buildStatItem(
              theme,
              isDark,
              'Total',
              '$totalClientes',
              Icons.business,
              Colors.blue,
            ),
            _buildStatItem(
              theme,
              isDark,
              'Cobradores',
              '$totalCobradores',
              Icons.person,
              Colors.green,
            ),
            _buildStatItem(
              theme,
              isDark,
              'Directos',
              '$clientesDirectos',
              Icons.person_pin,
              Colors.indigo,
            ),
            _buildStatItem(
              theme,
              isDark,
              'Asignados',
              '$clientesDeCobradores',
              Icons.group,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 70,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
    final theme = Theme.of(context);

    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clientesFiltrados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business_center,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                managerState.clientesDelManager.isEmpty
                    ? 'No hay clientes en tu equipo'
                    : 'No se encontraron clientes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              if (managerState.clientesDelManager.isEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Los clientes aparecerán aquí cuando tus cobradores tengan clientes asignados',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.read(authProvider);
    final managerId = authState.usuario?.id;
    final esClienteDirecto = cliente.assignedCobradorId == managerId;
    final categoryColor = _getCategoryColor(cliente.clientCategory);

    return Card(
      margin: esEnGrupo
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.only(bottom: 12),
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
                          border: Border.all(color: theme.cardColor, width: 2),
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
                          Icon(Icons.phone, size: 14, color: Colors.green),
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

                    // Cobrador asignado (si aplica)
                    if (!esEnGrupo &&
                        !esClienteDirecto &&
                        cliente.assignedCobradorId != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _obtenerNombreCobrador(
                                cliente.assignedCobradorId!,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Badge "Directo" si aplica
                    if (esClienteDirecto) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.indigo.withValues(
                            alpha: isDark ? 0.3 : 0.15,
                          ),
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
                    onSelected: (value) =>
                        _manejarAccionCliente(value, cliente),
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
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'ver_perfil',
                        child: ListTile(
                          leading: Icon(Icons.person, size: 20),
                          title: Text('Ver Perfil'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      if (cliente.telefono.isNotEmpty)
                        ContactActionsWidget.buildContactMenuItem(
                          phoneNumber: cliente.telefono,
                          value: 'contactar',
                          icon: Icons.phone,
                          iconColor: Colors.green,
                          label: 'Llamar / WhatsApp',
                        ),
                      const PopupMenuItem(
                        value: 'ver_ubicacion',
                        child: ListTile(
                          leading: Icon(Icons.location_on, size: 20),
                          title: Text('Ver Ubicación'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 20,
                          ),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      if (esClienteDirecto)
                        const PopupMenuItem(
                          value: 'asignar_cobrador',
                          child: ListTile(
                            leading: Icon(
                              Icons.person_add,
                              color: Colors.orange,
                              size: 20,
                            ),
                            title: Text('Asignar Cobrador'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        )
                      else if (cliente.assignedCobradorId != null)
                        const PopupMenuItem(
                          value: 'asignar_cobrador',
                          child: ListTile(
                            leading: Icon(
                              Icons.swap_horiz,
                              color: Colors.purple,
                              size: 20,
                            ),
                            title: Text('Reasignar'),
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
    if (cliente.latitud != null && cliente.longitud != null) {
      // Crear marcador para la ubicación del cliente
      final clienteMarker = Marker(
        markerId: MarkerId('cliente_${cliente.id}'),
        position: LatLng(cliente.latitud!, cliente.longitud!),
        infoWindow: InfoWindow(
          title: cliente.nombre,
          snippet:
              'Cliente ${cliente.clientCategory ?? 'B'} - ${cliente.telefono}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene ubicación GPS registrada'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
        builder: (context) => ClienteFormScreen(onClienteSaved: _cargarDatos),
      ),
    );
  }

  void _navegarEditarCliente(Usuario cliente) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ClienteFormScreen(cliente: cliente, onClienteSaved: _cargarDatos),
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
