import '../../../datos/modelos/reporte/report_response.dart';
import 'base_report_builder.dart';

/// Constructor de reportes de portafolio (distribución por cobrador/categoría)
class PortfolioReportBuilder extends BaseReportBuilder {
  @override
  String get reportType => 'portfolio';

  @override
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    final transformedData = transformData(data);

    return ReportResponse(
      type: reportType,
      title: 'Reporte de Portafolio',
      description: 'Distribución de portafolio por cobrador y categoría',
      data: transformedData,
      metadata: {
        ...?metadata,
        'totalPortfolio': _calculateTotalPortfolio(transformedData),
      },
    );
  }

  @override
  bool validateData(Map<String, dynamic> data) {
    return data.containsKey('data');
  }

  @override
  Map<String, dynamic> transformData(Map<String, dynamic> data) {
    return {
      'byCobradores': data['byCobradores'] ?? {},
      'byCategory': data['byCategory'] ?? {},
      'frequency': data['frequency'] ?? {},
      'projections': data['projections'] ?? [],
    };
  }

  double _calculateTotalPortfolio(Map<String, dynamic> data) {
    double total = 0.0;
    final byCobradores = data['byCobradores'] as Map?;
    if (byCobradores != null) {
      for (final value in byCobradores.values) {
        if (value is Map<String, dynamic>) {
          final amount = value['total_amount'];
          if (amount is num) {
            total += amount.toDouble();
          }
        }
      }
    }
    return total;
  }
}
