/// Define la estructura de un tipo de reporte disponible
class ReportTypeDefinition {
  final String id;
  final String name;
  final String? description;
  final List<String> filters;
  final List<String> formats; // ['json', 'excel', 'pdf']
  final String? icon;
  final Map<String, dynamic>? metadata;

  ReportTypeDefinition({
    required this.id,
    required this.name,
    this.description,
    required this.filters,
    required this.formats,
    this.icon,
    this.metadata,
  });

  ReportTypeDefinition copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? filters,
    List<String>? formats,
    String? icon,
    Map<String, dynamic>? metadata,
  }) {
    return ReportTypeDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      filters: filters ?? this.filters,
      formats: formats ?? this.formats,
      icon: icon ?? this.icon,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'filters': filters,
      'formats': formats,
      'icon': icon,
      'metadata': metadata,
    };
  }

  factory ReportTypeDefinition.fromJson(Map<String, dynamic> json) {
    return ReportTypeDefinition(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      filters: List<String>.from(json['filters'] ?? []),
      formats: List<String>.from(json['formats'] ?? ['json']),
      icon: json['icon'],
      metadata: json['metadata'],
    );
  }
}
