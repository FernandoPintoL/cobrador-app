import '../../../datos/modelos/reporte/report_response.dart';
import 'base_report_builder.dart';

/// Constructor de reportes de comisiones (ganancias, comisiones por cobrador)
class CommissionReportBuilder extends BaseReportBuilder {
  @override
  String get reportType => 'commission';

  @override
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    final transformedData = transformData(data);

    return ReportResponse(
      type: reportType,
      title: 'Reporte de Comisiones',
      description: 'Análisis de comisiones y ganancias por cobrador',
      data: transformedData,
      metadata: {
        ...?metadata,
        'totalCommission': _calculateTotalCommission(transformedData),
        'topEarnersCount': (transformedData['topEarners'] as List?)?.length ?? 0,
      },
    );
  }

  @override
  bool validateData(Map<String, dynamic> data) {
    // Ahora acepta 'items' como clave genérica, con fallback a estructura antigua
    return data.containsKey('items') || data.containsKey('commissions') || data.containsKey('data');
  }

  @override
  Map<String, dynamic> transformData(Map<String, dynamic> data) {
    // Ahora accede a 'items' con fallback a 'commissions' para backward compatibility
    final items = (data['items'] ?? data['commissions'] ?? []) as List?;

    return {
      'topEarners': data['topEarners'] ?? [],
      'commissions': items ?? [],
      'categories': data['categories'] ?? {},
    };
  }

  double _calculateTotalCommission(Map<String, dynamic> data) {
    double total = 0.0;
    // Ahora accede a 'items' con fallback a 'commissions'
    final commissions = ((data['items'] ?? data['commissions']) as List?) ?? [];
    for (final commission in commissions) {
      if (commission is Map<String, dynamic>) {
        final amount = commission['amount'] ?? commission['commission_amount'];
        if (amount is num) {
          total += amount.toDouble();
        }
      }
    }
    return total;
  }
}
