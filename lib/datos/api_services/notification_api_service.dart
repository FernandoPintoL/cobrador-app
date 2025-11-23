import 'base_api_service.dart';

/// Servicio para consultar notificaciones desde el backend
class NotificationApiService extends BaseApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  /// Obtener notificaciones del usuario actual
  ///
  /// Parámetros opcionales:
  /// - status: 'unread', 'read', 'archived'
  /// - type: 'payment_received', 'credit_approved', etc.
  /// - limit: cantidad de notificaciones a obtener (por defecto 50)
  Future<Map<String, dynamic>> getNotifications({
    int? userId,
    String? status,
    String? type,
    int limit = 50,
  }) async {
    try {
      // Construir query parameters
      final queryParams = <String, String>{};
      if (userId != null) queryParams['user_id'] = userId.toString();
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;
      queryParams['limit'] = limit.toString();

      final response = await get('/notifications', queryParameters: queryParams);

      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data as Map<String, dynamic>;
        final dataField = responseData['data'];

        // Manejar estructura paginada de Laravel
        List<dynamic> notifications = [];
        if (dataField is Map<String, dynamic>) {
          // Estructura paginada: {current_page, data: [...], per_page, total, last_page}
          notifications = dataField['data'] as List<dynamic>? ?? [];
        } else if (dataField is List) {
          // Estructura simple: data: [...]
          notifications = dataField;
        }

        return {
          'success': true,
          'data': notifications,
          'message': 'Notificaciones obtenidas exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener notificaciones: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
        'data': [],
      };
    }
  }

  /// Marcar notificación como leída
  Future<Map<String, dynamic>> markAsRead(int notificationId) async {
    try {
      final response = await put('/notifications/$notificationId/mark-as-read');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'data': data['data'],
          'message': 'Notificación marcada como leída',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al marcar notificación: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Marcar todas las notificaciones como leídas
  Future<Map<String, dynamic>> markAllAsRead(int userId) async {
    try {
      final response = await post(
        '/notifications/mark-all-as-read',
        data: {'user_id': userId},
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Todas las notificaciones marcadas como leídas',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al marcar notificaciones: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  /// Obtener contador de notificaciones no leídas
  Future<Map<String, dynamic>> getUnreadCount(int userId) async {
    try {
      final response = await get('/notifications/user/$userId/unread-count');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'data': data['data'],
          'unread_count': data['data']?['unread_count'] ?? 0,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener contador: ${response.statusCode}',
          'unread_count': 0,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
        'unread_count': 0,
      };
    }
  }

  /// Obtener notificaciones por usuario
  Future<Map<String, dynamic>> getByUser(int userId) async {
    try {
      final response = await get('/notifications/user/$userId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener notificaciones: ${response.statusCode}',
          'data': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
        'data': [],
      };
    }
  }
}
