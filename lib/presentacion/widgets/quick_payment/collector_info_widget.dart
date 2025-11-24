import 'package:flutter/material.dart';
import '../../../datos/modelos/credito/pago.dart';
import '../../../datos/modelos/usuario.dart';

/// Widget que muestra información de los cobradores que recibieron pagos
class CollectorInfoWidget extends StatelessWidget {
  final List<Pago> payments;

  const CollectorInfoWidget({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context) {
    // Agrupar pagos por cobrador
    final collectorStats = _getCollectorStats();

    if (collectorStats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cobradores',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Mostrar estadísticas por cobrador
            ...collectorStats.entries.map((entry) {
              return _buildCollectorItem(
                entry.key,
                entry.value['count'] as int,
                entry.value['total'] as double,
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<Usuario, Map<String, dynamic>> _getCollectorStats() {
    final Map<BigInt, Map<String, dynamic>> tempStats = {};

    for (final payment in payments) {
      if (payment.cobrador == null) continue;

      final cobradorId = payment.cobrador!.id;

      if (!tempStats.containsKey(cobradorId)) {
        tempStats[cobradorId] = {
          'cobrador': payment.cobrador!,
          'count': 0,
          'total': 0.0,
        };
      }

      tempStats[cobradorId]!['count'] = (tempStats[cobradorId]!['count'] as int) + 1;
      tempStats[cobradorId]!['total'] =
          (tempStats[cobradorId]!['total'] as double) + payment.amount;
    }

    // Convertir a Map<Usuario, Map<String, dynamic>>
    final result = <Usuario, Map<String, dynamic>>{};
    for (final entry in tempStats.values) {
      final cobrador = entry['cobrador'] as Usuario;
      result[cobrador] = {
        'count': entry['count'],
        'total': entry['total'],
      };
    }

    return result;
  }

  Widget _buildCollectorItem(Usuario collector, int paymentCount, double totalAmount) {
    // Colores aleatorios basados en el ID para consistencia
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    final color = colors[collector.id.toInt() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Avatar del cobrador
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
            child: Center(
              child: Text(
                _getInitials(collector.nombre),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Información del cobrador
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collector.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.receipt, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$paymentCount ${paymentCount == 1 ? 'pago' : 'pagos'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.attach_money, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Bs ${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Porcentaje visual
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${((paymentCount / payments.length) * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }
}
