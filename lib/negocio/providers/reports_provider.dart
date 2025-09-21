import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/servicios/reports_api_service.dart';

final reportsApiProvider = Provider((ref) => ReportsApiService());

/// Provider para obtener tipos de reportes
final reportTypesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(reportsApiProvider);
  final resp = await service.getReportTypes();

  if (resp['success'] == true && resp['data'] != null) {
    return Map<String, dynamic>.from(resp['data'] as Map);
  }

  return {};
});

/// Provider para generar reportes (familia) - devuelve dynamic (JSON o bytes)
final generateReportProvider =
    FutureProvider.family<dynamic, Map<String, dynamic>>((ref, params) async {
      final service = ref.read(reportsApiProvider);
      final type = params['type'] as String;
      final filters = params['filters'] as Map<String, dynamic>?;
      final format = params['format'] as String? ?? 'json';

      final data = await service.generateReport(
        type,
        filters: filters,
        format: format,
      );
      return data;
    });
