/// Modelo específico para el reporte de balances de caja
/// Esta estructura mapea exactamente lo que devuelve el endpoint /api/reports/balances

class BalancesReport {
  final List<BalanceReportItem> items;
  final BalancesReportSummary summary;
  final String generatedAt;
  final String generatedBy;

  BalancesReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory BalancesReport.fromJson(Map<String, dynamic> json) {
    return BalancesReport(
      items: _parseItems(json['items']),
      summary: BalancesReportSummary.fromJson(json['summary'] ?? {}),
      generatedAt: json['generated_at'] ?? '',
      generatedBy: json['generated_by'] ?? '',
    );
  }

  static List<BalanceReportItem> _parseItems(dynamic itemsList) {
    if (itemsList is List) {
      return itemsList
          .map((item) => BalanceReportItem.fromJson(item as Map<String, dynamic>))
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

class BalanceReportItem {
  final int id;
  final int cobradorId;
  final String cobradorName;
  final String date;
  final String dateFormatted;
  final double initialAmount;
  final String initialAmountFormatted;
  final double finalAmount;
  final String finalAmountFormatted;
  final double paymentsTotal;
  final String paymentsTotalFormatted;
  final double expensesTotal;
  final String expensesTotalFormatted;
  final double discrepancy;
  final String discrepancyFormatted;
  final String status; // 'open', 'closed', 'reconciled'
  final String createdAt;
  final String createdAtFormatted;
  final String? closedAt;
  final String? closedAtFormatted;

  BalanceReportItem({
    required this.id,
    required this.cobradorId,
    required this.cobradorName,
    required this.date,
    required this.dateFormatted,
    required this.initialAmount,
    required this.initialAmountFormatted,
    required this.finalAmount,
    required this.finalAmountFormatted,
    required this.paymentsTotal,
    required this.paymentsTotalFormatted,
    required this.expensesTotal,
    required this.expensesTotalFormatted,
    required this.discrepancy,
    required this.discrepancyFormatted,
    required this.status,
    required this.createdAt,
    required this.createdAtFormatted,
    this.closedAt,
    this.closedAtFormatted,
  });

  factory BalanceReportItem.fromJson(Map<String, dynamic> json) {
    return BalanceReportItem(
      id: json['id'] as int? ?? 0,
      cobradorId: json['cobrador_id'] as int? ?? 0,
      cobradorName: json['cobrador_name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      dateFormatted: json['date_formatted'] as String? ?? '',
      initialAmount: _toDouble(json['initial_amount']),
      initialAmountFormatted: json['initial_amount_formatted'] as String? ?? '',
      finalAmount: _toDouble(json['final_amount']),
      finalAmountFormatted: json['final_amount_formatted'] as String? ?? '',
      paymentsTotal: _toDouble(json['payments_total']),
      paymentsTotalFormatted: json['payments_total_formatted'] as String? ?? '',
      expensesTotal: _toDouble(json['expenses_total']),
      expensesTotalFormatted: json['expenses_total_formatted'] as String? ?? '',
      discrepancy: _toDouble(json['discrepancy']),
      discrepancyFormatted: json['discrepancy_formatted'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      createdAtFormatted: json['created_at_formatted'] as String? ?? '',
      closedAt: json['closed_at'] as String?,
      closedAtFormatted: json['closed_at_formatted'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cobrador_id': cobradorId,
    'cobrador_name': cobradorName,
    'date': date,
    'date_formatted': dateFormatted,
    'initial_amount': initialAmount,
    'initial_amount_formatted': initialAmountFormatted,
    'final_amount': finalAmount,
    'final_amount_formatted': finalAmountFormatted,
    'payments_total': paymentsTotal,
    'payments_total_formatted': paymentsTotalFormatted,
    'expenses_total': expensesTotal,
    'expenses_total_formatted': expensesTotalFormatted,
    'discrepancy': discrepancy,
    'discrepancy_formatted': discrepancyFormatted,
    'status': status,
    'created_at': createdAt,
    'created_at_formatted': createdAtFormatted,
    'closed_at': closedAt,
    'closed_at_formatted': closedAtFormatted,
  };

  /// Indica si hay discrepancia en el balance
  bool get hasDiscrepancy => discrepancy.abs() > 0.01;

  /// Indica si el balance está cerrado
  bool get isClosed => status == 'closed' || status == 'reconciled';

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class BalancesReportSummary {
  final int totalBalances;
  final double totalInitialAmount;
  final String totalInitialAmountFormatted;
  final double totalFinalAmount;
  final String totalFinalAmountFormatted;
  final double totalPayments;
  final String totalPaymentsFormatted;
  final double totalExpenses;
  final String totalExpensesFormatted;
  final double totalDiscrepancy;
  final String totalDiscrepancyFormatted;
  final int openBalances;
  final int closedBalances;
  final int reconciledBalances;
  final int balancesWithDiscrepancy;

  BalancesReportSummary({
    required this.totalBalances,
    required this.totalInitialAmount,
    required this.totalInitialAmountFormatted,
    required this.totalFinalAmount,
    required this.totalFinalAmountFormatted,
    required this.totalPayments,
    required this.totalPaymentsFormatted,
    required this.totalExpenses,
    required this.totalExpensesFormatted,
    required this.totalDiscrepancy,
    required this.totalDiscrepancyFormatted,
    required this.openBalances,
    required this.closedBalances,
    required this.reconciledBalances,
    required this.balancesWithDiscrepancy,
  });

  factory BalancesReportSummary.fromJson(Map<String, dynamic> json) {
    return BalancesReportSummary(
      totalBalances: json['total_balances'] as int? ?? 0,
      totalInitialAmount: _toDouble(json['total_initial_amount']),
      totalInitialAmountFormatted: json['total_initial_amount_formatted'] as String? ?? '',
      totalFinalAmount: _toDouble(json['total_final_amount']),
      totalFinalAmountFormatted: json['total_final_amount_formatted'] as String? ?? '',
      totalPayments: _toDouble(json['total_payments']),
      totalPaymentsFormatted: json['total_payments_formatted'] as String? ?? '',
      totalExpenses: _toDouble(json['total_expenses']),
      totalExpensesFormatted: json['total_expenses_formatted'] as String? ?? '',
      totalDiscrepancy: _toDouble(json['total_discrepancy']),
      totalDiscrepancyFormatted: json['total_discrepancy_formatted'] as String? ?? '',
      openBalances: json['open_balances'] as int? ?? 0,
      closedBalances: json['closed_balances'] as int? ?? 0,
      reconciledBalances: json['reconciled_balances'] as int? ?? 0,
      balancesWithDiscrepancy: json['balances_with_discrepancy'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'total_balances': totalBalances,
    'total_initial_amount': totalInitialAmount,
    'total_initial_amount_formatted': totalInitialAmountFormatted,
    'total_final_amount': totalFinalAmount,
    'total_final_amount_formatted': totalFinalAmountFormatted,
    'total_payments': totalPayments,
    'total_payments_formatted': totalPaymentsFormatted,
    'total_expenses': totalExpenses,
    'total_expenses_formatted': totalExpensesFormatted,
    'total_discrepancy': totalDiscrepancy,
    'total_discrepancy_formatted': totalDiscrepancyFormatted,
    'open_balances': openBalances,
    'closed_balances': closedBalances,
    'reconciled_balances': reconciledBalances,
    'balances_with_discrepancy': balancesWithDiscrepancy,
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
