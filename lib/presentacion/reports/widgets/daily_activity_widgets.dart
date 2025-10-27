import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

Widget buildDailyActivitiesList(List activities, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: activities.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final activity = activities[i] as Map;
      final cobradorName = activity['cobrador_name']?.toString() ?? 'Cobrador';
      final cashBalance = activity['cash_balance'] is Map ? activity['cash_balance'] as Map : {};
      final creditsDelivered = activity['credits_delivered'] is Map ? activity['credits_delivered'] as Map : {};
      final paymentsCollected = activity['payments_collected'] is Map ? activity['payments_collected'] as Map : {};
      final expectedPayments = activity['expected_payments'] is Map ? activity['expected_payments'] as Map : {};
      final balanceStatus = cashBalance['status']?.toString() ?? 'not_opened';
      final efficiency = expectedPayments['efficiency'] ?? 0;
      Color statusColor = Colors.grey;
      String statusLabel = 'No abierta';
      if (balanceStatus == 'open') { statusColor = Colors.blue; statusLabel = 'Abierta'; }
      else if (balanceStatus == 'closed') { statusColor = Colors.green; statusLabel = 'Cerrada'; }
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 12),
                  Expanded(child: Text(cobradorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  Chip(label: Text(statusLabel), backgroundColor: statusColor.withOpacity(0.1), side: BorderSide(color: statusColor), avatar: Icon(Icons.circle, size: 12, color: statusColor)),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              if (cashBalance.isNotEmpty) ...[
                Row(children: [Icon(Icons.account_balance_wallet, size: 20, color: Colors.green), const SizedBox(width: 8), const Text('Caja:', style: TextStyle(fontWeight: FontWeight.w600))]),
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 8, children: [
                  buildDailyStat('Inicial', ReportFormatters.formatCurrency(cashBalance['initial_amount'] ?? 0)),
                  buildDailyStat('Recaudado', ReportFormatters.formatCurrency(cashBalance['collected_amount'] ?? 0)),
                  buildDailyStat('Prestado', ReportFormatters.formatCurrency(cashBalance['lent_amount'] ?? 0)),
                  buildDailyStat('Final', ReportFormatters.formatCurrency(cashBalance['final_amount'] ?? 0)),
                ]),
                const SizedBox(height: 12),
              ],
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(Icons.local_shipping, size: 20, color: Colors.blue), const SizedBox(width: 8), Text('Créditos entregados: ${creditsDelivered['count'] ?? 0}')]),
                Text(ReportFormatters.formatCurrency(creditsDelivered['total_amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(Icons.payment, size: 20, color: Colors.teal), const SizedBox(width: 8), Text('Pagos cobrados: ${paymentsCollected['count'] ?? 0}')]),
                Text(ReportFormatters.formatCurrency(paymentsCollected['total_amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ]),
              if (expectedPayments.isNotEmpty) ...[const SizedBox(height: 8), Row(children: [Icon(Icons.speed, size: 20, color: Colors.orange), const SizedBox(width: 8), Text('Eficiencia: '), Text('${expectedPayments['collected'] ?? 0}/${expectedPayments['count'] ?? 0}')])],
            ],
          ),
        ),
      );
    },
  );
}

Widget buildDailyStat(String label, String value) {
  return Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );
}
