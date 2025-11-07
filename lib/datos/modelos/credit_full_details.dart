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
    // Intentar primero con 'payments_history', luego con 'payments'
    final rawHistory = (data is Map<String, dynamic>)
        ? (data['payments_history'] ?? data['payments'])
        : null;
    if (rawHistory is List) {
      history = rawHistory
          .whereType<Map<String, dynamic>>()
          .map((e) => Pago.fromJson(e))
          .toList();
    }

    // Construir summary desde los datos disponibles en data
    Map<String, dynamic>? summary;
    if (data is Map<String, dynamic>) {
      // Si hay un campo 'summary' explícito, usarlo
      if (data['summary'] is Map<String, dynamic>) {
        summary = data['summary'] as Map<String, dynamic>;
      } else {
        // Si no, construir el summary a partir de los campos disponibles en data
        summary = {
          'installment_amount': data['installment_amount'],
          'pending_installments': data['pending_installments'],
          'completed_installments_count': data['completed_installments_count'],
          'total_installments': data['total_installments'],
          'balance': data['balance'],
          'total_amount': data['total_amount'],
          'amount': data['amount'],
          'original_amount': data['amount'], // Monto del préstamo original
          'interest_rate': data['interest_rate'],
          'total_paid': data['total_paid'],
          'paid_installments': data['paid_installments'],
          // Calcular si está en mora basado en el balance y la fecha
          'is_overdue': (data['balance'] != null &&
                         (double.tryParse(data['balance'].toString()) ?? 0) > 0),
          'overdue_amount': 0, // El API no provee este campo directamente
        };
      }
    }

    return CreditFullDetails(
      credit: credito,
      summary: summary,
      schedule: schedule,
      paymentsHistory: history,
    );
  }
}
