import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// Servicio para manejar y mostrar errores de API de forma amigable
class ErrorHandlerService {
  /// Muestra un SnackBar con el mensaje de error formateado
  static void showErrorSnackBar(BuildContext context, dynamic error, {String? title}) {
    final String errorMessage = formatErrorMessage(error);

    // Crear un SnackBar con estilo mejorado
    final snackBar = SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 4),
          Text(errorMessage),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(8),
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'CERRAR',
        textColor: Colors.white,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      ),
    );

    // Mostrar el SnackBar
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Muestra un diálogo con detalles completos del error
  static void showErrorDialog(BuildContext context, dynamic error, {String? title}) {
    final String formattedMessage = formatErrorMessage(error);
    final Map<String, dynamic> errorDetails = extractErrorDetails(error);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title ?? 'Error'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formattedMessage),
              const SizedBox(height: 16),
              if (errorDetails.isNotEmpty) ...[
                const Text(
                  'Detalles:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...errorDetails.entries.map((entry) => _buildErrorDetailItem(context, entry.key, entry.value)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ACEPTAR'),
          ),
        ],
      ),
    );
  }

  /// Construye un widget para mostrar un detalle de error
  static Widget _buildErrorDetailItem(BuildContext context, String field, dynamic value) {
    final formattedField = field.replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    // Usar el color del texto según el tema actual
    final textColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    if (value is List) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$formattedField:',
              style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
            ),
            ...value.map((item) => Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text('• $item', style: TextStyle(color: textColor)),
            )),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: RichText(
          text: TextSpan(
            text: '$formattedField: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
            children: [
              TextSpan(
                text: value.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Formatea el mensaje de error para mostrarlo al usuario
  static String formatErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response?.statusCode == 422) {
        return _formatValidationError(error.response?.data);
      } else if (error.response?.data != null && error.response?.data['message'] != null) {
        return error.response?.data['message'].toString() ?? 'Error desconocido';
      } else {
        return _getErrorMessageByStatusCode(error.response?.statusCode);
      }
    }

    return error.toString().replaceAll('Exception: ', '');
  }

  /// Formatea errores de validación (código 422)
  static String _formatValidationError(dynamic data) {
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    } else if (data is Map && data['errors'] is Map) {
      final errors = data['errors'] as Map;
      if (errors.isNotEmpty) {
        final firstErrorKey = errors.keys.first;
        final firstError = errors[firstErrorKey];

        // Formatear el nombre del campo para mejor legibilidad
        final formattedField = firstErrorKey.toString().replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : '')
            .join(' ');

        if (firstError is List && firstError.isNotEmpty) {
          return '$formattedField: ${firstError.first}';
        }
      }
    }

    return 'Error de validación';
  }

  /// Devuelve un mensaje amigable según el código de estado HTTP
  static String _getErrorMessageByStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud incorrecta';
      case 401:
        return 'No autorizado. Por favor inicie sesión de nuevo';
      case 403:
        return 'No tiene permisos para realizar esta acción';
      case 404:
        return 'Recurso no encontrado';
      case 422:
        return 'Los datos enviados son inválidos';
      case 429:
        return 'Demasiadas solicitudes. Intente más tarde';
      case 500:
        return 'Error interno del servidor';
      default:
        return 'Error de conexión (${statusCode ?? "desconocido"})';
    }
  }

  /// Extrae detalles de error para mostrarlos en el diálogo
  static Map<String, dynamic> extractErrorDetails(dynamic error) {
    if (error is DioException && error.response?.data is Map) {
      final data = error.response!.data as Map;
      final result = <String, dynamic>{};

      // Si hay un campo de errores de validación, lo incluimos
      if (data['errors'] is Map) {
        result.addAll(Map<String, dynamic>.from(data['errors'] as Map));
      }

      return result;
    }

    return {};
  }
}
