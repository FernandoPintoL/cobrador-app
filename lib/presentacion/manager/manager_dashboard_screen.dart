import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/websocket_provider.dart';
import 'manager_cobradores_screen.dart';
import 'manager_clientes_screen.dart';
import 'manager_reportes_screen.dart';
import 'manager_notifications_screen.dart';
import 'manager_client_assignment_screen.dart';
import 'manager_credits_screen.dart';
import 'manager_direct_clients_screen.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> {
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  void _cargarDatosIniciales() {
    if (_hasLoadedInitialData) return;

    final authState = ref.read(authProvider);
    final usuario = authState.usuario;

    if (usuario != null) {
      _hasLoadedInitialData = true;
      final managerId = usuario.id.toString();
      ref.read(managerProvider.notifier).establecerManagerActual(usuario);
      ref.read(managerProvider.notifier).cargarEstadisticasManager(managerId);
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gestión Manager'),
        actions: [
          // Botón de notificaciones WebSocket
          Consumer(
            builder: (context, ref, child) {
              final wsState = ref.watch(webSocketProvider);
              final unreadCount = wsState.notifications
                  .where((n) => !(n['isRead'] ?? false))
                  .length;

              return IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text('$unreadCount') : null,
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManagerNotificationsScreen(),
                  ),
                ),
                tooltip: 'Notificaciones Manager',
              );
            },
          ),
          const SizedBox(width: 8),
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
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Manager',
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.orange[300]
                                    : Colors.orange,
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.1, // Ratio conservador para evitar overflow
              children: [
                _buildStatCard(
                  context,
                  'Cobradores Activos',
                  '${managerState.estadisticas?['total_cobradores'] ?? managerState.cobradoresAsignados.length}',
                  Icons.person_pin,
                  Colors.blue,
                ),
                _buildStatCard(
                  context,
                  'Clientes Asignados',
                  '${managerState.estadisticas?['total_clientes'] ?? 0}',
                  Icons.business,
                  Colors.green,
                ),
                _buildStatCard(
                  context,
                  'Préstamos Activos',
                  '${managerState.estadisticas?['total_creditos'] ?? 0}',
                  Icons.account_balance_wallet,
                  Colors.orange,
                ),
                _buildStatCard(
                  context,
                  'Cobros del Mes',
                  '\$${managerState.estadisticas?['cobros_mes'] ?? 0}',
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
                  'Gestión de Clientes del Equipo',
                  'Ver y gestionar clientes de todos los cobradores',
                  Icons.business_center,
                  Colors.green,
                  () => _navigateToTeamClientManagement(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Mis Clientes Directos',
                  'Gestionar clientes asignados directamente',
                  Icons.person_pin,
                  Colors.indigo,
                  () => _navigateToDirectClients(context),
                ),
                /* const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Crear Nuevo Cliente',
                  'Agregar cliente y asignar a cobrador',
                  Icons.person_add,
                  Colors.indigo,
                  () => _navigateToCreateClient(context),
                ), */
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
                  'Gestión de Créditos',
                  'Crear, aprobar y gestionar créditos del equipo',
                  Icons.credit_card,
                  Colors.teal,
                  () => _navigateToCreditManagement(context),
                ),
                /* const SizedBox(height: 12),
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
                ),*/
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
        padding: const EdgeInsets.all(8.0), // Reducido de 12 a 8
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize:
              MainAxisSize.min, // Importante: usar el mínimo espacio necesario
          children: [
            Icon(icon, size: 28, color: color), // Reducido de 32 a 28
            const SizedBox(height: 4), // Reducido de 6 a 4
            Flexible(
              // Permitir que el texto se adapte al espacio
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 18, // Reducido de 20 a 18
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(height: 2), // Reducido de 4 a 2
            Flexible(
              // Permitir que el título se adapte al espacio
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10, // Reducido de 11 a 10
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
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
          padding: const EdgeInsets.all(12.0), // Reducido de 16 a 12
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10), // Reducido de 12 a 10
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ), // Reducido de 24 a 20
              ),
              const SizedBox(width: 12), // Reducido de 16 a 12
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14, // Reducido de 16 a 14
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2), // Reducido de 4 a 2
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ), // Reducido de 12 a 11
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 14,
              ), // Reducido de 16 a 14
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCollectorManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManagerCobradoresScreen()),
    );
  }

  void _navigateToTeamClientManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManagerClientesScreen()),
    );
  }

  void _navigateToCreateClient(BuildContext context) {
    Navigator.pushNamed(context, '/crear-cliente');
  }

  void _navigateToRouteAssignment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManagerClientAssignmentScreen(),
      ),
    );
  }

  void _navigateToCollectorReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManagerReportesScreen()),
    );
  }

  void _navigateToCollectionControl(BuildContext context) {
    // TODO: Implementar navegación a control de cobros
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Control de cobros - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : null,
      ),
    );
  }

  void _navigateToZoneConfiguration(BuildContext context) {
    // TODO: Implementar navegación a configuración de zonas
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Configuración de zonas - En desarrollo'),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : null,
      ),
    );
  }

  void _navigateToCreditManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ManagerCreditsScreen()),
    );
  }

  void _navigateToDirectClients(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ManagerDirectClientsScreen(),
      ),
    );
  }
}
