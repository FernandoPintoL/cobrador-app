import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/notification_provider.dart';
import '../creditos/credit_detail_screen.dart';
import '../widgets/websocket_widgets.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch notifications from database when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchNotificationsFromDatabase();
    });
  }

  /// Fetch notifications from database
  Future<void> _fetchNotificationsFromDatabase() async {
    final authState = ref.read(authProvider);
    final userId = authState.usuario?.id.toInt();

    if (userId != null) {
      // Fetch both all notifications and unread count
      await ref.read(dbNotificationProvider.notifier).fetchNotifications(
            userId: userId,
            limit: 100,
          );
      await ref.read(dbNotificationProvider.notifier).fetchUnreadCount(userId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsState = ref.watch(webSocketProvider);
    final authState = ref.watch(authProvider); // aún usado para menú admin y estado
    // Ya no usamos tabs superiores; mostraremos una única lista. Si en el futuro
    // se desea filtrar, se podría añadir un filtro en menú.

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        /*backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,*/
        actions: [
          // Estado de conexión WebSocket
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: WebSocketStatusWidget(showAsIcon: true)),
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
      ),
      body: _buildNotificationsList('all'),
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

  /// Merge WebSocket notifications (real-time) with DB notifications (persistent)
  List<AppNotification> _getMergedNotifications(
    WebSocketState wsState,
    DbNotificationState dbState,
  ) {
    print('🔀 Merging notifications...');
    print('  📡 WebSocket notifications: ${wsState.notifications.length}');
    print('  💾 DB notifications: ${dbState.notifications.length}');

    // Create a map to avoid duplicates (use ID as key)
    final Map<String, AppNotification> notificationMap = {};

    // Add DB notifications first (persistent, older ones)
    for (final notification in dbState.notifications) {
      notificationMap[notification.id] = notification;
    }

    // Add WebSocket notifications (real-time, newer ones)
    // These will override DB notifications if they have the same ID
    for (final notification in wsState.notifications) {
      notificationMap[notification.id] = notification;
    }

    // Convert map to list and sort by timestamp (newest first)
    final mergedList = notificationMap.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    print('  ✅ Merged total: ${mergedList.length} notifications');
    return mergedList;
  }

  List<AppNotification> _getFilteredNotifications(
    List<AppNotification> allNotifications,
    String filter,
  ) {
    switch (filter) {
      case 'unread':
        return allNotifications.where((n) => !n.isRead).toList();
      case 'cobrador':
        return allNotifications
            .where(
              (n) =>
                  n.type.contains('cobrador') ||
                  n.type.contains('collector') ||
                  n.message.toLowerCase().contains('cobrador'),
            )
            .toList();
      case 'cliente':
        return allNotifications
            .where(
              (n) =>
                  n.type.contains('client') ||
                  n.type.contains('customer') ||
                  n.message.toLowerCase().contains('cliente'),
            )
            .toList();
      case 'payment':
        return allNotifications
            .where(
              (n) => n.type.contains('payment') || n.type.contains('credit') || n.type.contains('pago'),
            )
            .toList();
      case 'system':
        return allNotifications
            .where(
              (n) => n.type.contains('general') || n.type.contains('message') || n.type.contains('system') || n.type.contains('connection'),
            )
            .toList();
      default:
        return allNotifications;
    }
  }

  Widget _buildNotificationsList(String filter) {
    return Consumer(
      builder: (context, ref, child) {
        final wsState = ref.watch(webSocketProvider);
        final dbState = ref.watch(dbNotificationProvider);

        // Merge notifications from both sources
        final allNotifications = _getMergedNotifications(wsState, dbState);
        final notifications = _getFilteredNotifications(allNotifications, filter);

        // Show loading indicator if DB is still loading and no notifications yet
        if (dbState.isLoading && allNotifications.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (notifications.isEmpty) {
          return _buildEmptyState(filter);
        }

        return RefreshIndicator(
          onRefresh: () async {
            // Refresh both WebSocket connection and DB notifications
            if (!wsState.isConnected) {
              await ref.read(authProvider.notifier).initialize();
            }
            await _fetchNotificationsFromDatabase();
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

  Widget _buildNotificationCard(AppNotification notification) {
    final isUnread = !notification.isRead;
    final timeAgo = _getTimeAgo(notification.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isUnread ? 4 : 1,
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
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
                notification.message,
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
    } else if (type.contains('client') || type.contains('customer') || type.contains('cliente')) {
      return Icons.business;
    } else if (type.contains('user') || type.contains('usuario')) {
      return Icons.person;
    } else if (type.contains('credit') || type.contains('credito')) {
      return Icons.credit_card;
    } else if (type.contains('system') || type.contains('connection') || type.contains('general')) {
      return Icons.settings;
    }
    return Icons.notifications;
  }

  Color _getNotificationColor(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return Colors.green;
    } else if (type.contains('cobrador') || type.contains('collector')) {
      return Colors.blue;
    } else if (type.contains('client') || type.contains('customer') || type.contains('cliente')) {
      return Colors.orange;
    } else if (type.contains('user') || type.contains('usuario')) {
      return Colors.blueGrey;
    } else if (type.contains('credit') || type.contains('credito')) {
      return Colors.purple;
    } else if (type.contains('system') || type.contains('connection') || type.contains('general')) {
      return Colors.grey;
    }
    return Colors.grey;
  }

  String _getTypeLabel(String type) {
    if (type.contains('payment') || type.contains('pago')) {
      return 'Pago';
    } else if (type.contains('cobrador') || type.contains('collector')) {
      return 'Cobrador';
    } else if (type.contains('client') || type.contains('customer') || type.contains('cliente')) {
      return 'Cliente';
    } else if (type.contains('user') || type.contains('usuario')) {
      return 'Usuario';
    } else if (type.contains('credit') || type.contains('credito')) {
      return 'Crédito';
    } else if (type.contains('system') || type.contains('connection') || type.contains('general')) {
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

  void _markAsRead(AppNotification notification) {
    if (!notification.isRead) {
      ref.read(webSocketProvider.notifier).markAsRead(notification.id);
    }
  }

  int? _extractCreditId(AppNotification n) {
    final data = n.data;
    if (data == null) return null;
    try {
      // Common paths: data['credit']['id'] or data['creditId'] or data['credit_id']
      final creditFromObj = data['credit'];
      dynamic idCandidate;
      if (creditFromObj is Map<String, dynamic>) {
        idCandidate = creditFromObj['id'] ?? creditFromObj['credit_id'];
      }
      idCandidate ??= data['creditId'] ?? data['credit_id'];
      if (idCandidate == null) return null;
      final idStr = idCandidate.toString();
      final parsed = int.tryParse(idStr);
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onNotificationTap(AppNotification notification) async {
    // 1) Mark as read
    _markAsRead(notification);

    // 2) Try to open credit detail if this notif relates to a credit
    final creditId = _extractCreditId(notification);
    if (creditId == null) {
      // If not a credit notification, keep default behavior (nothing else)
      return;
    }

    // Optional: quick feedback
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    final loadingSnack = SnackBar(
      content: Text('Abriendo crédito #$creditId...'),
      duration: const Duration(seconds: 2),
    );
    ScaffoldMessenger.of(context).showSnackBar(loadingSnack);

    // 3) Fetch credit details
    final credit = await ref.read(creditProvider.notifier).fetchCreditById(creditId);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (!mounted) return;

    if (credit != null) {
      // 4) Navigate to detail screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreditDetailScreen(credit: credit),
        ),
      );
    } else {
      // Show error if not found
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo abrir el crédito #$creditId'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'mark_all_read':
        // Mark all as read in WebSocket
        ref.read(webSocketProvider.notifier).markAllAsRead();

        // Mark all as read in database
        final authState = ref.read(authProvider);
        final userId = authState.usuario?.id.toInt();
        if (userId != null) {
          await ref.read(dbNotificationProvider.notifier).markAllAsRead(userId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todas las notificaciones marcadas como leídas'),
            ),
          );
        }
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
              // Clear WebSocket notifications
              ref.read(webSocketProvider.notifier).clearNotifications();
              // Clear DB notifications (local state only)
              ref.read(dbNotificationProvider.notifier).clearAll();
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
