import 'package:flutter/material.dart';

/// Muestra la categoría del cliente (A, B, C) con un chip bonito y adaptable a modo oscuro
class ClientCategoryChip extends StatelessWidget {
  final String? category; // 'A' | 'B' | 'C' | null
  final bool compact; // si true, usa tamaño más pequeño
  final EdgeInsetsGeometry? padding;

  const ClientCategoryChip({
    super.key,
    this.category,
    this.compact = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final String cat = (category ?? 'B').toUpperCase();

    // Definir apariencia por categoría
    Color baseColor;
    String label;
    IconData icon;

    switch (cat) {
      case 'A':
        baseColor = Colors.green;
        label = 'VIP';
        icon = Icons.workspace_premium;
        break;
      case 'C':
        baseColor = Colors.red;
        label = 'Riesgo';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        baseColor = Colors.blueGrey;
        label = 'Normal';
        icon = Icons.person_outline;
    }

    final scheme = Theme.of(context).colorScheme;
    final bg = baseColor.withOpacity(0.12);
    final border = baseColor.withOpacity(0.35);
    final textColor = baseColor;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 12 : 14, color: textColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '$label ($cat)',
            style: TextStyle(
              color: textColor,
              fontSize: compact ? 10 : 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return Container(
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 6,
          ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: content,
    );
  }
}
