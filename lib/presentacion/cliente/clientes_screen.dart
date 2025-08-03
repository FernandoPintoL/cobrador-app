import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/usuario.dart';
import 'cliente_form_screen.dart';
import 'cliente_detalle_screen.dart';
import 'cliente_asignacion_screen.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarClientes();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarClientes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _cargarClientes() {
    if (!mounted) return;

    final authState = ref.read(authProvider);
    final search = _searchController.text.trim();
    String? cobradorId;
    String? filter;

    // Determinar filtros según el rol del usuario
    if (authState.isCobrador) {
      // Cobradores solo ven sus clientes asignados
      cobradorId = authState.usuario?.id.toString();
    }

    // Aplicar filtros según la pestaña seleccionada
    switch (_tabController.index) {
      case 0: // Todos
        filter = null;
        break;
      case 1: // Con Créditos
        filter = 'with_credits';
        break;
      case 2: // Pendientes
        filter = 'pending';
        break;
    }

    ref
        .read(clientProvider.notifier)
        .cargarClientes(
          search: search.isEmpty ? null : search,
          filter: filter,
          cobradorId: cobradorId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final clientState = ref.watch(clientProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios en el estado solo cuando cambian los valores específicos
    ref.listen<ClientState>(clientProvider, (previous, next) {
      // Solo procesar errores nuevos o diferentes
      if (next.error != null && next.error != previous?.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
          );

          // Limpiar el error después de mostrarlo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(clientProvider.notifier).limpiarError();
            }
          });
        }
      }

      // Solo procesar mensajes de éxito nuevos o diferentes
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: Colors.green,
            ),
          );

          // Limpiar el mensaje después de mostrarlo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(clientProvider.notifier).limpiarExito();
            }
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          authState.isCobrador ? 'Mis Clientes' : 'Gestión de Clientes',
        ),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Con Créditos'),
            Tab(text: 'Pendientes'),
          ],
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _cargarClientes();
                      }
                    });
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              ),
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    _cargarClientes();
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
                _buildClientList(clientState, 'todos'),
                _buildClientList(clientState, 'with_credits'),
                _buildClientList(clientState, 'pending'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          authState.isManager || authState.isAdmin || authState.isCobrador
          ? FloatingActionButton(
              onPressed: () => _mostrarFormularioCliente(),
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildClientList(ClientState state, String filterType) {
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
              onPressed: _cargarClientes,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (state.clientes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay clientes registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              filterType == 'todos'
                  ? 'Agrega tu primer cliente para comenzar'
                  : 'No hay clientes con este filtro',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.clientes.length,
      itemBuilder: (context, index) {
        final cliente = state.clientes[index];
        return _buildClientCard(cliente);
      },
    );
  }

  Widget _buildClientCard(Usuario cliente) {
    final authState = ref.read(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _verDetalleCliente(cliente),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: const Color(0xFF667eea),
                child: Text(
                  cliente.nombre.isNotEmpty
                      ? cliente.nombre[0].toUpperCase()
                      : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cliente.email,
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    if (cliente.telefono.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '📞 ${cliente.telefono}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                    if (cliente.direccion.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        '📍 ${cliente.direccion}',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (authState.isManager || authState.isAdmin)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editarCliente(cliente);
                        break;
                      case 'delete':
                        _confirmarEliminacion(cliente);
                        break;
                      case 'assign':
                        _asignarACobrador(cliente);
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
                      value: 'assign',
                      child: Row(
                        children: [
                          Icon(Icons.person_add, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Asignar'),
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
                )
              else if (authState.isCobrador)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editarCliente(cliente);
                        break;
                      case 'delete':
                        _confirmarEliminacion(cliente);
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
                )
              else
                const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioCliente() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteFormScreen(
          onClienteCreated: () {
            _cargarClientes();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cliente creado exitosamente')),
            );
          },
        ),
      ),
    );
  }

  void _editarCliente(Usuario cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteFormScreen(
          cliente: cliente,
          onClienteCreated: () {
            _cargarClientes();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cliente actualizado exitosamente')),
            );
          },
        ),
      ),
    );
  }

  void _verDetalleCliente(Usuario cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteDetalleScreen(cliente: cliente),
      ),
    );
  }

  void _confirmarEliminacion(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${cliente.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final authState = ref.read(authProvider);
              final cobradorId = authState.isCobrador
                  ? authState.usuario?.id.toString()
                  : null;

              final success = await ref
                  .read(clientProvider.notifier)
                  .eliminarCliente(
                    id: cliente.id.toString(),
                    cobradorId: cobradorId,
                  );

              if (success) {
                _cargarClientes();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente eliminado exitosamente'),
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

  void _asignarACobrador(Usuario cliente) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteAsignacionScreen(cliente: cliente),
      ),
    ).then((result) {
      if (result == true) {
        _cargarClientes();
      }
    });
  }
}
