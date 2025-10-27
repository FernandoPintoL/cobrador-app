import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

/// Tabla modernizada para vista de mora (alternativa a tarjetas)
class OverdueTable extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final String userRole;

  const OverdueTable({
    required this.items,
    this.userRole = 'admin',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No hay créditos en mora',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        horizontalMargin: 12,
        columns: _buildColumns(),
        rows: items.map((item) => _buildRow(item)).toList(),
      ),
    );
  }

  /// Construye las columnas según el rol
  List<DataColumn> _buildColumns() {
    return [
      DataColumn(label: _buildHeaderLabel('Cliente')),
      DataColumn(label: _buildHeaderLabel('Teléfono')),
      if (userRole == 'admin') DataColumn(label: _buildHeaderLabel('Cobrador')),
      DataColumn(label: _buildHeaderLabel('En Mora'), numeric: true),
      DataColumn(label: _buildHeaderLabel('Balance'), numeric: true),
      DataColumn(label: _buildHeaderLabel('Atrasadas')),
      DataColumn(label: _buildHeaderLabel('Atraso')),
      DataColumn(label: _buildHeaderLabel('Progreso')),
    ];
  }

  /// Construye una fila de datos
  DataRow _buildRow(Map<String, dynamic> item) {
    final client = item['client'] as Map<String, dynamic>?;
    final clientName = client?['name'] ?? 'Desconocido';
    final clientPhone = client?['phone'] ?? 'N/A';
    final cobradorName = item['created_by']?['name'] ?? 'Sin asignar';

    final overdueAmount = ReportFormatters.toDouble(item['overdue_amount'] ?? 0);
    final balance = ReportFormatters.toDouble(item['balance'] ?? 0);
    final daysOverdue = (item['days_overdue'] as num?)?.toInt() ?? 0;
    final overdueInstallments = item['overdue_installments'] ?? 0;
    final paidInstallments = item['paid_installments'] ?? 0;
    final totalInstallments = item['total_installments'] ?? 0;
    final completionRate = (item['completion_rate'] as num?)?.toDouble() ?? 0;

    final severityColor = _getSeverityColor(daysOverdue);

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.grey.shade50;
        }
        return Colors.white;
      }),
      cells: [
        DataCell(_buildClientCell(clientName)),
        DataCell(_buildPhoneCell(clientPhone)),
        if (userRole == 'admin')
          DataCell(_buildCobradorCell(cobradorName)),
        DataCell(_buildMoneyCell(overdueAmount, Colors.red)),
        DataCell(_buildMoneyCell(balance, Colors.orange)),
        DataCell(_buildOverdueCell(overdueInstallments, severityColor)),
        DataCell(_buildDaysOverdueCell(daysOverdue, severityColor)),
        DataCell(_buildProgressCell(paidInstallments, totalInstallments, completionRate)),
      ],
    );
  }

  /// Construye celda de cliente
  Widget _buildClientCell(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        name,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Construye celda de teléfono
  Widget _buildPhoneCell(String phone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone, size: 12, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            phone,
            style: const TextStyle(fontSize: 12, color: Colors.blue),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Construye celda de cobrador
  Widget _buildCobradorCell(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        name,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Construye celda de dinero
  Widget _buildMoneyCell(double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            amount >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 12,
            color: color.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Bs ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye celda de cuotas atrasadas
  Widget _buildOverdueCell(int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// Construye celda de días atrasados
  Widget _buildDaysOverdueCell(int days, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          '${days.abs()} d',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  /// Construye celda de progreso
  Widget _buildProgressCell(int paid, int total, double percentage) {
    final color = _getProgressColor(percentage);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$paid/$total',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 60,
              height: 3,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye label de encabezado
  Widget _buildHeaderLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
    );
  }

  /// Obtiene color de severidad
  Color _getSeverityColor(int daysOverdue) {
    final absDays = daysOverdue.abs();

    if (absDays >= 1 && absDays <= 5) return Colors.amber;
    if (absDays >= 6 && absDays <= 15) return Colors.orange;
    if (absDays > 15) return Colors.red;
    return Colors.grey;
  }

  /// Obtiene color de progreso
  Color _getProgressColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.amber;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }
}
