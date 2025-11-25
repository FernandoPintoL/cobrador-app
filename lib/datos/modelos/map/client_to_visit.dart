/// Modelo para un cliente que debe ser visitado hoy
class ClientToVisit {
  final int personId;
  final String name;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final String clientCategory;
  final int priority; // 1 = urgente (vencido), 2 = hoy, 3 = próximo
  final bool hasOverdue;
  final double overdueAmount;
  final String? nextPaymentDate;
  final double nextPaymentAmount;
  final int? nextInstallment;
  final double totalBalance;

  ClientToVisit({
    required this.personId,
    required this.name,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.clientCategory,
    required this.priority,
    required this.hasOverdue,
    required this.overdueAmount,
    this.nextPaymentDate,
    required this.nextPaymentAmount,
    this.nextInstallment,
    required this.totalBalance,
  });

  factory ClientToVisit.fromJson(Map<String, dynamic> json) {
    return ClientToVisit(
      personId: json['person_id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      clientCategory: json['client_category'] as String? ?? 'A',
      priority: json['priority'] as int,
      hasOverdue: json['has_overdue'] as bool,
      overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0.0,
      nextPaymentDate: json['next_payment_date'] as String?,
      nextPaymentAmount: (json['next_payment_amount'] as num?)?.toDouble() ?? 0.0,
      nextInstallment: json['next_installment'] as int?,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'name': name,
        'phone': phone,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'client_category': clientCategory,
        'priority': priority,
        'has_overdue': hasOverdue,
        'overdue_amount': overdueAmount,
        'next_payment_date': nextPaymentDate,
        'next_payment_amount': nextPaymentAmount,
        'next_installment': nextInstallment,
        'total_balance': totalBalance,
      };

  /// Retorna el color según la prioridad
  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'URGENTE';
      case 2:
        return 'HOY';
      case 3:
        return 'PRÓXIMO';
      default:
        return 'NORMAL';
    }
  }

  /// Retorna emoji según prioridad
  String get priorityEmoji {
    switch (priority) {
      case 1:
        return '🔴';
      case 2:
        return '🟡';
      case 3:
        return '🟢';
      default:
        return '⚪';
    }
  }
}
