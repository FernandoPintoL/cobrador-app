import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../../negocio/providers/credit_provider.dart';
import '../widgets/profile_image_widget.dart';
import '../pantallas/profile_settings_screen.dart';
import '../cliente/clientes_screen.dart';
import '../creditos/credits_screen.dart';
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
                  final stats = creditState.stats;
                  final activeCredits = creditState.credits
                      .where((c) => c.status == 'active')
                      .length;
                  final attentionCredits = creditState.attentionCredits.length;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: constraints.maxWidth > 400 ? 1.5 : 1.3,
                    children: [
                      _buildStatCard(
                        context,
                        'Créditos Activos',
                        '$activeCredits',
                        Icons.credit_card,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        context,
                        'Saldo Pendiente',
                        stats != null
                            ? 'Bs. ${NumberFormat('#,##0').format(stats.totalBalance)}'
                            : 'Bs. 0',
                        Icons.account_balance_wallet,
                        Colors.green,
                      ),
                      _buildStatCard(
                        context,
                        'Requieren Atención',
                        '$attentionCredits',
                        Icons.warning,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        context,
                        'Tasa Cobranza',
                        stats != null
                            ? '${stats.collectionRate.toStringAsFixed(1)}%'
                            : '0%',
                        Icons.trending_up,
                        Colors.purple,
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
                    'Gestionar Créditos',
                    'Ver y gestionar créditos de clientes',
                    Icons.credit_card,
                    Colors.green,
                    () => _navigateToCreditManagement(context),
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

  void _navigateToCreditManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreditsScreen()),
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
