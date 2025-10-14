class PaymentAnalysis {
  final double paymentAmount;
  final double regularInstallment;
  final double remainingBalance;
  final String
  type; // 'partial', 'regular', 'multiple_installments', 'full_payment'
  final int? installmentsCovered;
  final double? excessAmount;
  final String message;

  PaymentAnalysis({
    required this.paymentAmount,
    required this.regularInstallment,
    required this.remainingBalance,
    required this.type,
    this.installmentsCovered,
    this.excessAmount,
    required this.message,
  });

  factory PaymentAnalysis.fromJson(Map<String, dynamic> json) {
    return PaymentAnalysis(
      paymentAmount: double.tryParse(json['payment_amount'].toString()) ?? 0.0,
      regularInstallment:
          double.tryParse(json['regular_installment'].toString()) ?? 0.0,
      remainingBalance:
          double.tryParse(json['remaining_balance'].toString()) ?? 0.0,
      type: json['type'] ?? 'regular',
      installmentsCovered: json['installments_covered'],
      excessAmount: json['excess_amount'] != null
          ? double.tryParse(json['excess_amount'].toString())
          : null,
      message: json['message'] ?? '',
    );
  }
}
