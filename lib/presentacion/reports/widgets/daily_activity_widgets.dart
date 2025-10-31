import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../datos/modelos/reporte/daily_activity_report.dart';

/// Card de resumen general del reporte
class DailyActivitySummaryCard extends StatelessWidget {
  final DailyActivitySummary summary;

  const DailyActivitySummaryCard({
    Key? key,
    required this.summary,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.8),
              Theme.of(context).primaryColor.withOpacity(0.5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen del Día',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatItem(
                  label: 'Total de Pagos',
                  value: summary.totalPayments.toString(),
                  icon: Icons.receipt,
                ),
                _StatItem(
                  label: 'Monto Recaudado',
                  value: summary.totalAmountFormatted,
                  icon: Icons.attach_money,
                  isHighlight: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Item individual de estadística
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isHighlight;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withOpacity(0.9),
              ),
        ),
      ],
    );
  }
}

/// Card para mostrar resumen por cobrador
class CobradorSummaryCard extends StatelessWidget {
  final String cobradorId;
  final CobradorSummary summary;
  final String? cobradorName;

  const CobradorSummaryCard({
    Key? key,
    required this.cobradorId,
    required this.summary,
    this.cobradorName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      (cobradorName ?? 'Cobrador').substring(0, 1),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cobradorName ?? 'Cobrador #$cobradorId',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: $cobradorId',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      summary.count.toString(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pagos',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        currencyFormat.format(summary.amount),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monto',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip para mostrar método de pago
class PaymentMethodChip extends StatelessWidget {
  final String method;

  const PaymentMethodChip({
    Key? key,
    required this.method,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late Color textColor;
    late IconData icon;
    late String label;

    switch (method.toLowerCase()) {
      case 'cash':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade700;
        icon = Icons.money;
        label = 'Efectivo';
        break;
      case 'card':
        backgroundColor = Colors.blue.withOpacity(0.2);
        textColor = Colors.blue.shade700;
        icon = Icons.credit_card;
        label = 'Tarjeta';
        break;
      case 'transfer':
        backgroundColor = Colors.purple.withOpacity(0.2);
        textColor = Colors.purple.shade700;
        icon = Icons.account_balance;
        label = 'Transferencia';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey.shade700;
        icon = Icons.payment;
        label = method;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: textColor),
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: textColor.withOpacity(0.5)),
    );
  }
}

/// Chip para mostrar estado de pago
class PaymentStatusChip extends StatelessWidget {
  final String status;

  const PaymentStatusChip({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late Color backgroundColor;
    late Color textColor;
    late String label;

    switch (status.toLowerCase()) {
      case 'completed':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green.shade700;
        label = 'Completado';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange.shade700;
        label = 'Pendiente';
        break;
      case 'failed':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red.shade700;
        label = 'Fallido';
        break;
      default:
        backgroundColor = Colors.grey.withOpacity(0.2);
        textColor = Colors.grey.shade700;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
      ),
      backgroundColor: backgroundColor,
      side: BorderSide(color: textColor.withOpacity(0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// Tabla de actividades diarias
class DailyActivityTable extends StatelessWidget {
  final List<DailyActivityItem> items;

  const DailyActivityTable({
    Key? key,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: MaterialStateProperty.all(
          Theme.of(context).primaryColor.withOpacity(0.1),
        ),
        columns: [
          DataColumn(
            label: Text(
              'Pago ID',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Cliente',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Monto',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Método',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Fecha',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          DataColumn(
            label: Text(
              'Estado',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
        rows: items
            .map(
              (item) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      '#${item.id}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 150,
                      child: Text(
                        item.clientName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      currencyFormat.format(item.amount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                    ),
                  ),
                  DataCell(
                    PaymentMethodChip(method: item.paymentMethod),
                  ),
                  DataCell(
                    Text(
                      DateFormat('dd/MM/yyyy').format(item.paymentDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  DataCell(
                    PaymentStatusChip(status: item.status),
                  ),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Card individual para mostrar un pago en vista de lista
class DailyActivityCard extends StatelessWidget {
  final DailyActivityItem item;
  final VoidCallback? onTap;

  const DailyActivityCard({
    Key? key,
    required this.item,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con ID y estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pago #${item.id}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${item.installmentText} • ${item.cobradorName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  PaymentStatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 12),
              Divider(height: 1),
              const SizedBox(height: 12),
              // Información principal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cliente',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.clientName,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Monto',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currencyFormat.format(item.amount),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Información adicional
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PaymentMethodChip(method: item.paymentMethod),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(item.paymentDate),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey,
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
}

/// Widget para mostrar lista de actividades en vista móvil
class DailyActivityListView extends StatelessWidget {
  final List<DailyActivityItem> items;
  final Function(DailyActivityItem)? onItemTap;

  const DailyActivityListView({
    Key? key,
    required this.items,
    this.onItemTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin actividad',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'No hay registros de pagos para mostrar',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return DailyActivityCard(
          item: item,
          onTap: () => onItemTap?.call(item),
        );
      },
    );
  }
}
