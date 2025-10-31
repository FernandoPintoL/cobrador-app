/// Modelo para opciones de filtros disponibles
class FilterOptions {
  final List<FrequencyOption> frequencies;
  final List<ClientCategoryOption> clientCategories;
  final List<CreditStatusOption> creditStatuses;
  final List<PaymentMethodOption> paymentMethods;

  const FilterOptions({
    required this.frequencies,
    required this.clientCategories,
    required this.creditStatuses,
    required this.paymentMethods,
  });

  factory FilterOptions.empty() {
    return const FilterOptions(
      frequencies: [],
      clientCategories: [],
      creditStatuses: [],
      paymentMethods: [],
    );
  }

  factory FilterOptions.fromJson(Map<String, dynamic> json) {
    return FilterOptions(
      frequencies: (json['frequencies'] as List<dynamic>?)
              ?.map((e) => FrequencyOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      clientCategories: (json['client_categories'] as List<dynamic>?)
              ?.map((e) => ClientCategoryOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      creditStatuses: (json['credit_statuses'] as List<dynamic>?)
              ?.map((e) => CreditStatusOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentMethods: (json['payment_methods'] as List<dynamic>?)
              ?.map((e) => PaymentMethodOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequencies': frequencies.map((e) => e.toJson()).toList(),
      'client_categories': clientCategories.map((e) => e.toJson()).toList(),
      'credit_statuses': creditStatuses.map((e) => e.toJson()).toList(),
      'payment_methods': paymentMethods.map((e) => e.toJson()).toList(),
    };
  }
}

/// Opción de frecuencia de pago
class FrequencyOption {
  final String value;
  final String label;
  final String description;

  const FrequencyOption({
    required this.value,
    required this.label,
    required this.description,
  });

  factory FrequencyOption.fromJson(Map<String, dynamic> json) {
    return FrequencyOption(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
    };
  }
}

/// Opción de categoría de cliente
class ClientCategoryOption {
  final String category;
  final String label;
  final String description;
  final int totalClients;

  const ClientCategoryOption({
    required this.category,
    required this.label,
    required this.description,
    required this.totalClients,
  });

  factory ClientCategoryOption.fromJson(Map<String, dynamic> json) {
    return ClientCategoryOption(
      // El backend envía 'code' en lugar de 'category'
      category: json['code'] as String? ?? json['category'] as String,
      // El backend envía 'name' en lugar de 'label'
      label: json['name'] as String? ?? json['label'] as String,
      description: json['description'] as String? ?? '',
      totalClients: json['total_clients'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'label': label,
      'description': description,
      'total_clients': totalClients,
    };
  }
}

/// Opción de estado de crédito
class CreditStatusOption {
  final String value;
  final String label;
  final String description;

  const CreditStatusOption({
    required this.value,
    required this.label,
    required this.description,
  });

  factory CreditStatusOption.fromJson(Map<String, dynamic> json) {
    return CreditStatusOption(
      value: json['value'] as String,
      label: json['label'] as String,
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
      'description': description,
    };
  }
}

/// Opción de método de pago
class PaymentMethodOption {
  final String value;
  final String label;

  const PaymentMethodOption({
    required this.value,
    required this.label,
  });

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) {
    return PaymentMethodOption(
      value: json['value'] as String,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}
