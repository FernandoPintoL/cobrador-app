import 'package:flutter/material.dart';
import '../../../datos/modelos/reporte/report_response.dart';
import 'base_report_builder.dart';

/// Constructor de reportes de créditos
class CreditsReportBuilder extends BaseReportBuilder {
  @override
  String get reportType => 'credits';

  @override
  ReportResponse buildReport(
    Map<String, dynamic> data,
    Map<String, dynamic>? metadata,
  ) {
    final transformedData = transformData(data);

    return ReportResponse(
      type: reportType,
      title: 'Reporte de Créditos',
      description: 'Detalle de todos los créditos en el sistema',
      data: transformedData,
      metadata: {
        ...?metadata,
        'totalCredits': (transformedData['credits'] as List<dynamic>?)?.length ?? 0,
        'totalAmount': _calculateTotalAmount(transformedData),
      },
    );
  }

  @override
  bool validateData(Map<String, dynamic> data) {
    // Ahora acepta 'items' como clave genérica, con fallback a 'credits' para compatibility
    return (data.containsKey('items') || data.containsKey('credits')) &&
        (data['items'] is List || data['credits'] is List);
  }

  @override
  Map<String, dynamic> transformData(Map<String, dynamic> data) {
    // Ahora accede a 'items' con fallback a 'credits' para backward compatibility
    final credits = ((data['items'] ?? data['credits']) as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList() ??
        [];

    // Agrupar por estado
    final groupedByStatus = <String, List<Map<String, dynamic>>>{};
    for (final credit in credits) {
      final status = (credit['status'] ?? 'unknown').toString();
      groupedByStatus.putIfAbsent(status, () => []);
      groupedByStatus[status]!.add(credit);
    }

    return {
      'credits': credits,
      'groupedByStatus': groupedByStatus,
      'totalCount': credits.length,
      'totalAmount': _calculateTotalAmount(data),
    };
  }

  double _calculateTotalAmount(Map<String, dynamic> data) {
    double total = 0.0;
    // Ahora accede a 'items' con fallback a 'credits'
    final credits = ((data['items'] ?? data['credits']) as List<dynamic>?) ?? [];
    for (final credit in credits) {
      if (credit is Map<String, dynamic>) {
        final amount = credit['total_amount'];
        if (amount is num) {
          total += amount.toDouble();
        } else if (amount is String) {
          total += double.tryParse(amount) ?? 0.0;
        }
      }
    }
    return total;
  }
}
