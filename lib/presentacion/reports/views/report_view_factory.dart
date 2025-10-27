import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
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
    return GenericReportBuilder.buildAutomatic(
      payload,
      title: 'Datos de Actividad Diaria',
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
