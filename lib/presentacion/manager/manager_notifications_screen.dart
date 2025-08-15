import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/manager_provider.dart';
import '../widgets/websocket_widgets.dart';

class ManagerNotificationsScreen extends ConsumerStatefulWidget {
  const ManagerNotificationsScreen({super.key});

  @override
  ConsumerState<ManagerNotificationsScreen> createState() =>
      _ManagerNotificationsScreenState();
}

class _ManagerNotificationsScreenState
    extends ConsumerState<ManagerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(webSocketProvider);
    final managerState = ref.watch(managerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones Manager',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          // Estado de conexión WebSocket
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: const WebSocketStatusWidget(showAsIcon: true)),
          ),
          // Menú de opciones
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read),
                    SizedBox(width: 8),
                    Text('Marcar todas como leídas'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Limpiar todas'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Configurar Notificaciones'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: [
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredNotifications(wsState, 'all').length}',
                ),
                child: const Icon(Icons.all_inbox),
              ),
              text: 'Todas',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredNotifications(wsState, 'unread').length}',
                ),
                child: const Icon(Icons.mark_email_unread),
              ),
              text: 'Sin Leer',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredNotifications(wsState, 'cobrador').length}',
                ),
                child: const Icon(Icons.person_pin),
              ),
              text: 'Cobradores',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredNotifications(wsState, 'cliente').length}',
                ),
                child: const Icon(Icons.business),
              ),
              text: 'Clientes',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredNotifications(wsState, 'payment').length}',
                ),
                child: const Icon(Icons.payment),
              ),
              text: 'Pagos',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Panel de estadísticas rápidas
          _buildStatsPanel(managerState, wsState),

          // Contenido de las tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationsList('all'),
                _buildNotificationsList('unread'),
                _buildNotificationsList('cobrador'),
                _buildNotificationsList('cliente'),
                _buildNotificationsList('payment'),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !wsState.isConnected
          ? FloatingActionButton(
              onPressed: () async {
                await ref.read(authProvider.notifier).initialize();
              },
              backgroundColor: Colors.green,
              child: const Icon(Icons.wifi, color: Colors.white),
              tooltip: 'Reconectar WebSocket',
            )
          : null,
    );
  }

  Widget _buildStatsPanel(ManagerState managerState, WebSocketState wsState) {
    final totalNotifications = wsState.notifications.length;
    final unreadNotifications = wsState.notifications
        .where((n) => !n.isRead)
        .length;
    final totalCobradores = managerState.cobradoresAsignados.length;
    final totalClientes = managerState.clientesDelManager.length;

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de tu Equipo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Notificaciones',
                      totalNotifications.toString(),
                      unreadNotifications > 0
                          ? '$unreadNotifications sin leer'
                          : 'Todas leídas',
                      Icons.notifications,
                      unreadNotifications > 0 ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Cobradores',
                      totalCobradores.toString(),
                      'En tu equipo',
                      Icons.person_pin,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Clientes',
                      totalClientes.toString(),
                      'Asignados',
                      Icons.business,
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

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
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
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  List<AppNotification> _getFilteredNotifications(
    WebSocketState wsState,
    String filter,
  ) {
    switch (filter) {
      case 'unread':
        return wsState.notifications.where((n) => !n.isRead).toList();
      case 'cobrador':
        return wsState.notifications
            .where(
              (n) =>
                  n.type.contains('cobrador') ||
                  n.type.contains('collector') ||
                  n.message.toLowerCase().contains('cobrador'),
            )
            .toList();
      case 'cliente':
        return wsState.notifications
            .where(
              (n) =>
                  n.type.contains('client') ||
                  n.type.contains('customer') ||
                  n.message.toLowerCase().contains('cliente'),
            )
            .toList();
      case 'payment':
        return wsState.notifications
            .where((n) => n.type.contains('payment') || n.type.contains('pago'))
            .toList();
      default:
        return wsState.notifications;
    }
  }

  Widget _buildNotificationsList(String filter) {
    return Consumer(
      builder: (context, ref, child) {
        final wsState = ref.watch(webSocketProvider);
        final notifications = _getFilteredNotifications(wsState, filter);

        if (notifications.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Reconectar WebSocket si está desconectado
            if (!wsState.isConnected) {
              await ref.read(authProvider.notifier).initialize();
            }

            // Recargar datos del manager
            final authState = ref.read(authProvider);
            if (authState.usuario != null) {
              final managerId = authState.usuario!.id.toString();
              ref
                  .read(managerProvider.notifier)
                  .cargarCobradoresAsignados(managerId);
              ref
                  .read(managerProvider.notifier)
                  .cargarClientesDelManager(managerId);
            }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String filter) {
    IconData icon;
    String title;
    String subtitle;

    switch (filter) {
      case 'unread':
        icon = Icons.mark_email_read;
        title = '¡Excelente!';
        subtitle = 'No tienes notificaciones sin leer';
        break;
      case 'cobrador':
        icon = Icons.person_pin;
        title = 'Sin notificaciones de cobradores';
        subtitle =
            'Las notificaciones de tu equipo de cobradores aparecerán aquí';
        break;
      case 'cliente':
        icon = Icons.business;
        title = 'Sin notificaciones de clientes';
        subtitle =
            'Las notificaciones relacionadas con clientes aparecerán aquí';
        break;
      case 'payment':
        icon = Icons.payment;
        title = 'Sin notificaciones de pagos';
        subtitle = 'Las notificaciones de pagos de tu equipo aparecerán aquí';
        break;
      default:
        icon = Icons.notifications_off;
        title = 'Sin notificaciones';
        subtitle =
            'Las notificaciones de gestión aparecerán aquí cuando lleguen';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[600]
                : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[500]
                  : Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
    final isUnread = !notification.isRead;
    final timeAgo = _getTimeAgo(notification.timestamp);
    final priority = notification.data?['priority']?.toString() ?? 'normal';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 4 : 1,
      child: InkWell(
        onTap: () => _markAsRead(notification),
        onLongPress: () => _showNotificationActions(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(color: _getPriorityColor(priority), width: 2)
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono según el tipo
                  Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // Título
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 16,
                        color: priority == 'high' ? Colors.red[700] : null,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Indicador de prioridad
                  if (priority == 'high')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'URGENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Indicador de no leído
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Mensaje
              Text(
                notification.message,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Tiempo y tipo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[500],
                    ),
                  ),
                  if (notification.type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(
                          notification.type,
                        ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getNotificationColor(
                            notification.type,
                          ).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getTypeLabel(notification.type),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getNotificationColor(notification.type),
                          fontWeight: FontWeight.bold,
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

  IconData _getNotificationIcon(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return Icons.payment;
    } else if (type.contains('cobrador') || type.contains('collector')) {
      return Icons.person_pin;
    } else if (type.contains('client') || type.contains('customer')) {
      return Icons.business;
    } else if (type.contains('credit') || type.contains('credito')) {
      return Icons.credit_card;
    } else if (type.contains('system') || type.contains('connection')) {
      return Icons.settings;
    } else if (type.contains('team') || type.contains('equipo')) {
      return Icons.group;
    }
    return Icons.notifications;
  }

  Color _getNotificationColor(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return Colors.green;
    } else if (type.contains('cobrador') || type.contains('collector')) {
      return Colors.blue;
    } else if (type.contains('client') || type.contains('customer')) {
      return Colors.orange;
    } else if (type.contains('credit') || type.contains('credito')) {
      return Colors.purple;
    } else if (type.contains('system') || type.contains('connection')) {
      return Colors.grey;
    } else if (type.contains('team') || type.contains('equipo')) {
      return Colors.teal;
    }
    return Colors.indigo;
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getTypeLabel(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return 'Pago';
    } else if (type.contains('cobrador') || type.contains('collector')) {
      return 'Cobrador';
    } else if (type.contains('client') || type.contains('customer')) {
      return 'Cliente';
    } else if (type.contains('credit') || type.contains('credito')) {
      return 'Crédito';
    } else if (type.contains('system') || type.contains('connection')) {
      return 'Sistema';
    } else if (type.contains('team') || type.contains('equipo')) {
      return 'Equipo';
    }
    return 'General';
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes}m';
    } else {
      return 'Ahora mismo';
    }
  }

  void _markAsRead(AppNotification notification) {
    if (!notification.isRead) {
      ref.read(webSocketProvider.notifier).markAsRead(notification.id);

      // Mostrar feedback visual
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notificación marcada como leída'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showNotificationActions(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: Text(
                notification.isRead
                    ? 'Marcar como no leída'
                    : 'Marcar como leída',
              ),
              onTap: () {
                Navigator.pop(context);
                ref
                    .read(webSocketProvider.notifier)
                    .markAsRead(notification.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(notification);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Mensaje:'),
              Text(notification.message),
              const SizedBox(height: 8),
              Text('Tipo:'),
              Text(notification.type),
              const SizedBox(height: 8),
              Text('Fecha:'),
              Text(_getTimeAgo(notification.timestamp)),
              if (notification.data != null) ...[
                const SizedBox(height: 8),
                Text('Datos adicionales:'),
                Text(notification.data.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        ref.read(webSocketProvider.notifier).markAllAsRead();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        _showNotificationSettings();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar Notificaciones'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las notificaciones? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(webSocketProvider.notifier).clearNotifications();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las notificaciones eliminadas'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              'Eliminar Todo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuración de Notificaciones'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Configuración de notificaciones para managers'),
            SizedBox(height: 16),
            Text('• Notificaciones de equipo'),
            Text('• Alertas de pagos'),
            Text('• Actualizaciones de clientes'),
            Text('• Notificaciones del sistema'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuración guardada'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
