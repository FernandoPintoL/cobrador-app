enum MetodoPago { efectivo, qr, transferencia }

enum EstadoPago { pendiente, completado, fallido, cancelado }

class Pago {
  final BigInt id;
  final BigInt clienteId;
  final BigInt cobradorId;
  final BigInt creditoId;
  final double monto;
  final DateTime fechaPago;
  final MetodoPago metodoPago;
  final double? latitud;
  final double? longitud;
  final EstadoPago estado;
  final String? transactionId;
  final int numeroCuota;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Pago({
    required this.id,
    required this.clienteId,
    required this.cobradorId,
    required this.creditoId,
    required this.monto,
    required this.fechaPago,
    required this.metodoPago,
    this.latitud,
    this.longitud,
    required this.estado,
    this.transactionId,
    required this.numeroCuota,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: BigInt.parse(json['id'].toString()),
      clienteId: BigInt.parse(json['client_id'].toString()),
      cobradorId: BigInt.parse(json['cobrador_id'].toString()),
      creditoId: BigInt.parse(json['credit_id'].toString()),
      monto: double.parse(json['amount'].toString()),
      fechaPago: DateTime.parse(json['payment_date']),
      metodoPago: _parseMetodoPago(json['payment_method']),
      latitud: json['location']?['coordinates']?[1]?.toDouble(),
      longitud: json['location']?['coordinates']?[0]?.toDouble(),
      estado: _parseEstadoPago(json['status']),
      transactionId: json['transaction_id'],
      numeroCuota: json['installment_number'] ?? 0,
      fechaCreacion: DateTime.parse(json['created_at']),
      fechaActualizacion: DateTime.parse(json['updated_at']),
    );
  }

  static MetodoPago _parseMetodoPago(String? metodo) {
    switch (metodo?.toLowerCase()) {
      case 'cash':
        return MetodoPago.efectivo;
      case 'qr':
        return MetodoPago.qr;
      case 'transfer':
        return MetodoPago.transferencia;
      default:
        return MetodoPago.efectivo;
    }
  }

  static EstadoPago _parseEstadoPago(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'pending':
        return EstadoPago.pendiente;
      case 'completed':
        return EstadoPago.completado;
      case 'failed':
        return EstadoPago.fallido;
      case 'cancelled':
        return EstadoPago.cancelado;
      default:
        return EstadoPago.pendiente;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'client_id': clienteId.toString(),
      'cobrador_id': cobradorId.toString(),
      'credit_id': creditoId.toString(),
      'amount': monto.toString(),
      'payment_date': fechaPago.toIso8601String(),
      'payment_method': _metodoPagoToString(),
      'location': latitud != null && longitud != null
          ? {
              'type': 'Point',
              'coordinates': [longitud, latitud],
            }
          : null,
      'status': _estadoPagoToString(),
      'transaction_id': transactionId,
      'installment_number': numeroCuota,
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion.toIso8601String(),
    };
  }

  String _metodoPagoToString() {
    switch (metodoPago) {
      case MetodoPago.efectivo:
        return 'cash';
      case MetodoPago.qr:
        return 'qr';
      case MetodoPago.transferencia:
        return 'transfer';
    }
  }

  String _estadoPagoToString() {
    switch (estado) {
      case EstadoPago.pendiente:
        return 'pending';
      case EstadoPago.completado:
        return 'completed';
      case EstadoPago.fallido:
        return 'failed';
      case EstadoPago.cancelado:
        return 'cancelled';
    }
  }

  bool get esPresencial => metodoPago == MetodoPago.efectivo;
  bool get esRemoto =>
      metodoPago == MetodoPago.qr || metodoPago == MetodoPago.transferencia;
  bool get estaCompletado => estado == EstadoPago.completado;

  Pago copyWith({
    BigInt? id,
    BigInt? clienteId,
    BigInt? cobradorId,
    BigInt? creditoId,
    double? monto,
    DateTime? fechaPago,
    MetodoPago? metodoPago,
    double? latitud,
    double? longitud,
    EstadoPago? estado,
    String? transactionId,
    int? numeroCuota,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Pago(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      cobradorId: cobradorId ?? this.cobradorId,
      creditoId: creditoId ?? this.creditoId,
      monto: monto ?? this.monto,
      fechaPago: fechaPago ?? this.fechaPago,
      metodoPago: metodoPago ?? this.metodoPago,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      estado: estado ?? this.estado,
      transactionId: transactionId ?? this.transactionId,
      numeroCuota: numeroCuota ?? this.numeroCuota,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pago && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Pago{id: $id, clienteId: $clienteId, monto: $monto, metodoPago: $metodoPago, estado: $estado}';
  }
}
