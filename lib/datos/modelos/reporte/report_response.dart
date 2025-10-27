/// Modelo para la respuesta de un reporte
class ReportResponse {
  final String type; // Tipo de reporte: 'credits', 'balance', 'analysis', etc
  final String title;
  final String? description;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? metadata; // Información adicional: fecha generación, etc
  final DateTime generatedAt;

  ReportResponse({
    required this.type,
    required this.title,
    this.description,
    required this.data,
    this.metadata,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  ReportResponse copyWith({
    String? type,
    String? title,
    String? description,
    Map<String, dynamic>? data,
    Map<String, dynamic>? metadata,
    DateTime? generatedAt,
  }) {
    return ReportResponse(
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      data: data ?? this.data,
      metadata: metadata ?? this.metadata,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'metadata': metadata,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory ReportResponse.fromJson(Map<String, dynamic> json) {
    return ReportResponse(
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      data: json['data'] ?? {},
      metadata: json['metadata'],
      generatedAt: json['generatedAt'] != null
          ? DateTime.parse(json['generatedAt'])
          : DateTime.now(),
    );
  }
}
