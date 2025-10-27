import 'package:flutter/material.dart';

/// Widget para mostrar una tarjeta de estadística mini
class MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calcular un ancho responsivo para que quepan 2 cards por fila en móviles.
    // Suponemos ~16 px de padding a los lados y 8 px de separación entre cards
    // (coincide con los Wrap(spacing: 8) usados en esta pantalla).
    final screenW = MediaQuery.of(context).size.width;
    const sidePaddingGuess = 32.0; // 16 a cada lado
    const spacingBetween = 8.0; // Wrap spacing
    final twoColWidth = (screenW - sidePaddingGuess - spacingBetween) / 2;
    final cardWidth = twoColWidth.clamp(140.0, 220.0);

    return SizedBox(
      width: cardWidth,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.12),
                foregroundColor: color,
                child: Icon(icon, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (Theme.of(context).textTheme.labelLarge ??
                              const TextStyle())
                          .copyWith(color: Colors.grey[700], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      style:
                          (Theme.of(context).textTheme.titleLarge ??
                                  const TextStyle(fontSize: 18))
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
