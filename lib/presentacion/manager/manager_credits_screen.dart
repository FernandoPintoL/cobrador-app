import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/credito.dart';
import '../creditos/credit_form_screen.dart';
import '../creditos/credit_detail_screen.dart';
import '../creditos/waiting_list_screen.dart';

class ManagerCreditsScreen extends ConsumerStatefulWidget {
  const ManagerCreditsScreen({super.key});

  @override
  ConsumerState<ManagerCreditsScreen> createState() =>
      _ManagerCreditsScreenState();
}

class _ManagerCreditsScreenState extends ConsumerState<ManagerCreditsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchText = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    final authState = ref.read(authProvider);
    final usuario = authState.usuario;

    if (usuario != null) {
      final managerId = usuario.id.toString();

      // Cargar datos del manager
      await ref
          .read(managerProvider.notifier)
          .cargarCobradoresAsignados(managerId);
      await ref
          .read(managerProvider.notifier)
          .cargarClientesDelManager(managerId);

      // Cargar datos de créditos
      await ref.read(creditProvider.notifier).loadCredits();
      await ref.read(creditProvider.notifier).loadAllWaitingListData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gestión de Créditos Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Filtro por estado
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              _aplicarFiltros();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Text('Todos los estados'),
              ),
              const PopupMenuItem(
                value: 'pending_approval',
                child: Text('Pendientes aprobación'),
              ),
              const PopupMenuItem(
                value: 'waiting_delivery',
                child: Text('Esperando entrega'),
              ),
              const PopupMenuItem(value: 'active', child: Text('Activos')),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completados'),
              ),
              const PopupMenuItem(value: 'rejected', child: Text('Rechazados')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredCredits(creditState.credits, 'all').length}',
                ),
                child: const Icon(Icons.credit_card),
              ),
              text: 'Todos',
            ),
            Tab(
              icon: Badge(
                label: Text('${creditState.pendingApprovalCredits.length}'),
                child: const Icon(Icons.pending_actions),
              ),
              text: 'Pendientes',
            ),
            Tab(
              icon: Badge(
                label: Text('${creditState.waitingDeliveryCredits.length}'),
                child: const Icon(Icons.schedule),
              ),
              text: 'Por Entregar',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredCredits(creditState.credits, 'active').length}',
                ),
                child: const Icon(Icons.trending_up),
              ),
              text: 'Activos',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredCredits(creditState.credits, 'completed').length}',
                ),
                child: const Icon(Icons.check_circle),
              ),
              text: 'Completados',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Panel de estadísticas rápidas
          _buildStatsPanel(creditState, managerState),

          // Barra de búsqueda
          _buildSearchBar(),

          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreditsList(creditState.credits, 'all'),
                _buildCreditsList(
                  creditState.pendingApprovalCredits,
                  'pending_approval',
                ),
                _buildCreditsList(
                  creditState.waitingDeliveryCredits,
                  'waiting_delivery',
                ),
                _buildCreditsList(
                  _getFilteredCredits(creditState.credits, 'active'),
                  'active',
                ),
                _buildCreditsList(
                  _getFilteredCredits(creditState.credits, 'completed'),
                  'completed',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Botón de lista de espera
          FloatingActionButton(
            heroTag: "waiting_list",
            onPressed: () => _navegarAListaEspera(),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            child: Badge(
              label: Text(
                '${creditState.pendingApprovalCredits.length + creditState.waitingDeliveryCredits.length}',
              ),
              child: const Icon(Icons.pending_actions),
            ),
            tooltip: 'Lista de Espera',
          ),
          const SizedBox(height: 16),
          // Botón de crear crédito
          FloatingActionButton(
            heroTag: "create_credit",
            onPressed: () => _navegarACrearCredito(),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            child: const Icon(Icons.add),
            tooltip: 'Crear Crédito',
          ),
        ],
      ),
    );
  }

  Widget _buildStatsPanel(CreditState creditState, ManagerState managerState) {
    final totalCreditos = creditState.credits.length;
    final creditosActivos = _getFilteredCredits(
      creditState.credits,
      'active',
    ).length;
    final creditosPendientes = creditState.pendingApprovalCredits.length;
    final totalMonto = creditState.credits.fold<double>(
      0,
      (sum, credit) => sum + credit.amount,
    );

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de Créditos',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMiniStatCard(
                      'Total Créditos',
                      totalCreditos.toString(),
                      Icons.credit_card,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Activos',
                      creditosActivos.toString(),
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Pendientes',
                      creditosPendientes.toString(),
                      Icons.pending_actions,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMiniStatCard(
                      'Monto Total',
                      'Bs. ${NumberFormat('#,##0').format(totalMonto)}',
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
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
            title,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar por cliente, cobrador o ID...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchText = '';
                    });
                    _aplicarFiltros();
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          setState(() {
            _searchText = value;
          });
          _aplicarFiltros();
        },
      ),
    );
  }

  Widget _buildCreditsList(List<Credito> credits, String listType) {
    final filteredCredits = _searchText.isEmpty
        ? credits
        : credits.where((credit) {
            final searchLower = _searchText.toLowerCase();
            return credit.client?.nombre.toLowerCase().contains(searchLower) ??
                false ||
                    (credit.cobrador?.nombre.toLowerCase().contains(
                          searchLower,
                        ) ??
                        false) ||
                    credit.id.toString().contains(searchLower);
          }).toList();

    if (filteredCredits.isEmpty) {
      return _buildEmptyState(listType);
    }

    return RefreshIndicator(
      onRefresh: _cargarDatosIniciales,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredCredits.length,
        itemBuilder: (context, index) {
          final credit = filteredCredits[index];
          return _buildCreditCard(credit, listType);
        },
      ),
    );
  }

  Widget _buildCreditCard(Credito credit, String listType) {
    final isUrgent = _isUrgentCredit(credit);
    final statusColor = _getStatusColor(credit.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUrgent ? 6 : 2,
      child: InkWell(
        onTap: () => _navegarADetalleCredito(credit),
        onLongPress: () => _mostrarOpcionesCredito(credit),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUrgent ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: statusColor.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          'ID: ${credit.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (isUrgent) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'URGENTE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusLabel(credit.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del cliente
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      credit.client?.nombre ?? 'Cliente no encontrado',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              if (credit.cobrador != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Cobrador: ${credit.cobrador!.nombre}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Información financiera
              Row(
                children: [
                  Expanded(
                    child: _buildCreditInfoItem(
                      'Monto',
                      'Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
                      Icons.attach_money,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildCreditInfoItem(
                      'Balance',
                      'Bs. ${NumberFormat('#,##0.00').format(credit.balance)}',
                      Icons.account_balance,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildCreditInfoItem(
                      'Frecuencia',
                      _getFrequencyLabel(credit.frequency),
                      Icons.schedule,
                      Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Fechas importantes
              if (credit.scheduledDeliveryDate != null) ...[
                Row(
                  children: [
                    const Icon(Icons.event, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Entrega programada: ${DateFormat('dd/MM/yyyy').format(credit.scheduledDeliveryDate!)}',
                      style: TextStyle(
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Botones de acción según el estado
              if (listType == 'pending_approval') _buildApprovalButtons(credit),
              if (listType == 'waiting_delivery') _buildDeliveryButtons(credit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditInfoItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildApprovalButtons(Credito credit) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _aprobarCredito(credit),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _rechazarCredito(credit),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Rechazar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryButtons(Credito credit) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _entregarCredito(credit),
            icon: const Icon(Icons.handshake, size: 16),
            label: const Text('Entregar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _reprogramarEntrega(credit),
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Reprogramar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String listType) {
    IconData icon;
    String title;
    String subtitle;

    switch (listType) {
      case 'pending_approval':
        icon = Icons.pending_actions;
        title = 'No hay créditos pendientes';
        subtitle = 'Los créditos que requieran aprobación aparecerán aquí';
        break;
      case 'waiting_delivery':
        icon = Icons.schedule;
        title = 'No hay créditos por entregar';
        subtitle =
            'Los créditos aprobados y programados para entrega aparecerán aquí';
        break;
      case 'active':
        icon = Icons.trending_up;
        title = 'No hay créditos activos';
        subtitle =
            'Los créditos entregados y en proceso de cobro aparecerán aquí';
        break;
      case 'completed':
        icon = Icons.check_circle;
        title = 'No hay créditos completados';
        subtitle = 'Los créditos totalmente pagados aparecerán aquí';
        break;
      default:
        icon = Icons.credit_card;
        title = 'No hay créditos';
        subtitle = 'Crea tu primer crédito para comenzar';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<Credito> _getFilteredCredits(List<Credito> credits, String status) {
    if (status == 'all') return credits;
    return credits.where((credit) => credit.status == status).toList();
  }

  bool _isUrgentCredit(Credito credit) {
    if (credit.scheduledDeliveryDate != null) {
      final daysUntilDelivery = credit.scheduledDeliveryDate!
          .difference(DateTime.now())
          .inDays;
      return daysUntilDelivery <= 1 && credit.status == 'waiting_delivery';
    }
    if (credit.status == 'pending_approval') {
      final daysSinceCreation = DateTime.now()
          .difference(credit.createdAt)
          .inDays;
      return daysSinceCreation >= 2;
    }
    return false;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_approval':
        return Colors.orange;
      case 'waiting_delivery':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.teal;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending_approval':
        return 'Pendiente';
      case 'waiting_delivery':
        return 'Por Entregar';
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return 'Desconocido';
    }
  }

  String _getFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quincenal';
      case 'monthly':
        return 'Mensual';
      default:
        return frequency;
    }
  }

  void _aplicarFiltros() {
    // Implementar lógica de filtros si es necesario
    // Por ahora, solo actualizamos el estado para refrescar la UI
    setState(() {});
  }

  Future<void> _aprobarCredito(Credito credit) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _FechaEntregaDialog(),
    );

    if (result != null) {
      final success = await ref
          .read(creditProvider.notifier)
          .approveCreditForDelivery(
            creditId: credit.id,
            scheduledDeliveryDate: result,
          );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito aprobado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatosIniciales();
      }
    }
  }

  Future<void> _rechazarCredito(Credito credit) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _MotivoRechazoDialog(),
    );

    if (result != null && result.isNotEmpty) {
      final success = await ref
          .read(creditProvider.notifier)
          .rejectCredit(creditId: credit.id, reason: result);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito rechazado'),
            backgroundColor: Colors.red,
          ),
        );
        await _cargarDatosIniciales();
      }
    }
  }

  Future<void> _entregarCredito(Credito credit) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _NotasEntregaDialog(),
    );

    if (result != null) {
      final success = await ref
          .read(creditProvider.notifier)
          .deliverCreditToClient(creditId: credit.id, notes: result);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito entregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _cargarDatosIniciales();
      }
    }
  }

  Future<void> _reprogramarEntrega(Credito credit) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _ReprogramarEntregaDialog(
        fechaActual: credit.scheduledDeliveryDate ?? DateTime.now(),
      ),
    );

    if (result != null) {
      final success = await ref
          .read(creditProvider.notifier)
          .rescheduleCreditDelivery(
            creditId: credit.id,
            newScheduledDate: result,
          );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entrega reprogramada exitosamente'),
            backgroundColor: Colors.blue,
          ),
        );
        await _cargarDatosIniciales();
      }
    }
  }

  void _mostrarOpcionesCredito(Credito credit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _navegarADetalleCredito(credit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar crédito'),
              onTap: () {
                Navigator.pop(context);
                _navegarAEditarCredito(credit);
              },
            ),
            if (credit.status == 'pending_approval' ||
                credit.status == 'waiting_delivery')
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Cancelar crédito'),
                onTap: () {
                  Navigator.pop(context);
                  _mostrarDialogoCancelarCredito(credit);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoCancelarCredito(Credito credit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Crédito'),
        content: Text(
          '¿Estás seguro de que quieres cancelar el crédito #${credit.id}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelarCredito(credit);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Cancelar Crédito',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelarCredito(Credito credit) async {
    // Implementar cancelación de crédito
    final success = await ref
        .read(creditProvider.notifier)
        .deleteCredit(credit.id);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crédito cancelado exitosamente'),
          backgroundColor: Colors.orange,
        ),
      );
      await _cargarDatosIniciales();
    }
  }

  void _navegarACrearCredito() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreditFormScreen()),
    ).then((_) => _cargarDatosIniciales());
  }

  void _navegarAEditarCredito(Credito credit) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreditFormScreen(credit: credit)),
    ).then((_) => _cargarDatosIniciales());
  }

  void _navegarADetalleCredito(Credito credit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditDetailScreen(credit: credit),
      ),
    );
  }

  void _navegarAListaEspera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WaitingListScreen()),
    ).then((_) => _cargarDatosIniciales());
  }
}

// Dialog para seleccionar fecha de entrega
class _FechaEntregaDialog extends StatefulWidget {
  @override
  State<_FechaEntregaDialog> createState() => _FechaEntregaDialogState();
}

class _FechaEntregaDialogState extends State<_FechaEntregaDialog> {
  DateTime selectedDate = DateTime.now().add(const Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Fecha de Entrega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Selecciona la fecha programada para la entrega:'),
          const SizedBox(height: 16),
          CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedDate),
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

// Dialog para motivo de rechazo
class _MotivoRechazoDialog extends StatefulWidget {
  @override
  State<_MotivoRechazoDialog> createState() => _MotivoRechazoDialogState();
}

class _MotivoRechazoDialogState extends State<_MotivoRechazoDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Motivo de Rechazo'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Explica el motivo del rechazo...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Rechazar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Dialog para notas de entrega
class _NotasEntregaDialog extends StatefulWidget {
  @override
  State<_NotasEntregaDialog> createState() => _NotasEntregaDialogState();
}

class _NotasEntregaDialogState extends State<_NotasEntregaDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notas de Entrega'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Notas opcionales sobre la entrega...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Entregar'),
        ),
      ],
    );
  }
}

// Dialog para reprogramar entrega
class _ReprogramarEntregaDialog extends StatefulWidget {
  final DateTime fechaActual;

  const _ReprogramarEntregaDialog({required this.fechaActual});

  @override
  State<_ReprogramarEntregaDialog> createState() =>
      _ReprogramarEntregaDialogState();
}

class _ReprogramarEntregaDialogState extends State<_ReprogramarEntregaDialog> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.fechaActual.add(const Duration(days: 1));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reprogramar Entrega'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Fecha actual: ${DateFormat('dd/MM/yyyy').format(widget.fechaActual)}',
          ),
          const SizedBox(height: 16),
          const Text('Nueva fecha:'),
          const SizedBox(height: 8),
          CalendarDatePicker(
            initialDate: selectedDate,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 365)),
            onDateChanged: (date) {
              setState(() {
                selectedDate = date;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedDate),
          child: const Text('Reprogramar'),
        ),
      ],
    );
  }
}
