import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';

class CobradorClientesScreen extends ConsumerStatefulWidget {
  final Usuario cobrador;

  const CobradorClientesScreen({super.key, required this.cobrador});

  @override
  ConsumerState<CobradorClientesScreen> createState() =>
      _CobradorClientesScreenState();
}

class _CobradorClientesScreenState
    extends ConsumerState<CobradorClientesScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarClientesCobrador();
    });
  }

  void _cargarClientesCobrador() {
    if (_hasLoadedInitialData) return;
    _hasLoadedInitialData = true;

    // Usar el método existente que carga todos los clientes del manager
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      ref
          .read(managerProvider.notifier)
          .cargarClientesDelManager(authState.usuario!.id.toString());
    }
  }

  void _buscarClientes(String query) {
    // Para la búsqueda, simplemente filtraremos los clientes ya cargados
    setState(() {
      // Trigger rebuild para aplicar filtro
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);
    // Filtrar los clientes del manager que están asignados a este cobrador específico
    final clientesCobrador = managerState.clientesDelManager
        .where((cliente) => cliente.assignedCobradorId == widget.cobrador.id)
        .toList();

    // Aplicar filtro de búsqueda si hay texto
    final clientesFiltrados = _searchController.text.isEmpty
        ? clientesCobrador
        : clientesCobrador.where((cliente) {
            final searchTerm = _searchController.text.toLowerCase();
            return cliente.nombre.toLowerCase().contains(searchTerm) ||
                cliente.email.toLowerCase().contains(searchTerm) ||
                cliente.telefono.toLowerCase().contains(searchTerm);
          }).toList();

    return Scaffold(
      appBar: RoleAppBar(
        title: 'Clientes de ${widget.cobrador.nombre}',
        role: 'manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _hasLoadedInitialData = false;
              _cargarClientesCobrador();
            },
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del cobrador
          _buildCobradorInfo(),

          // Estadísticas de clientes
          _buildEstadisticasClientes(clientesFiltrados),

          // Barra de búsqueda
          _buildBarraBusqueda(),

          // Lista de clientes
          Expanded(child: _buildListaClientes(managerState, clientesFiltrados)),
        ],
      ),
    );
  }

  Widget _buildCobradorInfo() {
    return RoleHeaderCard(
      role: 'cobrador',
      userName: widget.cobrador.nombre,
      userEmail: widget.cobrador.email,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_pin, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Cobrador',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasClientes(List<Usuario> clientes) {
    // Como no tenemos campo activo, solo mostramos estadísticas básicas
    final totalClientes = clientes.length;
    final clientesConTelefono = clientes
        .where((c) => c.telefono.isNotEmpty)
        .length;
    final clientesConUbicacion = clientes
        .where((c) => c.latitud != null && c.longitud != null)
        .length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total',
              '$totalClientes',
              Icons.people,
              RoleColors.cobradorPrimary,
            ),
            _buildStatItem(
              'Con Teléfono',
              '$clientesConTelefono',
              Icons.phone,
              Colors.green,
            ),
            _buildStatItem(
              'Con Ubicación',
              '$clientesConUbicacion',
              Icons.location_on,
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
            fontSize: 20,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
                    _buscarClientes('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
        ),
        onChanged: _buscarClientes,
      ),
    );
  }

  Widget _buildListaClientes(
    ManagerState managerState,
    List<Usuario> clientes,
  ) {
    if (managerState.isLoading) {
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
              'Sin clientes asignados',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Este cobrador no tiene clientes asignados actualmente',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final cliente = clientes[index];
        return _buildClienteCard(cliente);
      },
    );
  }

  Widget _buildClienteCard(Usuario cliente) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: RoleAvatarWidget(
          role: 'client',
          userName: cliente.nombre,
          radius: 25,
        ),
        title: Text(
          cliente.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (cliente.email.isNotEmpty)
              Text(cliente.email, style: TextStyle(color: Colors.grey[600])),
            if (cliente.telefono.isNotEmpty)
              ContactActionsWidget.buildPhoneDisplay(
                context: context,
                userName: cliente.nombre,
                phoneNumber: cliente.telefono,
                userRole: 'cliente',
                customMessage: ContactActionsWidget.getDefaultMessage(
                  'cliente',
                  cliente.nombre,
                ),
              ),
            if (cliente.direccion.isNotEmpty)
              Text(
                'Dir: ${cliente.direccion}',
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            RoleDisplayWidget(
              role: 'client',
              fontSize: 12,
              showIcon: true,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                  value: 'ver_detalle',
                  child: ListTile(
                    leading: Icon(Icons.visibility, color: Colors.blue),
                    title: Text('Ver Detalle'),
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
                  value: 'ver_creditos',
                  child: ListTile(
                    leading: Icon(Icons.credit_card, color: Colors.green),
                    title: Text('Ver Créditos'),
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
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _manejarAccionCliente(String accion, Usuario cliente) {
    switch (accion) {
      case 'ver_detalle':
        _mostrarDetalleCliente(cliente);
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
      case 'ver_creditos':
        _navegarACreditosCliente(cliente);
        break;
      case 'ubicacion':
        _mostrarUbicacionCliente(cliente);
        break;
    }
  }

  void _mostrarDetalleCliente(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle de ${cliente.nombre}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Nombre:', cliente.nombre),
              _buildDetailRow(
                'Email:',
                cliente.email.isEmpty ? 'No registrado' : cliente.email,
              ),
              // Teléfono con opción de contacto
              _buildDetailRowWithContact(
                'Teléfono:',
                cliente.telefono,
                cliente,
              ),
              _buildDetailRow(
                'Dirección:',
                cliente.direccion.isEmpty ? 'No registrada' : cliente.direccion,
              ),
              if (cliente.latitud != null && cliente.longitud != null)
                _buildDetailRow(
                  'Coordenadas:',
                  '${cliente.latitud}, ${cliente.longitud}',
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithContact(
    String label,
    String phoneNumber,
    Usuario cliente,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: phoneNumber.isEmpty
                ? const Text('No registrado')
                : Row(
                    children: [
                      Expanded(
                        child: ContactActionsWidget.buildPhoneDisplay(
                          context: context,
                          userName: cliente.nombre,
                          phoneNumber: phoneNumber,
                          userRole: 'cliente',
                          customMessage: ContactActionsWidget.getDefaultMessage(
                            'cliente',
                            cliente.nombre,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _navegarACreditosCliente(Usuario cliente) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver créditos de ${cliente.nombre} - En desarrollo'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _mostrarUbicacionCliente(Usuario cliente) {
    if (cliente.latitud == null || cliente.longitud == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene ubicación registrada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ubicación: ${cliente.latitud}, ${cliente.longitud}\n'
          'Función de mapa en desarrollo',
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
