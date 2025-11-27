class PaymentSchedule {
  final int installmentNumber;
  final DateTime dueDate;
  final double amount;
  final String status; // 'pending', 'paid', 'overdue', 'partial'

  // Nuevos campos para mostrar información de pagos reales
  final double paidAmount;
  final double remainingAmount;
  final bool isPaidFull;
  final bool isPartial;
  final int paymentCount;
  final DateTime? lastPaymentDate;
  final String? paymentMethod;

  // ✅ OPTIMIZACIÓN: Información del cobrador que recibió el pago
  // Ahora viene directo del backend, sin necesidad de cargar payments
  final int? receivedById;
  final String? receivedByName;

  PaymentSchedule({
    required this.installmentNumber,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.isPaidFull = false,
    this.isPartial = false,
    this.paymentCount = 0,
    this.lastPaymentDate,
    this.paymentMethod,
    this.receivedById,
    this.receivedByName,
  });

  factory PaymentSchedule.fromJson(Map<String, dynamic> json) {
    return PaymentSchedule(
      installmentNumber: json['installment_number'] ?? 0,
      dueDate: DateTime.tryParse(json['due_date'] ?? '') ?? DateTime.now(),
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      status: json['status'] ?? 'pending',
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      remainingAmount: double.tryParse(json['remaining_amount']?.toString() ?? '0') ?? 0.0,
      isPaidFull: json['is_paid'] ?? false,
      isPartial: json['is_partial'] ?? false,
      paymentCount: json['payment_count'] ?? 0,
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.tryParse(json['last_payment_date'])
          : null,
      paymentMethod: json['payment_method'],
      receivedById: json['received_by_id'],
      receivedByName: json['received_by_name'],
    );
  }

  // Getters de compatibilidad con código existente
  bool get isPaid => status == 'paid' || isPaidFull;
  bool get isPending => status == 'pending';
  bool get isOverdue => status == 'overdue';
}
