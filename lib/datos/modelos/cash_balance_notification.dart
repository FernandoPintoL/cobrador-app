/// Modelo para notificaciones de cajas (Cash Balance)
/// Usado para eventos WebSocket relacionados con operaciones de caja
class CashBalanceNotification {
  final String action;
  final CashBalanceData cashBalance;
  final String? reason;
  final bool requiresReconciliation;
  final DateTime timestamp;

  CashBalanceNotification({
    required this.action,
    required this.cashBalance,
    this.reason,
    this.requiresReconciliation = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory CashBalanceNotification.fromJson(Map<String, dynamic> json) {
    return CashBalanceNotification(
      action: json['type'] ?? json['action'] ?? '',
      cashBalance: CashBalanceData.fromJson(json['cash_balance'] ?? {}),
      reason: json['reason'],
      requiresReconciliation: json['requires_reconciliation'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'cash_balance': cashBalance.toJson(),
      'reason': reason,
      'requires_reconciliation': requiresReconciliation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  String get actionText {
    switch (action) {
      case 'auto_closed':
        return 'Caja Auto-Cerrada';
      case 'auto_created':
        return 'Caja Virtual Creada';
      case 'requires_reconciliation':
        return 'Requiere Conciliación';
      default:
        return 'Notificación de Caja';
    }
  }

  String get message {
    switch (action) {
      case 'auto_closed':
        return 'Tu caja del ${cashBalance.date} fue cerrada automáticamente. Saldo final: ${cashBalance.finalAmount.toStringAsFixed(2)} Bs';
      case 'auto_created':
        final reasonText = reason == 'payment'
            ? 'al registrar un pago'
            : 'al entregar un crédito';
        return 'Se creó una caja virtual para ${cashBalance.date} automáticamente $reasonText.';
      case 'requires_reconciliation':
        return 'Tu caja del ${cashBalance.date} requiere conciliación. ${reason ?? ''}';
      default:
        return 'Notificación de caja para ${cashBalance.date}';
    }
  }
}

/// Datos de la caja (Cash Balance)
class CashBalanceData {
  final int id;
  final String date;
  final double initialAmount;
  final double collectedAmount;
  final double lentAmount;
  final double finalAmount;
  final String status;
  final String? autoClosedAt;
  final String? closureNotes;

  CashBalanceData({
    required this.id,
    required this.date,
    this.initialAmount = 0.0,
    this.collectedAmount = 0.0,
    this.lentAmount = 0.0,
    required this.finalAmount,
    required this.status,
    this.autoClosedAt,
    this.closureNotes,
  });

  factory CashBalanceData.fromJson(Map<String, dynamic> json) {
    return CashBalanceData(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      initialAmount: _parseDouble(json['initial_amount']),
      collectedAmount: _parseDouble(json['collected_amount']),
      lentAmount: _parseDouble(json['lent_amount']),
      finalAmount: _parseDouble(json['final_amount']),
      status: json['status'] ?? '',
      autoClosedAt: json['auto_closed_at'],
      closureNotes: json['closure_notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'initial_amount': initialAmount,
      'collected_amount': collectedAmount,
      'lent_amount': lentAmount,
      'final_amount': finalAmount,
      'status': status,
      'auto_closed_at': autoClosedAt,
      'closure_notes': closureNotes,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  bool get wasAutoClosed => autoClosedAt != null;

  String get formattedDate {
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (_) {
      return date;
    }
  }
}
