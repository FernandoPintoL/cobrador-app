import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../datos/modelos/usuario.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
    } else {
      ref
          .read(userManagementProvider.notifier)
          .cargarCobradores(search: search.isEmpty ? null : search);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userManagementProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Usuarios'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Clientes'),
            Tab(text: 'Cobradores'),
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
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mostrarFormularioUsuario();
        },
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              userType == 'client' ? Icons.people : Icons.person_pin,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay ${userType == 'client' ? 'clientes' : 'cobradores'} registrados',
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
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            usuario.nombre.isNotEmpty ? usuario.nombre[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
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
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(usuario.roles.first),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                usuario.roles.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _editarUsuario(usuario);
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

  Color _getRoleColor(String role) {
    switch (role) {
      case 'client':
        return Colors.blue;
      case 'cobrador':
        return Colors.green;
      case 'manager':
        return Colors.orange;
      case 'admin':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _mostrarFormularioUsuario() {
    final userType = _tabController.index == 0 ? 'client' : 'cobrador';
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
