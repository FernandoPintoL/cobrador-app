import '../../../datos/modelos/reporte/report_response.dart';

/// Clase base para todos los constructores de reportes
/// Define la interfaz común que todos los builders deben implementar
abstract class BaseReportBuilder {
  /// Nombre del tipo de reporte que construye este builder
  String get reportType;

  /// Construye un reporte a partir de datos crudos
  ///
  /// [data] - Los datos crudos del API
  /// [metadata] - Metadatos adicionales del reporte (filtros usados, etc)
  ///
  /// Retorna un ReportResponse estructurado
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  );

  /// Valida que los datos tengan la estructura esperada
  bool validateData(Map<String, dynamic> data);

  /// Procesa y transforma los datos antes de construir el reporte
  /// Puede ser sobrescrito por subclases si necesitan transformaciones especiales
  Map<String, dynamic> transformData(Map<String, dynamic> data) {
    return data;
  }
}
