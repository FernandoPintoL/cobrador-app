import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
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
    // ✅ El backend SIEMPRE envía 'items' (estandarizado)
    return payload is Map && payload.containsKey('items');
  }

  /// Obtiene el icono para un estado de pago
  IconData _getStatusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'overdue':
        return Icons.error;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info_outline;
    }
  }

  /// Banner de contexto mostrando el cobrador dueño de los pagos
  Widget _buildCobradorContextBanner(BuildContext context, List? payments) {
    if (payments == null || payments.isEmpty) return const SizedBox.shrink();

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
      // Hay filtro específico: mostrar el nombre del cobrador del primer pago
      final firstPayment = payments.first as Map<String, dynamic>;
      final cobradorName = firstPayment['cobrador_name']?.toString() ?? 'Cobrador';
      bannerText = 'Mostrando pagos de: $cobradorName';
      bannerIcon = Icons.person;
    } else {
      // Sin filtro: mostrar que se ven pagos de todos los cobradores asignados
      bannerText = 'Mostrando pagos de todos tus cobradores asignados';
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
  Widget _buildCobradorGroupHeader(BuildContext context, Map<String, dynamic> payment) {
    final cobradorName = payment['cobrador_name']?.toString() ?? 'Cobrador Desconocido';
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

  /// Widget que muestra el nombre del cobrador que recibió el pago
  Widget _buildCobradorInfo(BuildContext context, Map<String, dynamic> payment) {
    final cobradorName = payment['cobrador_name']?.toString() ?? 'N/A';
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

  /// Construye una tarjeta compacta de pago con toda la información
  Widget _buildCompactPaymentCard(BuildContext context, Map<String, dynamic> payment) {
    final theme = Theme.of(context);
    final clientName = ReportFormatters.extractPaymentClientName(payment);
    final paymentDate = ReportFormatters.formatDate(payment['payment_date'] ?? '');
    final amountValue = ReportFormatters.toDouble(payment['amount'] ?? 0);
    final methodRaw = payment['payment_method']?.toString();
    final method = ReportFormatters.translatePaymentMethod(methodRaw);
    final methodColor = ReportFormatters.colorForPaymentMethod(methodRaw);
    final methodIcon = ReportFormatters.iconForPaymentMethod(methodRaw);
    final statusRaw = payment['status']?.toString();
    final statusColor = ReportFormatters.colorForStatus(statusRaw);
    final statusText = ReportFormatters.translateCreditStatus(statusRaw);

    // ✅ Obtener el número de cuota del objeto anidado 'credit'
    final credit = payment['credit'] as Map<String, dynamic>?;
    final installmentNumber = credit?['installment_number_display']?.toString() ??
                              credit?['installment_number']?.toString() ??
                              'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Opcional: Implementar navegación al detalle del pago
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila 1: Cliente y Monto
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: theme.colorScheme.primary.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            clientName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Bs ${amountValue.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fila 2: Fecha, Cuota, ID
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    paymentDate,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.numbers,
                    size: 12,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Cuota $installmentNumber',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'ID: ${payment['id'] ?? 'N/A'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fila 3: Método de Pago y Estado
              Row(
                children: [
                  // Método de pago
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: methodColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(methodIcon, size: 12, color: methodColor),
                        const SizedBox(width: 4),
                        Text(
                          method,
                          style: TextStyle(
                            color: methodColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Estado
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
                        Icon(_getStatusIcon(statusRaw), size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fila 4: Cobrador info
              _buildCobradorInfo(context, payment),
            ],
          ),
        ),
      ),
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
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
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
    // Obtener la lista de pagos
    final payments = payload is Map ? payload['items'] as List? : null;

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
        _buildCobradorContextBanner(context, payments),
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
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
            SummaryCardConfig(
              title: 'Promedio',
              summaryKey: 'average_payment',
              icon: Icons.trending_up,
              color: Colors.orange,
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
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

        // 4. Listado de Pagos con headers de grupo por cobrador
        Text(
          'Listado de Pagos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        if (payments == null || payments.isEmpty)
          Center(
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
          )
        else
          // Lista compacta de pagos con headers de grupo por cobrador
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index] as Map<String, dynamic>;
              final currentCobradorId = payment['cobrador_id']?.toString();
              final previousCobradorId = index > 0
                  ? (payments[index - 1] as Map<String, dynamic>)['cobrador_id']
                      ?.toString()
                  : null;

              // Mostrar header de grupo si cambia el cobrador
              final showGroupHeader = currentCobradorId != previousCobradorId;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showGroupHeader)
                    _buildCobradorGroupHeader(context, payment),
                  _buildCompactPaymentCard(context, payment),
                ],
              );
            },
          ),
      ],
    );
  }
}
