import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import '../../../datos/modelos/reporte/daily_activity_report.dart';
import '../utils/generic_report_builder.dart';
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
                  color: Colors.grey.withValues(alpha: 0.5),
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
                  'No hay registros de actividad',
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

      final currencyFormat = NumberFormat.currency(
        locale: 'es_BO',
        symbol: 'Bs ',
        decimalDigits: 2,
      );

      // Mostrar el reporte con los datos nuevos
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de resumen del día
              _buildDaySummaryCard(context, report.summary, currencyFormat),
              const SizedBox(height: 24),

              // Actividad por cobrador
              Text(
                'Actividad por Cobrador',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: report.items.length,
                itemBuilder: (context, index) {
                  final cobradorItem = report.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildCobradorCard(context, cobradorItem, currencyFormat),
                  );
                },
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

  Widget _buildDaySummaryCard(
    BuildContext context,
    DailyActivitySummary summary,
    NumberFormat currencyFormat,
  ) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 4,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen del Día',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${summary.dayName}, ${summary.date}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildStatChip(
                    context,
                    'Créditos Entregados',
                    summary.totals.creditsDelivered.toString(),
                    Icons.add_card,
                  ),
                  _buildStatChip(
                    context,
                    'Monto Prestado',
                    currencyFormat.format(summary.totals.amountLent),
                    Icons.attach_money,
                  ),
                  _buildStatChip(
                    context,
                    'Pagos Cobrados',
                    summary.totals.paymentsCollected.toString(),
                    Icons.receipt,
                  ),
                  _buildStatChip(
                    context,
                    'Monto Cobrado',
                    currencyFormat.format(summary.totals.amountCollected),
                    Icons.money,
                  ),
                  _buildStatChip(
                    context,
                    'Eficiencia',
                    summary.overallEfficiencyFormatted,
                    Icons.trending_up,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCobradorCard(
    BuildContext context,
    DailyActivityCobradorItem cobrador,
    NumberFormat currencyFormat,
  ) {
    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          child: Text(cobrador.cobradorName.substring(0, 1)),
        ),
        title: Text(
          cobrador.cobradorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${cobrador.cobradorId}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Balance',
                  cobrador.cashBalance.isOpen ? 'Abierto' : 'Cerrado',
                ),
                _buildInfoRow(
                  'Monto Cobrado',
                  currencyFormat.format(cobrador.cashBalance.collectedAmount),
                ),
                _buildInfoRow(
                  'Monto Prestado',
                  currencyFormat.format(cobrador.cashBalance.lentAmount),
                ),
                _buildInfoRow(
                  'Créditos Entregados',
                  '${cobrador.creditsDelivered.count}',
                ),
                _buildInfoRow(
                  'Pagos Cobrados',
                  '${cobrador.paymentsCollected.count}',
                ),
                _buildInfoRow(
                  'Pagos Esperados',
                  '${cobrador.expectedPayments.count}',
                ),
                _buildInfoRow(
                  'Pendientes',
                  '${cobrador.expectedPayments.pending}',
                ),
                _buildInfoRow(
                  'Eficiencia',
                  cobrador.expectedPayments.efficiencyFormatted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
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
