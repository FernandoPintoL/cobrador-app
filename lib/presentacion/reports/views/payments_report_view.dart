import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
import '../widgets/payments_list_widget.dart';
import '../widgets/report_table.dart';
import '../widgets/summary_cards_builder.dart';
import 'base_report_view.dart';

/// Vista especializada para reportes de Pagos (Payments)
/// Muestra un resumen de pagos realizados con estadísticas y detalle
class PaymentsReportView extends BaseReportView {
  const PaymentsReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  IconData getReportIcon() => Icons.payments;

  @override
  String getReportTitle() => 'Reporte de Pagos';

  @override
  bool hasValidPayload() {
    if (!super.hasValidPayload()) return false;
    // Ahora accedemos a 'items' en lugar de 'payments'
    return payload is Map && (payload.containsKey('items') || payload.containsKey('payments'));
  }


  /// Verifica si el reporte es del día actual (para mostrar vista especial)
  bool _isTodayReport() {
    if (request.filters == null) return false;
    final startDate = request.filters!['start_date'];
    final endDate = request.filters!['end_date'];

    if (startDate == null || endDate == null) return false;

    try {
      final start = DateTime.parse(startDate.toString());
      final end = DateTime.parse(endDate.toString());
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      return startDate.toString().contains(todayStr) &&
          endDate.toString().contains(todayStr);
    } catch (_) {
      return false;
    }
  }

  /// Construye la tabla de pagos con columnas apropiadas
  Widget _buildPaymentsTable() {
    // Ahora accedemos a 'items', con fallback a 'payments' para backward compatibility
    final payments = payload is Map
      ? (payload['items'] ?? payload['payments']) as List?
      : null;

    if (payments == null || payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No hay pagos registrados',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Formatear pagos para la tabla
    final List<Map<String, dynamic>> rows = payments.map<Map<String, dynamic>>((
      p,
    ) {
      final Map<String, dynamic> pm = Map<String, dynamic>.from(p as Map);

      // Extraer información
      final clientName = ReportFormatters.extractPaymentClientName(pm);
      final cobradorName = ReportFormatters.extractPaymentCobradorName(pm);
      final paymentDate = ReportFormatters.formatDate(pm['payment_date'] ?? '');
      final amount = ReportFormatters.formatCurrency(pm['amount'] ?? 0);
      final method = pm['payment_method']?.toString() ?? 'N/A';
      final status = pm['status']?.toString() ?? 'Completado';

      return {
        'ID': pm['id']?.toString() ?? '',
        'Fecha': paymentDate,
        'Cuota': pm['installment_number']?.toString() ?? '',
        'Cobrador': cobradorName,
        'Cliente': clientName,
        'Monto': amount,
        'Tipo': method,
        'Estado': status,
        'Notas': pm['notes']?.toString() ?? '',
      };
    }).toList();

    return buildTableFromJson(
      rows,
      columnOrder: [
        'ID',
        'Fecha',
        'Cuota',
        'Cobrador',
        'Cliente',
        'Monto',
        'Tipo',
        'Estado',
      ],
    );
  }

  @override
  Widget buildReportSummary(BuildContext context) {
    // Mostrar rango de fechas si está disponible
    final startDate = request.filters?['start_date']?.toString() ?? '';
    final endDate = request.filters?['end_date']?.toString() ?? '';

    if (startDate.isEmpty || endDate.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            'Período: ${ReportFormatters.formatDate(startDate)} - ${ReportFormatters.formatDate(endDate)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
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
              title: 'Total Pagos',
              summaryKey: 'total_payments',
              icon: Icons.payments,
              color: Colors.green,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Monto Total',
              summaryKey: 'total_amount',
              icon: Icons.attach_money,
              color: Colors.blue,
              formatter: ReportFormatters.formatCurrency,
            ),
            SummaryCardConfig(
              title: 'Promedio',
              summaryKey: 'average_payment',
              icon: Icons.trending_up,
              color: Colors.orange,
              formatter: ReportFormatters.formatCurrency,
            ),
            SummaryCardConfig(
              title: 'Métodos',
              summaryKey: 'by_payment_method',
              icon: Icons.credit_card,
              color: Colors.purple,
              formatter: (value) => value is Map ? '${value.length}' : '0',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Vista especial si es reporte de hoy
        if (_isTodayReport()) ...[
          Text(
            'Pagos de Hoy (Detalle)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          buildTodayPaymentsList(
            // Acceder a 'items' con fallback a 'payments' para compatibility
            ((payload['items'] ?? payload['payments']) as List?)?.cast<Map<String, dynamic>>() ?? [],
            context,
          ),
          const SizedBox(height: 24),
        ],

        // Tabla de pagos
        Text(
          'Listado de Pagos',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildPaymentsTable(),
      ],
    );
  }
}
