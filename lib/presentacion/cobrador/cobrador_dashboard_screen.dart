import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../datos/modelos/credito/credit_stats.dart';
import '../../config/role_colors.dart';
import '../widgets/profile_image_widget.dart';
import '../pantallas/profile_settings_screen.dart';
import '../pantallas/notifications_screen.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/modern_stat_card.dart';
import '../widgets/modern_action_card.dart';
import '../widgets/section_header.dart';
import '../widgets/cash_balance_notification_badge.dart';
import '../cliente/clientes_screen.dart'; // Pantalla genérica reutilizable
import '../creditos/credit_type_screen.dart';
import '../reports/reports_screen.dart';
import '../map/map_screen.dart';
import '../cajas/cash_balances_list_screen.dart';
import 'daily_route_screen.dart';
import 'quick_payment_screen.dart';
import 'package:intl/intl.dart';

class CobradorDashboardScreen extends ConsumerStatefulWidget {
  const CobradorDashboardScreen({super.key});

  @override
  ConsumerState<CobradorDashboardScreen> createState() =>
      _CobradorDashboardScreenState();
}

class _CobradorDashboardScreenState
    extends ConsumerState<CobradorDashboardScreen> {
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales solo UNA VEZ
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  void _cargarDatosIniciales() {
    // Protección contra cargas duplicadas
    if (_hasLoadedInitialData) return;
    _hasLoadedInitialData = true;

    final authState = ref.read(authProvider);

    // ✅ OPTIMIZACIÓN: Usar estadísticas del login en lugar de hacer petición
    if (authState.statistics != null) {
      debugPrint(
        '✅ Usando estadísticas del login (evitando petición innecesaria)',
      );
      // Convertir las estadísticas del login al formato CreditStats
      final statsFromLogin = authState.statistics!;
      print("-------");
      print(statsFromLogin.toJson());
      final creditStats = CreditStats.fromDashboardStatistics(
        statsFromLogin.toJson(),
      );

      print(creditStats.activeCredits);

      // Establecer las estadísticas en el provider sin hacer petición
      ref.read(creditProvider.notifier).setStats(creditStats);
    } else {
      // Solo si NO vinieron estadísticas del login, cargar del backend
      debugPrint(
        '⚠️ No hay estadísticas del login, cargando desde el backend...',
      );
      ref.read(creditProvider.notifier).loadCobradorStats();
    }

    // ✅ Cargar créditos (esto sí es necesario para la lista)
    // ref.read(creditProvider.notifier).loadCredits();

    // ✅ Verificar si hay cajas pendientes de cierre
    _verificarCajasPendientes();
  }

  /// Verifica si el cobrador tiene cajas pendientes de cierre
  Future<void> _verificarCajasPendientes() async {
    final authState = ref.read(authProvider);
    if (authState.usuario == null) return;

    try {
      final resp = await ref
          .read(cashBalanceProvider.notifier)
          .getPendingClosures(cobradorId: authState.usuario!.id.toInt());

      if (!mounted) return;

      // Verificar si hay cajas pendientes
      final pendingBoxes = resp['data'];
      if (pendingBoxes is List && pendingBoxes.isNotEmpty) {
        // Mostrar diálogo con las cajas pendientes
        _mostrarDialogoCajasPendientes(pendingBoxes);
      }
    } catch (e) {
      // Si hay error al verificar, no mostrar nada (silencioso)
      debugPrint('Error verificando cajas pendientes: $e');
    }
  }

  /// Muestra un diálogo con las cajas pendientes de cierre
  void _mostrarDialogoCajasPendientes(dynamic pendingBoxesData) {
    if (!mounted) return;

    // Convertir a lista
    final List<dynamic> boxes = pendingBoxesData is List
        ? pendingBoxesData
        : [];

    if (boxes.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            const Expanded(child: Text('Cajas Pendientes')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tienes las siguientes cajas pendientes de cierre:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...boxes.map((box) {
                final id = box['id'];
                final date = box['date'];
                final amount = box['initial_amount'] ?? 0.0;

                // Formatear fecha
                String formattedDate = date?.toString() ?? 'Sin fecha';
                try {
                  if (date != null) {
                    final parsedDate = DateTime.parse(date.toString());
                    formattedDate = DateFormat('dd/MM/yyyy').format(parsedDate);
                  }
                } catch (e) {
                  formattedDate = date?.toString() ?? 'Sin fecha';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: Colors.orange[100],
                      child: Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: Colors.orange[700],
                      ),
                    ),
                    title: Text('Caja #$id'),
                    subtitle: Text('Fecha: $formattedDate'),
                    trailing: Text(
                      'Bs ${amount is num ? amount.toStringAsFixed(2) : amount}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
              Text(
                'Debes cerrar estas cajas antes de abrir una nueva.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToCashBalances(context);
            },
            child: const Text('Ver Cajas'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final profileImageState = ref.watch(profileImageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios en el estado de la imagen de perfil
    ref.listen<ProfileImageState>(profileImageProvider, (previous, next) {
      // Mostrar error solo cuando cambie
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.red[800]
                : Colors.red,
          ),
        );
        // No limpiar aquí para evitar bucles
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.green[800]
                : Colors.green,
          ),
        );
        ref.read(profileImageProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Paneles de Cobrador'),
        backgroundColor: RoleColors.cobradorPrimary,
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

          // Botón de notificaciones generales
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
                tooltip: 'Notificaciones',
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
              await showLogoutOptions(context: context, ref: ref);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                            RoleColors.cobradorPrimary.withValues(alpha: 0.15),
                            RoleColors.cobradorPrimary.withValues(alpha: 0.05),
                          ]
                        : [
                            RoleColors.cobradorPrimary.withValues(alpha: 0.1),
                            RoleColors.cobradorPrimary.withValues(alpha: 0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: RoleColors.cobradorPrimary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: RoleColors.cobradorPrimary.withValues(alpha: 0.1),
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
                              color: RoleColors.cobradorPrimary.withValues(alpha: 0.3),
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
                              usuario?.nombre ?? 'Cobrador',
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
                                    RoleColors.cobradorPrimary.withValues(alpha: 0.3),
                                    RoleColors.cobradorPrimary.withValues(alpha: 0.2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: RoleColors.cobradorPrimary.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_pin,
                                    color: RoleColors.cobradorPrimary,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cobrador',
                                    style: TextStyle(
                                      color: RoleColors.cobradorPrimary,
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
                subtitle: 'Resumen de tu cartera',
                icon: Icons.bar_chart_rounded,
                color: RoleColors.cobradorPrimary,
              ),

              const SizedBox(height: 16),
              // Modern Statistics Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final creditState = ref.watch(creditProvider);
                  final authState = ref.watch(authProvider);
                  final dash = authState.statistics;

                  final spacing = 16.0;
                  final itemWidth = (constraints.maxWidth - spacing) / 2;
                  final isLoading = dash == null && creditState.stats == null;

                  if (isLoading) {
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: List.generate(
                        2,
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
                          title: 'Clientes',
                          value: '${dash?.totalClientes ?? creditState.stats?.totalCredits ?? 0}',
                          icon: Icons.people_alt,
                          color: Colors.blue,
                          onTap: () => _navigateToClientManagement(context),
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        height: 160,
                        child: ModernStatCard(
                          title: 'Créditos Activos',
                          value: '${dash?.creditosActivos ?? creditState.stats?.activeCredits ?? 0}',
                          icon: Icons.account_balance_wallet,
                          color: Colors.green,
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
                subtitle: 'Administra tu cartera',
                icon: Icons.dashboard_customize,
                color: RoleColors.cobradorPrimary,
              ),

              const SizedBox(height: 16),

              // Modern Action Cards
              ModernActionCard(
                title: 'Gestión de Créditos',
                description: 'Ver y gestionar créditos de clientes',
                icon: Icons.credit_card,
                color: Colors.green,
                onTap: () => _navigateToCreditManagement(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Gestión de Clientes',
                description: 'Ver y gestionar mis clientes asignados',
                icon: Icons.business_center,
                color: Colors.blue,
                onTap: () => _navigateToClientManagement(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Mapa de Clientes',
                description: 'Ver mis clientes en el mapa',
                icon: Icons.map,
                color: Colors.indigo,
                onTap: () => _navigateToMap(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Cajas',
                description: 'Abrir, ver y cerrar mi caja del día',
                icon: Icons.point_of_sale,
                color: Colors.orange,
                onTap: () => _navigateToCashBalances(context),
              ),
              const SizedBox(height: 12),
              ModernActionCard(
                title: 'Mis Reportes',
                description: 'Ver estadísticas y reportes de mi desempeño',
                icon: Icons.analytics,
                color: Colors.purple,
                onTap: () => _navigateToReports(context),
              ),
              const SizedBox(height: 20), // Espacio adicional al final
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToQuickPayment(context),
        backgroundColor: RoleColors.cobradorPrimary,
        icon: const Icon(Icons.flash_on, color: Colors.white),
        label: const Text(
          'Pago Rápido',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        elevation: 6,
      ),
    );
  }

  void _navigateToClientManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClientesScreen(userRole: 'cobrador'),
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

  void _navigateToDailyRoute(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DailyRouteScreen()),
    );
  }

  void _navigateToQuickPayment(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QuickPaymentScreen()),
    );
  }

  void _navigateToReports(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportsScreen(userRole: 'cobrador'),
      ),
    );
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
    );
  }

  void _navigateToMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapScreen()),
    );
  }

  // NOTE: the above navigation helpers may not be referenced directly yet but
  // are kept for future feature links and to maintain parity with manager UI.
}
