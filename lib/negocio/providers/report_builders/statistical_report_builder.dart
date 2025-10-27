import '../../../datos/modelos/reporte/report_response.dart';
import 'base_report_builder.dart';

/// Constructor de reportes estadísticos (distribución de frecuencia, proyecciones)
class StatisticalReportBuilder extends BaseReportBuilder {
  @override
  String get reportType => 'statistical';

  @override
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    final transformedData = transformData(data);

    return ReportResponse(
      type: reportType,
      title: 'Reporte Estadístico',
      description: 'Análisis estadístico y proyecciones',
      data: transformedData,
      metadata: {
        ...?metadata,
        'projectionsCount': (transformedData['projections'] as List?)?.length ?? 0,
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
      'frequency': data['frequency'] ?? {},
      'projections': data['projections'] ?? [],
      'clients': data['clients'] ?? [],
      'categories': data['categories'] ?? {},
    };
  }
}
