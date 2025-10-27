import 'package:flutter/material.dart';
import 'mini_stat_card.dart';

/// Configuración para una tarjeta de resumen estadístico
class SummaryCardConfig {
  /// Título mostrado en la tarjeta
  final String title;

  /// Clave para extraer el valor del mapa de summary
  /// Ej: 'total_payments', 'total_amount', etc.
  final String summaryKey;

  /// Icono a mostrar
  final IconData icon;

  /// Color de fondo
  final Color color;

  /// Función opcional para formatear el valor
  /// Si no se proporciona, se usa el valor tal cual
  final String Function(dynamic value)? formatter;

  const SummaryCardConfig({
    required this.title,
    required this.summaryKey,
    required this.icon,
    required this.color,
    this.formatter,
  });
}

/// Widget genérico para construir tarjetas de resumen a partir de una configuración
///
/// Elimina la duplicación de código en vistas como PaymentsReportView,
/// CreditsReportView y BalancesReportView.
///
/// Uso:
/// ```dart
/// SummaryCardsBuilder(
///   payload: payload,
///   cards: [
///     SummaryCardConfig(
///       title: 'Total Pagos',
///       summaryKey: 'total_payments',
///       icon: Icons.payments,
///       color: Colors.green,
///     ),
///     SummaryCardConfig(
///       title: 'Monto Total',
///       summaryKey: 'total_amount',
///       icon: Icons.attach_money,
///       color: Colors.blue,
///       formatter: ReportFormatters.formatCurrency,
///     ),
///   ],
/// )
/// ```
class SummaryCardsBuilder extends StatelessWidget {
  /// El payload del reporte que contiene el mapa 'summary'
  final dynamic payload;

  /// Lista de configuraciones para cada tarjeta
  final List<SummaryCardConfig> cards;

  /// Espaciado horizontal entre tarjetas
  final double spacing;

  /// Espaciado vertical entre filas de tarjetas
  final double runSpacing;

  const SummaryCardsBuilder({
    required this.payload,
    required this.cards,
    this.spacing = 12,
    this.runSpacing = 12,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Extraer el mapa de summary del payload
    final summary = (payload is Map) ? (payload['summary'] as Map?) : null;

    // Si no hay summary, mostrar un contenedor vacío
    if (summary == null) return const SizedBox.shrink();

    // Construir lista de tarjetas
    final cardWidgets = cards.map((config) {
      // Extraer el valor del summary usando la clave
      final value = summary[config.summaryKey] ?? 0;

      // Formatear el valor usando el formateador proporcionado
      final displayValue = config.formatter?.call(value) ?? value.toString();

      return MiniStatCard(
        title: config.title,
        value: displayValue,
        icon: config.icon,
        color: config.color,
      );
    }).toList();

    // Obtener ancho de pantalla para responsividad
    final screenWidth = MediaQuery.of(context).size.width;

    // Determinar número de columnas y aspect ratio basado en ancho de pantalla
    int crossAxisCount = 2;
    double childAspectRatio = 2.8;

    if (screenWidth > 1200) {
      // Desktop grande
      crossAxisCount = 4;
      childAspectRatio = 2.5;
    } else if (screenWidth > 900) {
      // Tablet/Desktop pequeño
      crossAxisCount = 3;
      childAspectRatio = 2.6;
    } else if (screenWidth > 600) {
      // Tablet
      crossAxisCount = 2;
      childAspectRatio = 2.8;
    } else {
      // Móvil
      crossAxisCount = 1;
      childAspectRatio = 3.5;
    }

    // Usar GridView para mostrar en columnas responsivas
    return GridView.count(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      mainAxisSpacing: runSpacing,
      crossAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cardWidgets,
    );
  }
}
