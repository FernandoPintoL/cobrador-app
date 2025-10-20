import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';

class UserStatsWidget extends ConsumerWidget {
  const UserStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final statistics = authState.statistics;

    // Valores por defecto
    String clientesValue = '--';
    String cobradoresValue = '--';
    String managersValue = '--';

    // Si hay estadísticas del login, usarlas
    if (statistics != null) {
      clientesValue = statistics.totalClientesAdmin?.toString() ?? '--';
      cobradoresValue = statistics.totalCobradoresAdmin?.toString() ?? '--';
      managersValue = statistics.totalManagers?.toString() ?? '--';
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(context, 'Clientes', clientesValue, Icons.people, Colors.blue),
        _buildStatCard(
          context,
          'Cobradores',
          cobradoresValue,
          Icons.person_pin,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Managers',
          managersValue,
          Icons.supervisor_account,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 9,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
