import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';
import 'manager_cobrador_form_screen.dart';
import 'manager_client_assignment_screen.dart';
import 'cobrador_clientes_screen.dart';

class ManagerCobradoresScreen extends ConsumerStatefulWidget {
  const ManagerCobradoresScreen({super.key});

  @override
  ConsumerState<ManagerCobradoresScreen> createState() =>
      _ManagerCobradoresScreenState();
}

class _ManagerCobradoresScreenState
    extends ConsumerState<ManagerCobradoresScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _hasLoadedInitialData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  void _cargarDatosIniciales() {
    if (_hasLoadedInitialData) return;

    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      _hasLoadedInitialData = true;
      final managerId = authState.usuario!.id.toString();
      ref
          .read(managerProvider.notifier)
          .establecerManagerActual(authState.usuario!);
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
      ref.read(managerProvider.notifier).cargarEstadisticasManager(managerId);
    }
  }

  void _cargarDatos() {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
      ref.read(managerProvider.notifier).cargarEstadisticasManager(managerId);
    }
  }

  void _buscarCobradoresConDebounce(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final authState = ref.read(authProvider);
      if (authState.usuario != null) {
        final managerId = authState.usuario!.id.toString();
        ref
            .read(managerProvider.notifier)
            .cargarCobradoresAsignados(
              managerId,
              search: query.isEmpty ? null : query,
            );
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    // Escuchar cambios en el provider solo para mensajes de error/éxito
    ref.listen<ManagerState>(managerProvider, (previous, next) {
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    });

    return Scaffold(
      appBar: RoleAppBar(
        title: 'Gestión de Cobradores',
        role: 'manager',
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _navegarCrearCobrador(),
            tooltip: 'Crear Cobrador',
          ),
          /* IconButton(
            icon: const Icon(Icons.business_center),
            onPressed: () => _navegarAClientesDirectos(),
            tooltip: 'Mis Clientes Directos',
          ), */
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas rápidas
          _buildEstadisticasCard(managerState),

          // Barra de búsqueda
          _buildBarraBusqueda(),

          // Lista de cobradores asignados
          Expanded(child: _buildListaCobradores(managerState)),
        ],
      ),
    );
  }

  Widget _buildEstadisticasCard(ManagerState managerState) {
    final stats = managerState.estadisticas;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Cobradores',
              '${stats?['total_cobradores'] ?? managerState.cobradoresAsignados.length}',
              Icons.person,
              Colors.blue,
            ),
            /* _buildStatItem(
              'Clientes',
              '${stats?['total_clientes'] ?? 0}',
              Icons.business,
              Colors.green,
            ), */
            _buildStatItem(
              'Activos',
              '${stats?['cobradores_activos'] ?? managerState.cobradoresAsignados.length}',
              Icons.check_circle,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildBarraBusqueda() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar cobradores...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _buscarCobradoresConDebounce('');
                  },
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: (value) {
          _buscarCobradoresConDebounce(value);
        },
      ),
    );
  }

  Widget _buildListaCobradores(ManagerState managerState) {
    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (managerState.cobradoresAsignados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No tienes cobradores asignados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Usa el botón + para asignar cobradores',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _mostrarDialogoAsignacion(),
              icon: const Icon(Icons.person_add),
              label: const Text('Asignar Cobradores'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: managerState.cobradoresAsignados.length,
      itemBuilder: (context, index) {
        final cobrador = managerState.cobradoresAsignados[index];
        return _buildCobradorCard(cobrador);
      },
    );
  }

  Widget _buildCobradorCard(Usuario cobrador) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: RoleAvatarWidget(
          role: 'cobrador',
          userName: cobrador.nombre,
          radius: 25,
        ),
        title: Text(
          cobrador.nombre,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cobrador.email),
            if (cobrador.telefono.isNotEmpty)
              ContactActionsWidget.buildPhoneDisplay(
                context: context,
                userName: cobrador.nombre,
                phoneNumber: cobrador.telefono,
                userRole: 'cobrador',
                customMessage: ContactActionsWidget.getDefaultMessage(
                  'cobrador',
                  cobrador.nombre,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón de contacto rápido
            if (cobrador.telefono.isNotEmpty)
              ContactActionsWidget.buildContactButton(
                context: context,
                userName: cobrador.nombre,
                phoneNumber: cobrador.telefono,
                userRole: 'cobrador',
                customMessage: ContactActionsWidget.getDefaultMessage(
                  'cobrador',
                  cobrador.nombre,
                ),
                color: RoleColors.cobradorPrimary,
                tooltip: 'Contactar cobrador',
              ),
            // Menú contextual
            PopupMenuButton<String>(
              onSelected: (value) => _manejarAccionCobrador(value, cobrador),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'ver_clientes',
                  child: ListTile(
                    leading: Icon(Icons.business),
                    title: Text('Ver Clientes'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                ContactActionsWidget.buildContactMenuItem(
                  phoneNumber: cobrador.telefono,
                  value: 'contactar',
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  label: 'Llamar / WhatsApp',
                ),
                const PopupMenuItem(
                  value: 'asignar_clientes',
                  child: ListTile(
                    leading: Icon(Icons.person_add, color: Colors.green),
                    title: Text('Asignar Clientes'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'editar',
                  child: ListTile(
                    leading: Icon(Icons.edit, color: Colors.blue),
                    title: Text('Editar Cobrador'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem(
                  value: 'eliminar',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Eliminar Cobrador'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _manejarAccionCobrador(String accion, Usuario cobrador) {
    switch (accion) {
      case 'ver_clientes':
        _navegarAClientesCobrador(cobrador);
        break;
      case 'asignar_clientes':
        _navegarAAsignarClientes(cobrador);
        break;
      case 'contactar':
        ContactActionsWidget.showContactDialog(
          context: context,
          userName: cobrador.nombre,
          phoneNumber: cobrador.telefono,
          userRole: 'cobrador',
          customMessage: ContactActionsWidget.getDefaultMessage(
            'cobrador',
            cobrador.nombre,
          ),
        );
        break;
      case 'ver_perfil':
        _navegarAPerfilCobrador(cobrador);
        break;
      case 'editar':
        _navegarEditarCobrador(cobrador);
        break;
      case 'eliminar':
        _confirmarEliminarCobrador(cobrador);
        break;
      case 'remover':
        _confirmarRemoverCobrador(cobrador);
        break;
    }
  }

  void _navegarCrearCobrador() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ManagerCobradorFormScreen(),
      ),
    );
  }

  void _navegarEditarCobrador(Usuario cobrador) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ManagerCobradorFormScreen(cobrador: cobrador),
      ),
    );
  }

  void _confirmarEliminarCobrador(Usuario cobrador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente a ${cobrador.nombre}?\n\n'
          'Esta acción no se puede deshacer y el cobrador será eliminado del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _eliminarCobrador(cobrador);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _eliminarCobrador(Usuario cobrador) async {
    try {
      await ref
          .read(userManagementProvider.notifier)
          .eliminarUsuario(cobrador.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cobrador ${cobrador.nombre} eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        // Recargar la lista de cobradores
        final authState = ref.read(authProvider);
        if (authState.usuario != null) {
          ref
              .read(managerProvider.notifier)
              .cargarCobradoresAsignados(authState.usuario!.id.toString());
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cobrador: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navegarAClientesCobrador(Usuario cobrador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CobradorClientesScreen(cobrador: cobrador),
      ),
    );
  }

  void _navegarAAsignarClientes(Usuario cobrador) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ManagerClientAssignmentScreen(cobradorPreseleccionado: cobrador),
      ),
    );
  }

  void _navegarAPerfilCobrador(Usuario cobrador) {
    // TODO: Implementar navegación al perfil del cobrador
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ver perfil de ${cobrador.nombre} - En desarrollo'),
      ),
    );
  }

  void _confirmarRemoverCobrador(Usuario cobrador) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoción'),
        content: Text(
          '¿Estás seguro de que deseas remover a ${cobrador.nombre} de tu equipo?\n\n'
          'El cobrador quedará sin manager asignado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _removerCobrador(cobrador);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  void _removerCobrador(Usuario cobrador) {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      ref
          .read(managerProvider.notifier)
          .removerCobradorDeManager(
            authState.usuario!.id.toString(),
            cobrador.id.toString(),
          );
    }
  }

  void _mostrarDialogoAsignacion() {
    showDialog(
      context: context,
      builder: (context) => const AsignacionCobradoresDialog(),
    );
  }
}

class AsignacionCobradoresDialog extends ConsumerStatefulWidget {
  const AsignacionCobradoresDialog({super.key});

  @override
  ConsumerState<AsignacionCobradoresDialog> createState() =>
      _AsignacionCobradoresDialogState();
}

class _AsignacionCobradoresDialogState
    extends ConsumerState<AsignacionCobradoresDialog> {
  final Set<String> _cobradoresSeleccionados = {};
  final TextEditingController _searchController = TextEditingController();
  List<Usuario> _cobradoresFiltrados = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cobradoresAsyncValue = ref.watch(cobradoresDisponiblesProvider);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Asignar Cobradores',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar cobradores disponibles...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _filtrarCobradores,
            ),
            const SizedBox(height: 16),

            // Lista de cobradores disponibles
            Expanded(
              child: cobradoresAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (cobradores) {
                  if (_cobradoresFiltrados.isEmpty) {
                    _cobradoresFiltrados = cobradores;
                  }

                  if (_cobradoresFiltrados.isEmpty) {
                    return const Center(
                      child: Text('No hay cobradores disponibles para asignar'),
                    );
                  }

                  return ListView.builder(
                    itemCount: _cobradoresFiltrados.length,
                    itemBuilder: (context, index) {
                      final cobrador = _cobradoresFiltrados[index];
                      final isSelected = _cobradoresSeleccionados.contains(
                        cobrador.id.toString(),
                      );

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _cobradoresSeleccionados.add(
                                cobrador.id.toString(),
                              );
                            } else {
                              _cobradoresSeleccionados.remove(
                                cobrador.id.toString(),
                              );
                            }
                          });
                        },
                        title: Text(cobrador.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cobrador.email),
                            if (cobrador.telefono.isNotEmpty)
                              Text(cobrador.telefono),
                          ],
                        ),
                        secondary: RoleAvatarWidget(
                          role: 'cobrador',
                          userName: cobrador.nombre,
                          radius: 20,
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Botones de acción
            Row(
              children: [
                Text('${_cobradoresSeleccionados.length} seleccionados'),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _cobradoresSeleccionados.isEmpty
                      ? null
                      : () => _asignarCobradoresSeleccionados(),
                  child: const Text('Asignar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _filtrarCobradores(String query) {
    final cobradoresAsyncValue = ref.read(cobradoresDisponiblesProvider);
    cobradoresAsyncValue.whenData((cobradores) {
      setState(() {
        if (query.isEmpty) {
          _cobradoresFiltrados = cobradores;
        } else {
          _cobradoresFiltrados = cobradores.where((cobrador) {
            return cobrador.nombre.toLowerCase().contains(
                  query.toLowerCase(),
                ) ||
                cobrador.email.toLowerCase().contains(query.toLowerCase());
          }).toList();
        }
      });
    });
  }

  void _asignarCobradoresSeleccionados() {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      ref
          .read(managerProvider.notifier)
          .asignarCobradoresAManager(
            authState.usuario!.id.toString(),
            _cobradoresSeleccionados.toList(),
          )
          .then((success) {
            if (success) {
              Navigator.of(context).pop();
              // Refrescar la lista de cobradores disponibles
              ref.invalidate(cobradoresDisponiblesProvider);
            }
          });
    }
  }
}
