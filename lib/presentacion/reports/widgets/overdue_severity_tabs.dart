import 'package:flutter/material.dart';
import '../../../datos/modelos/reporte/overdue_report_model.dart';

/// Widget que muestra créditos en mora organizados por severidad - VERSIÓN COMPACTA
class OverdueSeverityTabs extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String userRole;

  const OverdueSeverityTabs({
    required this.items,
    this.userRole = 'admin',
    Key? key,
  }) : super(key: key);

  @override
  State<OverdueSeverityTabs> createState() => _OverdueSeverityTabsState();
}

class _OverdueSeverityTabsState extends State<OverdueSeverityTabs> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    // Convertir items a modelo tipado
    final typedItems = widget.items
        .map((item) => OverdueReportItem.fromJson(item))
        .toList();

    // Clasificar por severidad
    final light = typedItems.where((item) => item.severity == 'light').toList();
    final moderate = typedItems.where((item) => item.severity == 'moderate').toList();
    final severe = typedItems.where((item) => item.severity == 'severe').toList();

    return Column(
      children: [
        // Tabs con vista mejorada
        Row(
          children: [
            _buildSeverityCard('Leve', light.length, Colors.amber, Icons.info_outline, 0),
            const SizedBox(width: 12),
            _buildSeverityCard('Moderada', moderate.length, Colors.orange, Icons.warning, 1),
            const SizedBox(width: 12),
            _buildSeverityCard('Crítica', severe.length, Colors.red, Icons.error, 2),
          ],
        ),
        const SizedBox(height: 24),

        // Contenido del tab - VERSIÓN COMPACTA
        if (_selectedTab == 0) _buildCompactList(light),
        if (_selectedTab == 1) _buildCompactList(moderate),
        if (_selectedTab == 2) _buildCompactList(severe),
      ],
    );
  }

  /// Construye tarjeta visual de severidad
  Widget _buildSeverityCard(String label, int count, Color color, IconData icon, int index) {
    final isSelected = _selectedTab == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedTab = index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : color.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: isSelected ? 0.6 : 0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? color : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construye lista compacta de créditos en mora
  Widget _buildCompactList(List<OverdueReportItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: Colors.green.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              const Text('No hay créditos en esta categoría'),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) => _CompactOverdueCard(item: items[i]),
    );
  }
}

/// Tarjeta compacta de crédito en mora
class _CompactOverdueCard extends StatelessWidget {
  final OverdueReportItem item;

  const _CompactOverdueCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: item.categoryColor.withValues(alpha: 0.2),
        child: Text(
          item.clientName.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: item.categoryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        item.clientName,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 3),
              Text(
                '${item.absDaysOverdue}d',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
              const SizedBox(width: 6),
              Icon(Icons.receipt_long, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  '${item.overdueInstallments} cuotas',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.account_balance_wallet, size: 11, color: Colors.grey[600]),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  item.overdueAmountFormatted,
                  style: TextStyle(
                    fontSize: 11,
                    color: item.severityColor,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.categoryColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: item.categoryColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              item.categoryLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: item.categoryColor,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: item.severityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.severityLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: item.severityColor,
              ),
            ),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Información financiera
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Monto Total',
                      item.amountFormatted,
                      Icons.attach_money,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Balance',
                      item.balanceFormatted,
                      Icons.account_balance,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Cuotas Vencidas',
                      '${item.overdueInstallments}',
                      Icons.receipt,
                      Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      'Completado',
                      '${item.completionRate.toStringAsFixed(1)}%',
                      Icons.pie_chart,
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      'Cobrador',
                      item.cobradorName,
                      Icons.person,
                    ),
                    if (item.startDateFormatted != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        'Fecha Inicio',
                        item.startDateFormatted!,
                        Icons.calendar_month,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
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
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
