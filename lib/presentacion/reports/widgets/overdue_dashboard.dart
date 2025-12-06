import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

/// Dashboard de mora con diseño Hero Stats - compacto y moderno
class OverdueDashboard extends StatelessWidget {
  final Map<String, dynamic> summary;

  const OverdueDashboard({
    required this.summary,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraer datos del summary
    final totalOverdue = ReportFormatters.toDouble(summary['total_overdue_amount'] ?? 0);
    final totalBalance = ReportFormatters.toDouble(summary['total_balance_overdue'] ?? 0);
    final totalCredits = summary['total_overdue_credits'] ?? 0;
    final avgDaysOverdue = summary['average_days_overdue'] ?? 0;
    final bySeverity = summary['by_severity'] as Map<String, dynamic>?;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.red.shade50,
              Colors.orange.shade50,
            ],
          ),
        ),
        child: Column(
          children: [
            // HERO STAT - Monto en Mora (Principal)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: Colors.red.shade700,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTO EN MORA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs ${totalOverdue.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // MÉTRICAS SECUNDARIAS - Grid compacto
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactMetric(
                      icon: Icons.account_balance_wallet,
                      label: 'Balance',
                      value: 'Bs ${totalBalance.toStringAsFixed(2)}',
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactMetric(
                      icon: Icons.credit_card,
                      label: 'Créditos',
                      value: '$totalCredits',
                      color: Colors.purple.shade700,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCompactMetric(
                      icon: Icons.schedule,
                      label: 'Atraso',
                      value: '${avgDaysOverdue.abs().toStringAsFixed(1)} d',
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // SEVERIDADES - Badges horizontales compactos
            if (bySeverity != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _buildSeverityBadge(
                        label: 'Leve',
                        count: bySeverity['light'] ?? 0,
                        color: Colors.amber,
                        icon: Icons.info_outline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _buildSeverityBadge(
                        label: 'Mod',
                        count: bySeverity['moderate'] ?? 0,
                        color: Colors.orange,
                        icon: Icons.warning_amber,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: _buildSeverityBadge(
                        label: 'Crít',
                        count: bySeverity['severe'] ?? 0,
                        color: Colors.red,
                        icon: Icons.error_outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Métrica compacta para el grid
  Widget _buildCompactMetric({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Badge de severidad compacto
  Widget _buildSeverityBadge({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.1,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
