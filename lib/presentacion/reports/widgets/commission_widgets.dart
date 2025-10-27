import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

Widget buildTopEarnersList(List earners, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: earners.length > 5 ? 5 : earners.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final earner = earners[i] as Map;
      final name = earner['name']?.toString() ?? 'Cobrador';
      final collectionRate = earner['collection_rate'] ?? 0;
      final commission = earner['commission'] ?? 0;
      Color rankColor = Colors.grey;
      if (i == 0) rankColor = Colors.amber[700]!;
      else if (i == 1) rankColor = Colors.grey[400]!;
      else if (i == 2) rankColor = Colors.brown[300]!;
      return ListTile(
        dense: true,
        leading: CircleAvatar(backgroundColor: rankColor.withOpacity(0.15), foregroundColor: rankColor, radius: 18, child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold))),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Cobranza: ${collectionRate.toStringAsFixed(1)}%'),
        trailing: Text(ReportFormatters.formatCurrency(commission), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
      );
    },
  );
}

Widget buildCommissionsList(List commissions, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: commissions.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final c = commissions[i] as Map;
      final cobradorName = c['cobrador_name']?.toString() ?? 'Cobrador';
      final collected = c['total_collected'] ?? 0;
      final lent = c['total_lent'] ?? 0;
      final collectionRate = c['collection_rate'] ?? 0;
      final baseCommission = c['base_commission'] ?? 0;
      final bonus = c['bonus'] ?? 0;
      final totalCommission = c['total_commission'] ?? 0;
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(cobradorName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
                  Text(ReportFormatters.formatCurrency(totalCommission), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 8, children: [
                buildCommissionStat('Cobrado', ReportFormatters.formatCurrency(collected), Icons.payments),
                buildCommissionStat('Prestado', ReportFormatters.formatCurrency(lent), Icons.trending_up),
                buildCommissionStat('Tasa', '${collectionRate.toStringAsFixed(1)}%', Icons.percent),
              ]),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(Icons.attach_money, size: 16, color: Colors.green), const SizedBox(width: 4), Text('Base:', style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
                Text(ReportFormatters.formatCurrency(baseCommission), style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
              if (bonus > 0) ...[
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [Icon(Icons.card_giftcard, size: 16, color: Colors.orange), const SizedBox(width: 4), Text('Bonus:', style: TextStyle(color: Colors.grey[600], fontSize: 12))]),
                  Text(ReportFormatters.formatCurrency(bonus), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                ]),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget buildCommissionStat(String label, String value, IconData icon) {
  return Column(
    children: [
      Icon(icon, size: 18, color: Colors.green),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
    ],
  );
}
