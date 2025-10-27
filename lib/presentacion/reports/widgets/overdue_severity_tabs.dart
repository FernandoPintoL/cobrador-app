import 'package:flutter/material.dart';
import '../utils/report_formatters.dart';

/// Widget que muestra créditos en mora organizados por severidad
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
    // Clasificar por severidad
    final light = _filterBySeverity('light');
    final moderate = _filterBySeverity('moderate');
    final severe = _filterBySeverity('severe');

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

        // Contenido del tab
        if (_selectedTab == 0) _buildCardsList(light, Colors.amber),
        if (_selectedTab == 1) _buildCardsList(moderate, Colors.orange),
        if (_selectedTab == 2) _buildCardsList(severe, Colors.red),
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
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
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

  /// Construye lista de tarjetas
  Widget _buildCardsList(List<Map<String, dynamic>> items, Color color) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle, size: 48, color: color.withValues(alpha: 0.3)),
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
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _OverdueCard(
        credit: items[i],
        severityColor: color,
        userRole: widget.userRole,
      ),
    );
  }

  /// Filtra créditos por severidad
  List<Map<String, dynamic>> _filterBySeverity(String severity) {
    return widget.items.where((item) {
      final daysOverdue = (item['days_overdue'] as num?)?.toInt() ?? 0;
      final absDays = daysOverdue.abs();

      switch (severity) {
        case 'light':
          return absDays >= 1 && absDays <= 5;
        case 'moderate':
          return absDays >= 6 && absDays <= 15;
        case 'severe':
          return absDays > 15;
        default:
          return false;
      }
    }).toList();
  }
}

/// Tarjeta individual de crédito en mora con expansión
class _OverdueCard extends StatefulWidget {
  final Map<String, dynamic> credit;
  final Color severityColor;
  final String userRole;

  const _OverdueCard({
    required this.credit,
    required this.severityColor,
    required this.userRole,
  });

  @override
  State<_OverdueCard> createState() => _OverdueCardState();
}

class _OverdueCardState extends State<_OverdueCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final client = widget.credit['client'] as Map<String, dynamic>?;
    final clientName = client?['name'] ?? 'Cliente desconocido';
    final clientPhone = client?['phone'] ?? 'N/A';
    final clientCategory = client?['client_category'] ?? 'N/A';

    final overdueAmount = ReportFormatters.toDouble(widget.credit['overdue_amount'] ?? 0);
    final balance = ReportFormatters.toDouble(widget.credit['balance'] ?? 0);
    final daysOverdue = (widget.credit['days_overdue'] as num?)?.toInt() ?? 0;
    final overdueInstallments = widget.credit['overdue_installments'] ?? 0;
    final paidInstallments = widget.credit['paid_installments'] ?? 0;
    final totalInstallments = widget.credit['total_installments'] ?? 0;
    final completionRate = (widget.credit['completion_rate'] as num?)?.toDouble() ?? 0;

    final frequency = widget.credit['frequency']?.toString() ?? 'N/A';
    final startDate = ReportFormatters.formatDate(widget.credit['start_date'] ?? '');
    final endDate = ReportFormatters.formatDate(widget.credit['end_date'] ?? '');

    final cobradorName = widget.credit['created_by']?['name'] ?? 'Sin asignar';

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.severityColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            // Header colapsable
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cliente y estado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                clientName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    clientPhone,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(Icons.badge, size: 12, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Cat. $clientCategory',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: widget.severityColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${daysOverdue.abs()} días',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: widget.severityColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Icon(
                              _isExpanded ? Icons.expand_less : Icons.expand_more,
                              color: Colors.grey[600],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Información financiera
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn('En Mora', 'Bs ${overdueAmount.toStringAsFixed(2)}', Colors.red),
                        _buildInfoColumn('Balance', 'Bs ${balance.toStringAsFixed(2)}', Colors.orange),
                        _buildInfoColumn('Cuotas Atrasadas', '$overdueInstallments', widget.severityColor),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Barra de progreso
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso: $paidInstallments/$totalInstallments',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${completionRate.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _getProgressColor(completionRate),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completionRate / 100,
                            minHeight: 6,
                            backgroundColor: Colors.grey.shade300,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getProgressColor(completionRate),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Contenido expandido
            if (_isExpanded) ...[
              const Divider(height: 1),
              _buildExpandedContent(
                context,
                clientName,
                clientPhone,
                cobradorName,
                frequency,
                startDate,
                endDate,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Construye columna de información
  Widget _buildInfoColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// Construye contenido expandido
  Widget _buildExpandedContent(
    BuildContext context,
    String clientName,
    String phone,
    String cobradorName,
    String frequency,
    String startDate,
    String endDate,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información adicional
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Cobrador:', cobradorName),
                _buildDetailRow('Frecuencia:', frequency),
                _buildDetailRow('Inicio:', startDate),
                _buildDetailRow('Vencimiento:', endDate),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Historial de pagos (si existen)
          if (widget.credit['payments'] != null &&
              (widget.credit['payments'] as List).isNotEmpty) ...[
            Text(
              'Últimos Pagos',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._buildPaymentHistory(widget.credit['payments'] as List),
            const SizedBox(height: 12),
          ],

          // Acciones
          _buildActions(context),
        ],
      ),
    );
  }

  /// Construye fila de detalle
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 11, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  /// Construye historial de pagos
  List<Widget> _buildPaymentHistory(List payments) {
    final recentPayments = payments.take(3).toList();

    return recentPayments.map((payment) {
      final p = payment as Map<String, dynamic>;
      final amount = ReportFormatters.toDouble(p['amount'] ?? 0);
      final date = ReportFormatters.formatDate(p['payment_date'] ?? '');
      final method = p['payment_method']?.toString() ?? 'N/A';

      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$date - $method',
                style: const TextStyle(fontSize: 10),
              ),
              Text(
                'Bs ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  /// Construye sección de acciones
  Widget _buildActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Acciones',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (widget.userRole == 'cobrador') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 16),
                  label: const Text('Llamar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Mensaje'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.location_on, size: 16),
                  label: const Text('Navegar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.attach_money, size: 16),
                  label: const Text('Pagar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.userRole == 'manager') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('Reasignar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Detalles'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ] else if (widget.userRole == 'admin') ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Cambiar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications, size: 16),
                  label: const Text('Notificar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.pause, size: 16),
                  label: const Text('Suspender'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Obtiene color de progreso
  Color _getProgressColor(double percentage) {
    if (percentage >= 75) return Colors.green;
    if (percentage >= 50) return Colors.amber;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }
}
