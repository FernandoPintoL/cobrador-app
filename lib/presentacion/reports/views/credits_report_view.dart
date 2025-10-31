import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
import '../widgets/credits_list_widget.dart';
import '../widgets/summary_cards_builder.dart';
import 'base_report_view.dart';

/// Vista especializada para reportes de Créditos (Credits)
/// Muestra un resumen de créditos activos y completados con detalles
class CreditsReportView extends BaseReportView {
  const CreditsReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  IconData getReportIcon() => Icons.credit_card;

  @override
  String getReportTitle() => 'Reporte de Créditos';

  @override
  bool hasValidPayload() {
    if (!super.hasValidPayload()) return false;
    // Ahora accedemos a 'items' en lugar de 'credits'
    return payload is Map && (payload.containsKey('items') || payload.containsKey('credits'));
  }


  /// Construye la tabla de créditos con columnas apropiadas
  Widget _buildCreditsTable() {
    // Ahora accedemos a 'items', con fallback a 'credits' para backward compatibility
    final credits = payload is Map
      ? (payload['items'] ?? payload['credits']) as List?
      : null;

    if (credits == null || credits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No hay créditos registrados',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return _buildModernCreditsTable(credits.cast<Map<String, dynamic>>());
  }

  /// Construye una tabla modernizada de créditos con colores e iconos
  Widget _buildModernCreditsTable(List<Map<String, dynamic>> credits) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        horizontalMargin: 12,
        columns: [
          DataColumn(label: _buildHeaderLabel('ID')),
          DataColumn(label: _buildHeaderLabel('Cliente')),
          DataColumn(label: _buildHeaderLabel('Cobrador')),
          DataColumn(label: _buildHeaderLabel('Estado')),
          DataColumn(label: _buildHeaderLabel('Frecuencia')),
          DataColumn(label: _buildHeaderLabel('Monto'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Balance'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Cuotas')),
          DataColumn(label: _buildHeaderLabel('Atraso')),
          DataColumn(label: _buildHeaderLabel('Pagado'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Estado Pago')),
        ],
        rows: credits
            .map((credit) => _buildCreditDataRow(credit))
            .toList(),
      ),
    );
  }

  /// Construye una fila de datos de crédito con colores e iconos
  DataRow _buildCreditDataRow(Map<String, dynamic> credit) {
    // Extraer datos del formato simplificado del endpoint de reportes
    final clientName = credit['client_name']?.toString() ?? 'N/A';
    final cobradorName = credit['created_by_name']?.toString() ??
        credit['delivered_by_name']?.toString() ??
        'N/A';

    final statusRaw = credit['status']?.toString();
    // El endpoint no incluye 'frequency', usar N/A
    final frequencyRaw = credit['frequency']?.toString() ?? 'N/A';

    // Valores numéricos
    final amountValue = ReportFormatters.toDouble(credit['amount'] ?? 0);
    final balanceValue = ReportFormatters.toDouble(credit['balance'] ?? 0);

    // En el endpoint simplificado, calcular total pagado: amount - balance
    final totalPaidValue = amountValue - balanceValue;

    // Información de cuotas
    final totalInstallments = credit['total_installments'] as int?;
    final completedInstallments = credit['completed_installments'] as int?;
    final installmentsOverdue = credit['installments_overdue'] as int? ?? 0;

    // Colores e iconos
    final statusColor = ReportFormatters.colorForCreditStatus(statusRaw);
    final frequencyColor = ReportFormatters.colorForFrequency(frequencyRaw);
    final paymentStatusColor = ReportFormatters.colorForPaymentStatus(totalInstallments, completedInstallments);
    final paymentStatusIcon = ReportFormatters.getPaymentStatusIcon(totalInstallments, completedInstallments);

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.grey.shade50;
        }
        return Colors.white;
      }),
      cells: [
        DataCell(_buildCellContent(credit['id']?.toString() ?? '', color: Colors.blue, isNumber: true)),
        DataCell(_buildCellContent(clientName)),
        DataCell(_buildCellContent(cobradorName, color: Colors.green)),
        DataCell(_buildStatusCell(statusRaw, statusColor)),
        DataCell(_buildFrequencyCell(frequencyRaw, frequencyColor)),
        DataCell(_buildMoneyCell(amountValue)),
        DataCell(_buildMoneyCell(balanceValue)),
        DataCell(_buildInstallmentsCell(completedInstallments ?? 0, totalInstallments ?? 0)),
        DataCell(_buildOverdueCell(installmentsOverdue)),
        DataCell(_buildMoneyCell(totalPaidValue)),
        DataCell(_buildPaymentStatusCell(totalInstallments, completedInstallments, paymentStatusColor, paymentStatusIcon)),
      ],
    );
  }

  /// Construye una celda de contenido con color opcional
  Widget _buildCellContent(String text, {Color? color, bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: isNumber ? FontWeight.w600 : FontWeight.normal,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Construye una celda de dinero con formato especial
  Widget _buildMoneyCell(double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        'Bs ${amount.toStringAsFixed(2)}',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.green,
        ),
        textAlign: TextAlign.right,
      ),
    );
  }

  /// Construye una celda de estado de crédito con icono y color
  Widget _buildStatusCell(String? status, Color color) {
    final statusText = ReportFormatters.translateCreditStatus(status);
    final statusIcon = _getCreditStatusIcon(status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(statusIcon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              statusText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una celda de frecuencia con icono y color
  Widget _buildFrequencyCell(String? frequency, Color color) {
    final frequencyText = ReportFormatters.translateFrequency(frequency);
    final frequencyIcon = _getFrequencyIcon(frequency);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(frequencyIcon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              frequencyText,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una celda de cuotas pagadas
  Widget _buildInstallmentsCell(int paid, int total) {
    final percentage = total > 0 ? (paid * 100 / total).toInt() : 0;
    final color = _getProgressColor(percentage);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$paid/$total',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: 70,
              height: 3,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una celda de cuotas atrasadas
  Widget _buildOverdueCell(int overdue) {
    if (overdue == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, size: 14, color: Colors.green),
              const SizedBox(width: 4),
              const Text(
                'Al día',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning, size: 14, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              '$overdue atrasada${overdue > 1 ? 's' : ''}',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye una celda de estado de pago de cuotas
  Widget _buildPaymentStatusCell(int? totalInstallments, int? paidInstallments, Color color, IconData icon) {
    final label = ReportFormatters.getPaymentStatusLabel(totalInstallments, paidInstallments);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el label del encabezado con estilo
  Widget _buildHeaderLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  /// Obtiene el icono para un estado de crédito
  IconData _getCreditStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending_approval':
        return Icons.hourglass_empty;
      case 'waiting_delivery':
        return Icons.local_shipping;
      case 'active':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.info_outline;
    }
  }

  /// Obtiene el icono para una frecuencia
  IconData _getFrequencyIcon(String? frequency) {
    switch ((frequency ?? '').toLowerCase()) {
      case 'daily':
        return Icons.calendar_today;
      case 'weekly':
        return Icons.calendar_view_week;
      case 'biweekly':
        return Icons.calendar_view_week;
      case 'monthly':
        return Icons.calendar_view_month;
      case 'yearly':
        return Icons.event_note;
      default:
        return Icons.schedule;
    }
  }

  /// Obtiene el color basado en el progreso de cuotas
  Color _getProgressColor(int percentage) {
    if (percentage >= 100) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 50) return Colors.amber;
    if (percentage >= 25) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    // Ahora accedemos a 'items', con fallback a 'credits' para backward compatibility
    final credits = payload is Map
      ? (payload['items'] ?? payload['credits']) as List?
      : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones de descarga
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => ReportDownloadHelper.downloadReport(
                  context,
                  ref,
                  request,
                  'excel',
                ),
                icon: const Icon(Icons.grid_on),
                label: const Text('Excel'),
              ),
              ElevatedButton.icon(
                onPressed: () => ReportDownloadHelper.downloadReport(
                  context,
                  ref,
                  request,
                  'pdf',
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF'),
              ),
            ],
          ),
        ),

        // Resumen de estadísticas
        Text(
          'Resumen General',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SummaryCardsBuilder(
          payload: payload,
          cards: [
            SummaryCardConfig(
              title: 'Total Créditos',
              summaryKey: 'total_credits',
              icon: Icons.credit_card,
              color: Colors.blue,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Monto Total',
              summaryKey: 'total_amount',
              icon: Icons.attach_money,
              color: Colors.green,
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Créditos Activos',
              summaryKey: 'active_credits',
              icon: Icons.trending_up,
              color: Colors.orange,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Completados',
              summaryKey: 'completed_credits',
              icon: Icons.check_circle,
              color: Colors.purple,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Balance Pendiente',
              summaryKey: 'total_balance',
              icon: Icons.account_balance_wallet,
              color: Colors.red,
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Lista de créditos con detalles
        if (credits != null && credits.isNotEmpty) ...[
          Text(
            'Detalles de Créditos',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          buildCreditsList(
            credits.cast<Map<String, dynamic>>(),
            context,
          ),
          const SizedBox(height: 24),
        ],

        // Tabla de créditos
        Text(
          'Listado Completo',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildCreditsTable(),
      ],
    );
  }
}
