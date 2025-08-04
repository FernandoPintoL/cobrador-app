import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../datos/modelos/credito.dart';
import 'credit_form_screen.dart';
import 'credit_payment_screen.dart';

class CreditDetailScreen extends ConsumerStatefulWidget {
  final Credito credit;

  const CreditDetailScreen({super.key, required this.credit});

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _paymentAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);

    // Buscar el crédito actualizado en el estado
    final currentCredit = creditState.credits.firstWhere(
      (c) => c.id == widget.credit.id,
      orElse: () => widget.credit,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crédito #${currentCredit.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editCredit(currentCredit),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, currentCredit),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Información', icon: Icon(Icons.info_outline)),
            Tab(text: 'Pagos', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInformationTab(currentCredit),
          _buildPaymentsTab(currentCredit),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToPaymentScreen(currentCredit),
              icon: const Icon(Icons.payment),
              label: const Text('Procesar Pago'),
            )
          : null,
    );
  }

  Future<void> _navigateToPaymentScreen(Credito credit) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreditPaymentScreen(credit: credit),
      ),
    );

    // Si se procesó un pago exitosamente, actualizar la pantalla
    if (result == true) {
      // Recargar créditos para obtener información actualizada
      ref.read(creditProvider.notifier).loadCredits();
    }
  }

  Widget _buildInformationTab(Credito credit) {
    final progress = (credit.amount - credit.balance) / credit.amount;
    final daysRemaining = credit.endDate.difference(DateTime.now()).inDays;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Estado del crédito
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Estado del Crédito',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      _buildStatusChip(credit.status),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progreso
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progreso:',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Información de montos
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Monto Total',
                          'Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
                          Icons.attach_money,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Saldo Pendiente',
                          'Bs. ${NumberFormat('#,##0.00').format(credit.balance)}',
                          Icons.account_balance_wallet,
                          credit.balance > 0 ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Información de fechas
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          'Días Restantes',
                          daysRemaining > 0 ? '$daysRemaining días' : 'Vencido',
                          Icons.calendar_today,
                          daysRemaining > 7
                              ? Colors.green
                              : daysRemaining > 0
                              ? Colors.orange
                              : Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          'Frecuencia',
                          credit.frequencyLabel,
                          Icons.schedule,
                          Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  // Alertas de atención
                  if (credit.requiresAttention) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este crédito requiere atención: ${_getAttentionReason(credit)}',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Botones de acción rápida
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToPaymentScreen(credit),
                          icon: const Icon(Icons.payment),
                          label: const Text('Procesar Pago'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _tabController.animateTo(
                              1,
                            ); // Cambiar a pestaña de pagos
                          },
                          icon: const Icon(Icons.history),
                          label: const Text('Ver Pagos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Información del cliente
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información del Cliente',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      credit.client?.nombre ?? 'Cliente #${credit.clientId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (credit.client?.email != null)
                          Text('Email: ${credit.client!.email}'),
                        if (credit.client?.telefono != null)
                          Text('Teléfono: ${credit.client!.telefono}'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fechas del crédito
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fechas del Crédito',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildDateInfo('Fecha de Inicio', credit.startDate),
                  const SizedBox(height: 8),
                  _buildDateInfo('Fecha de Vencimiento', credit.endDate),
                  const SizedBox(height: 8),
                  _buildDateInfo('Fecha de Creación', credit.createdAt),
                ],
              ),
            ),
          ),

          // Notas
          if (credit.notes != null && credit.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(credit.notes!),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(Credito credit) {
    final payments = credit.payments ?? [];

    return Column(
      children: [
        // Resumen de pagos
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPaymentSummary(
                'Total Pagado',
                'Bs. ${NumberFormat('#,##0.00').format(credit.amount - credit.balance)}',
                Icons.payment,
                Colors.green,
              ),
              _buildPaymentSummary(
                'Número de Pagos',
                '${payments.length}',
                Icons.receipt,
                Colors.blue,
              ),
              if (credit.paymentAmount != null)
                _buildPaymentSummary(
                  'Cuota Sugerida',
                  'Bs. ${NumberFormat('#,##0.00').format(credit.paymentAmount!)}',
                  Icons.schedule,
                  Colors.orange,
                ),
            ],
          ),
        ),

        // Lista de pagos
        Expanded(
          child: payments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay pagos registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Los pagos aparecerán aquí una vez registrados',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.payment,
                            color: Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          'Bs. ${NumberFormat('#,##0.00').format(payment.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(payment.paymentDate),
                            ),
                            if (payment.notes != null &&
                                payment.notes!.isNotEmpty)
                              Text(
                                payment.notes!,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '#${payment.id}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'active':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completado';
        break;
      case 'defaulted':
        color = Colors.red;
        label = 'En Mora';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(DateFormat('dd/MM/yyyy').format(date)),
      ],
    );
  }

  String _getAttentionReason(Credito credit) {
    if (credit.endDate.isBefore(DateTime.now())) {
      return 'crédito vencido';
    }
    if (credit.endDate.difference(DateTime.now()).inDays <= 7) {
      return 'próximo a vencer';
    }
    if (credit.balance > credit.amount * 0.8) {
      return 'poco progreso en pagos';
    }
    return 'requiere seguimiento';
  }

  Future<void> _editCredit(Credito credit) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => CreditFormScreen(credit: credit)),
    );

    if (result == true) {
      // Recargar créditos para obtener los datos actualizados
      ref.read(creditProvider.notifier).loadCredits();
    }
  }

  void _handleMenuAction(String action, Credito credit) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation(credit);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(Credito credit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar este crédito?\n\n'
          'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}\n'
          'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .deleteCredit(credit.id);
      if (success && mounted) {
        Navigator.pop(context); // Regresar a la lista de créditos
      }
    }
  }
}
