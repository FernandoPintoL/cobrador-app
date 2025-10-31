import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/api_services/reports_api_service.dart';
import '../../datos/modelos/reporte/daily_activity_report.dart';
import '../services/report_authorization_service.dart';
import './auth_provider.dart';

final reportsApiProvider = Provider((ref) => ReportsApiService());

/// Provider para obtener tipos de reportes
final reportTypesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(reportsApiProvider);
  final resp = await service.getReportTypes();

  if (resp['success'] == true && resp['data'] != null) {
    // resp['data'] es una List, convertir a Map donde la clave es el 'name' de cada tipo
    final List<dynamic> dataList = resp['data'] as List<dynamic>;
    final Map<String, dynamic> result = {};

    for (final item in dataList) {
      if (item is Map<String, dynamic> && item.containsKey('name')) {
        result[item['name'] as String] = item;
      }
    }

    return result;
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
        result[k] = v.map((e) {
          if (e is Map) {
            return _orderMap(e);
          } else if (e is DateTime) {
            return e.toIso8601String();
          } else {
            return e;
          }
        }).toList();
      } else if (v is DateTime) {
        // Convertir DateTime a string ISO8601 para poder hacer JSON encode
        result[k] = v.toIso8601String();
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
/// Este provider AUTORIZA los filtros antes de enviar la solicitud al backend
final generateReportProvider = FutureProvider.family<dynamic, ReportRequest>((
  ref,
  req,
) async {
  final authState = ref.watch(authProvider);
  final usuario = authState.usuario;

  // Si no hay usuario autenticado, lanzar error
  if (usuario == null) {
    throw Exception('Usuario no autenticado');
  }

  // Verificar que el usuario tenga acceso a este reporte
  if (!ReportAuthorizationService.hasReportAccess(req.type, usuario)) {
    throw Exception('No tienes permiso para acceder a este reporte');
  }

  // Autorizar y validar los filtros
  final authorizedFilters = ReportAuthorizationService.authorizeFilters(
    reportType: req.type,
    filters: req.filters ?? {},
    usuario: usuario,
  );

  // Generar el reporte con los filtros autorizados
  final service = ref.read(reportsApiProvider);
  final data = await service.generateReport(
    req.type,
    filters: authorizedFilters,
    format: req.format,
  );
  return data;
});

/// Clase inmutable para los filtros de actividad diaria
class DailyActivityFilters {
  final DateTime? startDate;
  final DateTime? endDate;
  final int? cobradorId;
  final String? paymentMethod;

  DailyActivityFilters({
    this.startDate,
    this.endDate,
    this.cobradorId,
    this.paymentMethod,
  });

  // Equality y hashCode para que Riverpod pueda cachear correctamente
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DailyActivityFilters &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.cobradorId == cobradorId &&
        other.paymentMethod == paymentMethod;
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, cobradorId, paymentMethod);
}

/// Provider familia para obtener reporte de actividad diaria con filtros
/// Este provider AUTORIZA los filtros antes de enviar la solicitud al backend
final dailyActivityReportProvider =
    FutureProvider.family<DailyActivityReport, DailyActivityFilters>((
  ref,
  filters,
) async {
  final authState = ref.watch(authProvider);
  final usuario = authState.usuario;

  // Si no hay usuario autenticado, lanzar error
  if (usuario == null) {
    throw Exception('Usuario no autenticado');
  }

  // Para cobrador, forzar que vea solo su actividad
  int? authorizedCobradorId = filters.cobradorId;
  if (usuario.esCobrador()) {
    authorizedCobradorId = usuario.id.toInt();
  }
  // Para manager, dejar que el backend filtre sus cobradores
  // Para admin, permitir ver todo

  final service = ref.read(reportsApiProvider);
  return service.getDailyActivityReport(
    startDate: filters.startDate,
    endDate: filters.endDate,
    cobradorId: authorizedCobradorId,
    paymentMethod: filters.paymentMethod,
  );
});
