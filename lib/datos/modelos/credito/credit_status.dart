class CreditStatus {
  final double currentBalance;
  final double totalPaid;
  final int pendingInstallments;
  final bool isOverdue;
  final double overdueAmount;

  CreditStatus({
    required this.currentBalance,
    required this.totalPaid,
    required this.pendingInstallments,
    required this.isOverdue,
    required this.overdueAmount,
  });

  factory CreditStatus.fromJson(Map<String, dynamic> json) {
    return CreditStatus(
      currentBalance:
          double.tryParse(json['current_balance'].toString()) ?? 0.0,
      totalPaid: double.tryParse(json['total_paid'].toString()) ?? 0.0,
      pendingInstallments: json['pending_installments'] ?? 0,
      isOverdue: json['is_overdue'] ?? false,
      overdueAmount: double.tryParse(json['overdue_amount'].toString()) ?? 0.0,
    );
  }
}
