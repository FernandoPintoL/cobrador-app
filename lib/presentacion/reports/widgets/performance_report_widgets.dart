import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

Widget buildTopPerformersList(List performers, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: performers.length > 5 ? 5 : performers.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final performer = performers[i] as Map;
      final name = performer['name']?.toString() ?? 'Cobrador';
      final collectionRate = performer['collection_rate'] ?? 0;
      final portfolioQuality = performer['portfolio_quality'] ?? 0;
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
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('Cobranza: ${collectionRate.toStringAsFixed(1)}% • Calidad: ${portfolioQuality.toStringAsFixed(1)}%'),
        trailing: const Icon(Icons.star, color: Colors.amber),
      );
    },
  );
}

Widget buildPerformanceList(List performance, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: performance.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final p = performance[i] as Map;
      final cobradorName = p['cobrador_name']?.toString() ?? 'Cobrador';
      final managerName = p['manager_name']?.toString() ?? '';
      final metrics = p['metrics'] is Map ? p['metrics'] as Map : {};
      final creditsDelivered = metrics['credits_delivered'] ?? 0;
      final totalLent = metrics['total_amount_lent'] ?? 0;
      final totalCollected = metrics['total_amount_collected'] ?? 0;
      final collectionRate = metrics['collection_rate'] ?? 0;
      final portfolioQuality = metrics['portfolio_quality'] ?? 0;
      final efficiencyScore = metrics['efficiency_score'] ?? 0;
      final activeCredits = metrics['active_credits'] ?? 0;
      final overdueCredits = metrics['overdue_credits'] ?? 0;
      Color performanceColor = Colors.green;
      if (collectionRate < 60) performanceColor = Colors.red;
      else if (collectionRate < 75) performanceColor = Colors.orange;
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(backgroundColor: performanceColor.withOpacity(0.15), foregroundColor: performanceColor, child: Text('${i + 1}')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cobradorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        if (managerName.isNotEmpty) Text('Manager: $managerName', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Row(children: [Icon(Icons.star, size: 16, color: Colors.amber), const SizedBox(width: 4), Text(efficiencyScore.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold))]),
                    Text('Eficiencia', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ]),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                buildPerformanceStat('Entregados', '$creditsDelivered', Icons.local_shipping, Colors.blue),
                buildPerformanceStat('Prestado', ReportFormatters.formatCurrency(totalLent), Icons.trending_up, Colors.green),
                buildPerformanceStat('Cobrado', ReportFormatters.formatCurrency(totalCollected), Icons.payments, Colors.teal),
              ]),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                buildPerformanceStat('Tasa Cobranza', '${collectionRate.toStringAsFixed(1)}%', Icons.percent, performanceColor),
                buildPerformanceStat('Calidad Cartera', '${portfolioQuality.toStringAsFixed(1)}%', Icons.star, Colors.amber),
                buildPerformanceStat('Activos', '$activeCredits', Icons.trending_up, Colors.indigo),
              ]),
              if (overdueCredits > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Text('$overdueCredits créditos en mora', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

Widget buildPerformanceStat(String label, String value, IconData icon, Color color) {
  return Column(
    children: [
      Icon(icon, size: 20, color: color),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
    ],
  );
}
