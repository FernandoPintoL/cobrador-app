import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/reporte/credits_report_model.dart';
import '../../datos/api_services/reports_api_service.dart';

final creditsReportApiProvider = Provider((ref) => ReportsApiService());

/// Provider para obtener el reporte de créditos con estructura específica
final creditsReportProvider = FutureProvider.family<CreditsReport, Map<String, dynamic>>(
  (ref, filters) async {
    final service = ref.read(creditsReportApiProvider);

    // Llamar al endpoint de créditos
    final response = await service.generateReport(
      'credits',
      filters: filters,
      format: 'json',
    );

    // El response debería ser un Map con la estructura del reporte
    if (response is Map<String, dynamic>) {
      return CreditsReport.fromJson(response);
    }

    // Si viene envuelto en un 'data', extraerlo
    if (response is Map && response.containsKey('data')) {
      return CreditsReport.fromJson(response['data'] as Map<String, dynamic>);
    }

    throw Exception('Formato inesperado en la respuesta del reporte de créditos');
  },
);
