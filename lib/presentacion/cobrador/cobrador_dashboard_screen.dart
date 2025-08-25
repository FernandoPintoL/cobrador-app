import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/websocket_widgets.dart';
import '../pantallas/profile_settings_screen.dart';
import '../pantallas/notifications_screen.dart';
import '../cliente/clientes_screen.dart'; // Pantalla genérica reutilizable
import '../creditos/credit_type_screen.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final creditState = ref.watch(creditProvider);
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

      if (previous?.successMessage != next.successMessage && next.successMessage != null) {
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
            onPressed: () => ref.read(authProvider.notifier).logout(),
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

  void _navigateToDailyRoute(BuildContext context) {
    // TODO: Implementar ruta diaria
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ruta del día - En desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToRecordPayment(BuildContext context) {
    // TODO: Implementar registro de cobros
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Registro de cobros - En desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _navigateToReports(BuildContext context) {
    // TODO: Implementar pantalla de reportes
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reportes - En desarrollo')));
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
    );
  }
}
