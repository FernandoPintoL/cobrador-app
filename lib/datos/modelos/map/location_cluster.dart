// Modelos para location clusters del nuevo endpoint unificado

class LocationCluster {
  final String clusterId;
  final ClusterLocation location;
  final ClusterSummary clusterSummary;
  final String clusterStatus; // 'paid', 'pending', 'overdue'
  final List<ClusterPerson> people;

  LocationCluster({
    required this.clusterId,
    required this.location,
    required this.clusterSummary,
    required this.clusterStatus,
    required this.people,
  });

  factory LocationCluster.fromJson(Map<String, dynamic> json) {
    return LocationCluster(
      clusterId: json['cluster_id'] ?? '',
      location: ClusterLocation.fromJson(json['location'] ?? {}),
      clusterSummary: ClusterSummary.fromJson(json['cluster_summary'] ?? {}),
      clusterStatus: json['cluster_status'] ?? 'pending',
      people: (json['people'] as List?)
          ?.map((p) => ClusterPerson.fromJson(p as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'cluster_id': clusterId,
        'location': location.toJson(),
        'cluster_summary': clusterSummary.toJson(),
        'cluster_status': clusterStatus,
        'people': people.map((p) => p.toJson()).toList(),
      };
}

class ClusterLocation {
  final double latitude;
  final double longitude;
  final String address;

  ClusterLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  factory ClusterLocation.fromJson(Map<String, dynamic> json) {
    return ClusterLocation(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };
}

class ClusterSummary {
  final int totalPeople;
  final int totalCredits;
  final double totalAmount;
  final double totalBalance;
  final int overdueCount;
  final double overdueAmount;
  final int activeCount;
  final double activeAmount;
  final int completedCount;
  final double completedAmount;

  ClusterSummary({
    required this.totalPeople,
    required this.totalCredits,
    required this.totalAmount,
    required this.totalBalance,
    required this.overdueCount,
    required this.overdueAmount,
    required this.activeCount,
    required this.activeAmount,
    required this.completedCount,
    required this.completedAmount,
  });

  factory ClusterSummary.fromJson(Map<String, dynamic> json) {
    return ClusterSummary(
      totalPeople: (json['total_people'] as num?)?.toInt() ?? 0,
      totalCredits: (json['total_credits'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      overdueCount: (json['overdue_count'] as num?)?.toInt() ?? 0,
      overdueAmount: (json['overdue_amount'] as num?)?.toDouble() ?? 0.0,
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
      activeAmount: (json['active_amount'] as num?)?.toDouble() ?? 0.0,
      completedCount: (json['completed_count'] as num?)?.toInt() ?? 0,
      completedAmount: (json['completed_amount'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_people': totalPeople,
        'total_credits': totalCredits,
        'total_amount': totalAmount,
        'total_balance': totalBalance,
        'overdue_count': overdueCount,
        'overdue_amount': overdueAmount,
        'active_count': activeCount,
        'active_amount': activeAmount,
        'completed_count': completedCount,
        'completed_amount': completedAmount,
      };
}

class ClusterPerson {
  final int personId;
  final String name;
  final String phone;
  final String? email;
  final String address;
  final String clientCategory;
  final int totalCredits;
  final double totalAmount;
  final double totalPaid;
  final double totalBalance;
  final String personStatus;
  final PaymentStats paymentStats;
  final List<ClusterCredit> credits;

  ClusterPerson({
    required this.personId,
    required this.name,
    required this.phone,
    this.email,
    required this.address,
    required this.clientCategory,
    required this.totalCredits,
    required this.totalAmount,
    required this.totalPaid,
    required this.totalBalance,
    required this.personStatus,
    required this.paymentStats,
    required this.credits,
  });

  factory ClusterPerson.fromJson(Map<String, dynamic> json) {
    return ClusterPerson(
      personId: (json['person_id'] as num?)?.toInt() ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] as String?,
      address: json['address'] ?? '',
      clientCategory: json['client_category'] ?? '',
      totalCredits: (json['total_credits'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0.0,
      personStatus: json['person_status'] ?? '',
      paymentStats:
          PaymentStats.fromJson(json['payment_stats'] as Map<String, dynamic>? ?? {}),
      credits: (json['credits'] as List?)
          ?.map((c) => ClusterCredit.fromJson(c as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'person_id': personId,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'client_category': clientCategory,
        'total_credits': totalCredits,
        'total_amount': totalAmount,
        'total_paid': totalPaid,
        'total_balance': totalBalance,
        'person_status': personStatus,
        'payment_stats': paymentStats.toJson(),
        'credits': credits.map((c) => c.toJson()).toList(),
      };
}

class PaymentStats {
  final int totalPayments;
  final int paidPayments;
  final int pendingPayments;
  final int overduePayments;
  final double totalPaidAmount;
  final double totalPendingAmount;
  final double totalOverdueAmount;
  final PaymentRecord? lastPayment;

  PaymentStats({
    required this.totalPayments,
    required this.paidPayments,
    required this.pendingPayments,
    required this.overduePayments,
    required this.totalPaidAmount,
    required this.totalPendingAmount,
    required this.totalOverdueAmount,
    this.lastPayment,
  });

  factory PaymentStats.fromJson(Map<String, dynamic> json) {
    return PaymentStats(
      totalPayments: (json['total_payments'] as num?)?.toInt() ?? 0,
      paidPayments: (json['paid_payments'] as num?)?.toInt() ?? 0,
      pendingPayments: (json['pending_payments'] as num?)?.toInt() ?? 0,
      overduePayments: (json['overdue_payments'] as num?)?.toInt() ?? 0,
      totalPaidAmount: (json['total_paid_amount'] as num?)?.toDouble() ?? 0.0,
      totalPendingAmount: (json['total_pending_amount'] as num?)?.toDouble() ?? 0.0,
      totalOverdueAmount: (json['total_overdue_amount'] as num?)?.toDouble() ?? 0.0,
      lastPayment: json['last_payment'] != null
          ? PaymentRecord.fromJson(json['last_payment'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_payments': totalPayments,
        'paid_payments': paidPayments,
        'pending_payments': pendingPayments,
        'overdue_payments': overduePayments,
        'total_paid_amount': totalPaidAmount,
        'total_pending_amount': totalPendingAmount,
        'total_overdue_amount': totalOverdueAmount,
        'last_payment': lastPayment?.toJson(),
      };
}

class PaymentRecord {
  final String date;
  final double amount;
  final String method;
  final String status;

  PaymentRecord({
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
  });

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      date: json['date'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      method: json['method'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'amount': amount,
        'method': method,
        'status': status,
      };
}

class ClusterCredit {
  final int creditId;
  final double amount;
  final double balance;
  final double paidAmount;
  final double paymentPercentage;
  final String status;
  final String startDate;
  final String endDate;
  final double daysUntilDue;
  final double overdueDays;
  final NextPaymentDue? nextPaymentDue;
  final PaymentRecord? lastPayment;
  final CreditPaymentStats paymentStats;
  final List<PaymentRecord> recentPayments;

  ClusterCredit({
    required this.creditId,
    required this.amount,
    required this.balance,
    required this.paidAmount,
    required this.paymentPercentage,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.daysUntilDue,
    required this.overdueDays,
    this.nextPaymentDue,
    this.lastPayment,
    required this.paymentStats,
    required this.recentPayments,
  });

  factory ClusterCredit.fromJson(Map<String, dynamic> json) {
    return ClusterCredit(
      creditId: (json['credit_id'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentPercentage: (json['payment_percentage'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? '',
      startDate: json['start_date'] ?? '',
      endDate: json['end_date'] ?? '',
      daysUntilDue: (json['days_until_due'] as num?)?.toDouble() ?? 0.0,
      overdueDays: (json['overdue_days'] as num?)?.toDouble() ?? 0.0,
      nextPaymentDue: json['next_payment_due'] != null
          ? NextPaymentDue.fromJson(json['next_payment_due'] as Map<String, dynamic>)
          : null,
      lastPayment: json['last_payment'] != null
          ? PaymentRecord.fromJson(json['last_payment'] as Map<String, dynamic>)
          : null,
      paymentStats: CreditPaymentStats.fromJson(
          json['payment_stats'] as Map<String, dynamic>? ?? {}),
      recentPayments: (json['recent_payments'] as List?)
          ?.map((p) => PaymentRecord.fromJson(p as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'credit_id': creditId,
        'amount': amount,
        'balance': balance,
        'paid_amount': paidAmount,
        'payment_percentage': paymentPercentage,
        'status': status,
        'start_date': startDate,
        'end_date': endDate,
        'days_until_due': daysUntilDue,
        'overdue_days': overdueDays,
        'next_payment_due': nextPaymentDue?.toJson(),
        'last_payment': lastPayment?.toJson(),
        'payment_stats': paymentStats.toJson(),
        'recent_payments': recentPayments.map((p) => p.toJson()).toList(),
      };
}

class NextPaymentDue {
  final String date;
  final double amount;
  final int installment;

  NextPaymentDue({
    required this.date,
    required this.amount,
    required this.installment,
  });

  factory NextPaymentDue.fromJson(Map<String, dynamic> json) {
    return NextPaymentDue(
      date: json['date'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      installment: (json['installment'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'amount': amount,
        'installment': installment,
      };
}

class CreditPaymentStats {
  final int totalPayments;
  final int paidPayments;
  final int pendingPayments;
  final int overduePayments;

  CreditPaymentStats({
    required this.totalPayments,
    required this.paidPayments,
    required this.pendingPayments,
    required this.overduePayments,
  });

  factory CreditPaymentStats.fromJson(Map<String, dynamic> json) {
    return CreditPaymentStats(
      totalPayments: (json['total_payments'] as num?)?.toInt() ?? 0,
      paidPayments: (json['paid_payments'] as num?)?.toInt() ?? 0,
      pendingPayments: (json['pending_payments'] as num?)?.toInt() ?? 0,
      overduePayments: (json['overdue_payments'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'total_payments': totalPayments,
        'paid_payments': paidPayments,
        'pending_payments': pendingPayments,
        'overdue_payments': overduePayments,
      };
}
