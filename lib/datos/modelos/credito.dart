import 'usuario.dart';

class Credito {
  final int id;
  final int clientId;
  final int? cobradorId;
  final int? createdBy;
  final double amount; // Monto original
  final double balance; // Balance actual pendiente
  final double? interestRate; // Porcentaje de interés (ej: 20.00 para 20%)
  final double? totalAmount; // Monto total con interés incluido
  final double? installmentAmount; // Monto de cada cuota
  final String frequency; // 'daily', 'weekly', 'biweekly', 'monthly'
  final String status; // 'active', 'completed', 'defaulted'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime? nextPaymentDate;
  final double? paymentAmount; // Deprecated: usar installmentAmount
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Relaciones
  final Usuario? client;
  final Usuario? cobrador;
  final Usuario? creator;
  final List<Pago>? payments;

  Credito({
    required this.id,
    required this.clientId,
    this.cobradorId,
    this.createdBy,
    required this.amount,
    required this.balance,
    this.interestRate,
    this.totalAmount,
    this.installmentAmount,
    required this.frequency,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.nextPaymentDate,
    this.paymentAmount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.client,
    this.cobrador,
    this.creator,
    this.payments,
  });

  factory Credito.fromJson(Map<String, dynamic> json) {
    return Credito(
      id: json['id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      cobradorId: json['cobrador_id'],
      createdBy: json['created_by'] is Map
          ? json['created_by']['id']
          : json['created_by'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      interestRate: json['interest_rate'] != null
          ? double.tryParse(json['interest_rate'].toString())
          : null,
      totalAmount: json['total_amount'] != null
          ? double.tryParse(json['total_amount'].toString())
          : null,
      installmentAmount: json['installment_amount'] != null
          ? double.tryParse(json['installment_amount'].toString())
          : null,
      frequency: json['frequency'] ?? 'monthly',
      status: json['status'] ?? 'active',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      nextPaymentDate: json['next_payment_date'] != null
          ? DateTime.tryParse(json['next_payment_date'])
          : null,
      paymentAmount: json['payment_amount'] != null
          ? double.tryParse(json['payment_amount'].toString())
          : null,
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      client: json['client'] != null ? Usuario.fromJson(json['client']) : null,
      cobrador: json['cobrador'] != null
          ? Usuario.fromJson(json['cobrador'])
          : null,
      creator: json['created_by'] != null && json['created_by'] is Map
          ? Usuario.fromJson(json['created_by'])
          : (json['creator'] != null
                ? Usuario.fromJson(json['creator'])
                : null),
      payments: json['payments'] != null
          ? (json['payments'] as List).map((p) => Pago.fromJson(p)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
      'cobrador_id': cobradorId,
      'created_by': createdBy,
      'amount': amount,
      'balance': balance,
      'interest_rate': interestRate,
      'total_amount': totalAmount,
      'installment_amount': installmentAmount,
      'frequency': frequency,
      'status': status,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate.toIso8601String().split('T')[0],
      'next_payment_date': nextPaymentDate?.toIso8601String().split('T')[0],
      'payment_amount': paymentAmount,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Métodos de utilidad
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isDefaulted => status == 'defaulted';

  bool get isOverdue {
    return DateTime.now().isAfter(endDate) && !isCompleted;
  }

  bool get requiresAttention {
    if (isOverdue) return true;

    // Próximo a vencer en 7 días
    final now = DateTime.now();
    final daysUntilDue = endDate.difference(now).inDays;
    return daysUntilDue <= 7 && daysUntilDue >= 0 && isActive;
  }

  double get progressPercentage {
    final total = totalAmount ?? amount;
    if (total == 0) return 0.0;
    return ((total - balance) / total) * 100;
  }

  // Calcular el número total de cuotas
  int get totalInstallments {
    final daysDiff = endDate.difference(startDate).inDays + 1;
    switch (frequency) {
      case 'daily':
        return daysDiff;
      case 'weekly':
        return (daysDiff / 7).ceil();
      case 'biweekly':
        return (daysDiff / 14).ceil();
      case 'monthly':
        return (daysDiff / 30).ceil();
      default:
        return daysDiff;
    }
  }

  // Calcular cuotas pendientes
  int get pendingInstallments {
    final currentInstallment =
        installmentAmount ?? (totalAmount ?? amount) / totalInstallments;
    if (currentInstallment == 0) return 0;
    return (balance / currentInstallment).ceil();
  }

  // Calcular cuotas pagadas
  int get paidInstallments {
    return totalInstallments - pendingInstallments;
  }

  // Calcular monto total pagado
  double get totalPaidAmount {
    final total = totalAmount ?? amount;
    return total - balance;
  }

  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quincenal';
      case 'monthly':
        return 'Mensual';
      default:
        return frequency;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'defaulted':
        return 'En Mora';
      default:
        return status;
    }
  }

  Credito copyWith({
    int? id,
    int? clientId,
    int? cobradorId,
    int? createdBy,
    double? amount,
    double? balance,
    String? frequency,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? nextPaymentDate,
    double? paymentAmount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    Usuario? client,
    Usuario? cobrador,
    Usuario? creator,
    List<Pago>? payments,
  }) {
    return Credito(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      cobradorId: cobradorId ?? this.cobradorId,
      createdBy: createdBy ?? this.createdBy,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      client: client ?? this.client,
      cobrador: cobrador ?? this.cobrador,
      creator: creator ?? this.creator,
      payments: payments ?? this.payments,
    );
  }
}

class Pago {
  final int id;
  final int creditId;
  final int? cobradorId;
  final double amount;
  final String? paymentType; // 'cash', 'transfer', etc.
  final String status; // 'pending', 'completed', 'failed'
  final DateTime paymentDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Pago({
    required this.id,
    required this.creditId,
    this.cobradorId,
    required this.amount,
    this.paymentType,
    this.status = 'completed',
    required this.paymentDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Pago.fromJson(Map<String, dynamic> json) {
    return Pago(
      id: json['id'] ?? 0,
      creditId: json['credit_id'] ?? 0,
      cobradorId: json['cobrador_id'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentType: json['payment_type'],
      status: json['status'] ?? 'completed',
      paymentDate:
          DateTime.tryParse(json['payment_date'] ?? '') ?? DateTime.now(),
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'credit_id': creditId,
      'cobrador_id': cobradorId,
      'amount': amount,
      'payment_type': paymentType,
      'status': status,
      'payment_date': paymentDate.toIso8601String().split('T')[0],
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

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

// Análisis de pago
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

// Estado del crédito después de un pago
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

// Cuota del cronograma de pagos
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
