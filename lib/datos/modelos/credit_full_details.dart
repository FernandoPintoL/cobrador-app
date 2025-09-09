import 'credito.dart';

class CreditFullDetails {
  final Credito credit;
  final Map<String, dynamic>? summary;
  final List<PaymentSchedule>? schedule;
  final List<Pago>? paymentsHistory;

  CreditFullDetails({
    required this.credit,
    this.summary,
    this.schedule,
    this.paymentsHistory,
  });

  factory CreditFullDetails.fromApi(Map<String, dynamic> response) {
    final data = response['data'];
    final creditJson = (data is Map<String, dynamic> && data['credit'] != null)
        ? data['credit'] as Map<String, dynamic>
        : data as Map<String, dynamic>;
    var credito = Credito.fromJson(creditJson);

    // Merge client location if present
    if (data is Map<String, dynamic>) {
      final loc = data['location_cliente'];
      if (loc is Map<String, dynamic>) {
        final latStr = loc['latitude']?.toString();
        final lngStr = loc['longitude']?.toString();
        final lat = latStr != null ? double.tryParse(latStr) : null;
        final lng = lngStr != null ? double.tryParse(lngStr) : null;
        if (lat != null && lng != null && credito.client != null) {
          final updatedClient = credito.client!.copyWith(latitud: lat, longitud: lng);
          credito = credito.copyWith(client: updatedClient);
        }
      }
    }

    List<PaymentSchedule>? schedule;
    final rawSchedule = (data is Map<String, dynamic>) ? data['payment_schedule'] : null;
    if (rawSchedule is List) {
      schedule = rawSchedule
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentSchedule.fromJson(e))
          .toList();
    }

    List<Pago>? history;
    final rawHistory = (data is Map<String, dynamic>) ? data['payments_history'] : null;
    if (rawHistory is List) {
      history = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((e) => Pago.fromJson(e))
          .toList();
    }

    final summary = (data is Map<String, dynamic> && data['summary'] is Map<String, dynamic>)
        ? data['summary'] as Map<String, dynamic>
        : null;

    return CreditFullDetails(
      credit: credito,
      summary: summary,
      schedule: schedule,
      paymentsHistory: history,
    );
  }
}
