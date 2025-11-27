import 'dart:io';
import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../modelos/reporte/reporte_models.dart';

class ReportsApiService extends BaseApiService {
  /// Obtiene tipos de reportes disponibles
  Future<Map<String, dynamic>> getReportTypes() async {
    try {
      final resp = await get('/reports/types');
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener tipos de reportes: $e');
    }
  }

  /// Genera o descarga un reporte según tipo y filtros
  /// Si format es 'json' devuelve el body JSON, si es otro formato devuelve bytes
  Future<dynamic> generateReport(
    String reportType, {
    Map<String, dynamic>? filters,
    String format = 'json',
  }) async {
    try {
      // ✅ Formatear fechas correctamente antes de enviar
      final cleanedFilters = _cleanFilters(filters);
      final query = {...?cleanedFilters, 'format': format};

      if (format == 'json') {
        final resp = await get('/reports/$reportType', queryParameters: query);
        return resp.data;
      }

      // Para formatos binarios (pdf, excel) pedimos bytes
      // IMPORTANTE: Usar la URL completa con baseUrl para que se apliquen headers y auth
      final fullUrl = '${dio.options.baseUrl}/reports/$reportType';

      final resp = await dio.get<List<int>>(
        fullUrl,
        queryParameters: query,
        options: Options(
          responseType: ResponseType.bytes,
          // Asegurar que se envíen los headers de autenticación
          headers: dio.options.headers,
        ),
      );

      return resp.data;
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al generar reporte: $e');
    }
  }

  /// Helper para descargar bytes y guardar en archivo
  Future<File> downloadReportToFile(
    String reportType, {
    Map<String, dynamic>? filters,
    String format = 'pdf',
    required String outputPath,
  }) async {
    final data = await generateReport(
      reportType,
      filters: filters,
      format: format,
    );

    if (data is List<int>) {
      final file = File(outputPath);
      await file.writeAsBytes(data);
      return file;
    }

    throw Exception('Respuesta no contiene bytes para descargar');
  }

  /// Obtiene el reporte de actividad diaria con datos tipados
  Future<DailyActivityReport> getDailyActivityReport({
    DateTime? startDate,
    DateTime? endDate,
    int? cobradorId,
    String? paymentMethod,
  }) async {
    try {
      final Map<String, dynamic> filters = {};

      if (startDate != null) {
        filters['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        filters['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (cobradorId != null) {
        filters['cobrador_id'] = cobradorId;
      }
      if (paymentMethod != null) {
        filters['payment_method'] = paymentMethod;
      }

      final resp = await get(
        '/reports/daily-activity',
        queryParameters: {...filters, 'format': 'json'},
      );

      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return DailyActivityReport.fromJson(data['data']);
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener reporte de actividad diaria: $e');
    }
  }

  /// Obtiene el reporte de créditos con datos tipados
  Future<CreditsReport> getCreditsReport({
    String? status,
    int? cobradorId,
    int? clientId,
    int? createdBy,
    int? deliveredBy,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final Map<String, dynamic> filters = {};

      if (status != null) filters['status'] = status;
      if (cobradorId != null) filters['cobrador_id'] = cobradorId;
      if (clientId != null) filters['client_id'] = clientId;
      if (createdBy != null) filters['created_by'] = createdBy;
      if (deliveredBy != null) filters['delivered_by'] = deliveredBy;
      if (startDate != null) {
        filters['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        filters['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      final resp = await get(
        '/reports/credits',
        queryParameters: {...filters, 'format': 'json'},
      );

      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return CreditsReport.fromJson(data['data']);
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener reporte de créditos: $e');
    }
  }

  /// Obtiene el reporte de pagos con datos tipados
  Future<PaymentsReport> getPaymentsReport({
    DateTime? startDate,
    DateTime? endDate,
    int? cobradorId,
  }) async {
    try {
      final Map<String, dynamic> filters = {};

      if (startDate != null) {
        filters['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        filters['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (cobradorId != null) filters['cobrador_id'] = cobradorId;

      final resp = await get(
        '/reports/payments',
        queryParameters: {...filters, 'format': 'json'},
      );

      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return PaymentsReport.fromJson(data['data']);
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener reporte de pagos: $e');
    }
  }

  /// Obtiene el reporte de balances con datos tipados
  Future<BalancesReport> getBalancesReport({
    DateTime? startDate,
    DateTime? endDate,
    int? cobradorId,
    String? status,
    bool? withDiscrepancies,
  }) async {
    try {
      final Map<String, dynamic> filters = {};

      if (startDate != null) {
        filters['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        filters['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      if (cobradorId != null) filters['cobrador_id'] = cobradorId;
      if (status != null) filters['status'] = status;
      if (withDiscrepancies != null) filters['with_discrepancies'] = withDiscrepancies;

      final resp = await get(
        '/reports/balances',
        queryParameters: {...filters, 'format': 'json'},
      );

      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return BalancesReport.fromJson(data['data']);
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener reporte de balances: $e');
    }
  }

  /// Obtiene el reporte de créditos en mora con datos tipados
  Future<OverdueReport> getOverdueReport({
    int? cobradorId,
    int? clientId,
    String? clientCategory,
    int? minDaysOverdue,
    int? maxDaysOverdue,
    double? minOverdueAmount,
  }) async {
    try {
      final Map<String, dynamic> filters = {};

      if (cobradorId != null) filters['cobrador_id'] = cobradorId;
      if (clientId != null) filters['client_id'] = clientId;
      if (clientCategory != null) filters['client_category'] = clientCategory;
      if (minDaysOverdue != null) filters['min_days_overdue'] = minDaysOverdue;
      if (maxDaysOverdue != null) filters['max_days_overdue'] = maxDaysOverdue;
      if (minOverdueAmount != null) filters['min_overdue_amount'] = minOverdueAmount;

      final resp = await get(
        '/reports/overdue',
        queryParameters: {...filters, 'format': 'json'},
      );

      final data = resp.data as Map<String, dynamic>;

      if (data['success'] == true && data['data'] is Map<String, dynamic>) {
        return OverdueReport.fromJson(data['data']);
      }

      throw Exception('Respuesta inesperada del servidor');
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener reporte de mora: $e');
    }
  }

  /// ✅ Helper privado para limpiar y formatear filtros antes de enviar al backend
  /// Convierte DateTime a String en formato 'YYYY-MM-DD' que espera el backend
  Map<String, dynamic>? _cleanFilters(Map<String, dynamic>? filters) {
    if (filters == null) return null;

    final cleaned = <String, dynamic>{};

    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;

      // Formatear DateTime a 'YYYY-MM-DD'
      if (value is DateTime) {
        cleaned[key] = value.toIso8601String().split('T')[0];
      } else if (value != null) {
        // Mantener otros valores tal cual
        cleaned[key] = value;
      }
      // Si value es null, no lo incluimos en los filtros
    }

    return cleaned;
  }
}
