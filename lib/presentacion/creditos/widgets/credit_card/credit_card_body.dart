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
              children: _buildDateInfo(context),
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
              value:
                  'Bs. ${NumberFormat('#,##0.00').format(credit.totalPaid ?? ((credit.totalAmount ?? credit.amount) - credit.balance))}',
            ),
            if (credit.installmentAmount != null)
              CreditInfoChip(
                label: 'Cuota',
                value:
                    'Bs. ${NumberFormat('#,##0.00').format(credit.installmentAmount)}',
              ),
            CreditInfoChip(
              label: 'Pagadas',
              value:
                  '${credit.completedPaymentsCount ?? credit.paidInstallments}',
            ),
            CreditInfoChip(
              label: 'Por pagar',
              value:
                  '${credit.backendPendingInstallments ?? credit.pendingInstallments}',
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
            border: Border.all(color: Colors.orangeAccent.withOpacity(0.77)),
          ),
          child: const Row(
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
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

    if (listType == 'waiting_delivery') {
      // Mostrar información de entrega programada futura
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  credit.scheduledDeliveryDate != null
                      ? 'Programado para ${DateFormat('dd/MM/yyyy').format(credit.scheduledDeliveryDate!)}'
                      : 'Entrega programada pendiente',
                  style: const TextStyle(
                    color: Colors.blue,
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
      // Determinar si es urgente (hoy) o atrasada
      final isImmediate = credit.immediateDeliveryRequested == true;
      final isOverdue = credit.isOverdueForDelivery;

      Color bgColor;
      Color borderColor;
      Color textColor;
      IconData icon;
      String message;

      if (isOverdue) {
        bgColor = Colors.red.withOpacity(0.15);
        borderColor = Colors.red;
        textColor = Colors.red;
        icon = Icons.warning;
        message = 'ENTREGA ATRASADA (${credit.daysOverdueForDelivery} días)';
      } else if (isImmediate) {
        bgColor = Colors.orange.withOpacity(0.15);
        borderColor = Colors.orange;
        textColor = Colors.orange;
        icon = Icons.flash_on;
        message = 'ENTREGA INMEDIATA - HOY';
      } else {
        bgColor = Colors.green.withOpacity(0.15);
        borderColor = Colors.green;
        textColor = Colors.green;
        icon = Icons.check_circle;
        message = 'Listo para entregar HOY';
      }

      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
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

  /// Construye la información de fechas según el estado del crédito
  List<Widget> _buildDateInfo(BuildContext context) {
    final dateStyle = TextStyle(
      fontSize: 11,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
    final highlightStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
    );

    switch (credit.status) {
      case 'pending_approval':
        // Muestra cuándo se solicitó
        return [
          Text('Solicitado:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            DateFormat('dd/MM/yyyy').format(credit.createdAt),
            style: highlightStyle.copyWith(color: Colors.orange),
          ),
        ];

      case 'waiting_delivery':
        // Muestra cuándo fue aprobado y cuándo debe entregarse
        final widgets = <Widget>[];

        if (credit.approvedAt != null) {
          widgets.addAll([
            Text('Aprobado:', style: dateStyle.copyWith(fontSize: 10)),
            Text(
              DateFormat('dd/MM').format(credit.approvedAt!),
              style: highlightStyle.copyWith(color: Colors.green),
            ),
          ]);
        }

        if (credit.scheduledDeliveryDate != null) {
          if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 4));

          final isImmediate = credit.immediateDeliveryRequested == true;
          final isOverdue = credit.isOverdueForDelivery;
          final isToday = credit.isReadyForDelivery;

          Color deliveryColor;
          String deliveryLabel;

          if (isImmediate) {
            deliveryColor = Colors.red;
            deliveryLabel = 'HOY';
          } else if (isOverdue) {
            deliveryColor = Colors.red;
            deliveryLabel = 'ATRASADA';
          } else if (isToday) {
            deliveryColor = Colors.green;
            deliveryLabel = 'HOY';
          } else {
            deliveryColor = Colors.blue;
            deliveryLabel = DateFormat(
              'dd/MM',
            ).format(credit.scheduledDeliveryDate!);
          }

          widgets.addAll([
            Text('Entregar:', style: dateStyle.copyWith(fontSize: 10)),
            Text(
              deliveryLabel,
              style: highlightStyle.copyWith(color: deliveryColor),
            ),
          ]);
        }

        return widgets.isNotEmpty
            ? widgets
            : [Text('En espera', style: dateStyle)];

      case 'active':
        // Muestra cuándo fue entregado y el plazo del crédito
        final widgets = <Widget>[];

        if (credit.deliveredAt != null) {
          widgets.addAll([
            Text('Entregado:', style: dateStyle.copyWith(fontSize: 10)),
            Text(
              DateFormat('dd/MM/yyyy').format(credit.deliveredAt!),
              style: highlightStyle.copyWith(color: Colors.green),
            ),
          ]);
        }

        widgets.addAll([
          if (widgets.isNotEmpty) const SizedBox(height: 4),
          Text('Plazo:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            '${DateFormat('dd/MM').format(credit.startDate)} - ${DateFormat('dd/MM').format(credit.endDate)}',
            style: highlightStyle.copyWith(
              color: credit.isOverdue ? Colors.red : Colors.blue,
            ),
          ),
        ]);

        return widgets;

      case 'completed':
        // Muestra cuándo se completó
        return [
          Text('Completado:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            DateFormat('dd/MM/yyyy').format(credit.updatedAt),
            style: highlightStyle.copyWith(color: Colors.green),
          ),
        ];

      case 'rejected':
        // Muestra cuándo fue rechazado
        return [
          Text('Rechazado:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            DateFormat(
              'dd/MM/yyyy',
            ).format(credit.approvedAt ?? credit.updatedAt),
            style: highlightStyle.copyWith(color: Colors.red),
          ),
          if (credit.rejectionReason != null) ...[
            const SizedBox(height: 2),
            Text(
              credit.rejectionReason!,
              style: dateStyle.copyWith(
                fontSize: 10,
                color: Colors.red.shade700,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ],
        ];

      case 'cancelled':
        // Muestra cuándo fue cancelado
        return [
          Text('Cancelado:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            DateFormat('dd/MM/yyyy').format(credit.updatedAt),
            style: highlightStyle.copyWith(color: Colors.grey),
          ),
        ];

      case 'defaulted':
        // Muestra el plazo y resalta en rojo
        return [
          Text('En mora:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            '${DateFormat('dd/MM').format(credit.startDate)} - ${DateFormat('dd/MM').format(credit.endDate)}',
            style: highlightStyle.copyWith(color: Colors.red),
          ),
        ];

      default:
        // Por defecto muestra la fecha de creación
        return [
          Text(
            DateFormat('dd/MM/yyyy').format(credit.createdAt),
            style: dateStyle,
          ),
        ];
    }
  }
}
