import 'package:flutter/material.dart';

/// Handler centralizado para mostrar mensajes de error y éxito en la UI
///
/// Proporciona métodos estáticos para mostrar SnackBars consistentes
/// en toda la aplicación, evitando duplicación de código.
class ErrorHandler {
  /// Muestra un mensaje de error con estilo rojo
  ///
  /// [context]: BuildContext necesario para mostrar el SnackBar
  /// [message]: Mensaje de error a mostrar
  /// [duration]: Duración del SnackBar (default: 4 segundos)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!_isContextValid(context)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un mensaje de éxito con estilo verde
  ///
  /// [context]: BuildContext necesario para mostrar el SnackBar
  /// [message]: Mensaje de éxito a mostrar
  /// [duration]: Duración del SnackBar (default: 3 segundos)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!_isContextValid(context)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un mensaje de advertencia con estilo naranja
  ///
  /// [context]: BuildContext necesario para mostrar el SnackBar
  /// [message]: Mensaje de advertencia a mostrar
  /// [duration]: Duración del SnackBar (default: 4 segundos)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    if (!_isContextValid(context)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un mensaje informativo con estilo azul
  ///
  /// [context]: BuildContext necesario para mostrar el SnackBar
  /// [message]: Mensaje informativo a mostrar
  /// [duration]: Duración del SnackBar (default: 3 segundos)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!_isContextValid(context)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade700,
        behavior: SnackBarBehavior.floating,
        duration: duration,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Muestra un diálogo de error con opción de cerrar
  ///
  /// Útil para errores que requieren más atención del usuario
  static Future<void> showErrorDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    if (!_isContextValid(context)) return;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  /// Verifica si el contexto es válido antes de mostrar un SnackBar
  static bool _isContextValid(BuildContext context) {
    // Verificar que el context esté montado
    try {
      return context.mounted;
    } catch (_) {
      return false;
    }
  }
}
