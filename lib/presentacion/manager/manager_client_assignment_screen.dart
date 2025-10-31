import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/usuario.dart';

class ManagerClientAssignmentScreen extends ConsumerStatefulWidget {
  final Usuario? cobradorPreseleccionado;

  const ManagerClientAssignmentScreen({
    super.key,
    this.cobradorPreseleccionado,
  });

  @override
  ConsumerState<ManagerClientAssignmentScreen> createState() =>
      _ManagerClientAssignmentScreenState();
}

class _ManagerClientAssignmentScreenState
    extends ConsumerState<ManagerClientAssignmentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Usuario? _cobradorSeleccionado;
  List<String> _clientesSeleccionados = [];
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Si se proporciona un cobrador preseleccionado, configurarlo
    if (widget.cobradorPreseleccionado != null) {
      _cobradorSeleccionado = widget.cobradorPreseleccionado;
      // Si hay un cobrador preseleccionado, ir directamente a la pestaña de asignación
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tabController.animateTo(1); // Ir a la segunda pestaña (índice 1)
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatosIniciales() async {
    final authState = ref.read(authProvider);
    final usuario = authState.usuario;

    if (usuario != null) {
      final managerId = usuario.id.toString();

      // Cargar cobradores del manager
      await ref
          .read(managerProvider.notifier)
          .cargarCobradoresAsignados(managerId);

      // Cargar todos los clientes del manager
      await ref
          .read(managerProvider.notifier)
          .cargarClientesDelManager(managerId);

      // Cargar clientes sin asignar
      await ref.read(clientProvider.notifier).cargarClientesSinAsignar();
    }
  }

  void _seleccionarCobrador(Usuario cobrador) {
    setState(() {
      _cobradorSeleccionado = cobrador;
      _clientesSeleccionados.clear();
    });
    _tabController.animateTo(1); // Ir a la tab de clientes disponibles
  }

  void _toggleClienteSeleccion(String clienteId) {
    setState(() {
      if (_clientesSeleccionados.contains(clienteId)) {
        _clientesSeleccionados.remove(clienteId);
      } else {
        _clientesSeleccionados.add(clienteId);
      }
    });
  }

  Future<void> _asignarClientesSeleccionados() async {
    if (_cobradorSeleccionado == null || _clientesSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un cobrador y al menos un cliente'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isAssigning = true);

    try {
      final success = await ref
          .read(clientProvider.notifier)
          .asignarClientesACobrador(
            _cobradorSeleccionado!.id.toString(),
            _clientesSeleccionados,
          );

      if (success) {
        setState(() {
          _clientesSeleccionados.clear();
        });

        // Recargar datos
        await _cargarDatosIniciales();

        // Cambiar a la tab de clientes asignados
        _tabController.animateTo(2);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_clientesSeleccionados.length} clientes asignados exitosamente a ${_cobradorSeleccionado!.nombre}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al asignar clientes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);
    final clientState = ref.watch(clientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.cobradorPreseleccionado != null
              ? 'Asignar Clientes a ${widget.cobradorPreseleccionado!.nombre}'
              : 'Asignar Clientes a Cobradores',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Tab(
              icon: Badge(
                label: Text('${managerState.cobradoresAsignados.length}'),
                child: const Icon(Icons.person_pin),
              ),
              text: 'Cobradores',
            ),
            Tab(
              icon: Badge(
                label: Text('${clientState.clientesSinAsignar.length}'),
                child: const Icon(Icons.people_outline),
              ),
              text: 'Clientes Disponibles',
            ),
            Tab(
              icon: Badge(
                label: Text('${managerState.clientesDelManager.length}'),
                child: const Icon(Icons.assignment_ind),
              ),
              text: 'Asignaciones',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Panel de información
          _buildInfoPanel(),

          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCobradoresTab(managerState),
                _buildClientesDisponiblesTab(clientState),
                _buildAsignacionesTab(managerState),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton:
          _cobradorSeleccionado != null && _clientesSeleccionados.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _isAssigning ? null : _asignarClientesSeleccionados,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: _isAssigning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.assignment_turned_in),
              label: Text(
                _isAssigning
                    ? 'Asignando...'
                    : 'Asignar ${_clientesSeleccionados.length} cliente${_clientesSeleccionados.length != 1 ? 's' : ''}',
              ),
            )
          : null,
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestión de Asignaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              if (_cobradorSeleccionado != null) ...[
                Row(
                  children: [
                    const Icon(Icons.person_pin, size: 20, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cobrador seleccionado: ${_cobradorSeleccionado!.nombre}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      _cobradorSeleccionado!.telefono.isNotEmpty
                          ? _cobradorSeleccionado!.telefono
                          : 'Sin teléfono',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (_clientesSeleccionados.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        '${_clientesSeleccionados.length} cliente${_clientesSeleccionados.length != 1 ? 's' : ''} seleccionado${_clientesSeleccionados.length != 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ] else ...[
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Selecciona un cobrador para comenzar la asignación de clientes',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCobradoresTab(ManagerState managerState) {
    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (managerState.cobradoresAsignados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tienes cobradores asignados',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Solicita al administrador que te asigne cobradores',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
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
        final isSelected = _cobradorSeleccionado?.id == cobrador.id;
        final clientesAsignados = managerState.clientesDelManager
            .where((c) => c.assignedCobradorId == cobrador.id)
            .length;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 8 : 2,
          child: InkWell(
            onTap: () => _seleccionarCobrador(cobrador),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.blue,
                    child: Text(
                      cobrador.nombre.isNotEmpty
                          ? cobrador.nombre[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cobrador.nombre,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                        ),
                        if (cobrador.telefono.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                cobrador.telefono,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.people,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$clientesAsignados cliente${clientesAsignados != 1 ? 's' : ''} asignado${clientesAsignados != 1 ? 's' : ''}',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildClientesDisponiblesTab(ClientState clientState) {
    if (_cobradorSeleccionado == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Selecciona un cobrador primero',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Ve a la pestaña "Cobradores" y selecciona uno',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (clientState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (clientState.clientesSinAsignar.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay clientes disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Todos los clientes ya están asignados',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Contador de selección
        if (_clientesSeleccionados.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_clientesSeleccionados.length} cliente${_clientesSeleccionados.length != 1 ? 's' : ''} seleccionado${_clientesSeleccionados.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _clientesSeleccionados.clear();
                    });
                  },
                  child: const Text('Limpiar'),
                ),
              ],
            ),
          ),

        // Lista de clientes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: clientState.clientesSinAsignar.length,
            itemBuilder: (context, index) {
              final cliente = clientState.clientesSinAsignar[index];
              final isSelected = _clientesSeleccionados.contains(
                cliente.id.toString(),
              );

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: isSelected ? 4 : 1,
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _toggleClienteSeleccion(cliente.id.toString());
                  },
                  title: Text(
                    cliente.nombre,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (cliente.telefono.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.phone,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(cliente.telefono),
                          ],
                        ),
                      ],
                      if (cliente.direccion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(child: Text(cliente.direccion)),
                          ],
                        ),
                      ],
                    ],
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
                  activeColor: Theme.of(context).primaryColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAsignacionesTab(ManagerState managerState) {
    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final clientesAsignados = managerState.clientesDelManager;

    if (clientesAsignados.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay asignaciones aún',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Comienza asignando clientes a tus cobradores',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Agrupar clientes por cobrador
    final Map<BigInt, List<Usuario>> clientesPorCobrador = {};
    for (final cliente in clientesAsignados) {
      final cobradorId = cliente.assignedCobradorId;
      if (cobradorId != null) {
        if (!clientesPorCobrador.containsKey(cobradorId)) {
          clientesPorCobrador[cobradorId] = [];
        }
        clientesPorCobrador[cobradorId]!.add(cliente);
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientesPorCobrador.keys.length,
      itemBuilder: (context, index) {
        final cobradorId = clientesPorCobrador.keys.elementAt(index);
        final clientes = clientesPorCobrador[cobradorId]!;
        final cobrador = managerState.cobradoresAsignados.firstWhere(
          (c) => c.id == cobradorId,
        );

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Text(
                cobrador.nombre.isNotEmpty
                    ? cobrador.nombre[0].toUpperCase()
                    : 'C',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              cobrador.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${clientes.length} cliente${clientes.length != 1 ? 's' : ''} asignado${clientes.length != 1 ? 's' : ''}',
            ),
            children: clientes.map((cliente) {
              return ListTile(
                leading: const Icon(Icons.person, color: Colors.grey),
                title: Text(cliente.nombre),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cliente.telefono.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(cliente.telefono),
                        ],
                      ),
                    if (cliente.direccion.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(child: Text(cliente.direccion)),
                        ],
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () =>
                      _mostrarDialogoRemoverAsignacion(cliente, cobrador),
                  tooltip: 'Remover asignación',
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _mostrarDialogoRemoverAsignacion(Usuario cliente, Usuario cobrador) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remover Asignación'),
          content: Text(
            '¿Estás seguro de que quieres remover la asignación del cliente "${cliente.nombre}" del cobrador "${cobrador.nombre}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _removerAsignacion(
                  cliente.id.toString(),
                  cobrador.id.toString(),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Remover',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removerAsignacion(String clienteId, String cobradorId) async {
    try {
      final success = await ref
          .read(clientProvider.notifier)
          .removerClienteDeCobrador(
            cobradorId: cobradorId,
            clientId: clienteId,
          );

      if (success) {
        await _cargarDatosIniciales();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Asignación removida exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al remover asignación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
