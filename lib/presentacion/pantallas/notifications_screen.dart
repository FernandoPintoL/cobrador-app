import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../widgets/websocket_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(webSocketProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
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
              if (authState.isAdmin) ...[
                const PopupMenuItem(
                  value: 'test_notification',
                  child: Row(
                    children: [
                      Icon(Icons.bug_report),
                      SizedBox(width: 8),
                      Text('Enviar Notificación de Prueba'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
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
                  '${_getFilteredNotifications(wsState, 'payment').length}',
                ),
                child: const Icon(Icons.payment),
              ),
              text: 'Pagos',
            ),
            Tab(
              icon: Badge(
                label: Text(
                  '${_getFilteredNotifications(wsState, 'system').length}',
                ),
                child: const Icon(Icons.settings),
              ),
              text: 'Sistema',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList('all'),
          _buildNotificationsList('unread'),
          _buildNotificationsList('payment'),
          _buildNotificationsList('system'),
        ],
      ),
      floatingActionButton: !wsState.isConnected
          ? FloatingActionButton(
              onPressed: () =>
                  ref.read(webSocketProvider.notifier).connectToWebSocket(),
              backgroundColor: Colors.green,
              child: const Icon(Icons.wifi, color: Colors.white),
              tooltip: 'Reconectar WebSocket',
            )
          : null,
    );
  }

  List<Map<String, dynamic>> _getFilteredNotifications(
    WebSocketState wsState,
    String filter,
  ) {
    switch (filter) {
      case 'unread':
        return wsState.notifications
            .where((n) => !(n['isRead'] ?? false))
            .toList();
      case 'payment':
        return wsState.notifications
            .where(
              (n) =>
                  (n['type']?.toString().contains('payment') ?? false) ||
                  (n['type']?.toString().contains('pago') ?? false),
            )
            .toList();
      case 'system':
        return wsState.notifications
            .where(
              (n) =>
                  (n['type']?.toString().contains('system') ?? false) ||
                  (n['type']?.toString().contains('connection') ?? false),
            )
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
              ref.read(webSocketProvider.notifier).connectToWebSocket();
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
      case 'payment':
        icon = Icons.payment;
        title = 'Sin notificaciones de pagos';
        subtitle = 'Las notificaciones de pagos aparecerán aquí';
        break;
      case 'system':
        icon = Icons.settings;
        title = 'Sin notificaciones del sistema';
        subtitle = 'Las notificaciones del sistema aparecerán aquí';
        break;
      default:
        icon = Icons.notifications_off;
        title = 'Sin notificaciones';
        subtitle = 'Las notificaciones aparecerán aquí cuando lleguen';
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

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isUnread = !(notification['isRead'] ?? false);
    final timestamp =
        DateTime.tryParse(notification['timestamp']?.toString() ?? '') ??
        DateTime.now();
    final timeAgo = _getTimeAgo(timestamp);
    final title = notification['title']?.toString() ?? 'Notificación';
    final message = notification['message']?.toString() ?? '';
    final type = notification['type']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 4 : 1,
      child: InkWell(
        onTap: () => _markAsRead(notification),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isUnread
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icono según el tipo
                  Icon(
                    _getNotificationIcon(type),
                    color: _getNotificationColor(type),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  // Título
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontWeight: isUnread
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Indicador de no leído
                  if (isUnread)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Mensaje
              Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[400]
                      : Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              // Tiempo
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
                  if (type.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getNotificationColor(type).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        _getTypeLabel(type),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getNotificationColor(type),
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
    } else if (type.contains('user') || type.contains('usuario')) {
      return Icons.person;
    } else if (type.contains('credit') || type.contains('credito')) {
      return Icons.credit_card;
    } else if (type.contains('system') || type.contains('connection')) {
      return Icons.settings;
    }
    return Icons.notifications;
  }

  Color _getNotificationColor(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return Colors.green;
    } else if (type.contains('user') || type.contains('usuario')) {
      return Colors.blue;
    } else if (type.contains('credit') || type.contains('credito')) {
      return Colors.orange;
    } else if (type.contains('system') || type.contains('connection')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  String _getTypeLabel(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return 'Pago';
    } else if (type.contains('user') || type.contains('usuario')) {
      return 'Usuario';
    } else if (type.contains('credit') || type.contains('credito')) {
      return 'Crédito';
    } else if (type.contains('system') || type.contains('connection')) {
      return 'Sistema';
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

  void _markAsRead(Map<String, dynamic> notification) {
    // Por ahora solo simularemos marcar como leído localmente
    // En el futuro se puede implementar la funcionalidad en el provider
    if (!(notification['isRead'] ?? false)) {
      setState(() {
        notification['isRead'] = true;
      });
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'mark_all_read':
        // Simular marcar todas como leídas
        final wsState = ref.read(webSocketProvider);
        for (var notification in wsState.notifications) {
          notification['isRead'] = true;
        }
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones marcadas como leídas'),
          ),
        );
        break;
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'test_notification':
        // Esta funcionalidad se puede implementar más tarde
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionalidad en desarrollo')),
        );
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
              // Simular limpiar todas las notificaciones
              final wsState = ref.read(webSocketProvider);
              wsState.notifications.clear();
              setState(() {});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las notificaciones eliminadas'),
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
}
