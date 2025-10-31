import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../reports/reports_screen.dart';

class ManagerReportesScreen extends ConsumerStatefulWidget {
  const ManagerReportesScreen({super.key});

  @override
  ConsumerState<ManagerReportesScreen> createState() =>
      _ManagerReportesScreenState();
}

class _ManagerReportesScreenState extends ConsumerState<ManagerReportesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _cargarDatos();
      }
    });
  }

  void _cargarDatos() async {
    // Evitar llamadas duplicadas
    if (_isLoadingData) {
      debugPrint('⚠️ Ya se está cargando datos, ignorando llamada duplicada');
      return;
    }

    _isLoadingData = true;

    try {
      final authState = ref.read(authProvider);
      if (authState.usuario == null) {
        debugPrint('❌ Usuario no autenticado en _cargarDatos');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario no autenticado'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final managerId = authState.usuario!.id.toString();
      debugPrint('🔄 Iniciando carga de datos para manager ID: $managerId');
      debugPrint(
        '👤 Usuario: ${authState.usuario!.nombre} (${authState.usuario!.email})',
      );
      debugPrint('🎭 Roles: ${authState.usuario!.roles}');

      // Verificar que el usuario es realmente un manager
      if (!authState.isManager) {
        debugPrint('❌ ERROR: El usuario no tiene rol de manager');
        debugPrint('   Roles disponibles: ${authState.usuario!.roles}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: El usuario no tiene permisos de manager'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Establecer el manager actual primero
      ref
          .read(managerProvider.notifier)
          .establecerManagerActual(authState.usuario!);

      // ✅ OPTIMIZACIÓN: Usar estadísticas del login si están disponibles
      if (authState.statistics != null) {
        debugPrint(
          '📊 Usando estadísticas del login (evitando petición innecesaria)',
        );
        ref
            .read(managerProvider.notifier)
            .establecerEstadisticas(authState.statistics!.toCompatibleMap());
      } else {
        debugPrint('📊 Cargando estadísticas del manager desde el backend...');
        await ref
            .read(managerProvider.notifier)
            .cargarEstadisticasManager(managerId);
      }

      debugPrint('👥 Cargando cobradores asignados...');
      await ref
          .read(managerProvider.notifier)
          .cargarCobradoresAsignados(managerId);

      debugPrint('🏢 Cargando clientes del manager...');
      await ref
          .read(managerProvider.notifier)
          .cargarClientesDelManager(managerId);

      debugPrint('✅ Carga de datos completada exitosamente');
    } catch (e) {
      debugPrint('❌ Error cargando datos del manager: $e');
      // Mostrar un SnackBar con el error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLoadingData = false;
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

    // Verificar si hay errores en el estado
    if (managerState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reportes del Equipo')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error: ${managerState.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _cargarDatos,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes del Equipo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
            tooltip: 'Actualizar',
          ),
          /* IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Generador de reportes',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ReportsScreen(userRole: 'manager'),
              ),
            ),
          ), */
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard, color: Colors.white),
              text: 'Resumen',
            ),
            Tab(
              icon: Icon(Icons.person, color: Colors.white),
              text: 'Cobradores',
            ),
            Tab(
              icon: Icon(Icons.business, color: Colors.white),
              text: 'Clientes',
            ),
            Tab(
              icon: Icon(Icons.analytics, color: Colors.white),
              text: 'Generador',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildResumenTab(managerState),
          _buildCobradoresTab(managerState),
          _buildClientesTab(managerState),
          // Embebemos ReportsScreen para que el manager tenga el generador como una pestaña
          const ReportsScreen(userRole: 'manager'),
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
          /* const Text(
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
          const SizedBox(height: 32), */

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

        final cobradorList = managerState.cobradoresAsignados.where(
          (c) => c.id.toString() == cobradorId,
        );
        final cobrador = cobradorList.isNotEmpty ? cobradorList.first : null;

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

                final cobradorList = managerState.cobradoresAsignados.where(
                  (c) => c.id.toString() == cobradorId,
                );
                final cobrador = cobradorList.isNotEmpty
                    ? cobradorList.first
                    : null;

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
