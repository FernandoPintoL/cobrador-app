import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../widgets/profile_image_widget.dart';
import '../pantallas/profile_settings_screen.dart';
import '../cliente/clientes_screen.dart';

class CobradorDashboardScreen extends ConsumerWidget {
  const CobradorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final profileImageState = ref.watch(profileImageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios en el estado de la imagen de perfil
    ref.listen<ProfileImageState>(profileImageProvider, (previous, next) {
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        ref.read(profileImageProvider.notifier).clearError();
      }

      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(profileImageProvider.notifier).clearSuccess();
      }
    });

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
              Text(
                'Mis Estadísticas',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // GridView mejorado con mejor responsive design
              LayoutBuilder(
                builder: (context, constraints) {
                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10, // Reducido de 12 a 10
                    mainAxisSpacing: 10, // Reducido de 12 a 10
                    childAspectRatio: constraints.maxWidth > 400
                        ? 1.5
                        : 1.3, // Ajustado para más espacio
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
                  );
                },
              ),
              const SizedBox(height: 32),

              // Acciones rápidas
              Text(
                'Acciones Rápidas',
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
      MaterialPageRoute(builder: (context) => const ProfileSettingsScreen()),
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
