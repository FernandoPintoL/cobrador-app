import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ClientesScreen(),
    const CobrosScreen(),
    const MapScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Cobros'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Mapa'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjetas de estadísticas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Clientes Activos',
                    '25',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Cobros Hoy',
                    '8',
                    Icons.payment,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Pendientes',
                    '12',
                    Icons.schedule,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Recaudado',
                    '\$2,450',
                    Icons.attach_money,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Sección de acciones rápidas
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildActionCard(
                  'Nuevo Cliente',
                  Icons.person_add,
                  Colors.blue,
                  () => _navigateToNewClient(context),
                ),
                _buildActionCard(
                  'Registrar Pago',
                  Icons.payment,
                  Colors.green,
                  () => _navigateToPayment(context),
                ),
                _buildActionCard(
                  'Ver Mapa',
                  Icons.map,
                  Colors.orange,
                  () => _navigateToMap(context),
                ),
                _buildActionCard(
                  'Reportes',
                  Icons.assessment,
                  Colors.purple,
                  () => _navigateToReports(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToNewClient(BuildContext context) {
    // TODO: Implementar navegación
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función en desarrollo')));
  }

  void _navigateToPayment(BuildContext context) {
    // TODO: Implementar navegación
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función en desarrollo')));
  }

  void _navigateToMap(BuildContext context) {
    // TODO: Implementar navegación
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función en desarrollo')));
  }

  void _navigateToReports(BuildContext context) {
    // TODO: Implementar navegación
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Función en desarrollo')));
  }
}

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Agregar nuevo cliente
            },
          ),
        ],
      ),
      body: const Center(child: Text('Lista de clientes - En desarrollo')),
    );
  }
}

class CobrosScreen extends StatelessWidget {
  const CobrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Gestión de cobros - En desarrollo')),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: const Center(child: Text('Mapa de clientes - En desarrollo')),
    );
  }
}

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Mostrar diálogo de confirmación
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text(
                    '¿Estás seguro de que quieres cerrar sesión?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Cerrar Sesión'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            if (usuario != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: const Color(0xFF667eea),
                            child: Text(
                              usuario.nombre.isNotEmpty
                                  ? usuario.nombre[0].toUpperCase()
                                  : 'U',
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
                                  usuario.nombre,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  usuario.email,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  usuario.telefono,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Roles: ${usuario.roles.join(', ')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Opciones del perfil
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('Editar Perfil'),
                    onTap: () {
                      // TODO: Implementar edición de perfil
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Cambiar Contraseña'),
                    onTap: () {
                      // TODO: Implementar cambio de contraseña
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Configuración'),
                    onTap: () {
                      // TODO: Implementar configuración
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Ayuda'),
                    onTap: () {
                      // TODO: Implementar ayuda
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Función en desarrollo')),
                      );
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
