import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/auth_provider.dart';

/// Widget que muestra el estado de conexión WebSocket
class WebSocketStatusWidget extends ConsumerWidget {
  final bool showAsIcon;
  final bool showText;

  const WebSocketStatusWidget({
    super.key,
    this.showAsIcon = true,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsState = ref.watch(webSocketProvider);

    if (showAsIcon) {
      return _buildIconStatus(context, wsState);
    } else {
      return _buildTextStatus(context, wsState);
    }
  }

  Widget _buildIconStatus(BuildContext context, WebSocketState wsState) {
    IconData icon;
    Color color;
    String tooltip;

    if (wsState.isConnecting) {
      icon = Icons.sync;
      color = Colors.orange;
      tooltip = 'Conectando...';
    } else if (wsState.isConnected) {
      icon = Icons.wifi;
      color = Colors.green;
      tooltip = 'Conectado en tiempo real';
    } else {
      icon = Icons.wifi_off;
      color = Colors.red;
      tooltip = 'Sin conexión en tiempo real';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildTextStatus(BuildContext context, WebSocketState wsState) {
    String text;
    Color color;

    if (wsState.isConnecting) {
      text = 'Conectando...';
      color = Colors.orange;
    } else if (wsState.isConnected) {
      text = 'En línea';
      color = Colors.green;
    } else {
      text = 'Sin conexión';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            wsState.isConnected ? Icons.circle : Icons.circle_outlined,
            color: color,
            size: 8,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Provider para verificar si hay notificaciones no leídas
final unreadNotificationsProvider = Provider<int>((ref) {
  final wsState = ref.watch(webSocketProvider);
  return wsState.notifications.where((n) => !n.isRead).length;
});

/// Widget de notificaciones en tiempo real
class RealtimeNotificationBadge extends ConsumerWidget {
  final Widget child;

  const RealtimeNotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationsProvider);

    if (unreadCount == 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          right: -6,
          top: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
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
    );
  }
}

/// Widget compacto para mostrar resumen de notificaciones en dashboards
class NotificationsSummaryCard extends ConsumerWidget {
  const NotificationsSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsState = ref.watch(webSocketProvider);
    final unreadCount = wsState.notifications.where((n) => !n.isRead).length;
    final totalCount = wsState.notifications.length;

    return Card(
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/notifications'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_active,
                    color: unreadCount > 0
                        ? Colors.red
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[400]
                              : Colors.grey),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Notificacioness',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (totalCount == 0)
                const Text(
                  'No hay notificaciones',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                Text(
                  '$totalCount ${totalCount == 1 ? 'notificación' : 'notificaciones'}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (unreadCount > 0)
                  Text(
                    '$unreadCount sin leer',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              // Mostrar la notificación más reciente
              if (wsState.notifications.isNotEmpty) ...[
                const Divider(),
                const Text(
                  'Más reciente:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wsState.notifications.first.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  wsState.notifications.first.message,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget para mostrar notificaciones en tiempo real
class RealtimeNotificationsPanel extends ConsumerStatefulWidget {
  const RealtimeNotificationsPanel({super.key});

  @override
  ConsumerState<RealtimeNotificationsPanel> createState() =>
      _RealtimeNotificationsPanelState();
}

class _RealtimeNotificationsPanelState
    extends ConsumerState<RealtimeNotificationsPanel> {
  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(webSocketProvider);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.notifications_active),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Notificaciones en Tiempo Real',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const WebSocketStatusWidget(showAsIcon: false),
              ],
            ),
          ),
          const Divider(height: 1),
          if (wsState.notifications.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No hay notificaciones',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: wsState.notifications.length,
                itemBuilder: (context, index) {
                  final notification = wsState.notifications[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationColor(notification.type),
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(notification.message),
                    trailing: Text(
                      _formatTimestamp(notification.timestamp),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    dense: true,
                  );
                },
              ),
            ),
          if (wsState.notifications.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: TextButton(
                  onPressed: () {
                    ref.read(webSocketProvider.notifier).clearNotifications();
                  },
                  child: const Text('Limpiar Notificaciones'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getNotificationColor(String type) {
    if (type.contains('credit')) {
      return Colors.green;
    } else if (type.contains('payment')) {
      return Colors.blue;
    } else if (type.contains('urgent')) {
      return Colors.red;
    } else if (type.contains('route')) {
      return Colors.orange;
    } else if (type.contains('message')) {
      return Colors.purple;
    }
    return Colors.grey;
  }

  IconData _getNotificationIcon(String type) {
    if (type.contains('credit')) {
      return Icons.attach_money;
    } else if (type.contains('payment')) {
      return Icons.payment;
    } else if (type.contains('urgent')) {
      return Icons.warning;
    } else if (type.contains('route')) {
      return Icons.map;
    } else if (type.contains('message')) {
      return Icons.message;
    }
    return Icons.notifications;
  }

  String _formatTimestamp(DateTime timestamp) {
    try {
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      if (difference.inMinutes < 1) {
        return 'Ahora';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h';
      } else {
        return '${difference.inDays}d';
      }
    } catch (e) {
      return '';
    }
  }
}

/// Botón para probar el WebSocket
class WebSocketTestButton extends ConsumerWidget {
  const WebSocketTestButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wsState = ref.watch(webSocketProvider);

    return PopupMenuButton<String>(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Pruebas WebSocket',
      onSelected: (value) => _handleTestAction(context, ref, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'connect',
          enabled: !wsState.isConnected && !wsState.isConnecting,
          child: const Row(
            children: [
              Icon(Icons.wifi, color: Colors.green),
              SizedBox(width: 8),
              Text('Conectar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'disconnect',
          enabled: wsState.isConnected,
          child: const Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.red),
              SizedBox(width: 8),
              Text('Desconectar'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'test_notification',
          child: Row(
            children: [
              Icon(Icons.notifications),
              SizedBox(width: 8),
              Text('Enviar Notificación'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'test_payment',
          child: Row(
            children: [
              Icon(Icons.payment),
              SizedBox(width: 8),
              Text('Simular Pago'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleTestAction(BuildContext context, WidgetRef ref, String action) {
    final wsNotifier = ref.read(webSocketProvider.notifier);

    switch (action) {
      case 'connect':
        // Reconectar a través del auth provider
        ref.read(authProvider.notifier).initialize();
        break;
      case 'disconnect':
        wsNotifier.disconnect();
        break;
      case 'test_notification':
        wsNotifier.addTestNotification(
          title: 'Notificación de Prueba',
          message: 'Esta es una notificación de prueba generada localmente',
          type: 'test',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación de prueba creada')),
        );
        break;
      case 'test_payment':
        wsNotifier.addTestNotification(
          title: 'Pago Recibido',
          message:
              'Se ha recibido un pago de Bs. 500.00 del cliente Juan Pérez',
          type: 'payment',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notificación de pago simulada')),
        );
        break;
    }
  }
}
