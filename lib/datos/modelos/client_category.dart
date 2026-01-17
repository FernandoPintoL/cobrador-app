/// Modelo para representar una categoría de cliente con sus límites de crédito.
class ClientCategory {
  final int id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final int? minOverdueCount;
  final int? maxOverdueCount;
  // Campos de límite de crédito
  final double? maxAmount;
  final double? minAmount;
  final int? maxCredits;

  ClientCategory({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.isActive = true,
    this.minOverdueCount,
    this.maxOverdueCount,
    this.maxAmount,
    this.minAmount,
    this.maxCredits,
  });

  factory ClientCategory.fromJson(Map<String, dynamic> json) {
    return ClientCategory(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
      minOverdueCount: json['min_overdue_count'] is int
          ? json['min_overdue_count']
          : int.tryParse(json['min_overdue_count']?.toString() ?? ''),
      maxOverdueCount: json['max_overdue_count'] is int
          ? json['max_overdue_count']
          : int.tryParse(json['max_overdue_count']?.toString() ?? ''),
      maxAmount: _parseDouble(json['max_amount']),
      minAmount: _parseDouble(json['min_amount']),
      maxCredits: json['max_credits'] is int
          ? json['max_credits']
          : int.tryParse(json['max_credits']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'is_active': isActive,
      'min_overdue_count': minOverdueCount,
      'max_overdue_count': maxOverdueCount,
      'max_amount': maxAmount,
      'min_amount': minAmount,
      'max_credits': maxCredits,
    };
  }

  ClientCategory copyWith({
    int? id,
    String? code,
    String? name,
    String? description,
    bool? isActive,
    int? minOverdueCount,
    int? maxOverdueCount,
    double? maxAmount,
    double? minAmount,
    int? maxCredits,
  }) {
    return ClientCategory(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      minOverdueCount: minOverdueCount ?? this.minOverdueCount,
      maxOverdueCount: maxOverdueCount ?? this.maxOverdueCount,
      maxAmount: maxAmount ?? this.maxAmount,
      minAmount: minAmount ?? this.minAmount,
      maxCredits: maxCredits ?? this.maxCredits,
    );
  }

  /// Verifica si la categoría permite crear nuevos créditos
  bool get canCreateNewCredit => code.toUpperCase() != 'C';

  /// Obtiene el color asociado a la categoría
  int get colorValue {
    switch (code.toUpperCase()) {
      case 'A':
        return 0xFF4CAF50; // Verde
      case 'B':
        return 0xFF2196F3; // Azul
      case 'C':
        return 0xFFF44336; // Rojo
      default:
        return 0xFF9E9E9E; // Gris
    }
  }

  @override
  String toString() {
    return 'ClientCategory{code: $code, name: $name, maxAmount: $maxAmount, maxCredits: $maxCredits}';
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }
}

/// Modelo para los límites de crédito de un cliente
class ClientCreditLimits {
  final BigInt clientId;
  final String clientName;
  final String? clientCategory;
  final CategoryLimits? categoryLimits;
  final IndividualOverrides individualOverrides;
  final EffectiveLimits effectiveLimits;
  final bool hasCustomLimits;
  final int currentCredits;
  final int? availableCredits;

  ClientCreditLimits({
    required this.clientId,
    required this.clientName,
    this.clientCategory,
    this.categoryLimits,
    required this.individualOverrides,
    required this.effectiveLimits,
    required this.hasCustomLimits,
    required this.currentCredits,
    this.availableCredits,
  });

  factory ClientCreditLimits.fromJson(Map<String, dynamic> json) {
    return ClientCreditLimits(
      clientId: BigInt.from(json['client_id'] ?? 0),
      clientName: json['client_name']?.toString() ?? '',
      clientCategory: json['client_category']?.toString(),
      categoryLimits: json['category_limits'] != null
          ? CategoryLimits.fromJson(json['category_limits'])
          : null,
      individualOverrides: IndividualOverrides.fromJson(
        json['individual_overrides'] ?? {},
      ),
      effectiveLimits: EffectiveLimits.fromJson(
        json['effective_limits'] ?? {},
      ),
      hasCustomLimits: json['has_custom_limits'] == true,
      currentCredits: json['current_credits'] ?? 0,
      availableCredits: json['available_credits'],
    );
  }
}

class CategoryLimits {
  final double? maxAmount;
  final double? minAmount;
  final int? maxCredits;

  CategoryLimits({
    this.maxAmount,
    this.minAmount,
    this.maxCredits,
  });

  factory CategoryLimits.fromJson(Map<String, dynamic> json) {
    return CategoryLimits(
      maxAmount: _parseDouble(json['max_amount']),
      minAmount: _parseDouble(json['min_amount']),
      maxCredits: json['max_credits'] is int
          ? json['max_credits']
          : int.tryParse(json['max_credits']?.toString() ?? ''),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class IndividualOverrides {
  final double? creditLimitOverride;
  final int? maxCreditsOverride;

  IndividualOverrides({
    this.creditLimitOverride,
    this.maxCreditsOverride,
  });

  factory IndividualOverrides.fromJson(Map<String, dynamic> json) {
    return IndividualOverrides(
      creditLimitOverride: _parseDouble(json['credit_limit_override']),
      maxCreditsOverride: json['max_credits_override'] is int
          ? json['max_credits_override']
          : int.tryParse(json['max_credits_override']?.toString() ?? ''),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class EffectiveLimits {
  final double? maxAmount;
  final double minAmount;
  final int? maxCredits;

  EffectiveLimits({
    this.maxAmount,
    this.minAmount = 0,
    this.maxCredits,
  });

  factory EffectiveLimits.fromJson(Map<String, dynamic> json) {
    return EffectiveLimits(
      maxAmount: _parseDouble(json['max_amount']),
      minAmount: _parseDouble(json['min_amount']) ?? 0,
      maxCredits: json['max_credits'] is int
          ? json['max_credits']
          : int.tryParse(json['max_credits']?.toString() ?? ''),
    );
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
