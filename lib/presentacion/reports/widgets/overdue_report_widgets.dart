import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

Widget buildSeverityDistribution(Map severityMap, BuildContext context) {
  final light = severityMap['light'] ?? 0;
  final moderate = severityMap['moderate'] ?? 0;
  final severe = severityMap['severe'] ?? 0;
  final total = light + moderate + severe;

  if (total == 0) {
    return const Text('No hay datos de gravedad disponibles');
  }

  double lightPercent = (light / total) * 100;
  double moderatePercent = (moderate / total) * 100;
  double severePercent = (severe / total) * 100;

  return Column(
    children: [
      buildSeverityBar(context, 'Ligera (1-7 días)', light, lightPercent, Colors.orange),
      const SizedBox(height: 12),
      buildSeverityBar(context, 'Moderada (8-30 días)', moderate, moderatePercent, Colors.deepOrange),
      const SizedBox(height: 12),
      buildSeverityBar(context, 'Severa (>30 días)', severe, severePercent, Colors.red),
    ],
  );
}

Widget buildSeverityBar(BuildContext context, String label, int count, double percent, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Row(children: [
            Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(width: 8),
            Text('${percent.toStringAsFixed(1)}%', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: percent / 100,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
        ),
      ),
    ],
  );
}

Widget buildTopDebtorsList(List topDebtors, BuildContext context) {
  if (topDebtors.isEmpty) {
    return const Text('No hay datos de deudores disponibles');
  }

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: topDebtors.length > 10 ? 10 : topDebtors.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final debtor = topDebtors[i] as Map;
      final clientName = debtor['client_name']?.toString() ?? 'Cliente';
      final creditId = debtor['credit_id']?.toString() ?? '';
      final daysOverdue = debtor['days_overdue']?.toString() ?? '0';
      final overdueAmount = debtor['overdue_amount'];
      final totalBalance = debtor['total_balance'];

      Color rankColor = Colors.grey;
      if (i == 0) rankColor = Colors.amber[700]!;
      else if (i == 1) rankColor = Colors.grey[400]!;
      else if (i == 2) rankColor = Colors.brown[300]!;

      return ListTile(
        dense: true,
        leading: CircleAvatar(
          backgroundColor: rankColor.withOpacity(0.15),
          foregroundColor: rankColor,
          radius: 18,
          child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Crédito #$creditId • $daysOverdue días de mora'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(ReportFormatters.formatCurrency(overdueAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 14)),
            Text('Balance: ${ReportFormatters.formatCurrency(totalBalance)}', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      );
    },
  );
}

Widget buildCobradorAnalysis(Map cobradorMap, BuildContext context) {
  if (cobradorMap.isEmpty) {
    return const Text('No hay datos por cobrador disponibles');
  }

  final cobradores = cobradorMap.entries.toList();

  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: cobradores.length,
    separatorBuilder: (_, __) => const Divider(height: 16),
    itemBuilder: (ctx, i) {
      final entry = cobradores[i];
      final cobradorName = entry.key;
      final data = entry.value as Map;
      final count = data['count'] ?? 0;
      final totalAmount = data['total_amount'] ?? 0;
      final avgDays = data['avg_days'] ?? 0.0;

      return Card(
        elevation: 0,
        color: Colors.blue.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(cobradorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  buildCobradorStat('Créditos', '$count', Icons.receipt),
                  buildCobradorStat('Monto', ReportFormatters.formatCurrency(totalAmount), Icons.attach_money),
                  buildCobradorStat('Promedio', '${avgDays.toStringAsFixed(1)} días', Icons.calendar_today),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildCobradorStat(String label, String value, IconData icon) {
  return Column(
    children: [
      Icon(icon, size: 18, color: Colors.blue[700]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ],
  );
}

Widget buildCategoryAnalysis(Map categoryMap, BuildContext context) {
  if (categoryMap.isEmpty) {
    return const Text('No hay datos por categoría disponibles');
  }

  final categories = categoryMap.entries.toList();

  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: categories.map((entry) {
      final category = entry.key;
      final data = entry.value as Map;
      final count = data['count'] ?? 0;
      final totalAmount = data['total_amount'] ?? 0;

      Color categoryColor = Colors.purple;
      if (category == 'A') categoryColor = Colors.green;
      else if (category == 'B') categoryColor = Colors.blue;
      else if (category == 'C') categoryColor = Colors.orange;

      return SizedBox(
        width: 160,
        child: Card(
          elevation: 0,
          color: categoryColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: categoryColor.withOpacity(0.2),
                      foregroundColor: categoryColor,
                      radius: 16,
                      child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 8),
                    Text('Categoría $category', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Créditos:', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Monto:', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  Text(ReportFormatters.formatCurrency(totalAmount), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: categoryColor)),
                ]),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
