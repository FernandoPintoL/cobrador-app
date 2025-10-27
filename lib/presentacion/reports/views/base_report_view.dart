import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import '../utils/report_formatters.dart';

/// Clase base abstracta para todas las vistas de reportes específicas.
/// Proporciona funcionalidad común como:
/// - Manejo de estados (data, error, loading)
/// - Botones de descarga
/// - Headers y estructura básica
abstract class BaseReportView extends ConsumerWidget {
  final rp.ReportRequest request;
  final dynamic payload;

  const BaseReportView({required this.request, required this.payload, Key? key})
    : super(key: key);

  /// Construye el contenido principal específico del tipo de reporte
  /// Implementar en cada subclase
  Widget buildReportContent(BuildContext context, WidgetRef ref);

  /// Construye el header/resumen del reporte (opcional)
  /// Por defecto retorna SizedBox.shrink()
  Widget buildReportSummary(BuildContext context) {
    return const SizedBox.shrink();
  }

  /// Obtiene el ícono de tipo de reporte (opcional)
  IconData getReportIcon() {
    return Icons.description;
  }

  /// Obtiene el título del reporte
  String getReportTitle() {
    return 'Reporte de ${request.type}';
  }

  /// Verifica si el payload tiene datos válidos
  bool hasValidPayload() {
    return payload != null;
  }

  /// Construye el header estándar con título e ícono
  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(getReportIcon(), size: 32, color: Colors.blue),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  getReportTitle(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tipo: ${request.type}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye información de generación si está disponible
  Widget _buildGenerationInfo(BuildContext context) {
    final generatedBy = payload is Map ? payload['generated_by'] : null;
    final generatedAt = payload is Map ? payload['generated_at'] : null;

    if (generatedBy == null && generatedAt == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'Generado' +
            (generatedBy != null ? ' por $generatedBy' : '') +
            (generatedAt != null
                ? ' • ${ReportFormatters.formatDate(generatedAt)}'
                : ''),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!hasValidPayload()) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            buildReportSummary(context),
            const SizedBox(height: 16),
            buildReportContent(context, ref),
            _buildGenerationInfo(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
