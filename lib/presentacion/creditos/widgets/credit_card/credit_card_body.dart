import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../datos/modelos/credito.dart';
import '../credit_info_chip.dart';
import '../credit_card_indicators.dart';

/// Body de la tarjeta de crédito que muestra la información principal
/// Incluye información específica según el tipo de lista
class CreditCardBody extends StatelessWidget {
  final Credito credit;
  final String listType;

  const CreditCardBody({
    super.key,
    required this.credit,
    required this.listType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información básica del crédito
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
                  if (credit.creator != null) ...[
                    Text(
                      'Creado por: ${credit.creator!.nombre}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('dd/MM/yyyy').format(credit.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (credit.scheduledDeliveryDate != null)
                  Text(
                    'Entregado: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
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
        _buildListTypeSpecificInfo(context),

        // Datos adicionales del crédito en chips
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            CreditInfoChip(
              label: 'Saldo',
              value: 'Bs. ${NumberFormat('#,##0.00').format(credit.balance)}',
            ),
            CreditInfoChip(
              label: 'Pagado',
              value: 'Bs. ${NumberFormat('#,##0.00').format(credit.totalPaid ?? ((credit.totalAmount ?? credit.amount) - credit.balance))}',
            ),
            if (credit.installmentAmount != null)
              CreditInfoChip(
                label: 'Cuota',
                value: 'Bs. ${NumberFormat('#,##0.00').format(credit.installmentAmount)}',
              ),
            CreditInfoChip(
              label: 'Pagadas',
              value: '${credit.completedPaymentsCount ?? credit.paidInstallments}',
            ),
            CreditInfoChip(
              label: 'Por pagar',
              value: '${credit.backendPendingInstallments ?? credit.pendingInstallments}',
            ),
            CreditInfoChip(label: 'Frecuencia', value: credit.frequencyLabel),
          ],
        ),

        // Indicadores de cuotas atrasadas desde el backend
        const SizedBox(height: 8),
        Column(
          children: [
            Row(
              children: [
                Expanded(child: OverduePaymentsIndicator(credit: credit)),
                const SizedBox(width: 8),
                OverdueAmountChip(credit: credit),
              ],
            ),
            // Mostrar barra de progreso de pagos para créditos con datos del backend
            if (credit.expectedInstallments != null &&
                credit.completedPaymentsCount != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: PaymentProgressBar(credit: credit),
              ),
          ],
        ),

        // Información detallada de pagos (solo en créditos con datos del backend)
        if (credit.expectedInstallments != null &&
            credit.completedPaymentsCount != null)
          DetailedPaymentInfo(credit: credit),
      ],
    );
  }

  /// Información específica según el tipo de lista
  Widget _buildListTypeSpecificInfo(BuildContext context) {
    if (listType == 'pending_approval') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amberAccent.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orangeAccent.withOpacity(0.77),
            ),
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
      );
    }

    if (listType == 'ready_for_delivery') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.77)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Listo para entrega hoy',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (listType == 'overdue_delivery') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.77)),
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
      );
    }

    if (listType == 'overdue_payments') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withOpacity(0.1),
                Colors.orange.withOpacity(0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.4)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.money_off_csred,
                    color: Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Crédito con cuotas vencidas',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (credit.expectedInstallments != null &&
                  credit.completedPaymentsCount != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cuotas esperadas: ${credit.expectedInstallments}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Pagadas: ${credit.completedPaymentsCount}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (credit.overdueAmount != null &&
                    credit.overdueAmount! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 14,
                        color: Colors.red,
                      ),
                      Text(
                        'Monto vencido: Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Obtener el color de la fecha de entrega según el estado
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
}
