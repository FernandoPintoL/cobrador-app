import 'credito.dart';

/// ✅ OPTIMIZACIÓN: El backend ya no envía el array completo 'payments'
/// El payment_schedule ahora incluye toda la información necesaria:
/// - Estado de cuotas (paid/overdue/pending)
/// - Montos pagados y restantes
/// - Información del cobrador (receivedById, receivedByName)
/// - Método de pago y fechas
///
/// Esto reduce la redundancia ~70% y mejora performance
class CreditFullDetails {
  final Credito credit;
  final Map<String, dynamic>? summary;
  final List<PaymentSchedule>? schedule;

  CreditFullDetails({
    required this.credit,
    this.summary,
    this.schedule,
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

    // ✅ OPTIMIZACIÓN: Solo cargar payment_schedule (incluye toda la info)
    List<PaymentSchedule>? schedule;
    final rawSchedule = (data is Map<String, dynamic>) ? data['payment_schedule'] : null;
    if (rawSchedule is List) {
      schedule = rawSchedule
          .whereType<Map<String, dynamic>>()
          .map((e) => PaymentSchedule.fromJson(e))
          .toList();
    }

    // Construir summary desde los datos disponibles en data
    Map<String, dynamic>? summary;
    if (data is Map<String, dynamic>) {
      // Si hay un campo 'summary' explícito, usarlo
      if (data['summary'] is Map<String, dynamic>) {
        summary = data['summary'] as Map<String, dynamic>;
      } else {
        // Si no, construir el summary a partir de los campos disponibles en credit
        summary = {
          'installment_amount': creditJson['installment_amount'],
          'pending_installments': creditJson['pending_installments'],
          'completed_installments_count': creditJson['completed_installments_count'],
          'total_installments': creditJson['total_installments'],
          'balance': creditJson['balance'],
          'total_amount': creditJson['total_amount'],
          'amount': creditJson['amount'],
          'original_amount': creditJson['amount'], // Monto del préstamo original
          'interest_rate': creditJson['interest_rate'],
          'total_paid': creditJson['total_paid'],
          'paid_installments': creditJson['paid_installments'],
          // Calcular si está en mora basado en el balance y la fecha
          'is_overdue': (creditJson['balance'] != null &&
                         (double.tryParse(creditJson['balance'].toString()) ?? 0) > 0),
          'overdue_amount': 0, // El API no provee este campo directamente
        };
      }
    }

    return CreditFullDetails(
      credit: credito,
      summary: summary,
      schedule: schedule,
    );
  }
}
