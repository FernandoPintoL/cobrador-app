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
          padding: const EdgeInsets.all(12.0),  // 📱 Reducido de 16 a 12
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,  // 📱 Centra verticalmente
            children: [
              CircleAvatar(
                radius: 20,  // 📱 Reducido de 22 a 20
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                child: Icon(icon, size: 20),  // 📱 Reducido de 22 a 20
              ),
              const SizedBox(width: 12),  // 📱 Reducido de 14 a 12
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,  // 📱 Centra el contenido
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (Theme.of(context).textTheme.labelLarge ??
                              const TextStyle())
                          .copyWith(
                            color: Colors.grey[700],
                            fontSize: 12,  // 📱 Reducido de 14 a 12
                            height: 1.2,  // 📱 Controla el interlineado
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 2),  // 📱 Reducido de 4 a 2
                    Text(
                      value,
                      style:
                          (Theme.of(context).textTheme.titleLarge ??
                                  const TextStyle(fontSize: 18))
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,  // 📱 Reducido de 16 a 15
                                height: 1.2,  // 📱 Controla el interlineado
                              ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
