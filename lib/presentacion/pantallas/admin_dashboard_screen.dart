import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';
import 'user_management_screen.dart';
import 'cobrador_assignment_screen.dart';
import '../widgets/user_stats_widget.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        actions: [
          // Botón temporal para debug
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () => ref.read(authProvider.notifier).forceNewLogin(),
            tooltip: 'Limpiar sesión (Debug)',
          ),
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
                        usuario?.nombre.substring(0, 1).toUpperCase() ?? 'A',
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
                            usuario?.nombre ?? 'Administrador',
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
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Administrador',
                              style: TextStyle(
                                color: Colors.red,
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

            // Estadísticas generales
            const Text(
              'Estadísticas del Sistema',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const UserStatsWidget(),
            const SizedBox(height: 32),

            // Funciones administrativas
            const Text(
              'Funciones Administrativas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildAdminFunctionCard(
                  context,
                  'Gestión de Usuarios',
                  'Crear, editar y gestionar todos los usuarios del sistema',
                  Icons.people_alt,
                  Colors.blue,
                  () => _navigateToUserManagement(context),
                ),
                const SizedBox(height: 8),
                _buildAdminFunctionCard(
                  context,
                  'Asignaciones',
                  'Asignar clientes a cobradores',
                  Icons.person_add,
                  Colors.teal,
                  () => _navigateToCobradorAssignment(context),
                ),
                const SizedBox(height: 8), // Reducido de 12 a 8
                _buildAdminFunctionCard(
                  context,
                  'Gestión de Roles',
                  'Asignar y gestionar roles y permisos',
                  Icons.security,
                  Colors.green,
                  () => _navigateToRoleManagement(context),
                ),
                const SizedBox(height: 8), // Reducido de 12 a 8
                _buildAdminFunctionCard(
                  context,
                  'Configuración del Sistema',
                  'Configurar parámetros generales del sistema',
                  Icons.settings,
                  Colors.orange,
                  () => _navigateToSystemSettings(context),
                ),
                const SizedBox(height: 8), // Reducido de 12 a 8
                _buildAdminFunctionCard(
                  context,
                  'Reportes y Analytics',
                  'Ver reportes detallados y estadísticas',
                  Icons.analytics,
                  Colors.purple,
                  () => _navigateToReports(context),
                ),
                const SizedBox(height: 8), // Reducido de 12 a 8
                _buildAdminFunctionCard(
                  context,
                  'Soporte Técnico',
                  'Gestionar tickets de soporte y asistencia',
                  Icons.support_agent,
                  Colors.red,
                  () => _navigateToSupport(context),
                ),
                const SizedBox(height: 8), // Reducido de 12 a 8
                _buildAdminFunctionCard(
                  context,
                  'Logs del Sistema',
                  'Ver logs de actividad y auditoría',
                  Icons.history,
                  Colors.grey,
                  () => _navigateToSystemLogs(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminFunctionCard(
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
          padding: const EdgeInsets.all(10.0), // Reducido de 12 a 10
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Reducido de 10 a 8
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 18,
                ), // Reducido de 20 a 18
              ),
              const SizedBox(width: 10), // Reducido de 12 a 10
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize:
                      MainAxisSize.min, // Añadido para evitar overflow
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13, // Reducido de 14 a 13
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1), // Reducido de 2 a 1
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ), // Reducido de 11 a 10
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 12,
              ), // Reducido de 14 a 12
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUserManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UserManagementScreen()),
    );
  }

  void _navigateToCobradorAssignment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CobradorAssignmentScreen()),
    );
  }

  void _navigateToRoleManagement(BuildContext context) {
    // TODO: Implementar navegación a gestión de roles
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestión de roles - En desarrollo')),
    );
  }

  void _navigateToSystemSettings(BuildContext context) {
    // TODO: Implementar navegación a configuración del sistema
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración del sistema - En desarrollo'),
      ),
    );
  }

  void _navigateToReports(BuildContext context) {
    // TODO: Implementar navegación a reportes
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reportes - En desarrollo')));
  }

  void _navigateToSupport(BuildContext context) {
    // TODO: Implementar navegación a soporte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Soporte técnico - En desarrollo')),
    );
  }

  void _navigateToSystemLogs(BuildContext context) {
    // TODO: Implementar navegación a logs del sistema
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs del sistema - En desarrollo')),
    );
  }
}
