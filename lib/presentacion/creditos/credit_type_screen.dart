import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/role_colors.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../ui/widgets/validation_error_display.dart'; // Importar widget de errores
import 'credit_detail_screen.dart';
import 'credit_form_screen.dart';

class CreditTypeScreen extends ConsumerStatefulWidget {
  const CreditTypeScreen({super.key});

  @override
  ConsumerState<CreditTypeScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends ConsumerState<CreditTypeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
    // Cargar listas de espera
    ref.read(creditProvider.notifier).loadAllWaitingListData();

    // Además, cargar créditos activos según el rol
    final authState = ref.read(authProvider);
    final usuario = authState.usuario;
    final bool isCobrador = authState.isCobrador;

    ref.read(creditProvider.notifier).loadCredits(
      status: 'active',
      cobradorId: isCobrador && usuario != null ? usuario.id.toInt() : null,
      page: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    final authState = ref.watch(authProvider);
    // Obtener el rol del usuario actual
    String currentUserRole = 'cliente';
    if (authState.usuario != null) {
      if (authState.usuario!.roles.contains('admin')) {
        currentUserRole = 'admin';
      } else if (authState.usuario!.roles.contains('manager')) {
        currentUserRole = 'manager';
      } else if (authState.usuario!.roles.contains('cobrador')) {
        currentUserRole = 'cobrador';
      }
    }

    // Verificar permisos - Admins, managers y cobradores pueden ver esta pantalla
    if (!authState.isManager && !authState.isAdmin && !authState.isCobrador) {
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
      /*backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor
          : RoleColors.getAccentColor(currentUserRole),*/
      appBar: AppBar(
        title: const Text(
          'Mis Créditos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: RoleColors.getPrimaryColor(currentUserRole),
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
              text: 'Activos ('
                  '${creditState.credits.where((c) => c.status == 'active').length}'
                  ')',
              icon: const Icon(Icons.playlist_add_check_circle),
            ),
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
                  'Entregar (${creditState.readyForDeliveryCredits.length})',
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
          /*if (creditState.waitingListSummary != null)
            _buildSummaryCard(creditState.waitingListSummary!),*/

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCreditsList(
                  creditState.credits.where((c) => c.status == 'active').toList(),
                  'active',
                ),
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RoleColors.getPrimaryColor(currentUserRole),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreditFormScreen(),
            ),
          );
          _loadInitialData();
        },
        icon: const Icon(Icons.add, color: Colors.white,),
        label: const Text('Nuevo Crédito', style: TextStyle(color: Colors.white),),
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
                    color: Colors.amberAccent.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 77)),
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
                    color: Colors.green.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withValues(alpha: 77)),
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
                    color: Colors.red.withValues(alpha: 25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withValues(alpha: 77)),
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
        color = Colors.orangeAccent;
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
        color: color.withValues(alpha: 25),
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
    final authState = ref.watch(authProvider);
    final canApprove = authState.isManager || authState.isAdmin;
    final canDeliver = authState.isCobrador || authState.isManager || authState.isAdmin;

    List<Widget> buttons = [];

    if (listType == 'pending_approval' && canApprove) {
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
    } else if ((listType == 'ready_for_delivery' ||
        (listType == 'waiting_delivery' && credit.isReadyForDelivery)) && canDeliver) {
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
      case 'active':
        return Icons.playlist_add_check_circle_outlined;
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
      case 'active':
        return 'No hay créditos activos';
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
    final DateTime now = DateTime.now();
    // Por defecto, programar para el día siguiente a las 09:00 (fecha posterior al día)
    final DateTime tomorrow = now.add(const Duration(days: 1));
    DateTime selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);

    bool deliverImmediately = false;

    // Usamos StatefulBuilder para poder actualizar el diálogo cuando cambian los errores
    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final creditState = ref.watch(creditProvider);
          return AlertDialog(
            title: const Text('Aprobar para Entrega'),
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
                const Text('Fecha y hora de entrega programada:'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: now,
                      lastDate: DateTime(now.year + 1),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: deliverImmediately,
                  onChanged: (v) => setState(() => deliverImmediately = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Entregar inmediatamente al aprobar'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

                // Mostrar errores de validación si existen
                if (creditState.validationErrors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ValidationErrorDisplay(
                      errors: creditState.validationErrors,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool result;
                  if (deliverImmediately) {
                    result = await ref.read(creditProvider.notifier).approveAndDeliverCredit(
                          creditId: credit.id,
                          scheduledDeliveryDate: selectedDate,
                          approvalNotes: 'Aprobación rápida con entrega inmediata',
                          deliveryNotes: 'Entrega inmediata desde aprobación',
                        );
                  } else {
                    result = await ref
                        .read(creditProvider.notifier)
                        .approveCreditForDelivery(
                          creditId: credit.id,
                          scheduledDeliveryDate: selectedDate,
                          notes: 'Aprobación rápida para entrega',
                        );
                  }

                  if (result) {
                    Navigator.pop(context, true);
                    _loadInitialData();
                  } else {
                    // Actualizar el diálogo para mostrar los errores
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(deliverImmediately ? 'Aprobar y Entregar' : 'Aprobar'),
              ),
            ],
          );
        },
      ),
    );
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
    DateTime now = DateTime.now();
    DateTime selectedDate = credit.scheduledDeliveryDate ?? now;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmar Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
              ),
              Text(
                'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
              ),
              const SizedBox(height: 12),
              if (credit.scheduledDeliveryDate != null)
                Text(
                  'Programado: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              if (credit.scheduledDeliveryDate == null)
                const Text(
                  'Sin fecha programada. Puedes programar una antes de entregar.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              const SizedBox(height: 16),
              const Text('¿Cómo deseas proceder?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton.icon(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: now.subtract(const Duration(days: 0)),
                  lastDate: DateTime(now.year + 1),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });

                    // Llamar a reprogramación inmediatamente para dejar "fecha marcada"
                    final ok = await ref
                        .read(creditProvider.notifier)
                        .rescheduleCreditDelivery(
                          creditId: credit.id,
                          newScheduledDate: selectedDate,
                          reason: 'Reprogramación desde diálogo de entrega',
                        );
                    if (ok) {
                      if (context.mounted) Navigator.pop(context, 'rescheduled');
                    }
                  }
                }
              },
              icon: const Icon(Icons.event),
              label: const Text('Reprogramar fecha'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'deliver_now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entregar ahora'),
            ),
          ],
        ),
      ),
    );

    if (result == 'deliver_now') {
      await ref
          .read(creditProvider.notifier)
          .deliverCreditToClient(
            creditId: credit.id,
            notes: 'Entrega confirmada desde lista de espera',
          );
      _loadInitialData();
    } else if (result == 'rescheduled') {
      // Tras reprogramar, refrescar listas para reflejar la nueva fecha
      _loadInitialData();
    }
  }
}
