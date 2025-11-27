/// Modelo específico para el reporte de créditos en mora
/// Esta estructura mapea exactamente lo que devuelve el endpoint /api/reports/overdue

class OverdueReport {
  final List<OverdueReportItem> items;
  final OverdueReportSummary summary;
  final String generatedAt;
  final String generatedBy;

  OverdueReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory OverdueReport.fromJson(Map<String, dynamic> json) {
    return OverdueReport(
      items: _parseItems(json['items']),
      summary: OverdueReportSummary.fromJson(json['summary'] ?? {}),
      generatedAt: json['generated_at'] ?? '',
      generatedBy: json['generated_by'] ?? '',
    );
  }

  static List<OverdueReportItem> _parseItems(dynamic itemsList) {
    if (itemsList is List) {
      return itemsList
          .map((item) => OverdueReportItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'summary': summary.toJson(),
    'generated_at': generatedAt,
    'generated_by': generatedBy,
  };
}

class OverdueReportItem {
  final int id;
  final int clientId;
  final String clientName;
  final String? clientPhone;
  final String? clientCategory;
  final int cobradorId;
  final String cobradorName;
  final double amount;
  final String amountFormatted;
  final double balance;
  final String balanceFormatted;
  final String status;
  final int daysOverdue;
  final double overdueAmount;
  final String overdueAmountFormatted;
  final int totalInstallments;
  final int completedInstallments;
  final int expectedInstallments;
  final int pendingInstallments;
  final int installmentsOverdue;
  final String createdAt;
  final String createdAtFormatted;
  final String? lastPaymentDate;
  final String? lastPaymentDateFormatted;

  OverdueReportItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhone,
    this.clientCategory,
    required this.cobradorId,
    required this.cobradorName,
    required this.amount,
    required this.amountFormatted,
    required this.balance,
    required this.balanceFormatted,
    required this.status,
    required this.daysOverdue,
    required this.overdueAmount,
    required this.overdueAmountFormatted,
    required this.totalInstallments,
    required this.completedInstallments,
    required this.expectedInstallments,
    required this.pendingInstallments,
    required this.installmentsOverdue,
    required this.createdAt,
    required this.createdAtFormatted,
    this.lastPaymentDate,
    this.lastPaymentDateFormatted,
  });

  factory OverdueReportItem.fromJson(Map<String, dynamic> json) {
    return OverdueReportItem(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      clientPhone: json['client_phone'] as String?,
      clientCategory: json['client_category'] as String?,
      cobradorId: json['cobrador_id'] as int? ?? 0,
      cobradorName: json['cobrador_name'] as String? ?? '',
      amount: _toDouble(json['amount']),
      amountFormatted: json['amount_formatted'] as String? ?? '',
      balance: _toDouble(json['balance']),
      balanceFormatted: json['balance_formatted'] as String? ?? '',
      status: json['status'] as String? ?? '',
      daysOverdue: json['days_overdue'] as int? ?? 0,
      overdueAmount: _toDouble(json['overdue_amount']),
      overdueAmountFormatted: json['overdue_amount_formatted'] as String? ?? '',
      totalInstallments: json['total_installments'] as int? ?? 0,
      completedInstallments: json['completed_installments'] as int? ?? 0,
      expectedInstallments: json['expected_installments'] as int? ?? 0,
      pendingInstallments: json['pending_installments'] as int? ?? 0,
      installmentsOverdue: json['installments_overdue'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      createdAtFormatted: json['created_at_formatted'] as String? ?? '',
      lastPaymentDate: json['last_payment_date'] as String?,
      lastPaymentDateFormatted: json['last_payment_date_formatted'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'client_name': clientName,
    'client_phone': clientPhone,
    'client_category': clientCategory,
    'cobrador_id': cobradorId,
    'cobrador_name': cobradorName,
    'amount': amount,
    'amount_formatted': amountFormatted,
    'balance': balance,
    'balance_formatted': balanceFormatted,
    'status': status,
    'days_overdue': daysOverdue,
    'overdue_amount': overdueAmount,
    'overdue_amount_formatted': overdueAmountFormatted,
    'total_installments': totalInstallments,
    'completed_installments': completedInstallments,
    'expected_installments': expectedInstallments,
    'pending_installments': pendingInstallments,
    'installments_overdue': installmentsOverdue,
    'created_at': createdAt,
    'created_at_formatted': createdAtFormatted,
    'last_payment_date': lastPaymentDate,
    'last_payment_date_formatted': lastPaymentDateFormatted,
  };

  /// Calcula la severidad de la mora (0-3: bajo, medio, alto, crítico)
  int get severityLevel {
    if (daysOverdue <= 7) return 0;       // Bajo (1-7 días)
    if (daysOverdue <= 15) return 1;      // Medio (8-15 días)
    if (daysOverdue <= 30) return 2;      // Alto (16-30 días)
    return 3;                              // Crítico (>30 días)
  }

  /// Etiqueta de severidad
  String get severityLabel {
    switch (severityLevel) {
      case 0: return 'Bajo';
      case 1: return 'Medio';
      case 2: return 'Alto';
      case 3: return 'Crítico';
      default: return 'Desconocido';
    }
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class OverdueReportSummary {
  final int totalCredits;
  final double totalOverdueAmount;
  final String totalOverdueAmountFormatted;
  final double totalBalance;
  final String totalBalanceFormatted;
  final int creditsLowOverdue;      // 1-7 días
  final int creditsMediumOverdue;   // 8-15 días
  final int creditsHighOverdue;     // 16-30 días
  final int creditsCriticalOverdue; // >30 días
  final double averageDaysOverdue;
  final int totalInstallmentsOverdue;

  OverdueReportSummary({
    required this.totalCredits,
    required this.totalOverdueAmount,
    required this.totalOverdueAmountFormatted,
    required this.totalBalance,
    required this.totalBalanceFormatted,
    required this.creditsLowOverdue,
    required this.creditsMediumOverdue,
    required this.creditsHighOverdue,
    required this.creditsCriticalOverdue,
    required this.averageDaysOverdue,
    required this.totalInstallmentsOverdue,
  });

  factory OverdueReportSummary.fromJson(Map<String, dynamic> json) {
    return OverdueReportSummary(
      totalCredits: json['total_credits'] as int? ?? 0,
      totalOverdueAmount: _toDouble(json['total_overdue_amount']),
      totalOverdueAmountFormatted: json['total_overdue_amount_formatted'] as String? ?? '',
      totalBalance: _toDouble(json['total_balance']),
      totalBalanceFormatted: json['total_balance_formatted'] as String? ?? '',
      creditsLowOverdue: json['credits_low_overdue'] as int? ?? 0,
      creditsMediumOverdue: json['credits_medium_overdue'] as int? ?? 0,
      creditsHighOverdue: json['credits_high_overdue'] as int? ?? 0,
      creditsCriticalOverdue: json['credits_critical_overdue'] as int? ?? 0,
      averageDaysOverdue: _toDouble(json['average_days_overdue']),
      totalInstallmentsOverdue: json['total_installments_overdue'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_credits': totalCredits,
    'total_overdue_amount': totalOverdueAmount,
    'total_overdue_amount_formatted': totalOverdueAmountFormatted,
    'total_balance': totalBalance,
    'total_balance_formatted': totalBalanceFormatted,
    'credits_low_overdue': creditsLowOverdue,
    'credits_medium_overdue': creditsMediumOverdue,
    'credits_high_overdue': creditsHighOverdue,
    'credits_critical_overdue': creditsCriticalOverdue,
    'average_days_overdue': averageDaysOverdue,
    'total_installments_overdue': totalInstallmentsOverdue,
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
