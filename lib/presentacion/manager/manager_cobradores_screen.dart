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
import '../widgets/profile_image_widget.dart';
import '../pantallas/change_password_screen.dart';
import '../cliente/clientes_screen.dart'; // Nueva pantalla genérica
import '../cobrador/cobrador_form_screen.dart';
import 'manager_client_assignment_screen.dart';

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

      // ✅ OPTIMIZACIÓN: Usar estadísticas del login si están disponibles
      if (authState.statistics != null) {
        debugPrint(
          '📊 Usando estadísticas del login en cobradores (evitando petición innecesaria)',
        );
        ref
            .read(managerProvider.notifier)
            .establecerEstadisticas(authState.statistics!.toCompatibleMap());
      } else {
        debugPrint(
          '⚠️ No hay estadísticas del login, cargando desde el backend',
        );
        ref.read(managerProvider.notifier).cargarEstadisticasManager(managerId);
      }

      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
    }
  }

  void _cargarDatos() {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);

      // ✅ En refresh manual, siempre recargar estadísticas para tener datos frescos
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
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Estadísticas rápidas
          _buildEstadisticasCard(managerState),

          // Barra de búsqueda
          _buildBarraBusqueda(),

          // Lista de cobradores asignados
          Expanded(child: _buildListaCobradores(managerState)),
        ],
      ),
      floatingActionButton: RoleFloatingActionButton(
        role: 'manager',
        onPressed: () => _navegarCrearCobrador(),
        tooltip: 'Crear Cobrador',
        child: const Icon(Icons.person_add),
      ),
    );
  }

  Widget _buildEstadisticasCard(ManagerState managerState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = managerState.estadisticas;
    final totalCobradores = stats?['total_cobradores'] ?? managerState.cobradoresAsignados.length;
    final cobradoresActivos = stats?['cobradores_activos'] ?? managerState.cobradoresAsignados.length;
    final totalClientes = stats?['total_clientes'] ?? 0;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.spaceAround,
          children: [
            _buildStatItem(theme, isDark, 'Total', '$totalCobradores', Icons.person, Colors.blue),
            _buildStatItem(theme, isDark, 'Activos', '$cobradoresActivos', Icons.check_circle, Colors.green),
            _buildStatItem(theme, isDark, 'Clientes', '$totalClientes', Icons.business, Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 80,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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
    final theme = Theme.of(context);

    if (managerState.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando cobradores...'),
          ],
        ),
      );
    }

    if (managerState.cobradoresAsignados.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 80,
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 24),
              Text(
                'Aún no tienes cobradores registrados',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Usa el botón + para crear un nuevo cobrador',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navegarCrearCobrador(),
                icon: const Icon(Icons.person_add),
                label: const Text('Crear Cobrador'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: managerState.cobradoresAsignados.length,
      itemBuilder: (context, index) {
        final cobrador = managerState.cobradoresAsignados[index];
        return _buildCobradorCard(cobrador, managerState);
      },
    );
  }

  Widget _buildCobradorCard(Usuario cobrador, ManagerState managerState) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Obtener clientes asignados desde el campo del endpoint
    final clientesAsignados = cobrador.assignedClientsCount ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: RoleColors.cobradorPrimary.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _navegarAClientesCobrador(cobrador),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Foto de perfil
              Stack(
                children: [
                  ProfileImageWidget(
                    profileImage: cobrador.profileImage,
                    size: 56,
                  ),
                  // Badge con número de clientes
                  if (clientesAsignados > 0)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.cardColor,
                            width: 2,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        child: Text(
                          '$clientesAsignados',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Información del cobrador
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    Text(
                      cobrador.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Teléfono con icono
                    if (cobrador.telefono.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              cobrador.telefono,
                              style: theme.textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Badge con clientes asignados
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: isDark ? 0.3 : 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business,
                            size: 12,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$clientesAsignados cliente${clientesAsignados != 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botones de acción
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón ver clientes
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.business, size: 20),
                      color: Colors.blue,
                      onPressed: () => _navegarAClientesCobrador(cobrador),
                      tooltip: 'Ver clientes',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Menú de más opciones
                  PopupMenuButton<String>(
                    onSelected: (value) => _manejarAccionCobrador(value, cobrador),
                    icon: Icon(
                      Icons.more_vert,
                      color: theme.iconTheme.color,
                      size: 20,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'asignar_clientes',
                        child: ListTile(
                          leading: Icon(Icons.person_add, color: Colors.green, size: 20),
                          title: Text('Asignar Clientes'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      if (cobrador.telefono.isNotEmpty)
                        ContactActionsWidget.buildContactMenuItem(
                          phoneNumber: cobrador.telefono,
                          value: 'contactar',
                          icon: Icons.phone,
                          iconColor: Colors.green,
                          label: 'Llamar / WhatsApp',
                        ),
                      const PopupMenuItem(
                        value: 'change_password',
                        child: ListTile(
                          leading: Icon(Icons.lock_reset, color: Colors.orange, size: 20),
                          title: Text('Cambiar Contraseña'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'editar',
                        child: ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue, size: 20),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'eliminar',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red, size: 20),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
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
      case 'change_password':
        _navegarACambiarContrasena(cobrador);
        break;
    }
  }

  void _navegarCrearCobrador() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const CobradorFormScreen()));
  }

  void _navegarEditarCobrador(Usuario cobrador) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CobradorFormScreen(cobrador: cobrador),
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
    // Navegar a la pantalla de clientes especificando que se van a mostrar
    // los clientes de un cobrador específico desde el perfil del manager
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ClientesScreen(userRole: 'manager', cobrador: cobrador),
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

  void _navegarACambiarContrasena(Usuario cobrador) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          targetUser: cobrador,
          onPasswordChanged: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña cambiada exitosamente')),
            );
          },
        ),
      ),
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
                        secondary: ProfileAvatarWidget(
                          role: 'cobrador',
                          userName: cobrador.nombre,
                          profileImagePath: cobrador.profileImage,
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
