import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
import '../widgets/balances_list_widget.dart';
import '../widgets/report_table.dart';
import '../widgets/summary_cards_builder.dart';
import 'base_report_view.dart';

/// Vista especializada para reportes de Saldos (Balances)
/// Muestra un resumen de balances de caja con estadísticas y detalle
class BalancesReportView extends BaseReportView {
  const BalancesReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  IconData getReportIcon() => Icons.account_balance_wallet;

  @override
  String getReportTitle() => 'Reporte de Saldos';

  @override
  bool hasValidPayload() {
    if (!super.hasValidPayload()) return false;
    // Ahora accedemos a 'items' en lugar de 'balances'
    return payload is Map && (payload.containsKey('items') || payload.containsKey('balances'));
  }


  /// Construye la tabla de balances con columnas apropiadas
  Widget _buildBalancesTable() {
    // Ahora accedemos a 'items', con fallback a 'balances' para backward compatibility
    final balances = payload is Map
      ? (payload['items'] ?? payload['balances']) as List?
      : null;

    if (balances == null || balances.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'No hay saldos registrados',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Formatear balances para la tabla
    final List<Map<String, dynamic>> rows = balances.map<Map<String, dynamic>>((
      b,
    ) {
      final Map<String, dynamic> balance = Map<String, dynamic>.from(b as Map);

      // Extraer información
      final cobrador = ReportFormatters.extractBalanceCobradorName(balance);
      final fecha = ReportFormatters.extractBalanceDate(balance);
      final inicial = ReportFormatters.pickAmount(balance, [
        'initial',
        'initial_amount',
        'opening',
      ]);
      final recaudado = ReportFormatters.pickAmount(balance, [
        'collected',
        'collected_amount',
        'income',
      ]);
      final prestado = ReportFormatters.pickAmount(balance, [
        'lent',
        'lent_amount',
        'loaned',
      ]);
      final finalVal = ReportFormatters.pickAmount(balance, [
        'final',
        'final_amount',
        'closing',
      ]);
      final diferencia = ReportFormatters.computeBalanceDifference(balance);
      final notas = (balance['notes'] ?? balance['description'] ?? '')
          .toString();

      return {
        'Fecha': fecha,
        'Cobrador': cobrador,
        'Inicial': ReportFormatters.formatCurrency(inicial),
        'Recaudado': ReportFormatters.formatCurrency(recaudado),
        'Prestado': ReportFormatters.formatCurrency(prestado),
        'Final': ReportFormatters.formatCurrency(finalVal),
        'Diferencia': ReportFormatters.formatCurrency(diferencia),
        'Notas': notas,
      };
    }).toList();

    return buildTableFromJson(
      rows,
      columnOrder: [
        'Fecha',
        'Cobrador',
        'Inicial',
        'Recaudado',
        'Prestado',
        'Final',
        'Diferencia',
        'Notas',
      ],
    );
  }

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    // Ahora accedemos a 'items', con fallback a 'balances' para backward compatibility
    final balances = payload is Map
      ? (payload['items'] ?? payload['balances']) as List?
      : null;
    final hasBalances = balances != null && balances.isNotEmpty;

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
              title: 'Registros',
              summaryKey: 'total_records',
              icon: Icons.description,
              color: Colors.blue,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Inicial Total',
              summaryKey: 'total_initial',
              icon: Icons.trending_up,
              color: Colors.orange,
              formatter: ReportFormatters.formatCurrency,
            ),
            SummaryCardConfig(
              title: 'Recaudado',
              summaryKey: 'total_collected',
              icon: Icons.attach_money,
              color: Colors.green,
              formatter: ReportFormatters.formatCurrency,
            ),
            SummaryCardConfig(
              title: 'Prestado',
              summaryKey: 'total_lent',
              icon: Icons.trending_down,
              color: Colors.red,
              formatter: ReportFormatters.formatCurrency,
            ),
            SummaryCardConfig(
              title: 'Final Total',
              summaryKey: 'total_final',
              icon: Icons.account_balance,
              color: Colors.purple,
              formatter: ReportFormatters.formatCurrency,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Lista de balances con detalles (si hay datos)
        if (hasBalances) ...[
          Text(
            'Detalles de Saldos',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          buildBalancesList(
            balances?.cast<Map<String, dynamic>>() ?? [],
            context,
          ),
          const SizedBox(height: 24),
        ] else
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'No hay registros de saldos para el período seleccionado',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.amber[700]),
                  ),
                ),
              ],
            ),
          ),

        // Tabla de balances (solo si hay datos)
        if (hasBalances) ...[
          Text(
            'Listado Completo',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildBalancesTable(),
        ],
      ],
    );
  }
}
