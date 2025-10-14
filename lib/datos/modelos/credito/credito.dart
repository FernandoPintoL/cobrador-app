import '../../modelos/usuario.dart';
import 'pago.dart';

class Credito {
  final int id;
  final int clientId;
  final int? createdBy;
  final double amount; // Monto original
  final double balance; // Balance actual pendiente
  final double? interestRate; // Porcentaje de interés (ej: 20.00 para 20%)
  final double? totalAmount; // Monto total con interés incluido
  final double? installmentAmount; // Monto de cada cuota
  final String frequency; // 'daily', 'weekly', 'biweekly', 'monthly'
  final String
  status; // 'pending_approval', 'waiting_delivery', 'active', 'completed', 'defaulted', 'rejected', 'cancelled'
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  // (no agregar installmentNumber en Credito)

  // Nuevos campos para lista de espera
  final DateTime? scheduledDeliveryDate; // Fecha programada para entrega
  final int? approvedBy; // Usuario que aprobó el crédito
  final DateTime? approvedAt; // Fecha de aprobación
  final int? deliveredBy; // Usuario que entregó el crédito
  final DateTime? deliveredAt; // Fecha de entrega
  final String? deliveryNotes; // Notas del proceso de entrega
  final String? rejectionReason; // Motivo de rechazo

  // Campos de geolocalización
  final double? latitude; // Latitud donde se creó el crédito
  final double? longitude; // Longitud donde se creó el crédito

  // Campos de interés y pagos
  final int? interestRateId; // ID de la tasa de interés aplicada
  final bool? immediateDeliveryRequested; // Si se solicitó entrega inmediata
  final int? cashBalanceId; // ID del balance de caja relacionado

  // Campos de cuotas y mora del backend
  // Campos del backend (con nombres diferentes para evitar conflicto)
  final int?
  backendTotalInstallments; // Total de cuotas del crédito desde backend
  final double? totalPaid; // Monto total pagado
  final int? completedPaymentsCount; // Cuotas realmente pagadas
  final int?
  expectedInstallments; // Cuotas que debería tener pagadas a la fecha
  final int? backendPendingInstallments; // Cuotas pendientes desde backend
  final int? paidInstallmentsCount; // Cuotas pagadas según backend
  final bool? backendIsOverdue; // Si tiene cuotas atrasadas desde backend
  final double? overdueAmount; // Monto total atrasado

  // Relaciones
  final Usuario? client;
  final Usuario? cobrador;
  final Usuario? creator;
  final Usuario? approver; // Usuario que aprobó
  final Usuario? deliverer; // Usuario que entregó
  final List<Pago>? payments;

  Credito({
    required this.id,
    required this.clientId,
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
    required this.createdAt,
    required this.updatedAt,
    // Nuevos campos para lista de espera
    this.scheduledDeliveryDate,
    this.approvedBy,
    this.approvedAt,
    this.deliveredBy,
    this.deliveredAt,
    this.deliveryNotes,
    this.rejectionReason,
    // Campos de geolocalización
    this.latitude,
    this.longitude,
    // Campos de interés y pagos
    this.interestRateId,
    this.immediateDeliveryRequested,
    this.cashBalanceId,
    // Campos de cuotas y mora del backend
    this.backendTotalInstallments,
    this.totalPaid,
    this.completedPaymentsCount,
    this.expectedInstallments,
    this.backendPendingInstallments,
    this.paidInstallmentsCount,
    this.backendIsOverdue,
    this.overdueAmount,
    // Relaciones
    this.client,
    this.cobrador,
    this.creator,
    this.approver,
    this.deliverer,
    this.payments,
  });

  factory Credito.fromJson(Map<String, dynamic> json) {
    return Credito(
      id: json['id'] ?? 0,
      clientId: json['client_id'] ?? 0,
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
      status: json['status'] ?? 'pending_approval',
      startDate: DateTime.tryParse(json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['end_date'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      // Nuevos campos para lista de espera
      scheduledDeliveryDate: json['scheduled_delivery_date'] != null
          ? DateTime.tryParse(json['scheduled_delivery_date'])
          : null,
      approvedBy: json['approved_by'] is Map ? null : json['approved_by'],
      approvedAt: json['approved_at'] != null
          ? DateTime.tryParse(json['approved_at'])
          : null,
      deliveredBy: json['delivered_by'] is Map ? null : json['delivered_by'],
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      deliveryNotes: json['delivery_notes'],
      rejectionReason: json['rejection_reason'],
      // Campos de geolocalización
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      // Campos de interés y pagos
      interestRateId: json['interest_rate_id'],
      immediateDeliveryRequested: json['immediate_delivery_requested'],
      cashBalanceId: json['cash_balance_id'],
      // Campos del backend para cuotas y mora
      backendTotalInstallments:
          json['total_installments'] ?? json['expected_installments'],
      totalPaid: json['total_paid'] != null
          ? double.tryParse(json['total_paid'].toString())
          : null,
      completedPaymentsCount:
          json['completed_installments_count'] ??
          json['completed_payments_count'],
      expectedInstallments: json['expected_installments'],
      backendPendingInstallments: json['pending_installments'],
      paidInstallmentsCount: json['paid_installments'],
      backendIsOverdue: json['is_overdue'] == 1 || json['is_overdue'] == true,
      overdueAmount: json['overdue_amount'] != null
          ? double.tryParse(json['overdue_amount'].toString())
          : null,
      // Relaciones
      client: json['client'] != null ? Usuario.fromJson(json['client']) : null,
      cobrador: json['cobrador'] != null
          ? Usuario.fromJson(json['cobrador'])
          : null,
      creator: json['created_by'] != null && json['created_by'] is Map
          ? Usuario.fromJson(json['created_by'])
          : (json['creator'] != null
                ? Usuario.fromJson(json['creator'])
                : null),
      approver: json['approved_by'] != null && json['approved_by'] is Map
          ? Usuario.fromJson(json['approved_by'])
          : null,
      deliverer: json['delivered_by'] != null && json['delivered_by'] is Map
          ? Usuario.fromJson(json['delivered_by'])
          : null,
      payments: json['payments'] != null
          ? (json['payments'] as List).map((p) => Pago.fromJson(p)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'client_id': clientId,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // Nuevos campos para lista de espera
      'scheduled_delivery_date': scheduledDeliveryDate?.toIso8601String(),
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'delivered_by': deliveredBy,
      'delivered_at': deliveredAt?.toIso8601String(),
      'delivery_notes': deliveryNotes,
      'rejection_reason': rejectionReason,
      // Campos adicionales de ubicación y estadísticas
      'latitude': latitude,
      'longitude': longitude,
      'interest_rate_id': interestRateId,
      'immediate_delivery_requested': immediateDeliveryRequested,
      'cash_balance_id': cashBalanceId,
      'paid_installments_count': paidInstallmentsCount,
    };
  }

  // Métodos de utilidad
  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isDefaulted => status == 'defaulted';

  // Nuevos métodos para lista de espera
  bool get isPendingApproval => status == 'pending_approval';
  bool get isWaitingDelivery => status == 'waiting_delivery';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  // Estado de entrega
  bool get isReadyForDelivery {
    if (!isWaitingDelivery || scheduledDeliveryDate == null) return false;
    return DateTime.now().isAfter(scheduledDeliveryDate!) ||
        DateTime.now().isAtSameMomentAs(scheduledDeliveryDate!);
  }

  bool get isOverdueForDelivery {
    if (!isWaitingDelivery || scheduledDeliveryDate == null) return false;
    return DateTime.now().isAfter(
      scheduledDeliveryDate!.add(const Duration(days: 1)),
    );
  }

  int get daysUntilDelivery {
    if (scheduledDeliveryDate == null) return 0;
    return scheduledDeliveryDate!.difference(DateTime.now()).inDays;
  }

  int get daysOverdueForDelivery {
    if (!isOverdueForDelivery) return 0;
    return DateTime.now().difference(scheduledDeliveryDate!).inDays;
  }

  // Usar la lógica del backend si está disponible, sino calcular
  bool get isOverdue {
    // Si tenemos datos del backend, usarlos
    if (backendIsOverdue != null) return backendIsOverdue!;

    // Fallback al cálculo original
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
    // Usar datos del backend si están disponibles
    if (backendTotalInstallments != null) return backendTotalInstallments!;

    // Fallback al cálculo original
    final daysDiff = endDate.difference(startDate).inDays + 1;
    switch (frequency) {
      case 'daily':
        // 24 cuotas diarias (lunes a sábado), independientemente de los días calendario entre fechas
        return 24;
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
    // Usar datos del backend si están disponibles
    if (backendPendingInstallments != null) return backendPendingInstallments!;

    // Fallback al cálculo original
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
      case 'pending_approval':
        return 'Pendiente de Aprobación';
      case 'waiting_delivery':
        return 'En Lista de Espera';
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'defaulted':
        return 'En Mora';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
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
    // Nuevos campos para lista de espera
    DateTime? scheduledDeliveryDate,
    int? approvedBy,
    DateTime? approvedAt,
    int? deliveredBy,
    DateTime? deliveredAt,
    String? deliveryNotes,
    String? rejectionReason,
    // Relaciones
    Usuario? client,
    Usuario? cobrador,
    Usuario? creator,
    Usuario? approver,
    Usuario? deliverer,
    List<Pago>? payments,
  }) {
    return Credito(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      createdBy: createdBy ?? this.createdBy,
      amount: amount ?? this.amount,
      balance: balance ?? this.balance,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // Nuevos campos para lista de espera
      scheduledDeliveryDate:
          scheduledDeliveryDate ?? this.scheduledDeliveryDate,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      deliveredBy: deliveredBy ?? this.deliveredBy,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      // Relaciones
      client: client ?? this.client,
      cobrador: cobrador ?? this.cobrador,
      creator: creator ?? this.creator,
      approver: approver ?? this.approver,
      deliverer: deliverer ?? this.deliverer,
      payments: payments ?? this.payments,
    );
  }
}
