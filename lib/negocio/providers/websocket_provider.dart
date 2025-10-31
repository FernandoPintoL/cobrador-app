import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../datos/api_services/websocket_service.dart';
import '../../datos/api_services/notification_service.dart';
import '../../datos/modelos/websocket_stats.dart';

// Modelo para notificaciones
class AppNotification {
  final String id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.timestamp,
    this.isRead = false,
  });

  AppNotification copyWith({
    String? id,
    String? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Estado del WebSocket con notificaciones mejoradas
class WebSocketState {
  final bool isConnected;
  final bool isConnecting;
  final String? lastError;
  final List<AppNotification> notifications;
  final Map<String, dynamic>? lastPaymentUpdate;
  final Map<String, dynamic>? lastLocationUpdate;

  // Estadísticas en tiempo real
  final GlobalStats? globalStats;
  final CobradorStats? cobradorStats;
  final ManagerStats? managerStats;

  const WebSocketState({
    this.isConnected = false,
    this.isConnecting = false,
    this.lastError,
    this.notifications = const [],
    this.lastPaymentUpdate,
    this.lastLocationUpdate,
    this.globalStats,
    this.cobradorStats,
    this.managerStats,
  });

  WebSocketState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? lastError,
    List<AppNotification>? notifications,
    Map<String, dynamic>? lastPaymentUpdate,
    Map<String, dynamic>? lastLocationUpdate,
    GlobalStats? globalStats,
    CobradorStats? cobradorStats,
    ManagerStats? managerStats,
  }) {
    return WebSocketState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      lastError: lastError,
      notifications: notifications ?? this.notifications,
      lastPaymentUpdate: lastPaymentUpdate ?? this.lastPaymentUpdate,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
      globalStats: globalStats ?? this.globalStats,
      cobradorStats: cobradorStats ?? this.cobradorStats,
      managerStats: managerStats ?? this.managerStats,
    );
  }
}

/// Provider para WebSocket mejorado
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final WebSocketService _wsService = WebSocketService();
  final NotificationService _notificationService = NotificationService();

  // Subscriptions
  StreamSubscription<bool>? _connSub;
  StreamSubscription<Map<String, dynamic>>? _notifSub;
  StreamSubscription<Map<String, dynamic>>? _paymentSub;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _locationSub;
  StreamSubscription<Map<String, dynamic>>? _routeSub;

  // Subscriptions para estadísticas
  StreamSubscription<Map<String, dynamic>>? _globalStatsSub;
  StreamSubscription<Map<String, dynamic>>? _cobradorStatsSub;
  StreamSubscription<Map<String, dynamic>>? _managerStatsSub;

  WebSocketNotifier() : super(const WebSocketState()) {
    _initializeNotifications();
    _setupWebSocketListeners();
  }

  /// Inicializa el servicio de notificaciones
  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      print('✅ Servicio de notificaciones inicializado');
    } catch (e) {
      print('⚠️ Error inicializando notificaciones: $e');
    }
  }

  /// Conectar WebSocket con datos del usuario (evita dependencia a authProvider)
  Future<void> connectWithUser({
    required String userId,
    required String userType,
    String? userName,
  }) async {
    state = state.copyWith(isConnecting: true, lastError: null);

    try {
      // Conectar al servidor (la URL debe haberse configurado previamente desde la app)
      final connected = await _wsService.connect();

      if (connected) {
        // Autenticar usuario en el canal WS
        await _wsService.authenticate(
          userId: userId,
          userName: userName ?? userId,
          userType: userType,
        );
      }

      // Verificar conexión después de un breve delay
      await Future.delayed(const Duration(milliseconds: 500));

      state = state.copyWith(
        isConnected: _wsService.isConnected,
        isConnecting: false,
        lastError: null,
      );

      if (kDebugMode) {
        print('🔌 WebSocket conectado: ${_wsService.isConnected} como $userType');
      }
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        lastError: 'Error conectando WebSocket: $e',
      );

      if (kDebugMode) {
        print('❌ Error en WebSocket connect: $e');
      }
    }
  }

  /// Configurar listeners de WebSocket mediante streams
  void _setupWebSocketListeners() {
    // Estado de conexión
    _connSub = _wsService.connectionStream.listen((connected) {
      state = state.copyWith(isConnected: connected, isConnecting: false);
    });

    // Notificaciones generales/crediticias
    _notifSub = _wsService.notificationStream.listen((data) {
      if (data.isEmpty) return;

      // Determinar el tipo de notificación
      final type = (data['type'] ?? data['action'] ?? 'general').toString();

      if (type.contains('credit') || data.containsKey('credit') || data.containsKey('action')) {
        final action = data['action'] ?? 'actualizado';
        final clientName = data['credit']?['client_name'] ?? data['credit']?['client']?['name'] ?? 'Cliente';
        final creditId = data['credit']?['id']?.toString() ?? data['creditId']?.toString() ?? 'N/A';
        final amount = data['credit']?['amount']?.toString() ?? '';

        String actionText;
        String title;
        String message;

        switch (action) {
          case 'created':
            actionText = 'creado';
            title = '📄 Nuevo Crédito Creado';
            message = 'Crédito #$creditId $actionText para $clientName${amount.isNotEmpty ? ' por $amount Bs' : ''}';
            break;
          case 'approved':
            actionText = 'aprobado';
            title = '✅ Crédito Aprobado - Pendiente de Entrega';
            // Determinar si es entrega inmediata
            bool isImmediate = false;
            try {
              isImmediate = (data['entrega_inmediata'] == true) ||
                  (data['immediate_delivery_requested'] == true) ||
                  (data['credit'] is Map && data['credit']['entrega_inmediata'] == true) ||
                  (data['credit'] is Map && data['credit']['immediate_delivery_requested'] == true) ||
                  (data['credit'] is Map && data['credit']['immediate_delivery'] == true) ||
                  (data['credit'] is Map && data['credit']['immediateDelivery'] == true);
            } catch (_) {}

            // Mensaje según tipo de entrega
            if (isImmediate) {
              message = 'Tu crédito de ${amount.isNotEmpty ? '$amount Bs' : 'N/A'} ha sido aprobado. Debes entregar el dinero al cliente HOY.';
            } else {
              final scheduledDate = data['scheduled_delivery_date'] ?? data['credit']?['scheduled_delivery_date'];
              if (scheduledDate != null) {
                message = 'Tu crédito de ${amount.isNotEmpty ? '$amount Bs' : 'N/A'} ha sido aprobado. Entregar el $scheduledDate.';
              } else {
                message = 'Tu crédito de ${amount.isNotEmpty ? '$amount Bs' : 'N/A'} ha sido aprobado. Confirma la entrega física para activar el crédito.';
              }
            }
            break;
          case 'delivered':
            actionText = 'entregado y activado';
            title = '🚚 Crédito Entregado y Activado';
            // Mensaje para el manager que indica que el cronograma ha comenzado
            final cobradorName = data['cobrador_name'] ?? data['cobradorName'] ?? data['delivered_by_name'] ?? 'El cobrador';
            message = '$cobradorName ha entregado físicamente el crédito de ${amount.isNotEmpty ? '$amount Bs' : 'N/A'} a $clientName. El crédito está ahora ACTIVO y el cronograma de pagos ha comenzado.';
            break;
          case 'completed':
            actionText = 'completado';
            title = '🎉 Crédito Completado';
            message = 'Crédito #$creditId $actionText para $clientName${amount.isNotEmpty ? ' por $amount Bs' : ''}';
            break;
          case 'defaulted':
            actionText = 'en mora';
            title = '⚠️ Crédito en Mora';
            message = 'Crédito #$creditId $actionText para $clientName${amount.isNotEmpty ? ' por $amount Bs' : ''}';
            break;
          case 'requires_attention':
            actionText = 'requiere atención';
            title = '🔔 Atención Requerida';
            message = 'Crédito #$creditId $actionText para $clientName${amount.isNotEmpty ? ' por $amount Bs' : ''}';
            break;
          default:
            actionText = action.toString();
            title = '📄 Actualización de Crédito';
            message = 'Crédito #$creditId $actionText para $clientName${amount.isNotEmpty ? ' por $amount Bs' : ''}';
        }

        // Mostrar notificación local
        _notificationService.showCreditNotification(
          title: title,
          body: message,
          creditId: creditId,
          action: action,
        );

        _addNotification(
          AppNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'credit',
            title: title,
            message: message,
            data: data,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        final title = data['title'] ?? 'Notificación';
        final message = data['message'] ?? 'Nueva notificación';

        // Mostrar notificación local general
        _notificationService.showGeneralNotification(
          title: '🔔 $title',
          body: message,
          type: type,
          payload: data.toString(),
        );

        _addNotification(
          AppNotification(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: 'general',
            title: '🔔 $title',
            message: message,
            data: data,
            timestamp: DateTime.now(),
          ),
        );
      }
    });

    // Actualizaciones de pagos
    _paymentSub = _wsService.paymentStream.listen((data) {
      final paymentAmount = data['amount']?.toString() ?? data['payment']?['amount']?.toString() ?? 'N/A';
      final clientName = data['client']?['name'] ?? data['payment']?['client_name'] ?? 'Cliente';
      final paymentId = data['id']?.toString() ?? data['payment']?['id']?.toString();

      final title = '💰 Pago Recibido';
      final message = 'Pago de $paymentAmount Bs de $clientName';

      // Mostrar notificación local de pago
      _notificationService.showPaymentNotification(
        title: title,
        body: message,
        paymentId: paymentId,
        amount: double.tryParse(paymentAmount),
      );

      _addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'payment',
          title: title,
          message: message,
          data: data,
          timestamp: DateTime.now(),
        ),
      );

      state = state.copyWith(lastPaymentUpdate: data);
    });

    // Mensajes
    _messageSub = _wsService.messageStream.listen((data) {
      final fromUser = data['fromUserName'] ?? data['from_user_name'] ?? data['senderId'] ?? 'Usuario';
      final message = data['message'] ?? 'Mensaje recibido';
      final messageId = data['id']?.toString() ?? data['messageId']?.toString();
      final senderId = data['senderId']?.toString();

      final title = '💬 Nuevo Mensaje';
      final body = '$fromUser: $message';

      // Mostrar notificación local de mensaje
      _notificationService.showMessageNotification(
        title: title,
        body: body,
        messageId: messageId,
        senderId: senderId,
      );

      _addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'message',
          title: title,
          message: body,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    });

    // Ubicación
    _locationSub = _wsService.locationStream.listen((data) {
      state = state.copyWith(lastLocationUpdate: data);
      if (kDebugMode) {
        print('📍 Actualización de ubicación recibida: $data');
      }
    });

    // Rutas (opcional): crear notificación informativa
    _routeSub = _wsService.routeStream.listen((data) {
      final title = '🛣️ Ruta Actualizada';
      final message = 'Se ha actualizado una ruta';

      // Mostrar notificación local de ruta (opcional, puede ser silenciosa)
      _notificationService.showGeneralNotification(
        title: title,
        body: message,
        type: 'route',
        payload: 'route:${data['id'] ?? 'general'}',
      );

      _addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          type: 'route',
          title: title,
          message: message,
          data: data,
          timestamp: DateTime.now(),
        ),
      );
    });

    // --- ESTADÍSTICAS EN TIEMPO REAL ---

    // Estadísticas globales
    _globalStatsSub = _wsService.globalStatsStream.listen((data) {
      try {
        final stats = GlobalStats.fromJson(data);
        state = state.copyWith(globalStats: stats);

        if (kDebugMode) {
          print('📊 Estadísticas globales actualizadas: ${stats.totalClients} clientes, ${stats.todayCollections} Bs hoy');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parseando estadísticas globales: $e');
        }
      }
    });

    // Estadísticas del cobrador
    _cobradorStatsSub = _wsService.cobradorStatsStream.listen((data) {
      try {
        final stats = CobradorStats.fromJson(data);
        state = state.copyWith(cobradorStats: stats);

        if (kDebugMode) {
          print('📊 Estadísticas del cobrador actualizadas: ${stats.totalClients} clientes, ${stats.todayCollections} Bs hoy');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parseando estadísticas del cobrador: $e');
        }
      }
    });

    // Estadísticas del manager
    _managerStatsSub = _wsService.managerStatsStream.listen((data) {
      try {
        final stats = ManagerStats.fromJson(data);
        state = state.copyWith(managerStats: stats);

        if (kDebugMode) {
          print('📊 Estadísticas del manager actualizadas: ${stats.totalCobradores} cobradores, ${stats.todayCollections} Bs hoy');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error parseando estadísticas del manager: $e');
        }
      }
    });
  }

  /// Agregar notificación
  void _addNotification(AppNotification notification) {
    final newNotifications = [notification, ...state.notifications];
    // Mantener solo las últimas 100 notificaciones
    if (newNotifications.length > 100) {
      newNotifications.removeRange(100, newNotifications.length);
    }

    state = state.copyWith(notifications: newNotifications);

    if (kDebugMode) {
      print(
        '🔔 Nueva notificación: ${notification.title} - ${notification.message}',
      );
    }
  }

  /// Marcar notificación como leída
  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  /// Marcar todas como leídas
  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(notifications: updatedNotifications);
  }

  /// Limpiar notificaciones
  void clearNotifications() {
    state = state.copyWith(notifications: []);
  }

  /// Enviar ubicación
  void sendLocationUpdate(double latitude, double longitude) {
    _wsService.updateLocation(latitude, longitude);
  }

  /// Enviar mensaje
  void sendMessage(String toUserId, String message) {
    _wsService.sendMessage(recipientId: toUserId, message: message);
  }

  /// Notificar creación de crédito (compatibilidad)
  void notifyCreditCreated(Map<String, dynamic> creditData) {
    final targetUserId = (creditData['targetUserId'] ?? creditData['userId'] ?? creditData['managerId'] ?? creditData['cobradorId'])?.toString();
    if (targetUserId == null) {
      if (kDebugMode) {
        print('⚠️ notifyCreditCreated requiere targetUserId, userId, managerId o cobradorId en creditData');
      }
      return;
    }
    final title = (creditData['title'] ?? 'Crédito creado').toString();
    final message = (creditData['message'] ?? 'Se ha creado un crédito').toString();
    _wsService.sendCreditNotification(
      targetUserId: targetUserId,
      title: title,
      message: message,
      additionalData: creditData,
    );
  }

  /// Notificar cambios de ciclo de vida de un crédito (created/approved/rejected/delivered)
  void notifyCreditLifecycle({
    required String action,
    required int creditId,
    String? targetUserId,
    Map<String, dynamic>? credit,
    String? userType,
    String? message,
  }) {
    _wsService.sendCreditLifecycle(
      action: action,
      creditId: creditId.toString(),
      targetUserId: targetUserId,
      credit: credit,
      userType: userType,
      message: message,
    );
  }

  /// Notificar pago realizado (compatibilidad)
  void notifyPaymentMade(Map<String, dynamic> paymentData) {
    final paymentId = (paymentData['paymentId'] ?? paymentData['id'])?.toString();
    final cobradorId = (paymentData['cobradorId'] ?? paymentData['collectorId'] ?? paymentData['userId'])?.toString();
    final clientId = (paymentData['clientId'] ?? paymentData['clienteId'])?.toString();
    final amountDynamic = paymentData['amount'] ?? paymentData['monto'] ?? paymentData['payment']?['amount'];
    final status = (paymentData['status'] ?? 'completed').toString();
    final notes = paymentData['notes']?.toString();

    if (paymentId == null || cobradorId == null || clientId == null || amountDynamic == null) {
      if (kDebugMode) {
        print('⚠️ notifyPaymentMade requiere paymentId, cobradorId, clientId y amount');
      }
      return;
    }

    final double amount = amountDynamic is num ? amountDynamic.toDouble() : double.tryParse(amountDynamic.toString()) ?? 0.0;

    _wsService.updatePayment(
      paymentId: paymentId,
      cobradorId: cobradorId,
      clientId: clientId,
      amount: amount,
      status: status,
      notes: notes,
      additionalData: paymentData,
    );
    // Además, actualizar localmente para que la UI reaccione aunque el backend no emita evento
    try {
      state = state.copyWith(lastPaymentUpdate: paymentData);
    } catch (_) {}
  }

  /// Desconectar
  void disconnect() {
    _wsService.disconnect();
    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      notifications: [],
      lastError: null,
    );
  }

  /// Obtener número de notificaciones no leídas
  int get unreadCount => state.notifications.where((n) => !n.isRead).length;

  /// Verificar conexión
  bool get isConnected => _wsService.isConnected;

  /// Agregar notificación de prueba
  void addTestNotification({
    required String title,
    required String message,
    required String type,
  }) {
    _addNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: type,
        title: title,
        message: message,
        timestamp: DateTime.now(),
      ),
    );
  }

  /// Limpiar notificaciones locales
  void clearLocalNotifications() {
    _notificationService.cancelAllNotifications();
  }

  /// Verificar si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    return await _notificationService.areNotificationsEnabled();
  }

  /// Abrir configuración de notificaciones
  Future<void> openNotificationSettings() async {
    await _notificationService.openNotificationSettings();
  }

  @override
  void dispose() {
    // Cancelar suscripciones
    _connSub?.cancel();
    _notifSub?.cancel();
    _paymentSub?.cancel();
    _messageSub?.cancel();
    _locationSub?.cancel();
    _routeSub?.cancel();
    _globalStatsSub?.cancel();
    _cobradorStatsSub?.cancel();
    _managerStatsSub?.cancel();

    _wsService.disconnect();
    super.dispose();
  }
}

// Provider principal
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
      return WebSocketNotifier();
    });

// Providers derivados
final isWebSocketConnectedProvider = Provider<bool>((ref) {
  return ref.watch(webSocketProvider).isConnected;
});

final notificationsProvider = Provider<List<AppNotification>>((ref) {
  return ref.watch(webSocketProvider).notifications;
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  return ref.watch(webSocketProvider.notifier).unreadCount;
});

final lastPaymentUpdateProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(webSocketProvider).lastPaymentUpdate;
});

final lastLocationUpdateProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(webSocketProvider).lastLocationUpdate;
});

// Providers para estadísticas en tiempo real
final globalStatsProvider = Provider<GlobalStats?>((ref) {
  return ref.watch(webSocketProvider).globalStats;
});

final cobradorStatsProvider = Provider<CobradorStats?>((ref) {
  return ref.watch(webSocketProvider).cobradorStats;
});

final managerStatsProvider = Provider<ManagerStats?>((ref) {
  return ref.watch(webSocketProvider).managerStats;
});
