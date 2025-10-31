class PaymentSchedule {
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final String status; // 'pending', 'paid', 'overdue'

  PaymentSchedule({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      installmentNumber: json['installment_number'] ?? 0,
      dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';
}
