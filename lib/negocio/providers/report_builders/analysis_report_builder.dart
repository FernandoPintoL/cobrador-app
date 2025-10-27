import '../../../datos/modelos/reporte/report_response.dart';
import 'base_report_builder.dart';

/// Constructor de reportes de análisis (cobradores, categorías, severidad)
class AnalysisReportBuilder extends BaseReportBuilder {
  @override
  String get reportType => 'analysis';

  @override
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    final transformedData = transformData(data);

    return ReportResponse(
      type: reportType,
      title: 'Reporte de Análisis',
      description: 'Análisis de cobradores, categorías y severidades',
      data: transformedData,
      metadata: {
        ...?metadata,
        'cobradorCount': (transformedData['cobradores'] as Map?)?.length ?? 0,
        'categoryCount': (transformedData['categories'] as Map?)?.length ?? 0,
      },
    );
  }

  @override
  bool validateData(Map<String, dynamic> data) {
    return data.containsKey('data') ||
           data.containsKey('cobradores') ||
           data.containsKey('categories');
  }

  @override
  Map<String, dynamic> transformData(Map<String, dynamic> data) {
    return {
      'data': data['data'] ?? {},
      'cobradores': data['cobradores'] ?? {},
      'categories': data['categories'] ?? {},
      'severity': data['severity'] ?? {},
      'topDebtors': data['topDebtors'] ?? [],
    };
  }
}
