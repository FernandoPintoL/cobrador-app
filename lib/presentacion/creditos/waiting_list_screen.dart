import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/credito.dart';
import 'credit_detail_screen.dart';

class WaitingListScreen extends ConsumerStatefulWidget {
  const WaitingListScreen({super.key});

  @override
  ConsumerState<WaitingListScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends ConsumerState<WaitingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    ref.read(creditProvider.notifier).loadAllWaitingListData();
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    final authState = ref.watch(authProvider);

    // Verificar permisos - Solo managers y admins pueden ver esta pantalla
    if (!authState.isManager && !authState.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No tienes permisos para acceder a la lista de espera',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Listener para mensajes de error y éxito
    ref.listen<CreditState>(creditProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(creditProvider.notifier).clearError();
              },
            ),
          ),
        );
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(creditProvider.notifier).clearSuccess();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de Espera de Créditos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(
              text: 'Pendientes (${creditState.pendingApprovalCredits.length})',
              icon: const Icon(Icons.hourglass_empty),
            ),
            Tab(
              text: 'En Espera (${creditState.waitingDeliveryCredits.length})',
              icon: const Icon(Icons.schedule),
            ),
            Tab(
              text:
                  'Listos Hoy (${creditState.readyForDeliveryCredits.length})',
              icon: const Icon(Icons.today),
            ),
            Tab(
              text: 'Atrasados (${creditState.overdueDeliveryCredits.length})',
              icon: const Icon(Icons.warning),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Resumen de lista de espera
          if (creditState.waitingListSummary != null)
            _buildSummaryCard(creditState.waitingListSummary!),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreditsList(
                  creditState.pendingApprovalCredits,
                  'pending_approval',
                ),
                _buildCreditsList(
                  creditState.waitingDeliveryCredits,
                  'waiting_delivery',
                ),
                _buildCreditsList(
                  creditState.readyForDeliveryCredits,
                  'ready_for_delivery',
                ),
                _buildCreditsList(
                  creditState.overdueDeliveryCredits,
                  'overdue_delivery',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(WaitingListSummary summary) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de Lista de Espera',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      'Total en Lista',
                      '${summary.totalCreditsInWaitingList}',
                      'Bs. ${NumberFormat('#,##0.00').format(summary.totalAmountInWaitingList)}',
                      Icons.list,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryItem(
                      'Listos Hoy',
                      '${summary.readyToday}',
                      '',
                      Icons.today,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSummaryItem(
                      'Atrasados',
                      '${summary.overdueDelivery}',
                      '',
                      Icons.warning,
                      Colors.red,
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

  Widget _buildSummaryItem(
    String title,
    String count,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          if (amount.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditsList(List<Credito> credits, String listType) {
    if (credits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_getEmptyStateIcon(listType), size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(listType),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
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
        return _buildCreditCard(credit, listType);
      },
    );
  }

  Widget _buildCreditCard(Credito credit, String listType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToCreditDetail(credit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con cliente y estado
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credit.client?.nombre ??
                              'Cliente #${credit.clientId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Crédito #${credit.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(credit.status),
                ],
              ),

              const SizedBox(height: 12),

              // Información del crédito
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (credit.creator != null)
                          Text(
                            'Creado por: ${credit.creator!.nombre}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(credit.createdAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (credit.scheduledDeliveryDate != null)
                        Text(
                          'Entrega: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDeliveryDateColor(credit),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Información específica según el tipo de lista
              if (listType == 'pending_approval') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pendiente de aprobación por un manager',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (listType == 'ready_for_delivery') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Listo para entrega hoy',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (listType == 'overdue_delivery') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Entrega atrasada (${credit.daysOverdueForDelivery} días)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Botones de acción según el estado
              const SizedBox(height: 12),
              _buildActionButtons(credit, listType),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending_approval':
        color = Colors.orange;
        label = 'Pendiente';
        break;
      case 'waiting_delivery':
        color = Colors.blue;
        label = 'En Espera';
        break;
      case 'active':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rechazado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Credito credit, String listType) {
    List<Widget> buttons = [];

    if (listType == 'pending_approval') {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showQuickApprovalDialog(credit),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aprobar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showQuickRejectionDialog(credit),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Rechazar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      ]);
    } else if (listType == 'ready_for_delivery' ||
        (listType == 'waiting_delivery' && credit.isReadyForDelivery)) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showQuickDeliveryDialog(credit),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('Entregar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: buttons);
  }

  Color _getDeliveryDateColor(Credito credit) {
    if (credit.scheduledDeliveryDate == null) return Colors.grey;

    if (credit.isOverdueForDelivery) {
      return Colors.red;
    } else if (credit.isReadyForDelivery) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

  IconData _getEmptyStateIcon(String listType) {
    switch (listType) {
      case 'pending_approval':
        return Icons.inbox;
      case 'waiting_delivery':
        return Icons.schedule;
      case 'ready_for_delivery':
        return Icons.check_circle_outline;
      case 'overdue_delivery':
        return Icons.warning_amber;
      default:
        return Icons.folder_open;
    }
  }

  String _getEmptyStateMessage(String listType) {
    switch (listType) {
      case 'pending_approval':
        return 'No hay créditos pendientes de aprobación';
      case 'waiting_delivery':
        return 'No hay créditos en lista de espera';
      case 'ready_for_delivery':
        return 'No hay créditos listos para entrega hoy';
      case 'overdue_delivery':
        return 'No hay créditos con entrega atrasada';
      default:
        return 'No hay créditos';
    }
  }

  void _navigateToCreditDetail(Credito credit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditDetailScreen(credit: credit),
      ),
    ).then((_) {
      // Recargar datos después de regresar
      _loadInitialData();
    });
  }

  Future<void> _showQuickApprovalDialog(Credito credit) async {
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 2));

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobación Rápida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            const SizedBox(height: 16),
            const Text('¿Aprobar para entrega inmediata?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(creditProvider.notifier)
          .approveCreditForDelivery(
            creditId: credit.id,
            scheduledDeliveryDate: selectedDate,
            notes: 'Aprobación rápida para entrega inmediata',
          );
      _loadInitialData();
    }
  }

  Future<void> _showQuickRejectionDialog(Credito credit) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debe proporcionar un motivo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(creditProvider.notifier)
          .rejectCredit(
            creditId: credit.id,
            reason: reasonController.text.trim(),
          );
      _loadInitialData();
    }
  }

  Future<void> _showQuickDeliveryDialog(Credito credit) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            const SizedBox(height: 16),
            const Text('¿Confirmar entrega al cliente?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(creditProvider.notifier)
          .deliverCreditToClient(
            creditId: credit.id,
            notes: 'Entrega confirmada desde lista de espera',
          );
      _loadInitialData();
    }
  }
}
