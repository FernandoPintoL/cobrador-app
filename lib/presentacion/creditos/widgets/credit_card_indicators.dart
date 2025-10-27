import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../datos/modelos/credito.dart';
import 'credit_info_chip.dart';

/// Widget que muestra el indicador de cuotas atrasadas o al día con color de alerta
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
    final daysOverdueValue = credit.daysOverdue;

    if (!hasOverduePayments) {
      // Mostrar estado positivo si está al día
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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

    // Usar color basado en días de retraso
    final alertColor = credit.overdueColor;
    final alertIcon = daysOverdueValue > 3 ? Icons.error : Icons.warning;
    final daysText = daysOverdueValue == 1 ? 'día' : 'días';

    // Mostrar información de cuotas atrasadas
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alertColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(alertIcon, size: 14, color: alertColor),
          const SizedBox(width: 4),
          Text(
            '$overduePayments cuota${overduePayments > 1 ? 's' : ''} atrasada${overduePayments > 1 ? 's' : ''} ($daysOverdueValue $daysText)',
            style: TextStyle(
              color: alertColor,
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
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
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
    final progressColor = isOverdue ? credit.overdueColor : Colors.green;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: progressColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: progressColor.withValues(alpha: 0.2),
          width: 1,
        ),
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
                    color: progressColor,
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
                progressColor,
              ),
              minHeight: 6,
            ),
          ),
          if (isOverdue &&
              credit.overdueAmount != null &&
              credit.overdueAmount! > 0) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Monto vencido: Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: progressColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    credit.overdueStatusLabel,
                    style: TextStyle(
                      fontSize: 9,
                      color: progressColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
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
        color: Theme.of(context).colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
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
