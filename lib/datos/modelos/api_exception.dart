/// Excepción personalizada para errores de API
class ApiException implements Exception {
  /// Mensaje de error principal
  final String message;

  /// Código de estado HTTP (404, 422, 500, etc.)
  final int? statusCode;

  /// Datos completos de la respuesta de error
  final dynamic errorData;

  /// Error original (opcional)
  final dynamic originalError;

  ApiException({
    required this.message,
    this.statusCode,
    this.errorData,
    this.originalError,
  });

  /// Extrae mensajes de error de validación (para errores 422)
  Map<String, dynamic> get validationErrors {
    if (statusCode == 422 && errorData is Map<String, dynamic>) {
      final Map<String, dynamic> data = errorData;
      if (data.containsKey('errors') && data['errors'] is Map) {
        return Map<String, dynamic>.from(data['errors']);
      }
    }
    return {};
  }

  /// Verifica si hay errores de validación
  bool get hasValidationErrors => validationErrors.isNotEmpty;

  /// Obtiene un mensaje de error específico para un campo
  List<String> getFieldErrors(String fieldName) {
    final errors = validationErrors[fieldName];
    if (errors is List) {
      return errors.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  String toString() {
    if (statusCode != null) {
      return '$message (Código: $statusCode)';
    }
    return message;
  }
}
