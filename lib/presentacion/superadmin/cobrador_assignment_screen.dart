import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../datos/modelos/usuario.dart';

class CobradorAssignmentScreen extends ConsumerStatefulWidget {
  const CobradorAssignmentScreen({super.key});

  @override
  ConsumerState<CobradorAssignmentScreen> createState() =>
      _CobradorAssignmentScreenState();
}

class _CobradorAssignmentScreenState
    extends ConsumerState<CobradorAssignmentScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  Usuario? _cobradorSeleccionado;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarCobradores();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarCobradores() async {
    await ref.read(cobradorAssignmentProvider.notifier).cargarCobradores();
  }

  Future<void> _cargarClientesAsignados() async {
    if (_cobradorSeleccionado != null) {
      await ref
          .read(cobradorAssignmentProvider.notifier)
          .cargarClientesAsignados(_cobradorSeleccionado!.id);
    }
  }

  void _seleccionarCobrador(Usuario cobrador) {
    setState(() {
      _cobradorSeleccionado = cobrador;
    });
    _cargarClientesAsignados();
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(cobradorAssignmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Asignaciones'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cobradores'),
            Tab(text: 'Clientes Asignados'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Lista de Cobradores
          _buildCobradoresTab(assignmentState),

          // Tab 2: Clientes Asignados
          _buildClientesAsignadosTab(assignmentState),
        ],
      ),
    );
  }

  Widget _buildCobradoresTab(CobradorAssignmentState state) {
    return Column(
      children: [
        // Información del cobrador seleccionado
        if (_cobradorSeleccionado != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cobrador Seleccionado:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Text(
                        _cobradorSeleccionado!.nombre,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _cobradorSeleccionado = null;
                    });
                  },
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

        // Lista de cobradores
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.cobradores.isEmpty
              ? const Center(child: Text('No hay cobradores disponibles'))
              : ListView.builder(
                  itemCount: state.cobradores.length,
                  itemBuilder: (context, index) {
                    final cobrador = state.cobradores[index];
                    final isSelected = _cobradorSeleccionado?.id == cobrador.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: isSelected ? Colors.blue[50] : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            cobrador.nombre[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(cobrador.nombre),
                        subtitle: Text(cobrador.email),
                        trailing: isSelected
                            ? const Icon(Icons.check, color: Colors.blue)
                            : null,
                        onTap: () => _seleccionarCobrador(cobrador),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildClientesAsignadosTab(CobradorAssignmentState state) {
    if (_cobradorSeleccionado == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Selecciona un cobrador',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Para ver sus clientes asignados',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header con información del cobrador
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green[50],
          child: Row(
            children: [
              const Icon(Icons.people, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clientes de: ${_cobradorSeleccionado!.nombre}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    Text(
                      'Total: ${state.clientesAsignados.length} clientes',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _cargarClientesAsignados(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
        ),

        // Lista de clientes asignados
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : state.clientesAsignados.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay clientes asignados',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Este cobrador no tiene clientes asignados',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: state.clientesAsignados.length,
                  itemBuilder: (context, index) {
                    final cliente = state.clientesAsignados[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Text(
                            cliente.nombre[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(cliente.nombre),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cliente.email),
                            if (cliente.telefono.isNotEmpty)
                              Text('Tel: ${cliente.telefono}'),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'remove') {
                              _confirmarRemoverCliente(cliente);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.remove_circle, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Remover'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmarRemoverCliente(Usuario cliente) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoción'),
        content: Text(
          '¿Estás seguro de que quieres remover a ${cliente.nombre} de ${_cobradorSeleccionado!.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removerCliente(cliente);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }

  Future<void> _removerCliente(Usuario cliente) async {
    final success = await ref
        .read(cobradorAssignmentProvider.notifier)
        .removerClienteDeCobrador(
          cobradorId: _cobradorSeleccionado!.id,
          clienteId: cliente.id,
        );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cliente.nombre} removido exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _cargarClientesAsignados();
    } else {
      final state = ref.read(cobradorAssignmentProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error ?? 'Error al remover cliente'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
