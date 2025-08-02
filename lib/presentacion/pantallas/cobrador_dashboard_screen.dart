import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';

class CobradorDashboardScreen extends ConsumerWidget {
  const CobradorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Cobrador'),
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
                        usuario?.nombre.substring(0, 1).toUpperCase() ?? 'C',
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
                            usuario?.nombre ?? 'Cobrador',
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
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Cobrador',
                              style: TextStyle(
                                color: Colors.green,
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

            // Estadísticas del cobrador
            const Text(
              'Mis Estadísticas',
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
                  'Clientes Asignados',
                  '23',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Préstamos Activos',
                  '45',
                  Icons.account_balance_wallet,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Cobros del Día',
                  '\$2,450',
                  Icons.attach_money,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Visitas Pendientes',
                  '8',
                  Icons.schedule,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Acciones rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildCobradorActionCard(
                  context,
                  'Gestionar Clientes',
                  'Ver y gestionar mis clientes asignados',
                  Icons.people_alt,
                  Colors.blue,
                  () => _navigateToClientManagement(context),
                ),
                const SizedBox(height: 12),
                _buildCobradorActionCard(
                  context,
                  'Gestionar Préstamos',
                  'Ver y gestionar préstamos de clientes',
                  Icons.account_balance_wallet,
                  Colors.green,
                  () => _navigateToLoanManagement(context),
                ),
                const SizedBox(height: 12),
                _buildCobradorActionCard(
                  context,
                  'Ruta del Día',
                  'Ver mi ruta de cobro para hoy',
                  Icons.map,
                  Colors.orange,
                  () => _navigateToDailyRoute(context),
                ),
                const SizedBox(height: 12),
                _buildCobradorActionCard(
                  context,
                  'Registrar Cobro',
                  'Registrar un nuevo cobro',
                  Icons.payment,
                  Colors.purple,
                  () => _navigateToRecordPayment(context),
                ),
                const SizedBox(height: 12),
                _buildCobradorActionCard(
                  context,
                  'Reportes',
                  'Ver mis reportes de cobro',
                  Icons.analytics,
                  Colors.teal,
                  () => _navigateToReports(context),
                ),
                const SizedBox(height: 12),
                _buildCobradorActionCard(
                  context,
                  'Configuración',
                  'Configurar mi perfil y preferencias',
                  Icons.settings,
                  Colors.grey,
                  () => _navigateToSettings(context),
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

  Widget _buildCobradorActionCard(
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

  void _navigateToClientManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ClientesScreen()),
    );
  }

  void _navigateToLoanManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrestamosScreen()),
    );
  }

  void _navigateToDailyRoute(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RutaDiariaScreen()),
    );
  }

  void _navigateToRecordPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistrarCobroScreen()),
    );
  }

  void _navigateToReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportesCobradorScreen()),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConfiguracionCobradorScreen(),
      ),
    );
  }
}

// Pantallas auxiliares que se implementarán
class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Clientes')),
      body: const Center(child: Text('Lista de clientes - En desarrollo')),
    );
  }
}

class PrestamosScreen extends StatelessWidget {
  const PrestamosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Préstamos')),
      body: const Center(child: Text('Gestión de préstamos - En desarrollo')),
    );
  }
}

class RutaDiariaScreen extends StatelessWidget {
  const RutaDiariaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ruta del Día')),
      body: const Center(child: Text('Ruta diaria - En desarrollo')),
    );
  }
}

class RegistrarCobroScreen extends StatelessWidget {
  const RegistrarCobroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Cobro')),
      body: const Center(child: Text('Registrar cobro - En desarrollo')),
    );
  }
}

class ReportesCobradorScreen extends StatelessWidget {
  const ReportesCobradorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Reportes')),
      body: const Center(child: Text('Reportes - En desarrollo')),
    );
  }
}

class ConfiguracionCobradorScreen extends StatelessWidget {
  const ConfiguracionCobradorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: const Center(child: Text('Configuración - En desarrollo')),
    );
  }
}
