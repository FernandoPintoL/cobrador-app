/// Modelos para estadísticas en tiempo real recibidas por WebSocket
/// Basados en la documentación oficial del backend

/// Estadísticas globales (Todos los usuarios)
class GlobalStats {
  final int totalClients;
  final int totalCobradores;
  final int totalManagers;
  final int totalCredits;
  final int totalPayments;
  final int overduePayments;
  final int pendingPayments;
  final double totalBalance;
  final double todayCollections;
  final double monthCollections;
  final DateTime updatedAt;

  const GlobalStats({
    required this.totalClients,
    required this.totalCobradores,
    required this.totalManagers,
    required this.totalCredits,
    required this.totalPayments,
    required this.overduePayments,
    required this.pendingPayments,
    required this.totalBalance,
    required this.todayCollections,
    required this.monthCollections,
    required this.updatedAt,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) {
    // Extraer el objeto stats si existe, o usar el json directamente
    final statsData = json['stats'] as Map<String, dynamic>? ?? json;

    return GlobalStats(
      totalClients: _parseInt(statsData['total_clients']) ?? 0,
      totalCobradores: _parseInt(statsData['total_cobradores']) ?? 0,
      totalManagers: _parseInt(statsData['total_managers']) ?? 0,
      totalCredits: _parseInt(statsData['total_credits']) ?? 0,
      totalPayments: _parseInt(statsData['total_payments']) ?? 0,
      overduePayments: _parseInt(statsData['overdue_payments']) ?? 0,
      pendingPayments: _parseInt(statsData['pending_payments']) ?? 0,
      totalBalance: _parseDouble(statsData['total_balance']) ?? 0.0,
      todayCollections: _parseDouble(statsData['today_collections']) ?? 0.0,
      monthCollections: _parseDouble(statsData['month_collections']) ?? 0.0,
      updatedAt: _parseDateTime(statsData['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_clients': totalClients,
      'total_cobradores': totalCobradores,
      'total_managers': totalManagers,
      'total_credits': totalCredits,
      'total_payments': totalPayments,
      'overdue_payments': overduePayments,
      'pending_payments': pendingPayments,
      'total_balance': totalBalance,
      'today_collections': todayCollections,
      'month_collections': monthCollections,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  GlobalStats copyWith({
    int? totalClients,
    int? totalCobradores,
    int? totalManagers,
    int? totalCredits,
    int? totalPayments,
    int? overduePayments,
    int? pendingPayments,
    double? totalBalance,
    double? todayCollections,
    double? monthCollections,
    DateTime? updatedAt,
  }) {
    return GlobalStats(
      totalClients: totalClients ?? this.totalClients,
      totalCobradores: totalCobradores ?? this.totalCobradores,
      totalManagers: totalManagers ?? this.totalManagers,
      totalCredits: totalCredits ?? this.totalCredits,
      totalPayments: totalPayments ?? this.totalPayments,
      overduePayments: overduePayments ?? this.overduePayments,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      totalBalance: totalBalance ?? this.totalBalance,
      todayCollections: todayCollections ?? this.todayCollections,
      monthCollections: monthCollections ?? this.monthCollections,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'GlobalStats(totalClients: $totalClients, totalCobradores: $totalCobradores, '
        'totalManagers: $totalManagers, totalCredits: $totalCredits, totalPayments: $totalPayments, '
        'overduePayments: $overduePayments, pendingPayments: $pendingPayments, '
        'totalBalance: $totalBalance, todayCollections: $todayCollections, '
        'monthCollections: $monthCollections, updatedAt: $updatedAt)';
  }
}

/// Estadísticas del cobrador (Solo el cobrador específico)
class CobradorStats {
  final int cobradorId;
  final int totalClients;
  final int totalCredits;
  final int totalPayments;
  final int overduePayments;
  final int pendingPayments;
  final double totalBalance;
  final double todayCollections;
  final double monthCollections;
  final DateTime updatedAt;

  const CobradorStats({
    required this.cobradorId,
    required this.totalClients,
    required this.totalCredits,
    required this.totalPayments,
    required this.overduePayments,
    required this.pendingPayments,
    required this.totalBalance,
    required this.todayCollections,
    required this.monthCollections,
    required this.updatedAt,
  });

  factory CobradorStats.fromJson(Map<String, dynamic> json) {
    // Extraer el objeto stats si existe, o usar el json directamente
    final statsData = json['stats'] as Map<String, dynamic>? ?? json;

    return CobradorStats(
      cobradorId: _parseInt(statsData['cobrador_id']) ?? 0,
      totalClients: _parseInt(statsData['total_clients']) ?? 0,
      totalCredits: _parseInt(statsData['total_credits']) ?? 0,
      totalPayments: _parseInt(statsData['total_payments']) ?? 0,
      overduePayments: _parseInt(statsData['overdue_payments']) ?? 0,
      pendingPayments: _parseInt(statsData['pending_payments']) ?? 0,
      totalBalance: _parseDouble(statsData['total_balance']) ?? 0.0,
      todayCollections: _parseDouble(statsData['today_collections']) ?? 0.0,
      monthCollections: _parseDouble(statsData['month_collections']) ?? 0.0,
      updatedAt: _parseDateTime(statsData['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cobrador_id': cobradorId,
      'total_clients': totalClients,
      'total_credits': totalCredits,
      'total_payments': totalPayments,
      'overdue_payments': overduePayments,
      'pending_payments': pendingPayments,
      'total_balance': totalBalance,
      'today_collections': todayCollections,
      'month_collections': monthCollections,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CobradorStats copyWith({
    int? cobradorId,
    int? totalClients,
    int? totalCredits,
    int? totalPayments,
    int? overduePayments,
    int? pendingPayments,
    double? totalBalance,
    double? todayCollections,
    double? monthCollections,
    DateTime? updatedAt,
  }) {
    return CobradorStats(
      cobradorId: cobradorId ?? this.cobradorId,
      totalClients: totalClients ?? this.totalClients,
      totalCredits: totalCredits ?? this.totalCredits,
      totalPayments: totalPayments ?? this.totalPayments,
      overduePayments: overduePayments ?? this.overduePayments,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      totalBalance: totalBalance ?? this.totalBalance,
      todayCollections: todayCollections ?? this.todayCollections,
      monthCollections: monthCollections ?? this.monthCollections,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'CobradorStats(cobradorId: $cobradorId, totalClients: $totalClients, '
        'totalCredits: $totalCredits, totalPayments: $totalPayments, '
        'overduePayments: $overduePayments, pendingPayments: $pendingPayments, '
        'totalBalance: $totalBalance, todayCollections: $todayCollections, '
        'monthCollections: $monthCollections, updatedAt: $updatedAt)';
  }
}

/// Estadísticas del manager (Solo el manager específico y su equipo)
class ManagerStats {
  final int managerId;
  final int totalCobradores;
  final int totalCredits;
  final int totalPayments;
  final int overduePayments;
  final int pendingPayments;
  final double totalBalance;
  final double todayCollections;
  final double monthCollections;
  final DateTime updatedAt;

  const ManagerStats({
    required this.managerId,
    required this.totalCobradores,
    required this.totalCredits,
    required this.totalPayments,
    required this.overduePayments,
    required this.pendingPayments,
    required this.totalBalance,
    required this.todayCollections,
    required this.monthCollections,
    required this.updatedAt,
  });

  factory ManagerStats.fromJson(Map<String, dynamic> json) {
    // Extraer el objeto stats si existe, o usar el json directamente
    final statsData = json['stats'] as Map<String, dynamic>? ?? json;

    return ManagerStats(
      managerId: _parseInt(statsData['manager_id']) ?? 0,
      totalCobradores: _parseInt(statsData['total_cobradores']) ?? 0,
      totalCredits: _parseInt(statsData['total_credits']) ?? 0,
      totalPayments: _parseInt(statsData['total_payments']) ?? 0,
      overduePayments: _parseInt(statsData['overdue_payments']) ?? 0,
      pendingPayments: _parseInt(statsData['pending_payments']) ?? 0,
      totalBalance: _parseDouble(statsData['total_balance']) ?? 0.0,
      todayCollections: _parseDouble(statsData['today_collections']) ?? 0.0,
      monthCollections: _parseDouble(statsData['month_collections']) ?? 0.0,
      updatedAt: _parseDateTime(statsData['updated_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'manager_id': managerId,
      'total_cobradores': totalCobradores,
      'total_credits': totalCredits,
      'total_payments': totalPayments,
      'overdue_payments': overduePayments,
      'pending_payments': pendingPayments,
      'total_balance': totalBalance,
      'today_collections': todayCollections,
      'month_collections': monthCollections,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ManagerStats copyWith({
    int? managerId,
    int? totalCobradores,
    int? totalCredits,
    int? totalPayments,
    int? overduePayments,
    int? pendingPayments,
    double? totalBalance,
    double? todayCollections,
    double? monthCollections,
    DateTime? updatedAt,
  }) {
    return ManagerStats(
      managerId: managerId ?? this.managerId,
      totalCobradores: totalCobradores ?? this.totalCobradores,
      totalCredits: totalCredits ?? this.totalCredits,
      totalPayments: totalPayments ?? this.totalPayments,
      overduePayments: overduePayments ?? this.overduePayments,
      pendingPayments: pendingPayments ?? this.pendingPayments,
      totalBalance: totalBalance ?? this.totalBalance,
      todayCollections: todayCollections ?? this.todayCollections,
      monthCollections: monthCollections ?? this.monthCollections,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ManagerStats(managerId: $managerId, totalCobradores: $totalCobradores, '
        'totalCredits: $totalCredits, totalPayments: $totalPayments, '
        'overduePayments: $overduePayments, pendingPayments: $pendingPayments, '
        'totalBalance: $totalBalance, todayCollections: $todayCollections, '
        'monthCollections: $monthCollections, updatedAt: $updatedAt)';
  }
}

// Funciones auxiliares privadas para parseo
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    try {
      return int.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    try {
      return double.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}
