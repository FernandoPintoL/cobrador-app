enum FrecuenciaPago { diario, quincenal, mensual }

enum EstadoCredito { activo, pagado, vencido, cancelado }

class Credito {
  final BigInt id;
  final BigInt clienteId;
  final double monto;
  final double saldo;
  final FrecuenciaPago frecuencia;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EstadoCredito estado;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;

  Credito({
    required this.id,
    required this.clienteId,
    required this.monto,
    required this.saldo,
    required this.frecuencia,
    required this.fechaInicio,
    required this.fechaFin,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
  });

  factory Credito.fromJson(Map<String, dynamic> json) {
    return Credito(
      id: BigInt.parse(json['id'].toString()),
      clienteId: BigInt.parse(json['client_id'].toString()),
      monto: double.parse(json['amount'].toString()),
      saldo: double.parse(json['balance'].toString()),
      frecuencia: _parseFrecuencia(json['frequency']),
      fechaInicio: DateTime.parse(json['start_date']),
      fechaFin: DateTime.parse(json['end_date']),
      estado: _parseEstado(json['status']),
      fechaCreacion: DateTime.parse(json['created_at']),
      fechaActualizacion: DateTime.parse(json['updated_at']),
    );
  }

  static FrecuenciaPago _parseFrecuencia(String? frecuencia) {
    switch (frecuencia?.toLowerCase()) {
      case 'daily':
        return FrecuenciaPago.diario;
      case 'biweekly':
        return FrecuenciaPago.quincenal;
      case 'monthly':
        return FrecuenciaPago.mensual;
      default:
        return FrecuenciaPago.diario;
    }
  }

  static EstadoCredito _parseEstado(String? estado) {
    switch (estado?.toLowerCase()) {
      case 'active':
        return EstadoCredito.activo;
      case 'paid':
        return EstadoCredito.pagado;
      case 'overdue':
        return EstadoCredito.vencido;
      case 'cancelled':
        return EstadoCredito.cancelado;
      default:
        return EstadoCredito.activo;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'client_id': clienteId.toString(),
      'amount': monto.toString(),
      'balance': saldo.toString(),
      'frequency': _frecuenciaToString(),
      'start_date': fechaInicio.toIso8601String(),
      'end_date': fechaFin.toIso8601String(),
      'status': _estadoToString(),
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion.toIso8601String(),
    };
  }

  String _frecuenciaToString() {
    switch (frecuencia) {
      case FrecuenciaPago.diario:
        return 'daily';
      case FrecuenciaPago.quincenal:
        return 'biweekly';
      case FrecuenciaPago.mensual:
        return 'monthly';
    }
  }

  String _estadoToString() {
    switch (estado) {
      case EstadoCredito.activo:
        return 'active';
      case EstadoCredito.pagado:
        return 'paid';
      case EstadoCredito.vencido:
        return 'overdue';
      case EstadoCredito.cancelado:
        return 'cancelled';
    }
  }

  int getCuotasRestantes() {
    final diasTotales = fechaFin.difference(fechaInicio).inDays;
    switch (frecuencia) {
      case FrecuenciaPago.diario:
        return diasTotales;
      case FrecuenciaPago.quincenal:
        return (diasTotales / 15).ceil();
      case FrecuenciaPago.mensual:
        return (diasTotales / 30).ceil();
    }
  }

  double getMontoCuota() {
    return monto / getCuotasRestantes();
  }

  bool get estaVencido =>
      estado == EstadoCredito.activo && DateTime.now().isAfter(fechaFin);

  Credito copyWith({
    BigInt? id,
    BigInt? clienteId,
    double? monto,
    double? saldo,
    FrecuenciaPago? frecuencia,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    EstadoCredito? estado,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
  }) {
    return Credito(
      id: id ?? this.id,
      clienteId: clienteId ?? this.clienteId,
      monto: monto ?? this.monto,
      saldo: saldo ?? this.saldo,
      frecuencia: frecuencia ?? this.frecuencia,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      estado: estado ?? this.estado,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Credito && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Credito{id: $id, clienteId: $clienteId, monto: $monto, saldo: $saldo, estado: $estado}';
  }
}
