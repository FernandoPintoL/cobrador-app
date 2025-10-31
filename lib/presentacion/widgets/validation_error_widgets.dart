import 'package:flutter/material.dart';

/// Widget para mostrar errores de validación de forma amigable
class ValidationErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final List<String>? fieldErrors;

  const ValidationErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.fieldErrors,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fieldErrors != null && fieldErrors!.isNotEmpty) ...[
              Text(
                'Los siguientes campos tienen errores:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.red[900]?.withOpacity(0.2)
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red[800]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fieldErrors!
                      .map(
                        (error) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.circle,
                                size: 6,
                                color: Colors.red[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  error,
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Colors.red[300]
                                        : Colors.red[700],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ] else ...[
              Text(
                message,
                style: TextStyle(
                  height: 1.4,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[300]
                      : Colors.grey[700],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.blue[900]?.withOpacity(0.2)
                    : Colors.blue[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue[300]
                        : Colors.blue[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Corrige estos errores e intenta nuevamente.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue[300]
                            : Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Entendido',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.blue[300]
                  : Colors.blue[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  /// Método estático para mostrar el diálogo fácilmente
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    List<String>? fieldErrors,
  }) {
    showDialog(
      context: context,
      builder: (context) => ValidationErrorDialog(
        title: title,
        message: message,
        fieldErrors: fieldErrors,
      ),
    );
  }
}

/// Widget para mostrar errores en forma de SnackBar mejorado
class ValidationErrorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    List<String>? fieldErrors,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);

    // Limpiar SnackBars previos
    messenger.clearSnackBars();

    String displayMessage = message;
    if (fieldErrors != null && fieldErrors.isNotEmpty) {
      // Mostrar solo el primer error en el SnackBar para que no sea muy largo
      displayMessage = fieldErrors.first;

      // Si hay más errores, agregar indicador
      if (fieldErrors.length > 1) {
        displayMessage += ' (+${fieldErrors.length - 1} más)';
      }
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                displayMessage,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.red[800]
            : Colors.red[600],
        duration: duration ?? const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: fieldErrors != null && fieldErrors.length > 1
            ? SnackBarAction(
                label: 'Ver todo',
                textColor: Colors.white,
                onPressed: () {
                  ValidationErrorDialog.show(
                    context,
                    title: 'Errores de Validación',
                    message: message,
                    fieldErrors: fieldErrors,
                  );
                },
              )
            : null,
      ),
    );
  }
}
