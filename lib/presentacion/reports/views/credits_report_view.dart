import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
import '../widgets/credits_list_widget.dart';
import '../widgets/report_table.dart';
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

    // Formatear créditos para la tabla
    final List<Map<String, dynamic>> rows = credits.map<Map<String, dynamic>>((
      c,
    ) {
      final Map<String, dynamic> credit = Map<String, dynamic>.from(c as Map);

      // Extraer información
      final clientName = ReportFormatters.extractCreditClientName(credit);
      final cobradorName = ReportFormatters.extractCreditCobradorName(credit);
      final createdDate = ReportFormatters.formatDate(
        credit['created_at'] ?? '',
      );
      final endDate = ReportFormatters.formatDate(credit['end_date'] ?? '');
      final amount = ReportFormatters.formatCurrency(credit['amount'] ?? 0);
      final balance = ReportFormatters.formatCurrency(credit['balance'] ?? 0);
      final status = credit['status']?.toString() ?? 'Activo';
      final frequency = credit['frequency']?.toString() ?? 'N/A';

      return {
        'ID': credit['id']?.toString() ?? '',
        'Cliente': clientName,
        'Cobrador': cobradorName,
        'Estado': status,
        'Frecuencia': frequency,
        'Monto': amount,
        'Balance': balance,
        'Creación': createdDate,
        'Vencimiento': endDate,
      };
    }).toList();

    return buildTableFromJson(
      rows,
      columnOrder: [
        'ID',
        'Cliente',
        'Cobrador',
        'Estado',
        'Frecuencia',
        'Monto',
        'Balance',
        'Creación',
        'Vencimiento',
      ],
    );
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
              formatter: ReportFormatters.formatCurrency,
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
              formatter: ReportFormatters.formatCurrency,
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
