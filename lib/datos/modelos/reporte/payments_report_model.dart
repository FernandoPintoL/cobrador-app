/// Modelo específico para el reporte de pagos
/// Esta estructura mapea exactamente lo que devuelve el endpoint /api/reports/payments

class PaymentsReport {
  final List<PaymentReportItem> items;
  final PaymentsReportSummary summary;
  final String generatedAt;
  final String generatedBy;

  PaymentsReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory PaymentsReport.fromJson(Map<String, dynamic> json) {
    return PaymentsReport(
      items: _parseItems(json['items']),
      summary: PaymentsReportSummary.fromJson(json['summary'] ?? {}),
      generatedAt: json['generated_at'] ?? '',
      generatedBy: json['generated_by'] ?? '',
    );
  }

  static List<PaymentReportItem> _parseItems(dynamic itemsList) {
    if (itemsList is List) {
      return itemsList
          .map((item) => PaymentReportItem.fromJson(item as Map<String, dynamic>))
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

class PaymentReportItem {
  final int id;
  final int creditId;
  final String clientName;
  final String cobradorName;
  final double amount;
  final String amountFormatted;
  final String paymentMethod;
  final String paymentMethodDisplay;
  final int installmentNumber;
  final String paymentDate;
  final String paymentDateFormatted;
  final String status;
  final String? transactionId;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String createdAtFormatted;

  PaymentReportItem({
    required this.id,
    required this.creditId,
    required this.clientName,
    required this.cobradorName,
    required this.amount,
    required this.amountFormatted,
    required this.paymentMethod,
    required this.paymentMethodDisplay,
    required this.installmentNumber,
    required this.paymentDate,
    required this.paymentDateFormatted,
    required this.status,
    this.transactionId,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.createdAtFormatted,
  });

  factory PaymentReportItem.fromJson(Map<String, dynamic> json) {
    return PaymentReportItem(
      id: json['id'] as int? ?? 0,
      creditId: json['credit_id'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      cobradorName: json['cobrador_name'] as String? ?? '',
      amount: _toDouble(json['amount']),
      amountFormatted: json['amount_formatted'] as String? ?? '',
      paymentMethod: json['payment_method'] as String? ?? '',
      paymentMethodDisplay: json['payment_method_display'] as String? ?? '',
      installmentNumber: json['installment_number'] as int? ?? 0,
      paymentDate: json['payment_date'] as String? ?? '',
      paymentDateFormatted: json['payment_date_formatted'] as String? ?? '',
      status: json['status'] as String? ?? '',
      transactionId: json['transaction_id'] as String?,
      latitude: _toDoubleOrNull(json['latitude']),
      longitude: _toDoubleOrNull(json['longitude']),
      createdAt: json['created_at'] as String? ?? '',
      createdAtFormatted: json['created_at_formatted'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'credit_id': creditId,
    'client_name': clientName,
    'cobrador_name': cobradorName,
    'amount': amount,
    'amount_formatted': amountFormatted,
    'payment_method': paymentMethod,
    'payment_method_display': paymentMethodDisplay,
    'installment_number': installmentNumber,
    'payment_date': paymentDate,
    'payment_date_formatted': paymentDateFormatted,
    'status': status,
    'transaction_id': transactionId,
    'latitude': latitude,
    'longitude': longitude,
    'created_at': createdAt,
    'created_at_formatted': createdAtFormatted,
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class PaymentsReportSummary {
  final int totalPayments;
  final double totalAmount;
  final String totalAmountFormatted;
  final double averageAmount;
  final String averageAmountFormatted;
  final Map<String, int>? byPaymentMethod;
  final Map<String, double>? amountByPaymentMethod;

  PaymentsReportSummary({
    required this.totalPayments,
    required this.totalAmount,
    required this.totalAmountFormatted,
    required this.averageAmount,
    required this.averageAmountFormatted,
    this.byPaymentMethod,
    this.amountByPaymentMethod,
  });

  factory PaymentsReportSummary.fromJson(Map<String, dynamic> json) {
    return PaymentsReportSummary(
      totalPayments: json['total_payments'] as int? ?? 0,
      totalAmount: _toDouble(json['total_amount']),
      totalAmountFormatted: json['total_amount_formatted'] as String? ?? '',
      averageAmount: _toDouble(json['average_amount']),
      averageAmountFormatted: json['average_amount_formatted'] as String? ?? '',
      byPaymentMethod: (json['by_payment_method'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, v as int),
      ),
      amountByPaymentMethod: (json['amount_by_payment_method'] as Map<String, dynamic>?)?.map(
        (k, v) => MapEntry(k, _toDouble(v)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_payments': totalPayments,
    'total_amount': totalAmount,
    'total_amount_formatted': totalAmountFormatted,
    'average_amount': averageAmount,
    'average_amount_formatted': averageAmountFormatted,
    'by_payment_method': byPaymentMethod,
    'amount_by_payment_method': amountByPaymentMethod,
  };

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
