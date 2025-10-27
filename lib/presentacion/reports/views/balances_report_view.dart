import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
import '../widgets/balances_list_widget.dart';
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


  /// Construye la tabla de balances modernizada
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

    return _buildModernBalancesTable(balances.cast<Map<String, dynamic>>());
  }

  /// Construye una tabla modernizada de balances con colores e iconos
  Widget _buildModernBalancesTable(List<Map<String, dynamic>> balances) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 8,
        horizontalMargin: 12,
        columns: [
          DataColumn(label: _buildHeaderLabel('Fecha')),
          DataColumn(label: _buildHeaderLabel('Cobrador')),
          DataColumn(label: _buildHeaderLabel('Estado')),
          DataColumn(label: _buildHeaderLabel('Inicial'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Recaudado'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Prestado'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Final'), numeric: true),
          DataColumn(label: _buildHeaderLabel('Diferencia'), numeric: true),
        ],
        rows: balances
            .map((balance) => _buildBalanceDataRow(balance))
            .toList(),
      ),
    );
  }

  /// Construye una fila de datos de balance con colores e iconos
  DataRow _buildBalanceDataRow(Map<String, dynamic> balance) {
    final cobrador = ReportFormatters.extractBalanceCobradorName(balance);
    final fecha = ReportFormatters.extractBalanceDate(balance);
    final status = (balance['status'] ?? 'unknown').toString().toLowerCase();

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
    final difClr = ReportFormatters.colorForDifference(diferencia);

    return DataRow(
      color: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.hovered)) {
          return Colors.grey.shade50;
        }
        return Colors.white;
      }),
      cells: [
        DataCell(_buildCellContent(fecha)),
        DataCell(_buildCellContent(cobrador, color: Colors.green)),
        DataCell(_buildStatusBadge(status)),
        DataCell(_buildMoneyCell(inicial, Colors.blueGrey)),
        DataCell(_buildMoneyCell(recaudado, Colors.green)),
        DataCell(_buildMoneyCell(prestado, Colors.orange)),
        DataCell(_buildMoneyCell(finalVal, Colors.indigo)),
        DataCell(_buildDifferenceCell(diferencia, difClr)),
      ],
    );
  }

  /// Construye una celda de contenido
  Widget _buildCellContent(String text, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 13,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Construye una celda de dinero con color según el tipo
  Widget _buildMoneyCell(double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(
            amount >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 14,
            color: color.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 4),
          Text(
            'Bs ${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// Construye una celda de diferencia con indicador visual
  Widget _buildDifferenceCell(double diff, Color color) {
    final isOk = diff.abs() < 0.01;

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
            if (isOk)
              const Icon(Icons.check_circle, size: 14, color: Colors.green)
            else
              Icon(Icons.warning, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              'Bs ${diff.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un badge de estado con color e icono
  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;

    switch (status) {
      case 'open':
        bgColor = Colors.amber.withValues(alpha: 0.1);
        textColor = Colors.amber[700]!;
        icon = Icons.lock_open;
        label = 'Abierto';
        break;
      case 'closed':
        bgColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue[700]!;
        icon = Icons.lock;
        label = 'Cerrado';
        break;
      case 'reconciled':
        bgColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green[700]!;
        icon = Icons.verified;
        label = 'Conciliado';
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey[700]!;
        icon = Icons.help_outline;
        label = 'Desconocido';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Construye el label del encabezado
  Widget _buildHeaderLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
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
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Recaudado',
              summaryKey: 'total_collected',
              icon: Icons.attach_money,
              color: Colors.green,
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Prestado',
              summaryKey: 'total_lent',
              icon: Icons.trending_down,
              color: Colors.red,
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Final Total',
              summaryKey: 'total_final',
              icon: Icons.account_balance,
              color: Colors.purple,
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Estado de los balances
        Text(
          'Estado de Balances',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SummaryCardsBuilder(
          payload: payload,
          cards: [
            SummaryCardConfig(
              title: 'Abiertos',
              summaryKey: 'open_balances',
              icon: Icons.lock_open,
              color: Colors.amber,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Cerrados',
              summaryKey: 'closed_balances',
              icon: Icons.lock,
              color: Colors.blue,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Conciliados',
              summaryKey: 'reconciled_balances',
              icon: Icons.verified,
              color: Colors.green,
              formatter: (value) => '$value',
            ),
            SummaryCardConfig(
              title: 'Discrepancias',
              summaryKey: 'total_discrepancies',
              icon: Icons.warning,
              color: Colors.red,
              formatter: (value) => 'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
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
            balances.cast<Map<String, dynamic>>(),
            context,
          ),
          const SizedBox(height: 24),
        ] else
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
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
