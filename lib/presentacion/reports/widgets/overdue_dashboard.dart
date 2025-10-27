import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

/// Dashboard de mora que muestra métricas principales
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

    return Column(
      children: [
        // Tarjetas principales
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'En Mora',
                'Bs ${totalOverdue.toStringAsFixed(2)}',
                Icons.warning,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Balance Total',
                'Bs ${totalBalance.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Créditos',
                '$totalCredits',
                Icons.credit_card,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                'Atraso Promedio',
                '${avgDaysOverdue.abs().toStringAsFixed(1)} d',
                Icons.schedule,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Tarjetas de severidad
        if (bySeverity != null) ...[
          Text(
            'Por Severidad',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSeverityCard(
                  'Leve',
                  bySeverity['light'] ?? 0,
                  Colors.amber,
                  context,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSeverityCard(
                  'Moderada',
                  bySeverity['moderate'] ?? 0,
                  Colors.orange,
                  context,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSeverityCard(
                  'Crítica',
                  bySeverity['severe'] ?? 0,
                  Colors.red,
                  context,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Construye tarjeta de severidad
  Widget _buildSeverityCard(String label, int count, Color color, BuildContext context) {
    final icon = _getIcon(label);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Obtiene icono por severidad
  IconData _getIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'leve':
        return Icons.info_outline;
      case 'moderada':
        return Icons.warning;
      case 'crítica':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  /// Construye una tarjeta de métrica
  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
