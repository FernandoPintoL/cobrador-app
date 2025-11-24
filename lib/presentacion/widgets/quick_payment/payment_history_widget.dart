import 'package:flutter/material.dart';
import '../../../datos/modelos/credito/pago.dart';
import 'package:intl/intl.dart';

/// Widget que muestra el historial de pagos optimizado con ordenamiento y limitación
class PaymentHistoryWidget extends StatefulWidget {
  final List<Pago> payments;
  final int initialLimit;

  const PaymentHistoryWidget({
    super.key,
    required this.payments,
    this.initialLimit = 5,
  });

  @override
  State<PaymentHistoryWidget> createState() => _PaymentHistoryWidgetState();
}

class _PaymentHistoryWidgetState extends State<PaymentHistoryWidget> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    if (widget.payments.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No hay pagos registrados',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    }

    // Ordenar pagos por número de cuota (ascendente)
    final sortedPayments = List<Pago>.from(widget.payments);
    sortedPayments.sort((a, b) {
      final aInstallment = a.installmentNumber ?? 0;
      final bInstallment = b.installmentNumber ?? 0;
      return aInstallment.compareTo(bInstallment);
    });

    // Limitar la cantidad de pagos mostrados
    final displayPayments = _showAll
        ? sortedPayments
        : sortedPayments.take(widget.initialLimit).toList();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado
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

            // Lista de pagos
            ...displayPayments.map((payment) => _buildPaymentItem(payment)),

            // Botón para mostrar más/menos
            if (widget.payments.length > widget.initialLimit) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                  icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                  label: Text(
                    _showAll
                        ? 'Ver menos'
                        : 'Ver todos (${widget.payments.length - widget.initialLimit} más)',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(Pago payment) {
    final isToday = _isToday(payment.paymentDate);
    final hasCashBalance = _hasCashBalance(payment);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bs ${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(payment.paymentDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          _getPaymentMethodIcon(payment.paymentType),
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getPaymentMethodLabel(payment.paymentType),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Advertencia de cash_balance_id null
          if (!hasCashBalance) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 14, color: Colors.orange[800]),
                  const SizedBox(width: 4),
                  Text(
                    'Sin balance de caja asociado',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Información del cobrador que recibió el pago
          if (payment.cobrador != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.person, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  'Recibido por: ${payment.cobrador!.nombre}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  bool _hasCashBalance(Pago payment) {
    // Verificar si el pago tiene un cash_balance_id asociado
    return payment.cashBalanceId != null;
  }

  IconData _getPaymentMethodIcon(String? paymentType) {
    switch (paymentType?.toLowerCase()) {
      case 'cash':
        return Icons.money;
      case 'transfer':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
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
}
