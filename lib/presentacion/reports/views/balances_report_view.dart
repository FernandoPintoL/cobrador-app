import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
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
    // ✅ El backend SIEMPRE envía 'items' (estandarizado)
    return payload is Map && payload.containsKey('items');
  }

  /// Banner de contexto mostrando el cobrador dueño de los balances
  Widget _buildCobradorContextBanner(BuildContext context, List? balances) {
    if (balances == null || balances.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);

    // Verificar si hay filtro de cobrador activo en el request
    final filters = request.filters;
    final hasCobradorFilter = filters?.containsKey('cobrador_id') == true &&
        filters!['cobrador_id'] != null &&
        filters['cobrador_id'].toString().isNotEmpty;

    // Determinar el mensaje del banner
    String bannerText;
    IconData bannerIcon;

    if (hasCobradorFilter) {
      // Hay filtro específico: mostrar el nombre del cobrador del primer balance
      final firstBalance = balances.first as Map<String, dynamic>;
      final cobradorName = firstBalance['cobrador_name']?.toString() ?? 'Cobrador';
      bannerText = 'Mostrando balances de: $cobradorName';
      bannerIcon = Icons.person;
    } else {
      // Sin filtro: mostrar que se ven balances de todos los cobradores asignados
      bannerText = 'Mostrando balances de todos tus cobradores asignados';
      bannerIcon = Icons.people;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(bannerIcon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              bannerText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: hasCobradorFilter ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Header de grupo que muestra el cobrador cuando cambia
  Widget _buildCobradorGroupHeader(BuildContext context, Map<String, dynamic> balance) {
    final cobradorName = balance['cobrador_name']?.toString() ?? 'Cobrador Desconocido';
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.primary,
            width: 3,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.person, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              cobradorName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget que muestra el nombre del cobrador del balance
  Widget _buildCobradorInfo(BuildContext context, Map<String, dynamic> balance) {
    final cobradorName = balance['cobrador_name']?.toString() ?? 'N/A';
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.badge_outlined,
          size: 12,
          color: theme.colorScheme.primary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Cobrador: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
          ),
        ),
        Text(
          cobradorName,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  /// Construye una tarjeta compacta de balance con toda la información
  Widget _buildCompactBalanceCard(BuildContext context, Map<String, dynamic> balance) {
    final theme = Theme.of(context);
    final fecha = ReportFormatters.extractBalanceDate(balance);
    final status = (balance['status'] ?? 'unknown').toString().toLowerCase();

    final inicial = ReportFormatters.pickAmount(balance, ['initial', 'initial_amount', 'opening']);
    final recaudado = ReportFormatters.pickAmount(balance, ['collected', 'collected_amount', 'income']);
    final prestado = ReportFormatters.pickAmount(balance, ['lent', 'lent_amount', 'loaned']);
    final finalVal = ReportFormatters.pickAmount(balance, ['final', 'final_amount', 'closing']);
    final diferencia = ReportFormatters.computeBalanceDifference(balance);
    final difClr = ReportFormatters.colorForDifference(diferencia);
    final isOk = diferencia.abs() < 0.01;

    // Determinar color y texto del estado
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case 'open':
        statusColor = Colors.amber[700]!;
        statusLabel = 'Abierto';
        statusIcon = Icons.lock_open;
        break;
      case 'closed':
        statusColor = Colors.blue[700]!;
        statusLabel = 'Cerrado';
        statusIcon = Icons.lock;
        break;
      case 'reconciled':
        statusColor = Colors.green[700]!;
        statusLabel = 'Conciliado';
        statusIcon = Icons.verified;
        break;
      default:
        statusColor = Colors.grey[700]!;
        statusLabel = 'Desconocido';
        statusIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Opcional: Implementar navegación al detalle del balance
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Fecha y Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        fecha,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fila 2: Montos en grid 2x2
              Row(
                children: [
                  Expanded(
                    child: _buildAmountChip(
                      context,
                      'Inicial',
                      inicial,
                      Colors.blueGrey,
                      Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAmountChip(
                      context,
                      'Recaudado',
                      recaudado,
                      Colors.green,
                      Icons.attach_money,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildAmountChip(
                      context,
                      'Prestado',
                      prestado,
                      Colors.orange,
                      Icons.trending_down,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAmountChip(
                      context,
                      'Final',
                      finalVal,
                      Colors.indigo,
                      Icons.account_balance,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fila 3: Diferencia
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: difClr.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: difClr.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOk ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: difClr,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Diferencia: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Bs ${diferencia.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: difClr,
                      ),
                    ),
                    const Spacer(),
                    if (isOk)
                      Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Fila 4: Cobrador info
              _buildCobradorInfo(context, balance),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper para construir chips de monto
  Widget _buildAmountChip(
    BuildContext context,
    String label,
    double amount,
    Color color,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Bs ${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    // Obtener la lista de balances
    final balances = payload is Map ? payload['items'] as List? : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Botones de descarga
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

        // 2. Banner de contexto (cobrador)
        _buildCobradorContextBanner(context, balances),
        const SizedBox(height: 16),

        // 3. Resumen de estadísticas
        Text(
          'Resumen General',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Recaudado',
              summaryKey: 'total_collected',
              icon: Icons.attach_money,
              color: Colors.green,
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Prestado',
              summaryKey: 'total_lent',
              icon: Icons.trending_down,
              color: Colors.red,
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Final Total',
              summaryKey: 'total_final',
              icon: Icons.account_balance,
              color: Colors.purple,
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 4. Estado de los balances
        Text(
          'Estado de Balances',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
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
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 5. Listado de Balances con headers de grupo por cobrador
        Text(
          'Listado de Balances',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (balances == null || balances.isEmpty)
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.amber[700],
                        ),
                  ),
                ),
              ],
            ),
          )
        else
          // Lista compacta de balances con headers de grupo por cobrador
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: balances.length,
            itemBuilder: (context, index) {
              final balance = balances[index] as Map<String, dynamic>;
              final currentCobradorId = balance['cobrador_id']?.toString();
              final previousCobradorId = index > 0
                  ? (balances[index - 1] as Map<String, dynamic>)['cobrador_id']
                      ?.toString()
                  : null;

              // Mostrar header de grupo si cambia el cobrador
              final showGroupHeader = currentCobradorId != previousCobradorId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showGroupHeader)
                    _buildCobradorGroupHeader(context, balance),
                  _buildCompactBalanceCard(context, balance),
                ],
              );
            },
          ),
      ],
    );
  }
}
