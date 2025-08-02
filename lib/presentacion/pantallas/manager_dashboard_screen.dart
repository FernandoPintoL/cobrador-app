import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gestión'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del usuario
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: Text(
                        usuario?.nombre.substring(0, 1).toUpperCase() ?? 'M',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario?.nombre ?? 'Manager',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            usuario?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Manager',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Estadísticas del equipo
            const Text(
              'Estadísticas del Equipo',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  context,
                  'Cobradores Activos',
                  '12',
                  Icons.person_pin,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Clientes Asignados',
                  '156',
                  Icons.business,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Préstamos Activos',
                  '89',
                  Icons.account_balance_wallet,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Cobros del Mes',
                  '\$45,230',
                  Icons.attach_money,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Funciones de gestión
            const Text(
              'Funciones de Gestión',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildManagerFunctionCard(
                  context,
                  'Gestión de Cobradores',
                  'Crear, editar y asignar cobradores',
                  Icons.person_add,
                  Colors.blue,
                  () => _navigateToCollectorManagement(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Gestión de Clientes',
                  'Crear y gestionar clientes',
                  Icons.business_center,
                  Colors.green,
                  () => _navigateToClientManagement(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Asignación de Rutas',
                  'Asignar rutas y territorios',
                  Icons.map,
                  Colors.orange,
                  () => _navigateToRouteAssignment(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Reportes de Cobradores',
                  'Ver rendimiento y reportes',
                  Icons.analytics,
                  Colors.purple,
                  () => _navigateToCollectorReports(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Control de Cobros',
                  'Monitorear y controlar cobros',
                  Icons.monetization_on,
                  Colors.red,
                  () => _navigateToCollectionControl(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Configuración de Zonas',
                  'Definir zonas de cobro',
                  Icons.location_on,
                  Colors.teal,
                  () => _navigateToZoneConfiguration(context),
                ),
              ],
            ),
          ],
        ),
      ),
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagerFunctionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCollectorManagement(BuildContext context) {
    // TODO: Implementar navegación a gestión de cobradores
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestión de cobradores - En desarrollo')),
    );
  }

  void _navigateToClientManagement(BuildContext context) {
    // TODO: Implementar navegación a gestión de clientes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestión de clientes - En desarrollo')),
    );
  }

  void _navigateToRouteAssignment(BuildContext context) {
    // TODO: Implementar navegación a asignación de rutas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Asignación de rutas - En desarrollo')),
    );
  }

  void _navigateToCollectorReports(BuildContext context) {
    // TODO: Implementar navegación a reportes de cobradores
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reportes de cobradores - En desarrollo')),
    );
  }

  void _navigateToCollectionControl(BuildContext context) {
    // TODO: Implementar navegación a control de cobros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Control de cobros - En desarrollo')),
    );
  }

  void _navigateToZoneConfiguration(BuildContext context) {
    // TODO: Implementar navegación a configuración de zonas
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración de zonas - En desarrollo')),
    );
  }
}
