import '../../modelos/usuario.dart';

class Pago {
  final int id;
  final int creditId;
  final int? cobradorId;
  final double amount;
  final String?
  paymentType; // 'cash', 'transfer', etc. (mapeado también desde payment_method)
  final String status; // 'pending', 'completed', 'failed'
  final DateTime paymentDate;
  final String? notes;
  final int? installmentNumber;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Extras del backend para historial
  final double? latitude;
  final double? longitude;
  final int? receivedBy;
  final int? cashBalanceId; // ID del balance de caja asociado
  final Usuario? cobrador; // info del cobrador que recibió el pago

  Pago({
    required this.id,
    required this.creditId,
    this.cobradorId,
    required this.amount,
    this.paymentType,
    this.status = 'completed',
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.installmentNumber,
    this.latitude,
    this.longitude,
    this.receivedBy,
    this.cashBalanceId,
    this.cobrador,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    double? _tryDouble(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    return Pago(
      id: json['id'] ?? 0,
      creditId: json['credit_id'] ?? 0,
      cobradorId: json['cobrador_id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentType: json['payment_type'] ?? json['payment_method'],
      status: json['status'] ?? 'completed',
      paymentDate:
          DateTime.tryParse(json['payment_date'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      installmentNumber:
          json['installment_number'] ?? json['numero_cuota'] ?? 0,
      latitude: _tryDouble(json['latitude']),
      longitude: _tryDouble(json['longitude']),
      receivedBy: json['received_by'],
      cashBalanceId: json['cash_balance_id'],
      cobrador: json['cobrador'] is Map<String, dynamic>
          ? Usuario.fromJson(json['cobrador'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credit_id': creditId,
      'cobrador_id': cobradorId,
      'amount': amount,
      'payment_type': paymentType,
      'status': status,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'notes': notes,
      'installment_number': installmentNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'received_by': receivedBy,
      'cash_balance_id': cashBalanceId,
      // No serializamos 'cobrador' completo aquí por simplicidad
    };
  }
}

// Compatibilidad: exponer numeroCuota como alias para installmentNumber
extension PagoCompat on Pago {
  int? get numeroCuota => installmentNumber;
}
