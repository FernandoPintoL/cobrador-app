import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../datos/modelos/credito.dart';
import 'credit_form_screen.dart';
import 'credit_detail_screen.dart';

class CreditsScreen extends ConsumerStatefulWidget {
  const CreditsScreen({super.key});

  @override
  ConsumerState<CreditsScreen> createState() => _CreditsScreenState();
}

class _CreditsScreenState extends ConsumerState<CreditsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  bool _showOnlyAttention = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    ref.read(creditProvider.notifier).loadCredits();
    ref.read(creditProvider.notifier).loadCreditsRequiringAttention();
    ref.read(creditProvider.notifier).loadCobradorStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    // final authState = ref.watch(authProvider);

    // Listener para mensajes de error y éxito
    ref.listen<CreditState>(creditProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(creditProvider.notifier).clearError();
              },
            ),
          ),
        );
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(creditProvider.notifier).clearSuccess();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mis Créditos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualizar',
          ),
          if (creditState.attentionCredits.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${creditState.attentionCredits.length}'),
                child: const Icon(Icons.warning_amber),
              ),
              onPressed: () {
                setState(() {
                  _showOnlyAttention = !_showOnlyAttention;
                });
              },
              tooltip: 'Créditos que requieren atención',
            ),
        ],
      ),
      body: Column(
        children: [
          // Estadísticas
          if (creditState.stats != null) _buildStatsCard(creditState.stats!),

          // Filtros
          _buildFiltersSection(),

          // Lista de créditos
          Expanded(child: _buildCreditsList(creditState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateCredit(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Crear Crédito',
      ),
    );
  }

  Widget _buildStatsCard(CreditStats stats) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de Créditos',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total',
                      '${stats.totalCredits}',
                      Icons.credit_card,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Activos',
                      '${stats.activeCredits}',
                      Icons.trending_up,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'En Mora',
                      '${stats.defaultedCredits}',
                      Icons.warning,
                      Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Monto Total',
                      NumberFormat.currency(
                        symbol: 'Bs. ',
                      ).format(stats.totalAmount),
                      Icons.attach_money,
                      Colors.purple,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Saldo Pendiente',
                      NumberFormat.currency(
                        symbol: 'Bs. ',
                      ).format(stats.totalBalance),
                      Icons.account_balance_wallet,
                      Colors.orange,
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

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar por cliente...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            onChanged: (_) => _onSearchChanged(),
          ),
          const SizedBox(height: 8),

          // Filtros de estado
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Todos')),
                    DropdownMenuItem(value: 'active', child: Text('Activos')),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text('Completados'),
                    ),
                    DropdownMenuItem(
                      value: 'defaulted',
                      child: Text('En Mora'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'all';
                    });
                    _onFiltersChanged();
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showOnlyAttention = !_showOnlyAttention;
                  });
                },
                icon: Icon(
                  _showOnlyAttention ? Icons.warning : Icons.warning_outlined,
                ),
                label: Text(
                  _showOnlyAttention ? 'Mostrar Todos' : 'Requieren Atención',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _showOnlyAttention ? Colors.orange : null,
                  foregroundColor: _showOnlyAttention ? Colors.white : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsList(CreditState creditState) {
    if (creditState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final credits = _showOnlyAttention
        ? creditState.attentionCredits
        : creditState.credits;

    if (credits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showOnlyAttention ? Icons.check_circle : Icons.credit_card_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _showOnlyAttention
                  ? 'No hay créditos que requieran atención'
                  : 'No tienes créditos registrados',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              _showOnlyAttention
                  ? '¡Excelente! Todos tus créditos están al día.'
                  : 'Presiona el botón + para crear tu primer crédito',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadInitialData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: credits.length,
        itemBuilder: (context, index) {
          final credit = credits[index];
          return _buildCreditCard(credit);
        },
      ),
    );
  }

  Widget _buildCreditCard(Credito credit) {
    final progress = credit.progressPercentage;
    final daysUntilDue = credit.endDate.difference(DateTime.now()).inDays;

    Color statusColor;
    IconData statusIcon;

    if (credit.isCompleted) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (credit.isDefaulted || credit.isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (credit.requiresAttention) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToCreditDetail(credit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con cliente y estado
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credit.client?.nombre ??
                              'Cliente #${credit.clientId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Crédito #${credit.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          credit.statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Información del crédito
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto: ${NumberFormat.currency(symbol: 'Bs. ').format(credit.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Saldo: ${NumberFormat.currency(symbol: 'Bs. ').format(credit.balance)}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Frecuencia: ${credit.frequencyLabel}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Vence: ${DateFormat('dd/MM/yyyy').format(credit.endDate)}',
                          style: TextStyle(
                            color: credit.requiresAttention
                                ? Colors.orange
                                : Colors.grey[600],
                            fontWeight: credit.requiresAttention
                                ? FontWeight.bold
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Barra de progreso
              if (!credit.isCompleted) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.toStringAsFixed(1)}% pagado',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],

              // Alerta si requiere atención
              if (credit.requiresAttention && !credit.isCompleted) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          credit.isOverdue
                              ? 'Crédito vencido hace ${(-daysUntilDue)} días'
                              : 'Vence en ${daysUntilDue} días',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _onSearchChanged() {
    // Implementar búsqueda con debounce si es necesario
    _onFiltersChanged();
  }

  void _onFiltersChanged() {
    final search = _searchController.text.trim();
    final status = _selectedStatus == 'all' ? null : _selectedStatus;

    ref
        .read(creditProvider.notifier)
        .loadCredits(search: search.isEmpty ? null : search, status: status);
  }

  void _navigateToCreateCredit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreditFormScreen()),
    ).then((_) {
      // Recargar créditos después de crear uno nuevo
      _loadInitialData();
    });
  }

  void _navigateToCreditDetail(Credito credit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditDetailScreen(credit: credit),
      ),
    ).then((_) {
      // Recargar créditos después de ver/editar detalles
      _loadInitialData();
    });
  }
}
