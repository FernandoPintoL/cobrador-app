class DeliveryStatus {
  final String
  status; // 'pending_approval', 'waiting_delivery', 'ready_for_delivery', 'overdue_delivery', 'delivered'
  final bool isReadyForDelivery;
  final bool isOverdueForDelivery;
  final int daysUntilDelivery;
  final int daysOverdueForDelivery;
  final DateTime? scheduledDeliveryDate;
  final DateTime? deliveredAt;
  final String? deliveryNotes;
  final String? rejectionReason;

  DeliveryStatus({
    required this.status,
    required this.isReadyForDelivery,
    required this.isOverdueForDelivery,
    required this.daysUntilDelivery,
    required this.daysOverdueForDelivery,
    this.scheduledDeliveryDate,
    this.deliveredAt,
    this.deliveryNotes,
    this.rejectionReason,
  });

  factory DeliveryStatus.fromJson(Map<String, dynamic> json) {
    return DeliveryStatus(
      status: json['status'] ?? 'pending_approval',
      isReadyForDelivery: json['is_ready_for_delivery'] ?? false,
      isOverdueForDelivery: json['is_overdue_for_delivery'] ?? false,
      daysUntilDelivery: json['days_until_delivery'] ?? 0,
      daysOverdueForDelivery: json['days_overdue_for_delivery'] ?? 0,
      scheduledDeliveryDate: json['scheduled_delivery_date'] != null
          ? DateTime.tryParse(json['scheduled_delivery_date'])
          : null,
      deliveredAt: json['delivered_at'] != null
          ? DateTime.tryParse(json['delivered_at'])
          : null,
      deliveryNotes: json['delivery_notes'],
      rejectionReason: json['rejection_reason'],
    );
  }

  String get statusLabel {
    switch (status) {
      case 'pending_approval':
        return 'Pendiente de Aprobación';
      case 'waiting_delivery':
        return 'En Lista de Espera';
      case 'ready_for_delivery':
        return 'Listo para Entrega';
      case 'overdue_delivery':
        return 'Entrega Atrasada';
      case 'delivered':
        return 'Entregado';
      default:
        return status;
    }
  }
}
