import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/role_colors.dart';
import '../../negocio/providers/auth_provider.dart';
import '../cliente/clientes_screen.dart';
import '../pantallas/profile_settings_screen.dart';
import '../manager/manager_cobradores_screen.dart';
import '../cajas/cash_balances_list_screen.dart';
import '../cajas/open_cash_balance_dialog.dart';
import 'profile_image_widget.dart';
import 'logout_dialog.dart';
import '../map/map_screen.dart';

class AppDrawer extends ConsumerWidget {
  final String role;

  const AppDrawer({super.key, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final userRoleParam = role == 'manager'
        ? 'manager'
        : role == 'cobrador'
        ? 'cobrador'
        : null;

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header mejorado con información del usuario
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    RoleColors.getPrimaryColor(role),
                    RoleColors.getPrimaryColor(role).withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar y nombre del usuario
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child:
                            usuario?.profileImage != null &&
                                usuario!.profileImage.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: ProfileImageWidget(
                                  profileImage: usuario.profileImage,
                                  size: 60,
                                ),
                              )
                            : Text(
                                usuario?.nombre.substring(0, 1).toUpperCase() ??
                                    'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              usuario?.nombre ?? 'Usuario',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                role.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Información adicional del usuario
                  if (usuario?.email != null && usuario!.email.isNotEmpty)
                    Text(
                      usuario.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (usuario?.telefono != null &&
                      usuario!.telefono.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.phone,
                          size: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          usuario.telefono,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Accesos rápidos',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Lista de opciones del menú
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.people_alt, color: Colors.blue),
                    title: const Text('Gestionar clientes'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ClientesScreen(userRole: userRoleParam),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.map, color: Colors.teal),
                    title: const Text('Mapa de clientes'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    },
                  ),

                  // Opción de gestionar cobradores solo para managers
                  if (role == 'manager')
                    ListTile(
                      leading: const Icon(
                        Icons.supervisor_account,
                        color: Colors.green,
                      ),
                      title: const Text('Gestionar cobradores'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ManagerCobradoresScreen(),
                          ),
                        );
                      },
                    ),

                  // Acceso a Cajas para manager/admin/cobrador
                  if (role == 'manager' || role == 'admin' || role == 'cobrador')
                    ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.brown,
                      ),
                      title: const Text('Cajas'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CashBalancesListScreen(),
                          ),
                        );
                      },
                    ),

                  // Acceso rápido para cobrador: Abrir caja
                  if (role == 'cobrador')
                    ListTile(
                      leading: const Icon(
                        Icons.open_in_new,
                        color: Colors.deepOrange,
                      ),
                      title: const Text('Abrir caja'),
                      onTap: () async {
                        Navigator.pop(context);
                        await showDialog(
                          context: context,
                          builder: (_) => const OpenCashBalanceDialog(),
                        );
                      },
                    ),

                  ListTile(
                    leading: const Icon(Icons.person, color: Colors.orange),
                    title: const Text('Mi perfil'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileSettingsScreen(),
                        ),
                      );
                    },
                  ),

                  // Divider para separar opciones principales de secundarias
                  const Divider(),

                  // Información adicional dependiendo del rol
                  /* if (role == 'manager') ...[
                    ListTile(
                      leading: const Icon(
                        Icons.analytics,
                        color: Colors.purple,
                      ),
                      title: const Text('Estadísticas'),
                      subtitle: const Text('Ver rendimiento del equipo'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implementar pantalla de estadísticas
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función en desarrollo'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],

                  if (role == 'cobrador') ...[
                    ListTile(
                      leading: const Icon(Icons.route, color: Colors.indigo),
                      title: const Text('Mi ruta'),
                      subtitle: const Text('Clientes asignados'),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implementar pantalla de ruta del cobrador
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función en desarrollo'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ], */

                  // Opción de cerrar sesión
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Cerrar sesión'),
                    onTap: () async {
                      Navigator.pop(context);
                      await showLogoutOptions(context: context, ref: ref);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
