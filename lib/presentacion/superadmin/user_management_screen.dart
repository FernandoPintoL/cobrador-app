import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../datos/modelos/usuario.dart';
import '../widgets/role_widgets.dart';
import '../pantallas/change_password_screen.dart';
import 'user_form_screen.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      // Usar addPostFrameCallback para evitar errores de Riverpod
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarUsuarios();
      });
    });

    // Cargar datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarUsuarios();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _cargarUsuarios() {
    if (!mounted) return;

    final search = _searchController.text.trim();
    if (_tabController.index == 0) {
      ref
          .read(userManagementProvider.notifier)
          .cargarClientes(search: search.isEmpty ? null : search);
    } else if (_tabController.index == 1) {
      ref
          .read(userManagementProvider.notifier)
          .cargarCobradores(search: search.isEmpty ? null : search);
    } else {
      ref
          .read(userManagementProvider.notifier)
          .cargarUsuarios(
            role: 'manager',
            search: search.isEmpty ? null : search,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return Scaffold(
      appBar: RoleAppBar(
        title: 'Gestión de Usuarios',
        role: 'admin',
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Clientes'),
            Tab(text: 'Cobradores'),
            Tab(text: 'Managers'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuarios...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    // Usar addPostFrameCallback para evitar errores
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _cargarUsuarios();
                      }
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                // Usar debounce para evitar llamadas excesivas
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _cargarUsuarios();
                  }
                });
              },
            ),
          ),

          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildUserList(state, 'client'),
                _buildUserList(state, 'cobrador'),
                _buildUserList(state, 'manager'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: RoleFloatingActionButton(
        role: 'admin',
        onPressed: () {
          _mostrarFormularioUsuario();
        },
        tooltip: 'Agregar usuario',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUserList(UserManagementState state, String userType) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error: ${state.error}',
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarUsuarios,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.usuarios.isEmpty) {
      String userTypeDisplayName;
      IconData iconData;

      switch (userType) {
        case 'client':
          userTypeDisplayName = 'clientes';
          iconData = Icons.people;
          break;
        case 'cobrador':
          userTypeDisplayName = 'cobradores';
          iconData = Icons.person_pin;
          break;
        case 'manager':
          userTypeDisplayName = 'managers';
          iconData = Icons.supervisor_account;
          break;
        default:
          userTypeDisplayName = 'usuarios';
          iconData = Icons.person;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay $userTypeDisplayName registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Toca el botón + para agregar uno nuevo',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.usuarios.length,
      itemBuilder: (context, index) {
        final usuario = state.usuarios[index];
        return _buildUserCard(usuario);
      },
    );
  }

  Widget _buildUserCard(Usuario usuario) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: RoleAvatarWidget(
          role: usuario.roles.first,
          userName: usuario.nombre,
          radius: 25,
        ),
        title: Text(
          usuario.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(usuario.email),
            if (usuario.telefono.isNotEmpty) Text('Tel: ${usuario.telefono}'),
            if (usuario.direccion.isNotEmpty) Text('Dir: ${usuario.direccion}'),
            RoleDisplayWidget(
              role: usuario.roles.first,
              useGradient: true,
              showIcon: true,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editarUsuario(usuario);
                break;
              case 'change_password':
                _cambiarContrasena(usuario);
                break;
              case 'delete':
                _confirmarEliminacion(usuario);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            if (usuario.roles.first != 'client') // Solo mostrar para managers y cobradores
              const PopupMenuItem(
                value: 'change_password',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Cambiar Contraseña'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarFormularioUsuario() {
    String userType;
    if (_tabController.index == 0) {
      userType = 'client';
    } else if (_tabController.index == 1) {
      userType = 'cobrador';
    } else {
      userType = 'manager';
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          userType: userType,
          onUserCreated: () {
            _cargarUsuarios();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario creado exitosamente')),
            );
          },
        ),
      ),
    );
  }

  void _editarUsuario(Usuario usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserFormScreen(
          userType: usuario.roles.first,
          usuario: usuario,
          onUserCreated: () {
            _cargarUsuarios();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Usuario actualizado exitosamente')),
            );
          },
        ),
      ),
    );
  }

  void _cambiarContrasena(Usuario usuario) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          targetUser: usuario,
          onPasswordChanged: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña cambiada exitosamente')),
            );
          },
        ),
      ),
    );
  }

  void _confirmarEliminacion(Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${usuario.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref
                  .read(userManagementProvider.notifier)
                  .eliminarUsuario(usuario.id);

              if (success) {
                _cargarUsuarios();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario eliminado exitosamente'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ref.read(userManagementProvider).error ??
                          'Error al eliminar',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
