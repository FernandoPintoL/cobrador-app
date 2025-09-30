import 'dart:convert';

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

/// Clase inmutable que describe una petición de reporte.
/// Implementa equality/hasCode por contenido para que Riverpod pueda
/// reutilizar la misma key aunque la instancia se recree en builds.
class ReportRequest {
  final String type;
  final Map<String, dynamic>? filters;
  final String format;

  ReportRequest({required this.type, this.filters, required this.format});

  // Canonical JSON para comparar el contenido de filters
  String _canonicalFilters() {
    if (filters == null) return '{}';
    // Ordenar las claves para obtener representación estable
    final ordered = _orderMap(filters!);
    return jsonEncode(ordered);
  }

  static Map<String, dynamic> _orderMap(Map input) {
    final keys = input.keys.map((k) => k.toString()).toList()..sort();
    final result = <String, dynamic>{};
    for (final k in keys) {
      final v = input[k];
      if (v is Map) {
        result[k] = _orderMap(v);
      } else if (v is List) {
        result[k] = v.map((e) => e is Map ? _orderMap(e) : e).toList();
      } else {
        result[k] = v;
      }
    }
    return result;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReportRequest &&
        other.type == type &&
        other.format == format &&
        other._canonicalFilters() == _canonicalFilters();
  }

  @override
  int get hashCode => Object.hash(type, format, _canonicalFilters());
}

/// Provider para generar reportes (familia) - acepta ReportRequest y devuelve dynamic (JSON o bytes)
final generateReportProvider = FutureProvider.family<dynamic, ReportRequest>((
  ref,
  req,
) async {
  final service = ref.read(reportsApiProvider);
  final data = await service.generateReport(
    req.type,
    filters: req.filters,
    format: req.format,
  );
  return data;
});
