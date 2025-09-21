import 'dart:io';
import 'package:dio/dio.dart';
import 'base_api_service.dart';

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
      final query = {...?filters, 'format': format};

      if (format == 'json') {
        final resp = await get('/reports/$reportType', queryParameters: query);
        return resp.data;
      }

      // Para formatos binarios (pdf, excel, html) pedimos bytes usando dio con responseType
      final resp = await dio.get<List<int>>(
        '/reports/$reportType',
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
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
}
