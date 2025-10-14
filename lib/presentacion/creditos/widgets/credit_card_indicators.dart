import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../datos/modelos/credito.dart';
import 'credit_info_chip.dart';

/// Widget que muestra el indicador de cuotas atrasadas o al día
class OverduePaymentsIndicator extends StatelessWidget {
  final Credito credit;

  const OverduePaymentsIndicator({
    super.key,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos del backend, no mostrar nada
    if (credit.expectedInstallments == null ||
        credit.completedPaymentsCount == null) {
      return const SizedBox.shrink();
    }

    final expectedPayments = credit.expectedInstallments!;
    final completedPayments = credit.completedPaymentsCount!;
    final overduePayments = expectedPayments - completedPayments;
    final hasOverduePayments = credit.isOverdue && overduePayments > 0;

    if (!hasOverduePayments) {
      // Mostrar estado positivo si está al día
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Al día ($completedPayments/$expectedPayments)',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar información de cuotas atrasadas
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            '$overduePayments cuota${overduePayments > 1 ? 's' : ''} atrasada${overduePayments > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra el monto atrasado en un chip
class OverdueAmountChip extends StatelessWidget {
  final Credito credit;

  const OverdueAmountChip({
    super.key,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    if (credit.overdueAmount == null || credit.overdueAmount! <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.money_off, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget que muestra una barra de progreso de pagos
class PaymentProgressBar extends StatelessWidget {
  final Credito credit;

  const PaymentProgressBar({
    super.key,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    if (credit.expectedInstallments == null ||
        credit.completedPaymentsCount == null) {
      return const SizedBox.shrink();
    }

    final expectedPayments = credit.expectedInstallments!;
    final completedPayments = credit.completedPaymentsCount!;
    final progressPercentage = expectedPayments > 0
        ? (completedPayments / expectedPayments).clamp(0.0, 1.0)
        : 0.0;
    final isOverdue = credit.isOverdue;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Progreso de Pagos',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  '$completedPayments de $expectedPayments cuotas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? Colors.red : Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? Colors.red : Colors.green,
              ),
              minHeight: 6,
            ),
          ),
          if (isOverdue &&
              credit.overdueAmount != null &&
              credit.overdueAmount! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Monto vencido: Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget que muestra información detallada de pagos (esperadas, pagadas, total)
class DetailedPaymentInfo extends StatelessWidget {
  final Credito credit;

  const DetailedPaymentInfo({
    super.key,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    // Solo mostrar si tenemos datos del backend
    if (credit.expectedInstallments == null ||
        credit.completedPaymentsCount == null) {
      return const SizedBox.shrink();
    }

    final expectedPayments = credit.expectedInstallments!;
    final completedPayments = credit.completedPaymentsCount!;
    final totalPaid = credit.totalPaid ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado de Pagos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: CreditInfoChip(
                  label: 'Esperadas',
                  value: '$expectedPayments',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CreditInfoChip(
                  label: 'Pagadas',
                  value: '$completedPayments',
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: CreditInfoChip(
                  label: 'Total',
                  value: 'Bs. ${NumberFormat('#,##0').format(totalPaid)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
