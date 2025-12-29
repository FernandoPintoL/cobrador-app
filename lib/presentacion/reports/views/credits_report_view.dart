import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/report_formatters.dart';
import '../utils/report_download_helper.dart';
import '../widgets/summary_cards_builder.dart';
import 'base_report_view.dart';

/// Vista especializada para reportes de Créditos (Credits)
/// REFACTORIZADA: Eficiente, sin duplicación, mejor UX móvil
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
    return payload is Map && payload.containsKey('items');
  }

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    final credits = payload is Map ? payload['items'] as List? : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Botones de descarga
        _buildDownloadButtons(context, ref),
        const SizedBox(height: 16),

        // 2. Banner de contexto (cobrador)
        _buildCobradorContextBanner(context, credits),
        const SizedBox(height: 16),

        // 3. Resumen de estadísticas (mantener)
        _buildSummarySection(context),
        const SizedBox(height: 24),

        // 4. Lista ÚNICA de créditos compacta (SIN duplicación)
        _buildCreditsListSection(context, credits),
      ],
    );
  }

  /// Botones de descarga (Excel/PDF)
  Widget _buildDownloadButtons(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      children: [
        ElevatedButton.icon(
          onPressed: () => ReportDownloadHelper.downloadReport(
            context,
            ref,
            request,
            'excel',
          ),
          icon: const Icon(Icons.grid_on, size: 18),
          label: const Text('Excel'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => ReportDownloadHelper.downloadReport(
            context,
            ref,
            request,
            'pdf',
          ),
          icon: const Icon(Icons.picture_as_pdf, size: 18),
          label: const Text('PDF'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  /// Banner de contexto mostrando el cobrador dueño de los créditos
  Widget _buildCobradorContextBanner(BuildContext context, List? credits) {
    if (credits == null || credits.isEmpty) return const SizedBox.shrink();

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
      // Hay filtro específico: mostrar el nombre del cobrador del primer crédito
      final firstCredit = credits.first as Map<String, dynamic>;
      final cobradorName = firstCredit['created_by_name']?.toString() ??
          firstCredit['cobrador_name']?.toString() ??
          'Cobrador';
      bannerText = 'Mostrando créditos de: $cobradorName';
      bannerIcon = Icons.person;
    } else {
      // Sin filtro: mostrar que se ven créditos de todos los cobradores asignados
      bannerText = 'Mostrando créditos de todos tus creditos asignados';
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
          Icon(
            bannerIcon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
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

  /// Resumen de estadísticas (mantener como estaba)
  Widget _buildSummarySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
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
              formatter: (value) =>
                  'Bs ${ReportFormatters.toDouble(value).toStringAsFixed(2)}',
            ),
          ],
        ),
      ],
    );
  }

  /// Lista ÚNICA de créditos (sin duplicación)
  Widget _buildCreditsListSection(BuildContext context, List? credits) {
    if (credits == null || credits.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con contador
        Row(
          children: [
            Text(
              'Créditos Registrados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                '${credits.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista compacta de créditos con headers de grupo por cobrador
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: credits.length,
          itemBuilder: (context, index) {
            final credit = credits[index] as Map<String, dynamic>;
            final currentCobradorId = credit['created_by_id']?.toString();
            final previousCobradorId = index > 0
                ? (credits[index - 1] as Map<String, dynamic>)['created_by_id']
                        ?.toString()
                : null;

            // Mostrar header de grupo si cambia el cobrador
            final showGroupHeader = currentCobradorId != previousCobradorId;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showGroupHeader) _buildCobradorGroupHeader(context, credit),
                _buildCompactCreditCard(context, credit),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Card compacta de crédito (optimizada)
  Widget _buildCompactCreditCard(BuildContext context, Map<String, dynamic> credit) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Extraer datos
    final creditId = credit['id']?.toString() ?? 'N/A';
    final clientName = credit['client_name']?.toString() ?? 'N/A';
    final amountValue = ReportFormatters.toDouble(credit['amount'] ?? 0);
    final balanceValue = ReportFormatters.toDouble(credit['balance'] ?? 0);
    final totalInstallments = credit['total_installments'] as int? ?? 0;
    final completedInstallments = credit['completed_installments'] as int? ?? 0;
    final installmentsOverdue = credit['installments_overdue'] as int? ?? 0;

    // Fecha de creación
    final createdAt = credit['created_at']?.toString();
    final createdAtFormatted = _formatTimeAgo(createdAt);

    // Estados del crédito
    final creditStatus = credit['status']?.toString() ?? 'active';
    final paymentStatus = credit['payment_status']?.toString() ?? 'danger';

    // Colores y labels
    final creditStatusColor = _getCreditStatusColor(creditStatus);
    final creditStatusLabel = _getCreditStatusLabel(creditStatus);
    final creditStatusIcon = _getCreditStatusIcon(creditStatus);

    final paymentStatusColor = _getStatusColor(paymentStatus);
    final paymentStatusLabel = _getStatusLabel(paymentStatus, installmentsOverdue);

    final progress = totalInstallments > 0
        ? (completedInstallments / totalInstallments)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDark ? 2 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: paymentStatusColor.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // fila superior: ID del crédito
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: Text(
                    'Crédito #$creditId',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 18),
                // Estado de pago
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paymentStatusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getPaymentStatusIcon(paymentStatus),
                        size: 12,
                        color: paymentStatusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paymentStatusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: paymentStatusColor,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            // Fila 0: Estado del crédito (chip pequeño)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: creditStatusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: creditStatusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        creditStatusIcon,
                        size: 10,
                        color: creditStatusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        creditStatusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: creditStatusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Fila 0.5: Cobrador (nombre del creador del crédito)
            _buildCobradorInfo(context, credit),
            const SizedBox(height: 8),

            // Fila 1: Cliente + Estado de pago
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del cliente
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        clientName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                // Fecha de creación (tiempo relativo)
                if (createdAtFormatted != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 22),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          createdAtFormatted,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Fila 2: Montos
            Row(
              children: [
                // Monto
                Expanded(
                  child: _buildMoneyInfo(
                    context,
                    'Monto',
                    amountValue,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),

                // Balance
                Expanded(
                  child: _buildMoneyInfo(
                    context,
                    'Balance',
                    balanceValue,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fila 3: Progreso de cuotas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Cuotas: $completedInstallments / $totalInstallments',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: paymentStatusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(paymentStatusColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget de información monetaria compacta
  Widget _buildMoneyInfo(
    BuildContext context,
    String label,
    double amount,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
        ),
        const SizedBox(height: 2),
        Text(
          'Bs ${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Widget que muestra el nombre del cobrador que creó el crédito
  Widget _buildCobradorInfo(BuildContext context, Map<String, dynamic> credit) {
    final cobradorName = credit['created_by_name']?.toString() ??
        credit['cobrador_name']?.toString() ??
        'N/A';

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

  /// Header de grupo que muestra el cobrador cuando cambia
  Widget _buildCobradorGroupHeader(
      BuildContext context, Map<String, dynamic> credit) {
    final cobradorName = credit['created_by_name']?.toString() ??
        credit['cobrador_name']?.toString() ??
        'Cobrador Desconocido';

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
          Icon(
            Icons.person,
            size: 20,
            color: theme.colorScheme.primary,
          ),
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

  /// Estado vacío
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay créditos registrados',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los créditos aparecerán aquí cuando se registren',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ========== HELPERS - FORMATO DE FECHA ==========

  /// Formatea una fecha a formato "hace X tiempo"
  String? _formatTimeAgo(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inSeconds < 60) {
        return 'Hace unos segundos';
      } else if (difference.inMinutes < 60) {
        final minutes = difference.inMinutes;
        return 'Hace $minutes minuto${minutes != 1 ? 's' : ''}';
      } else if (difference.inHours < 24) {
        final hours = difference.inHours;
        return 'Hace $hours hora${hours != 1 ? 's' : ''}';
      } else if (difference.inDays < 7) {
        final days = difference.inDays;
        return 'Hace $days día${days != 1 ? 's' : ''}';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return 'Hace $weeks semana${weeks != 1 ? 's' : ''}';
      } else if (difference.inDays < 365) {
        final months = (difference.inDays / 30).floor();
        return 'Hace $months mes${months != 1 ? 'es' : ''}';
      } else {
        final years = (difference.inDays / 365).floor();
        return 'Hace $years año${years != 1 ? 's' : ''}';
      }
    } catch (e) {
      return null;
    }
  }

  // ========== HELPERS - ESTADO DE PAGO ==========

  /// Obtiene el color según el estado de pago
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'current':
        return Colors.blue;
      case 'ahead':
        return Colors.purple;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el icono según el estado de pago
  IconData _getPaymentStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'current':
        return Icons.schedule;
      case 'ahead':
        return Icons.arrow_upward;
      case 'warning':
        return Icons.warning;
      case 'danger':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  /// Obtiene el label según el estado de pago
  String _getStatusLabel(String status, int overdue) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completado';
      case 'current':
        return 'Al día';
      case 'ahead':
        return 'Adelantado';
      case 'warning':
        return overdue > 0 ? '$overdue cuota${overdue > 1 ? 's esperadas' : ' esperada'}' : 'Retraso';
      case 'danger':
        return overdue > 0 ? '$overdue cuota${overdue > 1 ? 's esperadas' : ' esperada'}' : 'Crítico';
      default:
        return 'Desconocido';
    }
  }

  // ========== HELPERS - ESTADO DEL CRÉDITO ==========

  /// Obtiene el color según el estado del crédito
  Color _getCreditStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'pending_approval':
        return Colors.orange;
      case 'waiting_delivery':
        return Colors.amber;
      case 'rejected':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      case 'on_hold':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el icono según el estado del crédito
  IconData _getCreditStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'pending_approval':
        return Icons.hourglass_empty;
      case 'waiting_delivery':
        return Icons.local_shipping;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      case 'on_hold':
        return Icons.pause_circle;
      default:
        return Icons.info;
    }
  }

  /// Obtiene el label según el estado del crédito
  String _getCreditStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'pending_approval':
        return 'Pendiente';
      case 'waiting_delivery':
        return 'Por Entregar';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      case 'on_hold':
        return 'En Espera';
      default:
        return 'Desconocido';
    }
  }
}
