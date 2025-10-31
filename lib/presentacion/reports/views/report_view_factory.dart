import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import '../../../datos/modelos/reporte/daily_activity_report.dart';
import '../utils/generic_report_builder.dart';
import '../widgets/daily_activity_widgets.dart';
import 'base_report_view.dart';
import 'payments_report_view.dart';
import 'credits_report_view.dart';
import 'balances_report_view.dart';
import 'overdue_report_view.dart';

/// Factory para crear instancias de vistas según el payload del reporte
/// Usa el patrón Strategy para detectar el tipo de reporte automáticamente
class ReportViewFactory {
  /// Crea una vista para el reporte basado en request.type
  /// NOTA: A partir del refactor del backend, todos los reportes retornan 'items'
  /// en lugar de claves específicas (payments, credits, etc)
  /// Por lo tanto, detectamos el tipo basándonos en request.type
  static BaseReportView createView({
    required rp.ReportRequest request,
    required dynamic payload,
  }) {
    final reportType = request.type.toLowerCase().trim();

    // Detectar tipo de reporte por request.type
    // Los reportes pueden ser 'payments', 'credits', 'users', 'balances', etc
    switch (reportType) {
      case 'payments':
        return PaymentsReportView(request: request, payload: payload);

      case 'credits':
        // Créditos - puede ser: créditos normales, mora o lista de espera
        // Detectamos por el summary
        if (payload is Map) {
          final summary = payload['summary'] as Map? ?? {};

          // Detectar si es reporte de MORA
          if (summary.containsKey('total_overdue_credits') ||
              summary.containsKey('average_days_overdue') ||
              summary.containsKey('by_severity')) {
            return OverdueReportView(request: request, payload: payload);
          }

          // Detectar si es reporte de LISTA DE ESPERA
          if (summary.containsKey('total_in_waiting_list')) {
            return _WaitingListReportView(request: request, payload: payload);
          }
        }
        // Es reporte de créditos normal
        return CreditsReportView(request: request, payload: payload);

      case 'balances':
        return BalancesReportView(request: request, payload: payload);

      case 'performance':
      case 'desempeño':
        return _PerformanceReportView(request: request, payload: payload);

      case 'daily-activity':
      case 'daily_activity':
      case 'actividad-diaria':
        return _DailyActivityReportView(request: request, payload: payload);

      case 'cash-flow-forecast':
      case 'cash_flow_forecast':
      case 'proyección':
      case 'proyeccion':
        return _CashFlowForecastReportView(request: request, payload: payload);

      case 'portfolio':
      case 'cartera':
        return _PortfolioReportView(request: request, payload: payload);

      case 'commissions':
      case 'comisiones':
        return _CommissionsReportView(request: request, payload: payload);

      case 'users':
      case 'usuarios':
        return _UsersReportView(request: request, payload: payload);

      case 'overdue':
      case 'mora':
        return OverdueReportView(request: request, payload: payload);

      case 'waiting-list':
      case 'waiting_list':
      case 'lista-espera':
        return _WaitingListReportView(request: request, payload: payload);

      default:
        // Fallback: intentar detectar por payload si no coincide el tipo
        // Este código mantiene backward compatibility
        if (payload is Map) {
          // Intentar por claves antiguas como fallback
          if (payload.containsKey('payments')) {
            return PaymentsReportView(request: request, payload: payload);
          }
          if (payload.containsKey('credits')) {
            return CreditsReportView(request: request, payload: payload);
          }
          if (payload.containsKey('balances')) {
            return BalancesReportView(request: request, payload: payload);
          }
          // Map genérico
          return _GenericMapReportView(request: request, payload: payload);
        }

        // Tabla genérica
        if (payload is List && payload.isNotEmpty && payload.first is Map) {
          return _GenericListReportView(request: request, payload: payload);
        }

        // Fallback final
        return _GenericReportView(request: request, payload: payload);
    }
  }
}

// ============ VISTAS PLACEHOLDERS (para futuras implementaciones) ============

class _WaitingListReportView extends BaseReportView {
  const _WaitingListReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Lista de Espera';

  @override
  IconData getReportIcon() => Icons.schedule;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Lista de Espera',
    );
  }
}

class _PerformanceReportView extends BaseReportView {
  const _PerformanceReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Desempeño';

  @override
  IconData getReportIcon() => Icons.trending_up;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Desempeño',
    );
  }
}

class _DailyActivityReportView extends BaseReportView {
  const _DailyActivityReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Actividad Diaria';

  @override
  IconData getReportIcon() => Icons.today;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    try {
      // Convertir el payload a DailyActivityReport
      final DailyActivityReport report;

      if (payload is Map<String, dynamic>) {
        report = DailyActivityReport.fromJson(payload);
      } else {
        // Fallback a vista genérica si no es el formato esperado
        return GenericReportBuilder.buildAutomatic(
          payload,
          title: 'Datos de Actividad Diaria',
        );
      }

      // Si no hay datos, mostrar mensaje
      if (report.items.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox,
                  size: 64,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sin actividad',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No hay registros de pagos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      // Mostrar el reporte con los widgets modernos
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de resumen
              DailyActivitySummaryCard(summary: report.summary),
              const SizedBox(height: 24),

              // Resumen por cobrador
              if (report.summary.byCobradores.isNotEmpty) ...[
                Text(
                  'Resumen por Cobrador',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: report.summary.byCobradores.entries.length,
                  itemBuilder: (context, index) {
                    final entry =
                        report.summary.byCobradores.entries.elementAt(index);
                    final cobradorId = entry.key;
                    final cobradorSummary = entry.value;

                    // Encontrar el nombre del cobrador desde los items
                    final cobradorName = report.items
                        .where((item) => item.cobradorId.toString() == cobradorId)
                        .firstOrNull
                        ?.cobradorName;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CobradorSummaryCard(
                        cobradorId: cobradorId,
                        summary: cobradorSummary,
                        cobradorName: cobradorName,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Detalle de actividades
              Text(
                'Detalle de Pagos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              DailyActivityListView(
                items: report.items,
                onItemTap: (item) => _showPaymentDetails(context, item),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return GenericReportBuilder.buildAutomatic(
        payload,
        title: 'Datos de Actividad Diaria',
      );
    }
  }

  void _showPaymentDetails(BuildContext context, DailyActivityItem item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles del Pago',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Pago #${item.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                  PaymentStatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 24),

              // Información del cliente
              _buildDetailSection(
                context,
                'Cliente',
                [
                  _buildDetailRow(context, 'Nombre', item.clientName),
                  _buildDetailRow(context, 'Crédito ID', '#${item.creditId}'),
                ],
              ),
              const SizedBox(height: 16),

              // Información del pago
              _buildDetailSection(
                context,
                'Información del Pago',
                [
                  _buildDetailRow(
                    context,
                    'Monto',
                    currencyFormat.format(item.amount),
                    isHighlight: true,
                  ),
                  _buildDetailRow(
                    context,
                    'Método',
                    item.paymentMethodDisplay,
                  ),
                  _buildDetailRow(
                    context,
                    'Cuota',
                    '${item.installmentNumber}',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información del cobrador
              _buildDetailSection(
                context,
                'Cobrador',
                [
                  _buildDetailRow(context, 'Nombre', item.cobradorName),
                  _buildDetailRow(context, 'ID', item.cobradorId.toString()),
                ],
              ),
              const SizedBox(height: 16),

              // Fechas
              _buildDetailSection(
                context,
                'Fechas',
                [
                  _buildDetailRow(
                    context,
                    'Fecha de Pago',
                    _formatDate(item.paymentDate),
                  ),
                  _buildDetailRow(
                    context,
                    'Creado',
                    _formatDate(item.createdAt),
                  ),
                ],
              ),

              // Ubicación si está disponible
              if (item.latitude != null && item.longitude != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection(
                  context,
                  'Ubicación',
                  [
                    _buildDetailRow(
                      context,
                      'Latitud',
                      item.latitude.toString(),
                    ),
                    _buildDetailRow(
                      context,
                      'Longitud',
                      item.longitude.toString(),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: isHighlight ? Colors.green.shade700 : null,
                ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _CashFlowForecastReportView extends BaseReportView {
  const _CashFlowForecastReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Proyección de Flujo';

  @override
  IconData getReportIcon() => Icons.show_chart;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Proyección de Flujo',
    );
  }
}

class _PortfolioReportView extends BaseReportView {
  const _PortfolioReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Cartera';

  @override
  IconData getReportIcon() => Icons.folder;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Cartera',
    );
  }
}

class _CommissionsReportView extends BaseReportView {
  const _CommissionsReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Comisiones';

  @override
  IconData getReportIcon() => Icons.monetization_on;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Comisiones',
    );
  }
}

class _UsersReportView extends BaseReportView {
  const _UsersReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte de Usuarios';

  @override
  IconData getReportIcon() => Icons.people;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Usuarios',
    );
  }
}

class _GenericListReportView extends BaseReportView {
  const _GenericListReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte Genérico (Lista)';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildListReport(
      payload,
      title: 'Datos',
    );
  }
}

class _GenericMapReportView extends BaseReportView {
  const _GenericMapReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte Genérico (Mapa)';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildMapReport(
      payload,
      title: 'Datos',
    );
  }
}

class _GenericReportView extends BaseReportView {
  const _GenericReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Reporte Genérico';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return GenericReportBuilder.buildAutomatic(payload);
  }
}
