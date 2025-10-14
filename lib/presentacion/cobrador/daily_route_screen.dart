import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/credito.dart';
import '../cliente/cliente_detalle_screen.dart';
import 'dart:math' show cos, sqrt, asin;

class DailyRouteScreen extends ConsumerStatefulWidget {
  const DailyRouteScreen({super.key});

  @override
  ConsumerState<DailyRouteScreen> createState() => _DailyRouteScreenState();
}

class _DailyRouteScreenState extends ConsumerState<DailyRouteScreen> {
  String _filterOption = 'all'; // 'all', 'overdue', 'today'
  String _sortOption = 'priority'; // 'priority', 'name', 'amount'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.usuario != null) {
        ref.read(creditProvider.notifier).loadCredits(
          cobradorId: authState.usuario!.id.toInt(),
          status: 'active',
        );
      }
    });
  }

  List<Credito> _getSortedAndFilteredCredits(List<Credito> credits) {
    // Filtrar
    List<Credito> filtered = credits.where((credit) {
      if (!credit.isActive) return false;

      switch (_filterOption) {
        case 'overdue':
          return credit.backendIsOverdue == true;
        case 'today':
          // Créditos que deberían pagarse hoy (según frecuencia)
          final today = DateTime.now();
          return credit.frequency == 'daily' ||
              (credit.frequency == 'weekly' && today.weekday == credit.startDate.weekday) ||
              (credit.frequency == 'monthly' && today.day == credit.startDate.day);
        default:
          return true;
      }
    }).toList();

    // Ordenar
    filtered.sort((a, b) {
      switch (_sortOption) {
        case 'priority':
          // Primero los atrasados, luego por monto de mora
          final aOverdue = a.backendIsOverdue == true ? 1 : 0;
          final bOverdue = b.backendIsOverdue == true ? 1 : 0;
          if (aOverdue != bOverdue) return bOverdue.compareTo(aOverdue);

          final aOverdueAmount = a.overdueAmount ?? 0;
          final bOverdueAmount = b.overdueAmount ?? 0;
          return bOverdueAmount.compareTo(aOverdueAmount);

        case 'name':
          final aName = a.client?.nombre ?? '';
          final bName = b.client?.nombre ?? '';
          return aName.compareTo(bName);

        case 'amount':
          return b.balance.compareTo(a.balance);

        default:
          return 0;
      }
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    final credits = creditState.credits;
    final filteredCredits = _getSortedAndFilteredCredits(credits);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta del Día'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros y ordenamiento
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtrar por:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: Text('Todos (${credits.where((c) => c.isActive).length})'),
                      selected: _filterOption == 'all',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterOption = 'all');
                      },
                    ),
                    ChoiceChip(
                      label: Text('Atrasados (${credits.where((c) => c.backendIsOverdue == true).length})'),
                      selected: _filterOption == 'overdue',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterOption = 'overdue');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Pago Hoy'),
                      selected: _filterOption == 'today',
                      onSelected: (selected) {
                        if (selected) setState(() => _filterOption = 'today');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ordenar por:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Prioridad'),
                      selected: _sortOption == 'priority',
                      onSelected: (selected) {
                        if (selected) setState(() => _sortOption = 'priority');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Nombre'),
                      selected: _sortOption == 'name',
                      onSelected: (selected) {
                        if (selected) setState(() => _sortOption = 'name');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Monto'),
                      selected: _sortOption == 'amount',
                      onSelected: (selected) {
                        if (selected) setState(() => _sortOption = 'amount');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Resumen
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? Colors.grey[850] : Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredCredits.length} clientes en ruta',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total: Bs ${filteredCredits.fold<double>(0, (sum, c) => sum + c.balance).toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),

          // Lista de clientes
          Expanded(
            child: creditState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCredits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.route,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay clientes en tu ruta',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredCredits.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final credit = filteredCredits[index];
                          return _buildClientCard(context, credit, index + 1);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(BuildContext context, Credito credit, int position) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOverdue = credit.backendIsOverdue == true;
    final clientName = credit.client?.nombre ?? 'Cliente #${credit.clientId}';
    final clientAddress = credit.client?.direccion ?? 'Sin dirección';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isOverdue
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (credit.client != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClienteDetalleScreen(cliente: credit.client!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Información del cliente no disponible'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con número y estado
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red : Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$position',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          clientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                clientAddress,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ATRASADO',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const Divider(height: 24),

              // Información del crédito
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      'Balance',
                      'Bs ${credit.balance.toStringAsFixed(2)}',
                      Icons.account_balance_wallet,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Cuota',
                      'Bs ${credit.installmentAmount?.toStringAsFixed(2) ?? 'N/A'}',
                      Icons.payments,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      'Frecuencia',
                      credit.frequencyLabel,
                      Icons.calendar_today,
                      Colors.orange,
                    ),
                  ),
                ],
              ),

              if (isOverdue && credit.overdueAmount != null && credit.overdueAmount! > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mora: Bs ${credit.overdueAmount!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Abrir navegación en mapa
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Función de navegación en desarrollo'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.directions, size: 16),
                      label: const Text('Navegar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (credit.client?.telefono != null) {
                          // TODO: Integrar llamada telefónica
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Llamar a ${credit.client!.telefono}'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Llamar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}