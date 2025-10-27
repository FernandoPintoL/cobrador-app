/// Modelo para representar un filtro de reporte
class ReportFilter {
  final String key;
  final String label;
  final String type; // 'date', 'select', 'text', 'number'
  final dynamic value;
  final List<String>? options; // Para filtros tipo 'select'
  final bool required;

  ReportFilter({
    required this.key,
    required this.label,
    required this.type,
    this.value,
    this.options,
    this.required = false,
  });

  ReportFilter copyWith({
    String? key,
    String? label,
    String? type,
    dynamic value,
    List<String>? options,
    bool? required,
  }) {
    return ReportFilter(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      value: value ?? this.value,
      options: options ?? this.options,
      required: required ?? this.required,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'label': label,
      'type': type,
      'value': value,
      'options': options,
      'required': required,
    };
  }

  factory ReportFilter.fromMap(Map<String, dynamic> map) {
    return ReportFilter(
      key: map['key'] ?? '',
      label: map['label'] ?? '',
      type: map['type'] ?? 'text',
      value: map['value'],
      options: List<String>.from(map['options'] ?? []),
      required: map['required'] ?? false,
    );
  }
}
