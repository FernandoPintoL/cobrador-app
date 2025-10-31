/// Modelo para el estado actual de la caja del usuario
class CashBalanceStatus {
  final bool isOpen;
  final bool hasPendingClosures;
  final bool canOpenNew;
  final SimpleCashBalance? currentCashBalance;
  final List<SimpleCashBalance> pendingClosures;
  final String date;

  CashBalanceStatus({
    required this.isOpen,
    required this.hasPendingClosures,
    required this.canOpenNew,
    this.currentCashBalance,
    required this.pendingClosures,
    required this.date,
  });

  factory CashBalanceStatus.fromJson(Map<String, dynamic> json) {
    return CashBalanceStatus(
      isOpen: json['is_open'] as bool,
      hasPendingClosures: json['has_pending_closures'] as bool,
      canOpenNew: json['can_open_new'] as bool,
      currentCashBalance: json['current_cash_balance'] != null
          ? SimpleCashBalance.fromJson(
              json['current_cash_balance'] as Map<String, dynamic>,
            )
          : null,
      pendingClosures: (json['pending_closures'] as List<dynamic>?)
              ?.map((e) => SimpleCashBalance.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_open': isOpen,
      'has_pending_closures': hasPendingClosures,
      'can_open_new': canOpenNew,
      'current_cash_balance': currentCashBalance?.toJson(),
      'pending_closures': pendingClosures.map((e) => e.toJson()).toList(),
      'date': date,
    };
  }

  @override
  String toString() {
    return 'CashBalanceStatus('
        'isOpen: $isOpen, '
        'hasPendingClosures: $hasPendingClosures, '
        'canOpenNew: $canOpenNew, '
        'date: $date, '
        'pendingClosures: ${pendingClosures.length}'
        ')';
  }
}

/// Modelo simplificado de caja para el estado actual
class SimpleCashBalance {
  final int id;
  final String date;
  final String status;
  final double initialAmount;
  final double? collectedAmount;
  final double? lentAmount;
  final double? finalAmount;

  SimpleCashBalance({
    required this.id,
    required this.date,
    required this.status,
    required this.initialAmount,
    this.collectedAmount,
    this.lentAmount,
    this.finalAmount,
  });

  factory SimpleCashBalance.fromJson(Map<String, dynamic> json) {
    return SimpleCashBalance(
      id: json['id'] as int,
      date: json['date'] as String,
      status: json['status'] as String,
      initialAmount: _parseDouble(json['initial_amount']),
      collectedAmount: json['collected_amount'] != null
          ? _parseDouble(json['collected_amount'])
          : null,
      lentAmount: json['lent_amount'] != null
          ? _parseDouble(json['lent_amount'])
          : null,
      finalAmount: json['final_amount'] != null
          ? _parseDouble(json['final_amount'])
          : null,
    );
  }

  /// Parsea un valor que puede ser String, int, double a double
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'status': status,
      'initial_amount': initialAmount,
      'collected_amount': collectedAmount,
      'lent_amount': lentAmount,
      'final_amount': finalAmount,
    };
  }

  @override
  String toString() {
    return 'SimpleCashBalance(id: $id, date: $date, status: $status)';
  }
}
