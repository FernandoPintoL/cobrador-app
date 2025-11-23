import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import 'user_management_screen.dart';
import 'cobrador_assignment_screen.dart';
import '../widgets/user_stats_widget.dart';
import '../pantallas/profile_settings_screen.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/cash_balance_notification_badge.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: RoleColors.adminPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Badge de notificaciones de cajas
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/cash-balance-notifications');
            },
            child: const CashBalanceNotificationBadge(),
          ),

          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Editar perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await showLogoutOptions(context: context, ref: ref);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información del usuario
            Container(
              decoration: BoxDecoration(
                gradient: RoleColors.getGradient('admin'),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white.withOpacity(0.2),
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
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            usuario?.email ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  RoleColors.getRoleIcon('admin'),
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Administrador',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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
            Text(
              'Estadísticas del Sistema',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            const UserStatsWidget(),
            const SizedBox(height: 32),

            // Funciones administrativas
            Text(
              'Funciones Administrativas',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Column(
              children: [
                _buildAdminFunctionCard(
                  context,
                  'Gestión de Usuarios',
                  'Crear y gestionar clientes, cobradores y managers',
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
                const SizedBox(height: 8),
                _buildAdminFunctionCard(
                  context,
                  'Asignaciones Manager-Cobrador',
                  'Gestionar asignaciones entre managers y cobradores',
                  Icons.account_tree,
                  Colors.purple,
                  () => _navigateToManagerAssignment(context),
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

                // Panel de notificaciones WebSocket (temporalmente deshabilitado)
                // const SizedBox(height: 24),
                // const RealtimeNotificationsPanel(),
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
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ), // Reducido de 11 a 10
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[500]
                    : Colors.grey[400],
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

  void _navigateToManagerAssignment(BuildContext context) {
    // TODO: Implementar navegación a asignaciones manager-cobrador
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Asignaciones Manager-Cobrador - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[600],
      ),
    );
  }

  void _navigateToRoleManagement(BuildContext context) {
    // TODO: Implementar navegación a gestión de roles
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Gestión de roles - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[600],
      ),
    );
  }

  void _navigateToSystemSettings(BuildContext context) {
    // TODO: Implementar navegación a configuración del sistema
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Configuración del sistema - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[600],
      ),
    );
  }

  void _navigateToReports(BuildContext context) {
    // TODO: Implementar navegación a reportes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reportes - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[600],
      ),
    );
  }

  void _navigateToSupport(BuildContext context) {
    // TODO: Implementar navegación a soporte
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Soporte técnico - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[600],
      ),
    );
  }

  void _navigateToSystemLogs(BuildContext context) {
    // TODO: Implementar navegación a logs del sistema
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logs del sistema - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[600],
      ),
    );
  }
}
