import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/modelos/credito.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../creditos/credit_detail_screen.dart';
import '../creditos/credit_form_screen.dart';

class ClienteCreditosScreen extends ConsumerStatefulWidget {
  final Usuario cliente;

  const ClienteCreditosScreen({super.key, required this.cliente});

  @override
  ConsumerState<ClienteCreditosScreen> createState() =>
      _ClienteCreditosScreenState();
}

class _ClienteCreditosScreenState extends ConsumerState<ClienteCreditosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';

  // Método para obtener el rol del usuario actual
  String _getUserRole(Usuario? usuario) {
    if (usuario?.roles.contains('manager') == true) {
      return 'manager';
    } else if (usuario?.roles.contains('cobrador') == true) {
      return 'cobrador';
    }
    return 'cliente';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClientCredits();
    });
  }

  void _loadClientCredits() {
    // Cargar todos los créditos y filtrar en el lado del cliente
    ref.read(creditProvider.notifier).loadCredits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    final authState = ref.read(authProvider);
    final currentUserRole = _getUserRole(authState.usuario);

    // Filtrar créditos del cliente específico
    final clientCredits = creditState.credits
        .where((credit) => credit.clientId == widget.cliente.id)
        .toList();

    // Aplicar filtros adicionales
    final filteredCredits = _filterCredits(clientCredits);

    return Scaffold(
      appBar: RoleAppBar(
        title: 'Créditos de ${widget.cliente.nombre}',
        role: currentUserRole,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClientCredits,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Información del cliente
          _buildClientInfoCard(),

          // Estadísticas de créditos
          _buildCreditStatsCard(clientCredits),

          // Barra de búsqueda
          _buildSearchBar(),

          // Lista de créditos
          Expanded(
            child: _buildCreditsList(filteredCredits, creditState.isLoading),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarACrearCredito(),
        tooltip: 'Crear Nuevo Crédito',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildClientInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: RoleColors.clientePrimary,
              radius: 30,
              child: Text(
                widget.cliente.nombre.isNotEmpty
                    ? widget.cliente.nombre[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.cliente.nombre,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.cliente.email,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (widget.cliente.telefono.isNotEmpty)
                    Text(
                      widget.cliente.telefono,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreditStatsCard(List<Credito> credits) {
    final totalCredits = credits.length;
    final activeCredits = credits.where((c) => c.status == 'active').length;
    final completedCredits = credits
        .where((c) => c.status == 'completed')
        .length;
    final totalAmount = credits.fold<double>(
      0,
      (sum, credit) => sum + credit.amount,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total',
              '$totalCredits',
              Icons.account_balance_wallet,
              Colors.blue,
            ),
            _buildStatItem(
              'Activos',
              '$activeCredits',
              Icons.trending_up,
              Colors.green,
            ),
            _buildStatItem(
              'Completados',
              '$completedCredits',
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatItem(
              'Monto Total',
              '\$${NumberFormat('#,##0').format(totalAmount)}',
              Icons.attach_money,
              Colors.purple,
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
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar créditos...',
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

  Widget _buildCreditsList(List<Credito> credits, bool isLoading) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (credits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay créditos',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Este cliente no tiene créditos registrados',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: credits.length,
      itemBuilder: (context, index) {
        final credit = credits[index];
        return _buildCreditCard(credit);
      },
    );
  }

  Widget _buildCreditCard(Credito credit) {
    final statusColor = _getStatusColor(credit.status);
    final statusText = _getStatusText(credit.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            _getStatusIcon(credit.status),
            color: statusColor,
            size: 20,
          ),
        ),
        title: Text(
          'Crédito #${credit.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monto: \$${NumberFormat('#,##0').format(credit.amount)}',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              'Fecha: ${DateFormat('dd/MM/yyyy').format(credit.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _manejarAccionCredito(value, credit),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'ver_detalles',
              child: ListTile(
                leading: Icon(Icons.visibility, color: Colors.blue),
                title: Text('Ver Detalles'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'editar',
              child: ListTile(
                leading: Icon(Icons.edit, color: Colors.orange),
                title: Text('Editar Crédito'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToDetails(credit),
      ),
    );
  }

  List<Credito> _filterCredits(List<Credito> credits) {
    var filtered = credits;

    // Filtro por estado
    if (_selectedStatus != 'all') {
      filtered = filtered.where((c) => c.status == _selectedStatus).toList();
    }

    // Filtro por búsqueda
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      filtered = filtered.where((c) {
        return c.id.toString().contains(query) ||
            c.amount.toString().contains(query) ||
            c.status.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'defaulted':
        return Colors.red;
      case 'pending_approval':
        return Colors.orange;
      case 'waiting_delivery':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'defaulted':
        return 'En Mora';
      case 'pending_approval':
        return 'Pendiente';
      case 'waiting_delivery':
        return 'Por Entregar';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.trending_up;
      case 'completed':
        return Icons.check_circle;
      case 'defaulted':
        return Icons.warning;
      case 'pending_approval':
        return Icons.schedule;
      case 'waiting_delivery':
        return Icons.delivery_dining;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros de créditos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Estado del crédito:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('all', 'Todos'),
                _buildFilterChip('active', 'Activos'),
                _buildFilterChip('completed', 'Completados'),
                _buildFilterChip('defaulted', 'En Mora'),
                _buildFilterChip('pending_approval', 'Pendientes'),
                _buildFilterChip('waiting_delivery', 'Por Entregar'),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return FilterChip(
      label: Text(label),
      selected: _selectedStatus == value,
      onSelected: (selected) {
        setState(() {
          _selectedStatus = value;
        });
        Navigator.pop(context);
      },
    );
  }

  void _navigateToDetails(Credito credit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditDetailScreen(credit: credit),
      ),
    );
  }

  void _manejarAccionCredito(String accion, Credito credit) {
    switch (accion) {
      case 'ver_detalles':
        _navigateToDetails(credit);
        break;
      case 'editar':
        _navegarAEditarCredito(credit);
        break;
    }
  }

  void _navegarACrearCredito() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreditFormScreen(preselectedClient: widget.cliente),
      ),
    );

    // Si se creó exitosamente, recargar la lista
    if (result == true) {
      _loadClientCredits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _navegarAEditarCredito(Credito credit) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreditFormScreen(credit: credit)),
    );

    // Si se actualizó exitosamente, recargar la lista
    if (result == true) {
      _loadClientCredits();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
