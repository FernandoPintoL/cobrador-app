import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

Widget buildTopClientsList(List clients, BuildContext context) {
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: clients.length > 10 ? 10 : clients.length,
    separatorBuilder: (_, __) => const Divider(height: 1),
    itemBuilder: (ctx, i) {
      final client = clients[i] as Map;
      final category = client['category']?.toString() ?? 'X';
      final clientName = client['client_name']?.toString() ?? '';
      final creditId = client['credit_id']?.toString() ?? '';
      final progress = client['progress'] ?? 0;
      final balance = client['balance'] ?? 0;
      final total = client['total'] ?? 0;
      Color catColor = Colors.purple;
      if (category == 'A') catColor = Colors.green;
      else if (category == 'B') catColor = Colors.blue;
      else if (category == 'C') catColor = Colors.orange;
      return ListTile(
        leading: CircleAvatar(backgroundColor: catColor.withOpacity(0.15), foregroundColor: catColor, child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold))),
        title: Text(clientName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('Crédito #$creditId • ${progress.toStringAsFixed(1)}% completado'),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(ReportFormatters.formatCurrency(balance), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          Text(ReportFormatters.formatCurrency(total), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ]),
      );
    },
  );
}

Widget buildPortfolioByCobrador(Map portfolioMap, BuildContext context) {
  final cobradores = portfolioMap.entries.toList();
  return ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: cobradores.length,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      final entry = cobradores[i];
      final cobradorName = entry.key;
      final data = entry.value as Map;
      final totalCredits = data['total_credits'] ?? 0;
      final activeCredits = data['active_credits'] ?? 0;
      final totalBalance = data['total_balance'] ?? 0;
      final totalLent = data['total_lent'] ?? 0;
      final portfolioQuality = data['portfolio_quality'] ?? 0;
      final overdue = data['overdue'] ?? 0;
      Color qualityColor = Colors.green;
      if (portfolioQuality < 60) qualityColor = Colors.red;
      else if (portfolioQuality < 80) qualityColor = Colors.orange;
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(child: Text(cobradorName, style: const TextStyle(fontWeight: FontWeight.bold))),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('${portfolioQuality.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, color: qualityColor, fontSize: 16)),
                    Text('Calidad', style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                  ]),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 12, runSpacing: 8, children: [
                buildPortfolioStat('Créditos', '$totalCredits', Icons.receipt),
                buildPortfolioStat('Activos', '$activeCredits', Icons.trending_up),
                buildPortfolioStat('Balance', ReportFormatters.formatCurrency(totalBalance), Icons.account_balance_wallet),
              ]),
              if (overdue > 0) ...[const SizedBox(height: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text('⚠️ $overdue en mora', style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)))],
            ],
          ),
        ),
      );
    },
  );
}

Widget buildPortfolioStat(String label, String value, IconData icon) {
  return Column(
    children: [
      Icon(icon, size: 18, color: Colors.indigo),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
    ],
  );
}

Widget buildPortfolioByCategory(Map categoryMap, BuildContext context) {
  final categories = categoryMap.entries.toList();
  return Wrap(
    spacing: 12,
    runSpacing: 12,
    children: categories.map((entry) {
      final category = entry.key;
      final data = entry.value as Map;
      final totalCredits = data['total_credits'] ?? 0;
      final totalBalance = data['total_balance'] ?? 0;
      Color catColor = Colors.purple;
      if (category == 'A') catColor = Colors.green;
      else if (category == 'B') catColor = Colors.blue;
      else if (category == 'C') catColor = Colors.orange;
      return SizedBox(
        width: 160,
        child: Card(
          elevation: 0,
          color: catColor.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                CircleAvatar(backgroundColor: catColor.withOpacity(0.2), foregroundColor: catColor, radius: 20, child: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                const SizedBox(height: 8),
                Text('$totalCredits', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Text('créditos', style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(ReportFormatters.formatCurrency(totalBalance), style: TextStyle(fontWeight: FontWeight.bold, color: catColor, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }).toList(),
  );
}
