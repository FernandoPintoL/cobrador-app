import 'base_report_builder.dart';
import 'credits_report_builder.dart';
import 'analysis_report_builder.dart';
import 'performance_report_builder.dart';
import 'portfolio_report_builder.dart';
import 'commission_report_builder.dart';
import 'statistical_report_builder.dart';

/// Factory para crear instancias de builders según el tipo de reporte
class ReportBuilderFactory {
  static final Map<String, BaseReportBuilder> _builders = {
    'credits': CreditsReportBuilder(),
    'analysis': AnalysisReportBuilder(),
    'performance': PerformanceReportBuilder(),
    'portfolio': PortfolioReportBuilder(),
    'commission': CommissionReportBuilder(),
    'statistical': StatisticalReportBuilder(),
  };

  /// Obtiene un builder para el tipo de reporte especificado
  ///
  /// Lanza una excepción si el tipo no está registrado
  static BaseReportBuilder getBuilder(String reportType) {
    final builder = _builders[reportType];
    if (builder == null) {
      throw Exception('No builder registered for report type: $reportType');
    }
    return builder;
  }

  /// Obtiene todos los tipos de reportes disponibles
  static List<String> getAvailableReportTypes() {
    return _builders.keys.toList();
  }

  /// Registra un nuevo builder personalizado
  static void registerBuilder(String reportType, BaseReportBuilder builder) {
    _builders[reportType] = builder;
  }

  /// Verifica si existe un builder para el tipo especificado
  static bool hasBuilder(String reportType) {
    return _builders.containsKey(reportType);
  }
}
