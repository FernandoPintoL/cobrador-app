import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/api_services/notification_api_service.dart';
import 'websocket_provider.dart';

/// Estado para notificaciones de base de datos
class DbNotificationState {
  final bool isLoading;
  final String? errorMessage;
  final List<AppNotification> notifications;
  final int unreadCount;

  const DbNotificationState({
    this.isLoading = false,
    this.errorMessage,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  DbNotificationState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AppNotification>? notifications,
    int? unreadCount,
  }) {
    return DbNotificationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifier para manejar notificaciones desde la base de datos
class DbNotificationNotifier extends StateNotifier<DbNotificationState> {
  final NotificationApiService _service;

  DbNotificationNotifier(this._service) : super(const DbNotificationState());

  /// Obtener notificaciones del usuario desde la BD
  Future<void> fetchNotifications({
    required int userId,
    String? status,
    String? type,
    int limit = 50,
  }) async {
    print('📡 DbNotificationProvider: Fetching notifications for user $userId');
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _service.getNotifications(
        userId: userId,
        status: status,
        type: type,
        limit: limit,
      );

      print('📥 DbNotificationProvider: Response success=${response['success']}');

      if (response['success'] == true) {
        final data = response['data'] as List<dynamic>;
        print('📊 DbNotificationProvider: Received ${data.length} notifications from API');

        final notifications = _convertToAppNotifications(data);
        print('✅ DbNotificationProvider: Converted to ${notifications.length} AppNotifications');

        state = state.copyWith(
          isLoading: false,
          notifications: notifications,
          errorMessage: null,
        );

        print('🔄 DbNotificationProvider: State updated with ${state.notifications.length} notifications');
      } else {
        final errorMsg = response['message'] as String?;
        print('❌ DbNotificationProvider: Error - $errorMsg');
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMsg,
        );
      }
    } catch (e, stackTrace) {
      print('❌ DbNotificationProvider: Exception - $e');
      print('Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar notificaciones: ${e.toString()}',
      );
    }
  }

  /// Obtener contador de notificaciones no leídas
  Future<void> fetchUnreadCount(int userId) async {
    try {
      final response = await _service.getUnreadCount(userId);

      if (response['success'] == true) {
        final count = response['unread_count'] as int? ?? 0;
        state = state.copyWith(unreadCount: count);
      }
    } catch (e) {
      // Silently fail, unread count is not critical
    }
  }

  /// Marcar notificación como leída
  Future<bool> markAsRead(int notificationId) async {
    try {
      final response = await _service.markAsRead(notificationId);
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<bool> markAllAsRead(int userId) async {
    try {
      final response = await _service.markAllAsRead(userId);

      if (response['success'] == true) {
        // Actualizar estado local: marcar todas como leídas
        final updatedNotifications = state.notifications
            .map((n) => n.copyWith(isRead: true))
            .toList();

        state = state.copyWith(
          notifications: updatedNotifications,
          unreadCount: 0,
        );

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Limpiar todas las notificaciones (solo del estado local)
  void clearAll() {
    state = state.copyWith(
      notifications: [],
      unreadCount: 0,
    );
  }

  /// Convertir datos de la API a AppNotification
  List<AppNotification> _convertToAppNotifications(List<dynamic> data) {
    print('🔄 Converting ${data.length} notifications...');

    final converted = data.map((item) {
      final notification = item as Map<String, dynamic>;

      // Extraer información
      final id = notification['id']?.toString() ?? '';
      final type = notification['type'] as String? ?? 'system_alert';
      final message = notification['message'] as String? ?? '';
      final status = notification['status'] as String? ?? 'unread';
      final createdAt = notification['created_at'] as String?;

      print('  📋 Converting notification: id=$id, type=$type, status=$status');

      // Parsear timestamp
      DateTime timestamp;
      try {
        timestamp = createdAt != null
            ? DateTime.parse(createdAt)
            : DateTime.now();
      } catch (e) {
        print('  ⚠️ Error parsing timestamp for notification $id: $e');
        timestamp = DateTime.now();
      }

      // Generar título basado en el tipo
      String title = _getTitleFromType(type);

      return AppNotification(
        id: id,
        type: type,
        title: title,
        message: message,
        data: notification,
        timestamp: timestamp,
        isRead: status == 'read',
      );
    }).toList();

    print('✅ Conversion complete: ${converted.length} AppNotifications created');
    return converted;
  }

  /// Genera un título legible basado en el tipo de notificación
  String _getTitleFromType(String type) {
    switch (type) {
      case 'payment_received':
        return 'Pago Recibido';
      case 'cobrador_payment_received':
        return 'Pago Registrado';
      case 'payment_due':
        return 'Pago Pendiente';
      case 'credit_approved':
        return 'Crédito Aprobado';
      case 'credit_rejected':
        return 'Crédito Rechazado';
      case 'system_alert':
        return 'Alerta del Sistema';
      default:
        return 'Notificación';
    }
  }
}

/// Provider para notificaciones de base de datos
final dbNotificationProvider =
    StateNotifierProvider<DbNotificationNotifier, DbNotificationState>((ref) {
  return DbNotificationNotifier(NotificationApiService());
});
