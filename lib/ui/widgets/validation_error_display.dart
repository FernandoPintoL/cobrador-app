import 'package:flutter/material.dart';

/// Widget para mostrar errores de validación
class ValidationErrorDisplay extends StatelessWidget {
  final Map<String, dynamic> errors;
  final EdgeInsets padding;
  final Color? backgroundColor;
  final Color? textColor;

  const ValidationErrorDisplay({
    Key? key,
    required this.errors,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final bgColor = backgroundColor ?? theme.colorScheme.error.withOpacity(0.1);
    final txtColor = textColor ?? theme.colorScheme.error;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: txtColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Por favor corrige los siguientes errores:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: txtColor,
                  ),
                  softWrap: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.entries.map((entry) {
            final fieldName = _formatFieldName(entry.key);
            final errorMessages = entry.value is List
                ? entry.value as List
                : [entry.value.toString()];

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fieldName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: txtColor,
                    ),
                  ),
                  ...errorMessages.map((msg) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '•',
                          style: TextStyle(color: txtColor),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            msg.toString(),
                            style: TextStyle(color: txtColor),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Formatea el nombre del campo para mostrarlo al usuario
  String _formatFieldName(String field) {
    // Convierte snake_case o camelCase a palabras con espacios y primera letra mayúscula
    final formatted = field
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim();

    return formatted.isNotEmpty
        ? '${formatted[0].toUpperCase()}${formatted.substring(1)}'
        : '';
  }
}
