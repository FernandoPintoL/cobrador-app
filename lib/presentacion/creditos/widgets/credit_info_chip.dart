import 'package:flutter/material.dart';

/// Widget que muestra información en formato chip (label + value)
/// Usado para mostrar información compacta en las tarjetas de crédito
class CreditInfoChip extends StatelessWidget {
  final String label;
  final String value;

  const CreditInfoChip({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                ]
              : [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 1,
            height: 12,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
                fontSize: 11,
                letterSpacing: -0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
