class WaitingListSummary {
  final int pendingApproval;
  final int waitingDelivery;
  final int readyToday;
  final int overdueDelivery;
  final double totalAmountPendingApproval;
  final double totalAmountWaitingDelivery;

  WaitingListSummary({
    required this.pendingApproval,
    required this.waitingDelivery,
    required this.readyToday,
    required this.overdueDelivery,
    required this.totalAmountPendingApproval,
    required this.totalAmountWaitingDelivery,
  });

  factory WaitingListSummary.fromJson(Map<String, dynamic> json) {
    return WaitingListSummary(
      pendingApproval: json['pending_approval'] ?? 0,
      waitingDelivery: json['waiting_delivery'] ?? 0,
      readyToday: json['ready_today'] ?? 0,
      overdueDelivery: json['overdue_delivery'] ?? 0,
      totalAmountPendingApproval:
          double.tryParse(json['total_amount_pending_approval'].toString()) ??
          0.0,
      totalAmountWaitingDelivery:
          double.tryParse(json['total_amount_waiting_delivery'].toString()) ??
          0.0,
    );
  }

  int get totalCreditsInWaitingList => pendingApproval + waitingDelivery;
  double get totalAmountInWaitingList =>
      totalAmountPendingApproval + totalAmountWaitingDelivery;
}
