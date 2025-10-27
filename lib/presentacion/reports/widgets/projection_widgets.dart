import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

Widget buildFrequencyDistribution(Map frequencies, BuildContext context) {
  return Column(children: [
    buildFrequencyRow('Diario', frequencies['daily_count'] ?? 0, frequencies['daily_amount'] ?? 0, Colors.red),
    const SizedBox(height: 12),
    buildFrequencyRow('Semanal', frequencies['weekly_count'] ?? 0, frequencies['weekly_amount'] ?? 0, Colors.orange),
    const SizedBox(height: 12),
    buildFrequencyRow('Quincenal', frequencies['biweekly_count'] ?? 0, frequencies['biweekly_amount'] ?? 0, Colors.blue),
    const SizedBox(height: 12),
    buildFrequencyRow('Mensual', frequencies['monthly_count'] ?? 0, frequencies['monthly_amount'] ?? 0, Colors.green),
  ]);
}

Widget buildFrequencyRow(String label, int count, num amount, Color color) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
      Row(
        children: [
          Text('$count pagos', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 16),
          Text(ReportFormatters.formatCurrency(amount), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    ],
  );
}

Widget buildProjectionsList(List projections, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: projections.length > 30 ? 30 : projections.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final proj = projections[i] as Map;
      final period = proj['period']?.toString() ?? '';
      final paymentsCount = proj['payments_count'] ?? 0;
      final paymentsAmount = proj['payments_amount'] ?? 0;
      final overdue = proj['overdue'] ?? 0;
      final pending = proj['pending'] ?? 0;
      return ListTile(
        title: Text(period, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$paymentsCount pagos esperados'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(ReportFormatters.formatCurrency(paymentsAmount), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            if (overdue > 0) Text('⚠️ $overdue vencidos', style: const TextStyle(fontSize: 11, color: Colors.red)),
            if (pending > 0) Text('⏳ $pending pendientes', style: const TextStyle(fontSize: 11, color: Colors.orange)),
          ],
        ),
      );
    },
  );
}
