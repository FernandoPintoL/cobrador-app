import '../../../datos/modelos/reporte/report_response.dart';
import 'base_report_builder.dart';

/// Constructor de reportes de desempeño (actividades diarias, rendimiento)
class PerformanceReportBuilder extends BaseReportBuilder {
  @override
  String get reportType => 'performance';

  @override
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    final transformedData = transformData(data);

    return ReportResponse(
      type: reportType,
      title: 'Reporte de Desempeño',
      description: 'Análisis de desempeño y actividades diarias',
      data: transformedData,
      metadata: {
        ...?metadata,
        'performersCount': (transformedData['performers'] as List?)?.length ?? 0,
        'activitiesCount': (transformedData['activities'] as List?)?.length ?? 0,
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
      'performers': data['performers'] ?? [],
      'activities': data['activities'] ?? [],
      'performance': data['performance'] ?? [],
      'frequency': data['frequency'] ?? {},
    };
  }
}
