import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../datos/modelos/credito.dart';
import '../../../negocio/providers/credit_provider.dart';
import '../payment_schedule_calendar.dart';

/// Widget que permite alternar entre vista de Historial y Cronograma de pagos
class PaymentViewWidget extends ConsumerStatefulWidget {
  final Credito credit;
  final List<Pago> payments;
  final List<PaymentSchedule>? schedule;

  const PaymentViewWidget({
    super.key,
    required this.credit,
    required this.payments,
    this.schedule,
  });

  @override
  ConsumerState<PaymentViewWidget> createState() => _PaymentViewWidgetState();
}

class _PaymentViewWidgetState extends ConsumerState<PaymentViewWidget> {
  bool _showSchedule = false; // false = Historial, true = Cronograma
  List<PaymentSchedule>? _cachedSchedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Toggle para cambiar entre vistas
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.history,
                    label: 'Historial',
                    isSelected: !_showSchedule,
                    onTap: () {
                      setState(() {
                        _showSchedule = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildToggleButton(
                    icon: Icons.calendar_month,
                    label: 'Cronograma',
                    isSelected: _showSchedule,
                    onTap: () {
                      setState(() {
                        _showSchedule = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido según la vista seleccionada
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _showSchedule ? _buildScheduleView() : _buildHistoryView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      key: const ValueKey('history'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Historial de Pagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${widget.payments.length} pagos',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Reutilizar la lógica del PaymentHistoryWidget pero sin el Card
        _buildHistoryContent(),
      ],
    );
  }

  Widget _buildScheduleView() {
    return FutureBuilder<List<PaymentSchedule>>(
      future: _getSchedule(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error al cargar cronograma: ${snapshot.error}',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final schedule = snapshot.data ?? [];

        if (schedule.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'No hay cronograma disponible',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        return Column(
          key: const ValueKey('schedule'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cronograma de Pagos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Vista completa de todas las cuotas',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            PaymentScheduleCalendar(
              schedule: schedule,
              credit: widget.credit,
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryContent() {
    if (widget.payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'No hay pagos registrados',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    // Ordenar pagos por número de cuota
    final sortedPayments = List<Pago>.from(widget.payments);
    sortedPayments.sort((a, b) {
      final aInstallment = a.installmentNumber ?? 0;
      final bInstallment = b.installmentNumber ?? 0;
      return aInstallment.compareTo(bInstallment);
    });

    // Mostrar solo los últimos 5 pagos por defecto
    final displayPayments = sortedPayments.take(5).toList();

    return Column(
      children: [
        ...displayPayments.map((payment) => _buildPaymentItem(payment)),
        if (widget.payments.length > 5) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Mostrar todos los pagos en un diálogo o navegar a una vista completa
              _showAllPayments(context, sortedPayments);
            },
            child: Text('Ver todos (${widget.payments.length - 5} más)'),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentItem(Pago payment) {
    final isToday = _isToday(payment.paymentDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.green[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isToday ? Colors.green : Colors.grey[300]!,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Número de cuota
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isToday ? Colors.green : Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '#${payment.installmentNumber ?? "?"}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Información del pago
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bs ${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(payment.paymentDate)} • ${_getPaymentMethodLabel(payment.paymentType)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          if (isToday)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'HOY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<List<PaymentSchedule>> _getSchedule() async {
    // Si ya tenemos el schedule provisto como parámetro, usarlo
    if (widget.schedule != null) {
      return widget.schedule!;
    }

    // Si ya lo cargamos antes, usar el cache
    if (_cachedSchedule != null) {
      return _cachedSchedule!;
    }

    // Cargar desde el API
    try {
      final details = await ref.read(creditProvider.notifier).getCreditFullDetails(widget.credit.id);
      final schedule = details?.schedule ?? [];

      setState(() {
        _cachedSchedule = schedule;
      });

      return schedule;
    } catch (e) {
      return [];
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getPaymentMethodLabel(String? paymentType) {
    switch (paymentType?.toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'card':
        return 'Tarjeta';
      default:
        return paymentType ?? 'N/A';
    }
  }

  void _showAllPayments(BuildContext context, List<Pago> payments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Todos los Pagos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentItem(payments[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
