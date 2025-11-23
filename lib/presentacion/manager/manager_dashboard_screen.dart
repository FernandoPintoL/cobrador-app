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
import '../widgets/modern_stat_card.dart';
import '../widgets/modern_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/cash_balance_notification_badge.dart';

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
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Panel de Gestión Manager'),
        backgroundColor: RoleColors.managerPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Badge de notificaciones de cajas
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/cash-balance-notifications');
            },
            child: const CashBalanceNotificationBadge(),
          ),

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
      body: RefreshIndicator(
        onRefresh: () async {
          final authState = ref.read(authProvider);
          final usuario = authState.usuario;
          if (usuario != null) {
            final managerId = usuario.id.toString();
            await ref
                .read(managerProvider.notifier)
                .cargarEstadisticasManager(managerId);
            await ref
                .read(managerProvider.notifier)
                .cargarCobradoresAsignados(managerId);
          }
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modern Header with glassmorphism
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [
                            RoleColors.managerPrimary.withValues(alpha: 0.15),
                            RoleColors.managerPrimary.withValues(alpha: 0.05),
                          ]
                        : [
                            RoleColors.managerPrimary.withValues(alpha: 0.1),
                            RoleColors.managerPrimary.withValues(alpha: 0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: RoleColors.managerPrimary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RoleColors.managerPrimary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      // Profile Image with glow effect
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: RoleColors.managerPrimary
                                  .withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ProfileImageWithUpload(
                          profileImage: usuario?.profileImage,
                          size: 70,
                          isUploading: profileImageState.isUploading,
                          uploadError: profileImageState.error,
                          onImageSelected: (File imageFile) {
                            ref
                                .read(profileImageProvider.notifier)
                                .uploadProfileImage(imageFile);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario?.nombre ?? 'Manager',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              usuario?.email ?? '',
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    RoleColors.managerPrimary
                                        .withValues(alpha: 0.3),
                                    RoleColors.managerPrimary
                                        .withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: RoleColors.managerPrimary
                                      .withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.manage_accounts,
                                    color: RoleColors.managerPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Manager',
                                    style: TextStyle(
                                      color: RoleColors.managerPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
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

              const SizedBox(height: 32),

              // Section Header for Statistics
              SectionHeader(
                title: 'Mis estadísticas',
                subtitle: 'Resumen de tu equipo',
                icon: Icons.bar_chart_rounded,
                color: RoleColors.managerPrimary,
              ),

              const SizedBox(height: 16),

              // Modern Statistics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = 16.0;
                  final itemWidth = (constraints.maxWidth - spacing) / 2;
                  final isLoading = managerState.estadisticas == null;

                  if (isLoading) {
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(
                        3,
                        (_) => SizedBox(
                          width: itemWidth,
                          height: 160,
                          child: const ModernStatCardSkeleton(),
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        height: 160,
                        child: ModernStatCard(
                          title: 'Cobradores Activos',
                          value:
                              '${managerState.estadisticas?['total_cobradores'] ?? 0}',
                          icon: Icons.person_pin,
                          color: Colors.blue,
                          onTap: () => _navigateToCollectorManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 160,
                        child: ModernStatCard(
                          title: 'Clientes Asignados',
                          value:
                              '${managerState.estadisticas?['total_clientes'] ?? 0}',
                          icon: Icons.business,
                          color: Colors.green,
                          onTap: () => _navigateToTeamClientManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 160,
                        child: ModernStatCard(
                          title: 'Préstamos Activos',
                          value:
                              '${managerState.estadisticas?['creditos_activos'] ?? 0}',
                          icon: Icons.account_balance_wallet,
                          color: Colors.orange,
                          onTap: () => _navigateToCreditManagement(context),
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // Section Header for Actions
              SectionHeader(
                title: 'Funciones de Gestión',
                subtitle: 'Administra tu equipo',
                icon: Icons.dashboard_customize,
                color: RoleColors.managerPrimary,
              ),

              const SizedBox(height: 16),

              // Modern Action Cards
              ModernActionCard(
                title: 'Gestión de Créditos',
                description: 'Crear, aprobar y gestionar créditos del equipo',
                icon: Icons.credit_card,
                color: Colors.teal,
                onTap: () => _navigateToCreditManagement(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Gestión de Cobradores',
                description: 'Crear, editar y asignar cobradores',
                icon: Icons.person_add,
                color: Colors.blue,
                onTap: () => _navigateToCollectorManagement(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Gestión de Clientes',
                description: 'Gestionar todos los clientes: directos y de cobradores',
                icon: Icons.business_center,
                color: Colors.green,
                onTap: () => _navigateToTeamClientManagement(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Mapa de Clientes',
                description: 'Ver clientes en el mapa por estado y cobrador',
                icon: Icons.map,
                color: Colors.indigo,
                onTap: () => _navigateToMap(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Reportes de Cobradores',
                description: 'Ver rendimiento y reportes',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () => _navigateToCollectorReports(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Cajas',
                description: 'Ver y gestionar cajas (abrir/cerrar, filtros)',
                icon: Icons.point_of_sale,
                color: Colors.orange,
                onTap: () => _navigateToCashBalances(context),
              ),
              const SizedBox(height: 20),
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
