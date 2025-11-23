import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../datos/modelos/credito.dart';
import '../credit_info_chip.dart';
import '../credit_card_indicators.dart';

/// Body de la tarjeta de crédito que muestra la información principal
/// Incluye información específica según el tipo de lista
class CreditCardBody extends StatefulWidget {
  final Credito credit;
  final String listType;

  const CreditCardBody({
    super.key,
    required this.credit,
    required this.listType,
  });

  @override
  State<CreditCardBody> createState() => _CreditCardBodyState();
}

class _CreditCardBodyState extends State<CreditCardBody> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Información básica del crédito - Diseño modernizado
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Monto principal con diseño destacado
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Bs. ${NumberFormat('#,##0.00').format(widget.credit.amount)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.credit.creator != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.credit.creator!.nombre,
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildDateInfo(context),
            ),
          ],
        ),

        // Información específica según el tipo de lista
        _buildListTypeSpecificInfo(context),

        // Información esencial visible siempre (solo 3 chips principales compactos)
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _CompactInfoChip(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Saldo',
                value: 'Bs. ${NumberFormat('#,##0').format(widget.credit.balance)}',
                color: widget.credit.balance > 0
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                textColor: widget.credit.balance > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CompactInfoChip(
                icon: Icons.payments_outlined,
                label: 'Cuotas',
                value: '${widget.credit.completedPaymentsCount ?? widget.credit.paidInstallments}/${widget.credit.backendTotalInstallments ?? widget.credit.totalInstallments}',
                color: Colors.blue.shade50,
                textColor: Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _CompactInfoChip(
                icon: Icons.calendar_today_outlined,
                label: 'Frecuencia',
                value: widget.credit.frequencyLabel,
                color: Colors.purple.shade50,
                textColor: Colors.purple.shade700,
              ),
            ),
          ],
        ),

        // Botón para expandir/colapsar detalles
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            setState(() {
              _showDetails = !_showDetails;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showDetails ? Icons.expand_less : Icons.expand_more,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _showDetails ? 'Ocultar detalles' : 'Ver más detalles',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Detalles expandibles
        if (_showDetails) ...[
          const SizedBox(height: 8),
          // Chips adicionales
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              CreditInfoChip(
                label: 'Pagado',
                value: 'Bs. ${NumberFormat('#,##0.00').format(widget.credit.totalPaid ?? ((widget.credit.totalAmount ?? widget.credit.amount) - widget.credit.balance))}',
              ),
              if (widget.credit.installmentAmount != null)
                CreditInfoChip(
                  label: 'Cuota',
                  value: 'Bs. ${NumberFormat('#,##0.00').format(widget.credit.installmentAmount)}',
                ),
              CreditInfoChip(
                label: 'Por pagar',
                value: '${widget.credit.backendPendingInstallments ?? widget.credit.pendingInstallments}',
              ),
            ],
          ),

          // Indicadores de cuotas atrasadas
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: OverduePaymentsIndicator(credit: widget.credit)),
                const SizedBox(width: 6),
                OverdueAmountChip(credit: widget.credit),
              ],
            ),
          ),

          // Barra de progreso
          if (widget.credit.expectedInstallments != null &&
              widget.credit.completedPaymentsCount != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: PaymentProgressBar(credit: widget.credit),
            ),

          // Información detallada de pagos
          if (widget.credit.expectedInstallments != null &&
              widget.credit.completedPaymentsCount != null)
            DetailedPaymentInfo(credit: widget.credit),
        ],
      ],
    );
  }

  /// Información específica según el tipo de lista
  Widget _buildListTypeSpecificInfo(BuildContext context) {
    if (widget.listType == 'pending_approval') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amberAccent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.77)),
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

    if (widget.listType == 'waiting_delivery') {
      // Mostrar información de entrega programada futura
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
          ),
          child: Row(
            children: [
              const Icon(Icons.schedule, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.credit.scheduledDeliveryDate != null
                      ? 'Programado para ${DateFormat('dd/MM/yyyy').format(widget.credit.scheduledDeliveryDate!)}'
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

    if (widget.listType == 'ready_for_delivery') {
      // Determinar si es urgente (hoy) o atrasada
      final isImmediate = widget.credit.immediateDeliveryRequested == true;
      final isOverdue = widget.credit.isOverdueForDelivery;

      Color bgColor;
      Color borderColor;
      Color textColor;
      IconData icon;
      String message;

      if (isOverdue) {
        bgColor = Colors.red.withValues(alpha: 0.15);
        borderColor = Colors.red;
        textColor = Colors.red;
        icon = Icons.warning;
        message = 'ENTREGA ATRASADA (${widget.credit.daysOverdueForDelivery} días)';
      } else if (isImmediate) {
        bgColor = Colors.orange.withValues(alpha: 0.15);
        borderColor = Colors.orange;
        textColor = Colors.orange;
        icon = Icons.flash_on;
        message = 'ENTREGA INMEDIATA - HOY';
      } else {
        bgColor = Colors.green.withValues(alpha: 0.15);
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

    if (widget.listType == 'overdue_delivery') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.77)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Entrega atrasada (${widget.credit.daysOverdueForDelivery} días)',
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

    if (widget.listType == 'overdue_payments') {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.red.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.1),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
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
              if (widget.credit.expectedInstallments != null &&
                  widget.credit.completedPaymentsCount != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Cuotas esperadas: ${widget.credit.expectedInstallments}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Pagadas: ${widget.credit.completedPaymentsCount}',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (widget.credit.overdueAmount != null &&
                    widget.credit.overdueAmount! > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.attach_money,
                        size: 14,
                        color: Colors.red,
                      ),
                      Text(
                        'Monto vencido: Bs. ${NumberFormat('#,##0.00').format(widget.credit.overdueAmount)}',
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

    switch (widget.credit.status) {
      case 'pending_approval':
        // Muestra cuándo se solicitó
        return [
          Text('Solicitado:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            DateFormat('dd/MM/yyyy').format(widget.credit.createdAt),
            style: highlightStyle.copyWith(color: Colors.orange),
          ),
        ];

      case 'waiting_delivery':
        // Muestra cuándo fue aprobado y cuándo debe entregarse
        final widgets = <Widget>[];

        if (widget.credit.approvedAt != null) {
          widgets.addAll([
            Text('Aprobado:', style: dateStyle.copyWith(fontSize: 10)),
            Text(
              DateFormat('dd/MM').format(widget.credit.approvedAt!),
              style: highlightStyle.copyWith(color: Colors.green),
            ),
          ]);
        }

        if (widget.credit.scheduledDeliveryDate != null) {
          if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 4));

          final isImmediate = widget.credit.immediateDeliveryRequested == true;
          final isOverdue = widget.credit.isOverdueForDelivery;
          final isToday = widget.credit.isReadyForDelivery;

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
            ).format(widget.credit.scheduledDeliveryDate!);
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

        if (widget.credit.deliveredAt != null) {
          widgets.addAll([
            Text('Entregado:', style: dateStyle.copyWith(fontSize: 10)),
            Text(
              DateFormat('dd/MM/yyyy').format(widget.credit.deliveredAt!),
              style: highlightStyle.copyWith(color: Colors.green),
            ),
          ]);
        }

        widgets.addAll([
          if (widgets.isNotEmpty) const SizedBox(height: 4),
          Text('Plazo:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            '${DateFormat('dd/MM').format(widget.credit.startDate)} - ${DateFormat('dd/MM').format(widget.credit.endDate)}',
            style: highlightStyle.copyWith(
              color: widget.credit.isOverdue ? Colors.red : Colors.blue,
            ),
          ),
        ]);

        return widgets;

      case 'completed':
        // Muestra cuándo se completó
        return [
          Text('Completado:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            DateFormat('dd/MM/yyyy').format(widget.credit.updatedAt),
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
            ).format(widget.credit.approvedAt ?? widget.credit.updatedAt),
            style: highlightStyle.copyWith(color: Colors.red),
          ),
          if (widget.credit.rejectionReason != null) ...[
            const SizedBox(height: 2),
            Text(
              widget.credit.rejectionReason!,
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
            DateFormat('dd/MM/yyyy').format(widget.credit.updatedAt),
            style: highlightStyle.copyWith(color: Colors.grey),
          ),
        ];

      case 'defaulted':
        // Muestra el plazo y resalta en rojo
        return [
          Text('En mora:', style: dateStyle.copyWith(fontSize: 10)),
          Text(
            '${DateFormat('dd/MM').format(widget.credit.startDate)} - ${DateFormat('dd/MM').format(widget.credit.endDate)}',
            style: highlightStyle.copyWith(color: Colors.red),
          ),
        ];

      default:
        // Por defecto muestra la fecha de creación
        return [
          Text(
            DateFormat('dd/MM/yyyy').format(widget.credit.createdAt),
            style: dateStyle,
          ),
        ];
    }
  }
}

/// Widget compacto para mostrar información con icono y valores
/// Diseñado para ocupar menos espacio que CreditInfoChip tradicional
class _CompactInfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color textColor;

  const _CompactInfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: textColor,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: textColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: textColor,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
