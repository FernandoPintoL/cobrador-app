import 'package:flutter/material.dart';

/// Modelo específico para el reporte de créditos en mora
/// Esta estructura mapea exactamente lo que devuelve el endpoint /api/reports/overdue

class OverdueReport {
  final List<OverdueReportItem> items;
  final OverdueReportSummary summary;
  final String generatedAt;
  final String generatedBy;

  OverdueReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory OverdueReport.fromJson(Map<String, dynamic> json) {
    return OverdueReport(
      items: _parseItems(json['items']),
      summary: OverdueReportSummary.fromJson(json['summary'] ?? {}),
      generatedAt: json['generated_at'] ?? '',
      generatedBy: json['generated_by'] ?? '',
    );
  }

  static List<OverdueReportItem> _parseItems(dynamic itemsList) {
    if (itemsList is List) {
      return itemsList
          .map((item) => OverdueReportItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'summary': summary.toJson(),
    'generated_at': generatedAt,
    'generated_by': generatedBy,
  };
}

class OverdueReportItem {
  final int id;
  final int clientId;
  final String clientName;
  final String? clientCategory;
  final String cobradorName;
  final double amount;
  final String amountFormatted;
  final double balance;
  final String balanceFormatted;
  final String? startDate;
  final String? startDateFormatted;
  final int daysOverdue;
  final double overdueAmount;
  final String overdueAmountFormatted;
  final int overdueInstallments;
  final double completionRate;
  final String severity; // 'light', 'moderate', 'severe'

  OverdueReportItem({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientCategory,
    required this.cobradorName,
    required this.amount,
    required this.amountFormatted,
    required this.balance,
    required this.balanceFormatted,
    this.startDate,
    this.startDateFormatted,
    required this.daysOverdue,
    required this.overdueAmount,
    required this.overdueAmountFormatted,
    required this.overdueInstallments,
    required this.completionRate,
    required this.severity,
  });

  factory OverdueReportItem.fromJson(Map<String, dynamic> json) {
    return OverdueReportItem(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      clientCategory: json['client_category'] as String?,
      cobradorName: json['cobrador_name'] as String? ?? '',
      amount: _toDouble(json['amount']),
      amountFormatted: json['amount_formatted'] as String? ?? '',
      balance: _toDouble(json['balance']),
      balanceFormatted: json['balance_formatted'] as String? ?? '',
      startDate: json['start_date'] as String?,
      startDateFormatted: json['start_date_formatted'] as String?,
      daysOverdue: json['days_overdue'] as int? ?? 0,
      overdueAmount: _toDouble(json['overdue_amount']),
      overdueAmountFormatted: json['overdue_amount_formatted'] as String? ?? '',
      overdueInstallments: json['overdue_installments'] as int? ?? 0,
      completionRate: _toDouble(json['completion_rate']),
      severity: json['severity'] as String? ?? 'light',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'client_name': clientName,
    'client_category': clientCategory,
    'cobrador_name': cobradorName,
    'amount': amount,
    'amount_formatted': amountFormatted,
    'balance': balance,
    'balance_formatted': balanceFormatted,
    'start_date': startDate,
    'start_date_formatted': startDateFormatted,
    'days_overdue': daysOverdue,
    'overdue_amount': overdueAmount,
    'overdue_amount_formatted': overdueAmountFormatted,
    'overdue_installments': overdueInstallments,
    'completion_rate': completionRate,
    'severity': severity,
  };

  /// Obtiene el número absoluto de días en mora
  int get absDaysOverdue => daysOverdue.abs();

  /// Etiqueta de severidad en español
  String get severityLabel {
    switch (severity) {
      case 'light':
        return 'Leve';
      case 'moderate':
        return 'Moderada';
      case 'severe':
        return 'Crítica';
      default:
        return 'Desconocido';
    }
  }

  /// Color según severidad
  Color get severityColor {
    switch (severity) {
      case 'light':
        return Colors.amber;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Color según categoría del cliente
  Color get categoryColor {
    switch (clientCategory?.toUpperCase()) {
      case 'A':
        return Colors.green; // Mejor categoría - Bajo riesgo
      case 'B':
        return Colors.blue; // Categoría intermedia - Riesgo medio
      case 'C':
        return Colors.deepOrange; // Categoría de mayor riesgo
      default:
        return Colors.grey; // Sin categoría
    }
  }

  /// Etiqueta de categoría
  String get categoryLabel {
    return clientCategory != null ? 'Cat. $clientCategory' : 'Sin Cat.';
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class OverdueReportSummary {
  final int totalCredits;
  final double totalOverdueAmount;
  final String totalOverdueAmountFormatted;
  final double totalBalance;
  final String totalBalanceFormatted;
  final int creditsLowOverdue;      // 1-7 días
  final int creditsMediumOverdue;   // 8-15 días
  final int creditsHighOverdue;     // 16-30 días
  final int creditsCriticalOverdue; // >30 días
  final double averageDaysOverdue;
  final int totalInstallmentsOverdue;

  OverdueReportSummary({
    required this.totalCredits,
    required this.totalOverdueAmount,
    required this.totalOverdueAmountFormatted,
    required this.totalBalance,
    required this.totalBalanceFormatted,
    required this.creditsLowOverdue,
    required this.creditsMediumOverdue,
    required this.creditsHighOverdue,
    required this.creditsCriticalOverdue,
    required this.averageDaysOverdue,
    required this.totalInstallmentsOverdue,
  });

  factory OverdueReportSummary.fromJson(Map<String, dynamic> json) {
    return OverdueReportSummary(
      totalCredits: json['total_credits'] as int? ?? 0,
      totalOverdueAmount: _toDouble(json['total_overdue_amount']),
      totalOverdueAmountFormatted: json['total_overdue_amount_formatted'] as String? ?? '',
      totalBalance: _toDouble(json['total_balance']),
      totalBalanceFormatted: json['total_balance_formatted'] as String? ?? '',
      creditsLowOverdue: json['credits_low_overdue'] as int? ?? 0,
      creditsMediumOverdue: json['credits_medium_overdue'] as int? ?? 0,
      creditsHighOverdue: json['credits_high_overdue'] as int? ?? 0,
      creditsCriticalOverdue: json['credits_critical_overdue'] as int? ?? 0,
      averageDaysOverdue: _toDouble(json['average_days_overdue']),
      totalInstallmentsOverdue: json['total_installments_overdue'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_credits': totalCredits,
    'total_overdue_amount': totalOverdueAmount,
    'total_overdue_amount_formatted': totalOverdueAmountFormatted,
    'total_balance': totalBalance,
    'total_balance_formatted': totalBalanceFormatted,
    'credits_low_overdue': creditsLowOverdue,
    'credits_medium_overdue': creditsMediumOverdue,
    'credits_high_overdue': creditsHighOverdue,
    'credits_critical_overdue': creditsCriticalOverdue,
    'average_days_overdue': averageDaysOverdue,
    'total_installments_overdue': totalInstallmentsOverdue,
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
