import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/profile_image_widget.dart';
// import '../widgets/websocket_widgets.dart'; // removed unused import
import '../pantallas/profile_settings_screen.dart';
import '../pantallas/notifications_screen.dart';
import '../widgets/logout_dialog.dart';
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
  @override
  void initState() {
    super.initState();
    // Cargar datos iniciales
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creditProvider.notifier).loadCredits();
      ref.read(creditProvider.notifier).loadCobradorStats();

      // Verificar si hay cajas pendientes de cierre
      _verificarCajasPendientes();
    });
  }

  /// Verifica si el cobrador tiene cajas pendientes de cierre
  Future<void> _verificarCajasPendientes() async {
    final authState = ref.read(authProvider);
    if (authState.usuario == null) return;

    try {
      final resp = await ref.read(cashBalanceProvider.notifier).getPendingClosures(
        cobradorId: authState.usuario!.id.toInt(),
      );

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
                      child: Icon(Icons.calendar_today,
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
      appBar: AppBar(
        title: const Text('Paneles de Cobrador'),
        backgroundColor: RoleColors.cobradorPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          // Botón de notificaciones
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
                              usuario?.nombre ?? 'Cobrador',
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
                                    ? Colors.green[800]
                                    : Colors.green[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Cobrador',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.green[100]
                                      : Colors.green,
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
                'Mis estadísticas',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final creditState = ref.watch(creditProvider);
                  final stats = creditState.stats;

                  return LayoutBuilder(
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
                              'Créditos Totales',
                              '${stats?.totalCredits ?? 0}',
                              Icons.credit_score,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildStatCard(
                              context,
                              'Créditos Activos',
                              '${stats?.activeCredits ?? 0}',
                              Icons.play_circle,
                              Colors.green,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildStatCard(
                              context,
                              'Monto Total',
                              'Bs ${stats?.totalAmount.toStringAsFixed(2) ?? '0.00'}',
                              Icons.attach_money,
                              Colors.orange,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: _buildStatCard(
                              context,
                              'Balance Total',
                              'Bs ${stats?.totalBalance.toStringAsFixed(2) ?? '0.00'}',
                              Icons.account_balance_wallet,
                              Colors.purple,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),

              const SizedBox(height: 24),

              // Acciones rápidas
              Text(
                'Funciones de Gestión',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Lista de acciones con mejor espaciado
              Column(
                children: [
                  _buildCobradorActionCard(
                    context,
                    'Ruta del Día',
                    'Ver mis clientes a visitar hoy',
                    Icons.route,
                    Colors.teal,
                    () => _navigateToDailyRoute(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCobradorActionCard(
                    context,
                    'Registro Rápido',
                    'Registrar cobros de forma rápida',
                    Icons.flash_on,
                    Colors.amber,
                    () => _navigateToQuickPayment(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCobradorActionCard(
                    context,
                    'Gestionar Créditos',
                    'Ver y gestionar créditos de clientes',
                    Icons.credit_card,
                    Colors.green,
                    () => _navigateToCreditManagement(context),
                  ),
                  const SizedBox(height: 12),
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
                    'Mapa de Clientes',
                    'Ver mis clientes en el mapa',
                    Icons.map,
                    Colors.indigo,
                    () => _navigateToMap(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCobradorActionCard(
                    context,
                    'Cajas',
                    'Abrir, ver y cerrar mi caja del día',
                    Icons.point_of_sale,
                    Colors.orange,
                    () => _navigateToCashBalances(context),
                  ),
                  const SizedBox(height: 12),
                  _buildCobradorActionCard(
                    context,
                    'Mis Reportes',
                    'Ver estadísticas y reportes de mi desempeño',
                    Icons.analytics,
                    Colors.purple,
                    () => _navigateToReports(context),
                  ),
                ],
              ),
              const SizedBox(height: 20), // Espacio adicional al final
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
        padding: const EdgeInsets.all(10.0), // Reducido de 12 a 10
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color), // Reducido de 32 a 28
            const SizedBox(height: 6), // Reducido de 8 a 6
            Text(
              value,
              style: TextStyle(
                fontSize: 18, // Reducido de 20 a 18
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
                fontSize: 10, // Reducido de 11 a 10
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

  Widget _buildCobradorActionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  color: color.withOpacity(isDark ? 0.2 : 0.1),
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
                        fontSize: 11, // Reducido de 12 a 11
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
                size: 14, // Reducido de 16 a 14
              ),
            ],
          ),
        ),
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
