import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';

class ManagerReportesScreen extends ConsumerStatefulWidget {
  const ManagerReportesScreen({super.key});

  @override
  ConsumerState<ManagerReportesScreen> createState() =>
      _ManagerReportesScreenState();
}

class _ManagerReportesScreenState extends ConsumerState<ManagerReportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  void _cargarDatos() {
    final authState = ref.read(authProvider);
    if (authState.usuario != null) {
      final managerId = authState.usuario!.id.toString();
      ref
          .read(managerProvider.notifier)
          .establecerManagerActual(authState.usuario!);
      ref.read(managerProvider.notifier).cargarEstadisticasManager(managerId);
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
      ref.read(managerProvider.notifier).cargarClientesDelManager(managerId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes del Equipo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.person), text: 'Cobradores'),
            Tab(icon: Icon(Icons.business), text: 'Clientes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumenTab(managerState),
          _buildCobradoresTab(managerState),
          _buildClientesTab(managerState),
        ],
      ),
    );
  }

  Widget _buildResumenTab(ManagerState managerState) {
    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = managerState.estadisticas ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas principales
          const Text(
            'Estadísticas Generales',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Cobradores',
                '${stats['total_cobradores'] ?? 0}',
                Icons.person,
                Colors.blue,
              ),
              _buildStatCard(
                'Total Clientes',
                '${stats['total_clientes'] ?? 0}',
                Icons.business,
                Colors.green,
              ),
              _buildStatCard(
                'Créditos Activos',
                '${stats['total_creditos'] ?? 0}',
                Icons.account_balance_wallet,
                Colors.orange,
              ),
              _buildStatCard(
                'Cobros del Mes',
                '\$${stats['cobros_mes'] ?? 0}',
                Icons.attach_money,
                Colors.purple,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Distribución de clientes por cobrador
          const Text(
            'Distribución de Clientes',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildDistribucionClientesCard(managerState),
          const SizedBox(height: 32),

          // Rendimiento del equipo
          const Text(
            'Rendimiento del Equipo',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildRendimientoCard(managerState),
        ],
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
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: managerState.cobradoresAsignados.length,
      itemBuilder: (context, index) {
        final cobrador = managerState.cobradoresAsignados[index];
        return _buildCobradorReporteCard(cobrador, managerState);
      },
    );
  }

  Widget _buildClientesTab(ManagerState managerState) {
    if (managerState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Agrupar clientes por cobrador
    final Map<String, List<Usuario>> clientesPorCobrador = {};

    for (final cliente in managerState.clientesDelManager) {
      final cobradorId =
          cliente.assignedCobradorId?.toString() ?? 'sin_asignar';
      if (!clientesPorCobrador.containsKey(cobradorId)) {
        clientesPorCobrador[cobradorId] = [];
      }
      clientesPorCobrador[cobradorId]!.add(cliente);
    }

    if (clientesPorCobrador.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No hay clientes en tu equipo',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientesPorCobrador.keys.length,
      itemBuilder: (context, index) {
        final cobradorId = clientesPorCobrador.keys.elementAt(index);
        final clientes = clientesPorCobrador[cobradorId]!;

        final cobrador = managerState.cobradoresAsignados
            .where((c) => c.id.toString() == cobradorId)
            .firstOrNull;

        return _buildClientesGroupCard(cobrador, clientes);
      },
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
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistribucionClientesCard(ManagerState managerState) {
    // Calcular distribución de clientes por cobrador
    final Map<String, int> distribucion = {};

    for (final cliente in managerState.clientesDelManager) {
      final cobradorId =
          cliente.assignedCobradorId?.toString() ?? 'sin_asignar';
      distribucion[cobradorId] = (distribucion[cobradorId] ?? 0) + 1;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clientes por Cobrador',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (distribucion.isEmpty)
              const Text('No hay datos disponibles')
            else
              ...distribucion.entries.map((entry) {
                final cobradorId = entry.key;
                final clienteCount = entry.value;

                final cobrador = managerState.cobradoresAsignados
                    .where((c) => c.id.toString() == cobradorId)
                    .firstOrNull;

                final nombreCobrador = cobrador?.nombre ?? 'Sin asignar';
                final total = managerState.clientesDelManager.length;
                final porcentaje = total > 0
                    ? (clienteCount / total * 100).toStringAsFixed(1)
                    : '0';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(nombreCobrador)),
                      Expanded(
                        flex: 2,
                        child: LinearProgressIndicator(
                          value: total > 0 ? clienteCount / total : 0,
                          backgroundColor: Colors.grey[300],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('$clienteCount ($porcentaje%)'),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRendimientoCard(ManagerState managerState) {
    final totalCobradores = managerState.cobradoresAsignados.length;
    final totalClientes = managerState.clientesDelManager.length;
    final promedioClientesPorCobrador = totalCobradores > 0
        ? (totalClientes / totalCobradores).toStringAsFixed(1)
        : '0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Indicadores de Rendimiento',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildRendimientoItem(
              'Promedio de clientes por cobrador',
              promedioClientesPorCobrador,
              Icons.analytics,
            ),
            const Divider(),
            _buildRendimientoItem(
              'Cobradores activos',
              '$totalCobradores',
              Icons.person,
            ),
            const Divider(),
            _buildRendimientoItem(
              'Total de clientes gestionados',
              '$totalClientes',
              Icons.business,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRendimientoItem(String titulo, String valor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(titulo)),
          Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCobradorReporteCard(
    Usuario cobrador,
    ManagerState managerState,
  ) {
    // Contar clientes del cobrador
    final clientesCobrador = managerState.clientesDelManager
        .where((c) => c.assignedCobradorId == cobrador.id)
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            cobrador.nombre.isNotEmpty ? cobrador.nombre[0].toUpperCase() : 'C',
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(cobrador.email),
            Text(
              '$clientesCobrador cliente${clientesCobrador != 1 ? 's' : ''} asignado${clientesCobrador != 1 ? 's' : ''}',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              clientesCobrador > 0 ? Icons.check_circle : Icons.warning,
              color: clientesCobrador > 0 ? Colors.green : Colors.orange,
            ),
            Text(
              clientesCobrador > 0 ? 'Activo' : 'Sin clientes',
              style: TextStyle(
                fontSize: 12,
                color: clientesCobrador > 0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientesGroupCard(Usuario? cobrador, List<Usuario> clientes) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            cobrador?.nombre.isNotEmpty == true
                ? cobrador!.nombre[0].toUpperCase()
                : 'S',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cobrador?.nombre ?? 'Sin cobrador asignado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${clientes.length} cliente${clientes.length != 1 ? 's' : ''}',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: clientes.map((cliente) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.person, size: 20),
                  title: Text(cliente.nombre),
                  subtitle: Text(cliente.email),
                  trailing: Text(
                    cliente.telefono.isNotEmpty
                        ? cliente.telefono
                        : 'Sin teléfono',
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
