class CreditStats {
  final int totalCredits;
  final int activeCredits;
  final int completedCredits;
  final int defaultedCredits;
  final double totalAmount;
  final double totalBalance;

  CreditStats({
    required this.totalCredits,
    required this.activeCredits,
    required this.completedCredits,
    required this.defaultedCredits,
    required this.totalAmount,
    required this.totalBalance,
  });

  factory CreditStats.fromJson(Map<String, dynamic> json) {
    return CreditStats(
      totalCredits: json['total_credits'] ?? 0,
      activeCredits: json['active_credits'] ?? 0,
      completedCredits: json['completed_credits'] ?? 0,
      defaultedCredits: json['defaulted_credits'] ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      totalBalance: double.tryParse(json['total_balance'].toString()) ?? 0.0,
    );
  }

  double get collectionRate {
    if (totalAmount == 0) return 0.0;
    return ((totalAmount - totalBalance) / totalAmount) * 100;
  }

  double get defaultRate {
    if (totalCredits == 0) return 0.0;
    return (defaultedCredits / totalCredits) * 100;
  }
}
