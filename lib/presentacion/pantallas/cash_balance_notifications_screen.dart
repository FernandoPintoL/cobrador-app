import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_notification_provider.dart';
import '../widgets/cash_balance_notification_list.dart';

/// Pantalla completa de notificaciones de cajas
/// Muestra todas las notificaciones con estadísticas y opciones de filtrado
class CashBalanceNotificationsScreen extends ConsumerStatefulWidget {
  const CashBalanceNotificationsScreen({super.key});

  @override
  ConsumerState<CashBalanceNotificationsScreen> createState() =>
      _CashBalanceNotificationsScreenState();
}

class _CashBalanceNotificationsScreenState
    extends ConsumerState<CashBalanceNotificationsScreen> {
  String _selectedFilter = 'all'; // all, auto_closed, auto_created, requires_reconciliation

  @override
  Widget build(BuildContext context) {
    // Observar estadísticas
    final totalNotifications = ref.watch(totalCashBalanceNotificationsProvider);
    final autoClosedCount = ref.watch(autoClosedCountProvider);
    final autoCreatedCount = ref.watch(autoCreatedCountProvider);
    final reconciliationCount = ref.watch(cashBalanceReconciliationCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones de Cajas'),
        actions: [
          // Botón de filtro
          if (totalNotifications > 0)
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar',
              onSelected: (value) {
                setState(() {
                  _selectedFilter = value;
                });
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(
                        Icons.list,
                        color: _selectedFilter == 'all' ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Todas'),
                      const Spacer(),
                      Text(
                        '$totalNotifications',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'requires_reconciliation',
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: _selectedFilter == 'requires_reconciliation'
                            ? Colors.orange
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Requieren Conciliación'),
                      const Spacer(),
                      Text(
                        '$reconciliationCount',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'auto_closed',
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        color: _selectedFilter == 'auto_closed' ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Auto-Cerradas'),
                      const Spacer(),
                      Text(
                        '$autoClosedCount',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'auto_created',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: _selectedFilter == 'auto_created' ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text('Auto-Creadas'),
                      const Spacer(),
                      Text(
                        '$autoCreatedCount',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          // Botón limpiar
          if (totalNotifications > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () => _showClearDialog(context),
              tooltip: 'Limpiar todas',
            ),
        ],
      ),
      body: Column(
        children: [
          // Tarjetas de estadísticas
          _buildStatsCards(
            totalNotifications,
            autoClosedCount,
            autoCreatedCount,
            reconciliationCount,
          ),

          // Indicador de filtro activo
          if (_selectedFilter != 'all')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue[50],
              child: Row(
                children: [
                  Icon(Icons.filter_list, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Filtrando: ${_getFilterLabel(_selectedFilter)}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'all';
                      });
                    },
                    child: const Text('Limpiar filtro'),
                  ),
                ],
              ),
            ),

          // Lista de notificaciones
          Expanded(
            child: _buildFilteredList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(
    int total,
    int autoClosed,
    int autoCreated,
    int reconciliation,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard(
            'Total',
            total,
            Icons.notifications,
            Colors.blue,
            onTap: () => setState(() => _selectedFilter = 'all'),
          ),
          _buildStatCard(
            'Auto-Cerradas',
            autoClosed,
            Icons.lock_clock,
            Colors.blue[700]!,
            onTap: () => setState(() => _selectedFilter = 'auto_closed'),
          ),
          _buildStatCard(
            'Auto-Creadas',
            autoCreated,
            Icons.add_circle_outline,
            Colors.green,
            onTap: () => setState(() => _selectedFilter = 'auto_created'),
          ),
          _buildStatCard(
            'Conciliación',
            reconciliation,
            Icons.warning,
            Colors.orange,
            onTap: () => setState(() => _selectedFilter = 'requires_reconciliation'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredList() {
    if (_selectedFilter == 'all') {
      return const CashBalanceNotificationList();
    }

    // Lista filtrada
    return Consumer(
      builder: (context, ref, child) {
        final notifier = ref.read(cashBalanceNotificationProvider.notifier);
        final filteredNotifications =
            notifier.getNotificationsByAction(_selectedFilter);

        if (filteredNotifications.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay notificaciones de tipo\n"${_getFilterLabel(_selectedFilter)}"',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Mostrar lista filtrada usando el mismo widget de lista
        // pero solo con las notificaciones filtradas
        return ListView.builder(
          itemCount: filteredNotifications.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final notification = filteredNotifications[index];
            // Reutilizar el mismo card de CashBalanceNotificationList
            // pero sin acceso directo al método privado _buildNotificationCard
            // Por ahora usamos una versión simplificada
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Icon(
                  _getIconForAction(notification.action),
                  color: _getColorForAction(notification.action),
                ),
                title: Text(notification.actionText),
                subtitle: Text(notification.message),
                trailing: notification.requiresReconciliation
                    ? ElevatedButton(
                        onPressed: () {
                          ref
                              .read(cashBalanceNotificationProvider.notifier)
                              .markAsReconciled(notification.cashBalance.id);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Conciliar'),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  IconData _getIconForAction(String action) {
    switch (action) {
      case 'auto_closed':
        return Icons.lock_clock;
      case 'auto_created':
        return Icons.add_circle_outline;
      case 'requires_reconciliation':
        return Icons.warning_amber;
      default:
        return Icons.info_outline;
    }
  }

  Color _getColorForAction(String action) {
    switch (action) {
      case 'auto_closed':
        return Colors.blue;
      case 'auto_created':
        return Colors.green;
      case 'requires_reconciliation':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'auto_closed':
        return 'Auto-Cerradas';
      case 'auto_created':
        return 'Auto-Creadas';
      case 'requires_reconciliation':
        return 'Requieren Conciliación';
      default:
        return 'Todas';
    }
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar notificaciones'),
        content: Text(
          _selectedFilter == 'all'
              ? '¿Deseas eliminar todas las notificaciones de cajas?'
              : '¿Deseas eliminar las notificaciones de tipo "${_getFilterLabel(_selectedFilter)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              // Limpiar notificaciones según filtro
              if (_selectedFilter == 'all') {
                ref
                    .read(cashBalanceNotificationProvider.notifier)
                    .clearAllNotifications();
              } else {
                ref
                    .read(cashBalanceNotificationProvider.notifier)
                    .clearNotificationsByAction(_selectedFilter);
              }

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notificaciones eliminadas'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
