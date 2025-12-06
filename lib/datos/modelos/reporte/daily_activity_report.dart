/// Modelo principal del reporte de actividad diaria
class DailyActivityReport {
  final List<DailyActivityCobradorItem> items;
  final DailyActivitySummary summary;
  final DateTime generatedAt;
  final String generatedBy;

  DailyActivityReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory DailyActivityReport.fromJson(Map<String, dynamic> json) {
    List<DailyActivityCobradorItem> parseItems(dynamic itemsList) {
      if (itemsList is List) {
        return itemsList
            .map((item) => DailyActivityCobradorItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return DailyActivityReport(
      items: parseItems(json['items']),
      summary: DailyActivitySummary.fromJson(json['summary'] ?? {}),
      generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
      generatedBy: json['generated_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'summary': summary.toJson(),
    'generated_at': generatedAt.toIso8601String(),
    'generated_by': generatedBy,
  };
}

/// Item individual por cobrador en el reporte diario
class DailyActivityCobradorItem {
  final String cobradorName;
  final int cobradorId;
  final CashBalanceInfo cashBalance;
  final CreditsDeliveredInfo creditsDelivered;
  final PaymentsCollectedInfo paymentsCollected;
  final ExpectedPaymentsInfo expectedPayments;

  DailyActivityCobradorItem({
    required this.cobradorName,
    required this.cobradorId,
    required this.cashBalance,
    required this.creditsDelivered,
    required this.paymentsCollected,
    required this.expectedPayments,
  });

  factory DailyActivityCobradorItem.fromJson(Map<String, dynamic> json) {
    return DailyActivityCobradorItem(
      cobradorName: json['cobrador_name'] ?? '',
      cobradorId: json['cobrador_id'] ?? 0,
      cashBalance: CashBalanceInfo.fromJson(json['cash_balance'] ?? {}),
      creditsDelivered: CreditsDeliveredInfo.fromJson(json['credits_delivered'] ?? {}),
      paymentsCollected: PaymentsCollectedInfo.fromJson(json['payments_collected'] ?? {}),
      expectedPayments: ExpectedPaymentsInfo.fromJson(json['expected_payments'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'cobrador_name': cobradorName,
    'cobrador_id': cobradorId,
    'cash_balance': cashBalance.toJson(),
    'credits_delivered': creditsDelivered.toJson(),
    'payments_collected': paymentsCollected.toJson(),
    'expected_payments': expectedPayments.toJson(),
  };
}

/// Información del balance de efectivo
class CashBalanceInfo {
  final String status;
  final double initialAmount;
  final double collectedAmount;
  final double lentAmount;
  final double finalAmount;

  CashBalanceInfo({
    required this.status,
    required this.initialAmount,
    required this.collectedAmount,
    required this.lentAmount,
    required this.finalAmount,
  });

  factory CashBalanceInfo.fromJson(Map<String, dynamic> json) {
    double tryDouble(dynamic v) {
      if (v == null) return 0.0;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return CashBalanceInfo(
      status: json['status'] ?? 'unknown',
      initialAmount: tryDouble(json['initial_amount']),
      collectedAmount: tryDouble(json['collected_amount']),
      lentAmount: tryDouble(json['lent_amount']),
      finalAmount: tryDouble(json['final_amount']),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'initial_amount': initialAmount,
    'collected_amount': collectedAmount,
    'lent_amount': lentAmount,
    'final_amount': finalAmount,
  };

  bool get isOpen => status.toLowerCase() == 'open';
  bool get isClosed => status.toLowerCase() == 'closed';
}

/// Información de créditos entregados
class CreditsDeliveredInfo {
  final int count;
  final List<CreditDetail> details;

  CreditsDeliveredInfo({
    required this.count,
    required this.details,
  });

  factory CreditsDeliveredInfo.fromJson(Map<String, dynamic> json) {
    List<CreditDetail> parseDetails(dynamic detailsList) {
      if (detailsList is List) {
        return detailsList
            .map((item) => CreditDetail.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return CreditsDeliveredInfo(
      count: json['count'] ?? 0,
      details: parseDetails(json['details']),
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'details': details.map((d) => d.toJson()).toList(),
  };
}

/// Detalle de un crédito entregado
class CreditDetail {
  final int creditId;
  final String clientName;
  final double amount;
  final String? deliveredAt;

  CreditDetail({
    required this.creditId,
    required this.clientName,
    required this.amount,
    this.deliveredAt,
  });

  factory CreditDetail.fromJson(Map<String, dynamic> json) {
    return CreditDetail(
      creditId: json['credit_id'] ?? 0,
      clientName: json['client_name'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      deliveredAt: json['delivered_at'],
    );
  }

  Map<String, dynamic> toJson() => {
    'credit_id': creditId,
    'client_name': clientName,
    'amount': amount,
    'delivered_at': deliveredAt,
  };
}

/// Información de pagos cobrados
class PaymentsCollectedInfo {
  final int count;
  final List<PaymentDetail> details;

  PaymentsCollectedInfo({
    required this.count,
    required this.details,
  });

  factory PaymentsCollectedInfo.fromJson(Map<String, dynamic> json) {
    List<PaymentDetail> parseDetails(dynamic detailsList) {
      if (detailsList is List) {
        return detailsList
            .map((item) => PaymentDetail.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return PaymentsCollectedInfo(
      count: json['count'] ?? 0,
      details: parseDetails(json['details']),
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'details': details.map((d) => d.toJson()).toList(),
  };
}

/// Detalle de un pago cobrado
class PaymentDetail {
  final int paymentId;
  final String clientName;
  final double amount;
  final String? collectedAt;
  final String? paymentMethod;

  PaymentDetail({
    required this.paymentId,
    required this.clientName,
    required this.amount,
    this.collectedAt,
    this.paymentMethod,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) {
    return PaymentDetail(
      paymentId: json['payment_id'] ?? 0,
      clientName: json['client_name'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      collectedAt: json['collected_at'],
      paymentMethod: json['payment_method'],
    );
  }

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    'client_name': clientName,
    'amount': amount,
    'collected_at': collectedAt,
    'payment_method': paymentMethod,
  };
}

/// Información de pagos esperados
class ExpectedPaymentsInfo {
  final int count;
  final int collected;
  final int pending;
  final double efficiency;

  ExpectedPaymentsInfo({
    required this.count,
    required this.collected,
    required this.pending,
    required this.efficiency,
  });

  factory ExpectedPaymentsInfo.fromJson(Map<String, dynamic> json) {
    double tryDouble(dynamic v) {
      if (v == null) return 0.0;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return ExpectedPaymentsInfo(
      count: json['count'] ?? 0,
      collected: json['collected'] ?? 0,
      pending: json['pending'] ?? 0,
      efficiency: tryDouble(json['efficiency']),
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'collected': collected,
    'pending': pending,
    'efficiency': efficiency,
  };

  String get efficiencyFormatted => '${efficiency.toStringAsFixed(0)}%';
}

/// Resumen del reporte diario
class DailyActivitySummary {
  final String date;
  final String dayName;
  final int totalCobradores;
  final DailyActivityTotals totals;
  final double overallEfficiency;
  final CashBalancesStatus cashBalances;

  DailyActivitySummary({
    required this.date,
    required this.dayName,
    required this.totalCobradores,
    required this.totals,
    required this.overallEfficiency,
    required this.cashBalances,
  });

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    double tryDouble(dynamic v) {
      if (v == null) return 0.0;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return DailyActivitySummary(
      date: json['date'] ?? '',
      dayName: json['day_name'] ?? '',
      totalCobradores: json['total_cobradores'] ?? 0,
      totals: DailyActivityTotals.fromJson(json['totals'] ?? {}),
      overallEfficiency: tryDouble(json['overall_efficiency']),
      cashBalances: CashBalancesStatus.fromJson(json['cash_balances'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date,
    'day_name': dayName,
    'total_cobradores': totalCobradores,
    'totals': totals.toJson(),
    'overall_efficiency': overallEfficiency,
    'cash_balances': cashBalances.toJson(),
  };

  String get overallEfficiencyFormatted => '${overallEfficiency.toStringAsFixed(0)}%';
}

/// Totales del día
class DailyActivityTotals {
  final int creditsDelivered;
  final double amountLent;
  final int paymentsCollected;
  final double amountCollected;
  final int expectedPayments;
  final int pendingPayments;

  DailyActivityTotals({
    required this.creditsDelivered,
    required this.amountLent,
    required this.paymentsCollected,
    required this.amountCollected,
    required this.expectedPayments,
    required this.pendingPayments,
  });

  factory DailyActivityTotals.fromJson(Map<String, dynamic> json) {
    double tryDouble(dynamic v) {
      if (v == null) return 0.0;
      return double.tryParse(v.toString()) ?? 0.0;
    }

    return DailyActivityTotals(
      creditsDelivered: json['credits_delivered'] ?? 0,
      amountLent: tryDouble(json['amount_lent']),
      paymentsCollected: json['payments_collected'] ?? 0,
      amountCollected: tryDouble(json['amount_collected']),
      expectedPayments: json['expected_payments'] ?? 0,
      pendingPayments: json['pending_payments'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'credits_delivered': creditsDelivered,
    'amount_lent': amountLent,
    'payments_collected': paymentsCollected,
    'amount_collected': amountCollected,
    'expected_payments': expectedPayments,
    'pending_payments': pendingPayments,
  };
}

/// Estado de los balances de efectivo
class CashBalancesStatus {
  final int opened;
  final int closed;

  CashBalancesStatus({
    required this.opened,
    required this.closed,
  });

  factory CashBalancesStatus.fromJson(Map<String, dynamic> json) {
    return CashBalancesStatus(
      opened: json['opened'] ?? 0,
      closed: json['closed'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'opened': opened,
    'closed': closed,
  };
}
