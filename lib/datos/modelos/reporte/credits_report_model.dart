/// Modelo específico para el reporte de créditos
/// Esta estructura mapea exactamente lo que devuelve el endpoint /api/reports/credits

class CreditsReport {
  final List<CreditReportItem> items;
  final CreditsReportSummary summary;
  final String generatedAt;
  final String generatedBy;

  CreditsReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory CreditsReport.fromJson(Map<String, dynamic> json) {
    return CreditsReport(
      items: _parseItems(json['items']),
      summary: CreditsReportSummary.fromJson(json['summary'] ?? {}),
      generatedAt: json['generated_at'] ?? '',
      generatedBy: json['generated_by'] ?? '',
    );
  }

  static List<CreditReportItem> _parseItems(dynamic itemsList) {
    if (itemsList is List) {
      return itemsList
          .map((item) => CreditReportItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

class CreditReportItem {
  final int id;
  final int clientId;
  final String clientName;
  final double amount;
  final String amountFormatted;
  final double balance;
  final String balanceFormatted;
  final String status; // 'active', 'completed', etc.
  final double interestRate;
  final int createdById;
  final String createdByName;
  final int deliveredById;
  final String deliveredByName;
  final int totalInstallments;
  final int completedInstallments;
  final int expectedInstallments;
  final int pendingInstallments;
  final int installmentsOverdue;
  final int paymentsCount;
  final String createdAt;
  final String createdAtFormatted;
  final String paymentStatus; // 'warning', 'ahead', 'completed', 'danger'
  final String paymentStatusIcon;
  final String paymentStatusColor;
  final String paymentStatusLabel;

  CreditReportItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.amount,
    required this.amountFormatted,
    required this.balance,
    required this.balanceFormatted,
    required this.status,
    required this.interestRate,
    required this.createdById,
    required this.createdByName,
    required this.deliveredById,
    required this.deliveredByName,
    required this.totalInstallments,
    required this.completedInstallments,
    required this.expectedInstallments,
    required this.pendingInstallments,
    required this.installmentsOverdue,
    required this.paymentsCount,
    required this.createdAt,
    required this.createdAtFormatted,
    required this.paymentStatus,
    required this.paymentStatusIcon,
    required this.paymentStatusColor,
    required this.paymentStatusLabel,
  });

  factory CreditReportItem.fromJson(Map<String, dynamic> json) {
    return CreditReportItem(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      amount: _toDouble(json['amount']),
      amountFormatted: json['amount_formatted'] as String? ?? '',
      balance: _toDouble(json['balance']),
      balanceFormatted: json['balance_formatted'] as String? ?? '',
      status: json['status'] as String? ?? '',
      interestRate: _toDouble(json['interest_rate']),
      createdById: json['created_by_id'] as int? ?? 0,
      createdByName: json['created_by_name'] as String? ?? '',
      deliveredById: json['delivered_by_id'] as int? ?? 0,
      deliveredByName: json['delivered_by_name'] as String? ?? '',
      totalInstallments: json['total_installments'] as int? ?? 0,
      completedInstallments: json['completed_installments'] as int? ?? 0,
      expectedInstallments: json['expected_installments'] as int? ?? 0,
      pendingInstallments: json['pending_installments'] as int? ?? 0,
      installmentsOverdue: json['installments_overdue'] as int? ?? 0,
      paymentsCount: json['payments_count'] as int? ?? 0,
      createdAt: json['created_at'] as String? ?? '',
      createdAtFormatted: json['created_at_formatted'] as String? ?? '',
      paymentStatus: json['payment_status'] as String? ?? '',
      paymentStatusIcon: json['payment_status_icon'] as String? ?? '',
      paymentStatusColor: json['payment_status_color'] as String? ?? '',
      paymentStatusLabel: json['payment_status_label'] as String? ?? '',
    );
  }

  /// Calcula el porcentaje de cuotas pagadas
  int get paymentPercentage {
    if (totalInstallments == 0) return 0;
    return ((completedInstallments * 100) / totalInstallments).toInt();
  }

  /// Obtiene el color del estado de pago
  String get statusColor {
    switch (paymentStatus.toLowerCase()) {
      case 'completed':
        return 'success';
      case 'ahead':
        return 'info';
      case 'warning':
        return 'warning';
      case 'danger':
        return 'danger';
      default:
        return 'primary';
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

class CreditsReportSummary {
  final int totalCredits;
  final double totalAmount;
  final String totalAmountFormatted;
  final int activeCredits;
  final double activeAmount;
  final String activeAmountFormatted;
  final int completedCredits;
  final double completedAmount;
  final String completedAmountFormatted;
  final double totalBalance;
  final String totalBalanceFormatted;
  final double pendingAmount;
  final String pendingAmountFormatted;
  final double averageAmount;
  final String averageAmountFormatted;
  final double totalPaid;
  final String totalPaidFormatted;

  CreditsReportSummary({
    required this.totalCredits,
    required this.totalAmount,
    required this.totalAmountFormatted,
    required this.activeCredits,
    required this.activeAmount,
    required this.activeAmountFormatted,
    required this.completedCredits,
    required this.completedAmount,
    required this.completedAmountFormatted,
    required this.totalBalance,
    required this.totalBalanceFormatted,
    required this.pendingAmount,
    required this.pendingAmountFormatted,
    required this.averageAmount,
    required this.averageAmountFormatted,
    required this.totalPaid,
    required this.totalPaidFormatted,
  });

  factory CreditsReportSummary.fromJson(Map<String, dynamic> json) {
    return CreditsReportSummary(
      totalCredits: json['total_credits'] as int? ?? 0,
      totalAmount: _toDouble(json['total_amount']),
      totalAmountFormatted: json['total_amount_formatted'] as String? ?? '',
      activeCredits: json['active_credits'] as int? ?? 0,
      activeAmount: _toDouble(json['active_amount']),
      activeAmountFormatted: json['active_amount_formatted'] as String? ?? '',
      completedCredits: json['completed_credits'] as int? ?? 0,
      completedAmount: _toDouble(json['completed_amount']),
      completedAmountFormatted: json['completed_amount_formatted'] as String? ?? '',
      totalBalance: _toDouble(json['total_balance']),
      totalBalanceFormatted: json['total_balance_formatted'] as String? ?? '',
      pendingAmount: _toDouble(json['pending_amount']),
      pendingAmountFormatted: json['pending_amount_formatted'] as String? ?? '',
      averageAmount: _toDouble(json['average_amount']),
      averageAmountFormatted: json['average_amount_formatted'] as String? ?? '',
      totalPaid: _toDouble(json['total_paid']),
      totalPaidFormatted: json['total_paid_formatted'] as String? ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
