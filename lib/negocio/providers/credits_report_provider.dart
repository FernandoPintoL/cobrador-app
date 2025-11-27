import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/reporte/credits_report_model.dart';
import '../../datos/api_services/reports_api_service.dart';

final creditsReportApiProvider = Provider((ref) => ReportsApiService());

/// Clase inmutable para los filtros de créditos
class CreditsReportFilters {
  final String? status;
  final int? cobradorId;
  final int? clientId;
  final int? createdBy;
  final int? deliveredBy;
  final DateTime? startDate;
  final DateTime? endDate;

  CreditsReportFilters({
    this.status,
    this.cobradorId,
    this.clientId,
    this.createdBy,
    this.deliveredBy,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreditsReportFilters &&
        other.status == status &&
        other.cobradorId == cobradorId &&
        other.clientId == clientId &&
        other.createdBy == createdBy &&
        other.deliveredBy == deliveredBy &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(
        status,
        cobradorId,
        clientId,
        createdBy,
        deliveredBy,
        startDate,
        endDate,
      );
}

/// ✅ Provider TIPADO para obtener el reporte de créditos
/// Usa el método tipado del servicio para mejor type safety
final creditsReportProvider = FutureProvider.family<CreditsReport, CreditsReportFilters>(
  (ref, filters) async {
    final service = ref.read(creditsReportApiProvider);

    // ✅ Usar método tipado del servicio
    return await service.getCreditsReport(
      status: filters.status,
      cobradorId: filters.cobradorId,
      clientId: filters.clientId,
      createdBy: filters.createdBy,
      deliveredBy: filters.deliveredBy,
      startDate: filters.startDate,
      endDate: filters.endDate,
    );
  },
);
