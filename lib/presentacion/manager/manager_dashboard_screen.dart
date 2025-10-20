import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../widgets/logout_dialog.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../config/role_colors.dart';
import '../creditos/credit_type_screen.dart';
import 'manager_cobradores_screen.dart';
import '../cliente/clientes_screen.dart'; // Pantalla genérica reutilizable
// import 'manager_reportes_screen.dart';
import '../reports/reports_screen.dart';
import '../map/map_screen.dart';
import '../pantallas/notifications_screen.dart';
// import 'manager_client_assignment_screen.dart'; // removed unused import
import '../pantallas/profile_settings_screen.dart';
import '../cajas/cash_balances_list_screen.dart';
import '../widgets/profile_image_widget.dart';

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

      // Si las estadísticas ya vienen del login, usarlas en el ManagerProvider
      if (authState.statistics != null) {
        print(
          '📊 Usando estadísticas del login (evitando petición al backend)',
        );
        ref
            .read(managerProvider.notifier)
            .establecerEstadisticas(authState.statistics!.toCompatibleMap());
      } else {
        print('⚠️ No hay estadísticas del login, cargando desde el backend');
        ref.read(managerProvider.notifier).cargarEstadisticasManager(managerId);
      }

      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final managerState = ref.watch(managerProvider);
    final profileImageState = ref.watch(profileImageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios en el estado de la imagen de perfil
    ref.listen<ProfileImageState>(profileImageProvider, (previous, next) {
      // Mostrar error solo cuando cambie
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: isDark ? Colors.red[800] : Colors.red,
          ),
        );
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: isDark ? Colors.green[800] : Colors.green,
          ),
        );
        ref.read(profileImageProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Gestión Manager'),
        backgroundColor: RoleColors.managerPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Botón de notificaciones WebSocket
          Consumer(
            builder: (context, ref, child) {
              final wsState = ref.watch(webSocketProvider);
              final unreadCount = wsState.notifications
                  .where((n) => !n.isRead)
                  .length;

              return IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text('$unreadCount') : null,
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
                tooltip: 'Notificaciones Manager',
              );
            },
          ),
          const SizedBox(width: 8),
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
              // Mostrar opciones: cancelar, salir, cerrar sesión completa
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Widget de imagen de perfil con funcionalidad de subida
                    ProfileImageWithUpload(
                      profileImage: usuario?.profileImage,
                      size: 60,
                      isUploading: profileImageState.isUploading,
                      uploadError: profileImageState.error,
                      onImageSelected: (File imageFile) {
                        ref
                            .read(profileImageProvider.notifier)
                            .uploadProfileImage(imageFile);
                      },
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
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.orange.withValues(alpha: 0.2)
                                  : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Manager',
                              style: TextStyle(
                                color: isDark
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
              'Mis estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 12.0;
                final itemWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        context,
                        'Cobradores Activos',
                        '${managerState.estadisticas?['total_cobradores'] ?? 0}',
                        Icons.person_pin,
                        Colors.blue,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        context,
                        'Clientes Asignados',
                        '${managerState.estadisticas?['total_clientes'] ?? 0}',
                        Icons.business,
                        Colors.green,
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        context,
                        'Préstamos Activos',
                        '${managerState.estadisticas?['creditos_activos'] ?? 0}',
                        Icons.account_balance_wallet,
                        Colors.orange,
                      ),
                    ),
                    /* SizedBox(
                      width: itemWidth,
                      child: _buildStatCard(
                        context,
                        'Saldo Total',
                        'Bs ${(managerState.estadisticas?['saldo_total_cartera'] ?? 0).toString()}',
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ), */
                  ],
                );
              },
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
                  'Gestión de Créditos',
                  'Crear, aprobar y gestionar créditos del equipo',
                  Icons.credit_card,
                  Colors.teal,
                  () => _navigateToCreditManagement(context),
                ),
                const SizedBox(height: 12),
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
                  'Gestionar todos los clientes: directos y de cobradores',
                  Icons.business_center,
                  Colors.green,
                  () => _navigateToTeamClientManagement(context),
                ),
                const SizedBox(height: 12),
                _buildManagerFunctionCard(
                  context,
                  'Mapa de Clientes',
                  'Ver clientes en el mapa por estado y cobrador',
                  Icons.map,
                  Colors.teal,
                  () => _navigateToMap(context),
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
                  'Cajas',
                  'Ver y gestionar cajas (abrir/cerrar, filtros)',
                  Icons.point_of_sale,
                  Colors.orange,
                  () => _navigateToCashBalances(context),
                ),
              ],
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

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
      MaterialPageRoute(
        builder: (context) => const ClientesScreen(userRole: 'manager'),
      ),
    );
  }

  void _navigateToCollectorReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsScreen(userRole: 'manager'),
      ),
    );
  }

  void _navigateToCreditManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreditTypeScreen()),
    );
  }

  void _navigateToCashBalances(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CashBalancesListScreen()),
    );
  }

  void _navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }
}
