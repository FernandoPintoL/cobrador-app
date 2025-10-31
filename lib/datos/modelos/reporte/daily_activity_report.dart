import '../credito/credito.dart' as credito_model;
import '../usuario.dart';

class DailyActivityReport {
  final List<DailyActivityItem> items;
  final DailyActivitySummary summary;
  final DateTime generatedAt;
  final String generatedBy;

  DailyActivityReport({
    required this.items,
    required this.summary,
    required this.generatedAt,
    required this.generatedBy,
  });

  factory DailyActivityReport.fromJson(Map<String, dynamic> json) {
    List<DailyActivityItem> parseItems(dynamic itemsList) {
      if (itemsList is List) {
        return itemsList
            .map((item) => DailyActivityItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    }

    return DailyActivityReport(
      items: parseItems(json['items']),
      summary: DailyActivitySummary.fromJson(json['summary'] ?? {}),
      generatedAt: DateTime.tryParse(json['generated_at'] ?? '') ?? DateTime.now(),
      generatedBy: json['generated_by'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'items': items.map((item) => item.toJson()).toList(),
    'summary': summary.toJson(),
    'generated_at': generatedAt.toIso8601String(),
    'generated_by': generatedBy,
  };
}

class DailyActivityItem {
  final int id;
  final int clientId;
  final int cobradorId;
  final int creditId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod; // 'cash', 'card', etc.
  final double? latitude;
  final double? longitude;
  final String status; // 'completed', 'pending', etc.
  final String? transactionId;
  final int installmentNumber;
  final int? receivedBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? cashBalanceId;
  final double? accumulatedAmount;

  final Usuario? cobrador;
  final credito_model.Credito? credit;

  DailyActivityItem({
    required this.id,
    required this.clientId,
    required this.cobradorId,
    required this.creditId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    this.latitude,
    this.longitude,
    required this.status,
    this.transactionId,
    required this.installmentNumber,
    this.receivedBy,
    required this.createdAt,
    required this.updatedAt,
    this.cashBalanceId,
    this.accumulatedAmount,
    this.cobrador,
    this.credit,
  });

  factory DailyActivityItem.fromJson(Map<String, dynamic> json) {
    double? tryDouble(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    int? tryInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    return DailyActivityItem(
      id: json['id'] ?? 0,
      clientId: json['client_id'] ?? 0,
      cobradorId: json['cobrador_id'] ?? 0,
      creditId: json['credit_id'] ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentDate:
          DateTime.tryParse(json['payment_date'] ?? '') ?? DateTime.now(),
      paymentMethod: json['payment_method'] ?? 'cash',
      latitude: tryDouble(json['latitude']),
      longitude: tryDouble(json['longitude']),
      status: json['status'] ?? 'completed',
      transactionId: json['transaction_id'],
      installmentNumber: json['installment_number'] ?? 0,
      receivedBy: tryInt(json['received_by']),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
      cashBalanceId: tryInt(json['cash_balance_id']),
      accumulatedAmount: tryDouble(json['accumulated_amount']),
      cobrador: json['cobrador'] is Map<String, dynamic>
          ? Usuario.fromJson(json['cobrador'])
          : null,
      credit: json['credit'] is Map<String, dynamic>
          ? credito_model.Credito.fromJson(json['credit'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'client_id': clientId,
    'cobrador_id': cobradorId,
    'credit_id': creditId,
    'amount': amount,
    'payment_date': paymentDate.toIso8601String(),
    'payment_method': paymentMethod,
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
    'transaction_id': transactionId,
    'installment_number': installmentNumber,
    'received_by': receivedBy,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'cash_balance_id': cashBalanceId,
    'accumulated_amount': accumulatedAmount,
  };

  String get clientName => credit?.client?.nombre ?? 'N/A';
  String get cobradorName => cobrador?.nombre ?? 'N/A';
  String get installmentText => 'Cuota $installmentNumber';
  String get paymentMethodDisplay => paymentMethod == 'cash' ? 'Efectivo' : paymentMethod == 'card' ? 'Tarjeta' : paymentMethod;
}

class DailyActivitySummary {
  final int totalPayments;
  final double totalAmount;
  final String totalAmountFormatted;
  final Map<String, CobradorSummary> byCobradores;

  DailyActivitySummary({
    required this.totalPayments,
    required this.totalAmount,
    required this.totalAmountFormatted,
    required this.byCobradores,
  });

  factory DailyActivitySummary.fromJson(Map<String, dynamic> json) {
    Map<String, CobradorSummary> parseByCobradores(dynamic byCobradorData) {
      if (byCobradorData is Map) {
        return byCobradorData.map(
          (key, value) => MapEntry(
            key.toString(),
            CobradorSummary.fromJson(value as Map<String, dynamic>),
          ),
        );
      }
      return {};
    }

    return DailyActivitySummary(
      totalPayments: json['total_payments'] ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      totalAmountFormatted: json['total_amount_formatted'] ?? 'Bs 0.00',
      byCobradores: parseByCobradores(json['by_cobrador']),
    );
  }

  Map<String, dynamic> toJson() => {
    'total_payments': totalPayments,
    'total_amount': totalAmount,
    'total_amount_formatted': totalAmountFormatted,
    'by_cobrador': byCobradores.map(
      (key, value) => MapEntry(key, value.toJson()),
    ),
  };
}

class CobradorSummary {
  final int count;
  final double amount;

  CobradorSummary({
    required this.count,
    required this.amount,
  });

  factory CobradorSummary.fromJson(Map<String, dynamic> json) {
    return CobradorSummary(
      count: json['count'] ?? 0,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'amount': amount,
  };
}
