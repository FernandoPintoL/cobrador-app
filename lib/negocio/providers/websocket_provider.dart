import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/servicios/websocket_service.dart';
import 'auth_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Estado del WebSocket
class WebSocketState {
  final bool isConnected;
  final bool isConnecting;
  final String? serverUrl;
  final String? lastError;
  final List<Map<String, dynamic>> notifications;
  final List<Map<String, dynamic>> recentMessages;
  final Map<String, dynamic>? lastPaymentUpdate;
  final Map<String, dynamic>? lastLocationUpdate;

  const WebSocketState({
    this.isConnected = false,
    this.isConnecting = false,
    this.serverUrl,
    this.lastError,
    this.notifications = const [],
    this.recentMessages = const [],
    this.lastPaymentUpdate,
    this.lastLocationUpdate,
  });

  WebSocketState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? serverUrl,
    String? lastError,
    List<Map<String, dynamic>>? notifications,
    List<Map<String, dynamic>>? recentMessages,
    Map<String, dynamic>? lastPaymentUpdate,
    Map<String, dynamic>? lastLocationUpdate,
  }) {
    return WebSocketState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      serverUrl: serverUrl ?? this.serverUrl,
      lastError: lastError,
      notifications: notifications ?? this.notifications,
      recentMessages: recentMessages ?? this.recentMessages,
      lastPaymentUpdate: lastPaymentUpdate ?? this.lastPaymentUpdate,
      lastLocationUpdate: lastLocationUpdate ?? this.lastLocationUpdate,
    );
  }
}

/// Notifier para gestionar WebSocket
class WebSocketNotifier extends StateNotifier<WebSocketState> {
  final WebSocketService _wsService;
  final Ref _ref;

  WebSocketNotifier(this._wsService, this._ref)
    : super(const WebSocketState()) {
    _initializeListeners();
  }

  /// Inicializa los listeners del WebSocket
  void _initializeListeners() {
    // Escuchar estado de conexión
    _wsService.connectionStream.listen((isConnected) {
      state = state.copyWith(
        isConnected: isConnected,
        isConnecting: false,
        lastError: isConnected ? null : state.lastError,
      );
    });

    // Escuchar notificaciones
    _wsService.notificationStream.listen((notification) {
      final updatedNotifications = [notification, ...state.notifications];
      // Mantener solo las últimas 50 notificaciones
      final trimmedNotifications = updatedNotifications.take(50).toList();

      state = state.copyWith(notifications: trimmedNotifications);
    });

    // Escuchar actualizaciones de pagos
    _wsService.paymentStream.listen((payment) {
      state = state.copyWith(lastPaymentUpdate: payment);
    });

    // Escuchar mensajes
    _wsService.messageStream.listen((message) {
      final updatedMessages = [message, ...state.recentMessages];
      // Mantener solo los últimos 20 mensajes
      final trimmedMessages = updatedMessages.take(20).toList();

      state = state.copyWith(recentMessages: trimmedMessages);
    });

    // Escuchar actualizaciones de ubicación
    _wsService.locationStream.listen((location) {
      state = state.copyWith(lastLocationUpdate: location);
    });
  }

  /// Configura y conecta al WebSocket
  Future<bool> connectToWebSocket({
    String? customUrl,
    bool isProduction = false,
  }) async {
    try {
      state = state.copyWith(isConnecting: true, lastError: null);

      // Configurar URL del servidor
      final serverUrl = customUrl ?? _getDefaultServerUrl();

      _wsService.configureServer(url: serverUrl, isProduction: isProduction);

      state = state.copyWith(serverUrl: serverUrl);

      // Conectar
      final connected = await _wsService.connect();

      if (connected) {
        // Autenticar usuario si está logueado
        final authState = _ref.read(authProvider);
        if (authState.usuario != null) {
          await _authenticateCurrentUser();
        }

        print('✅ WebSocket conectado exitosamente');
        return true;
      } else {
        state = state.copyWith(
          isConnecting: false,
          lastError: 'No se pudo conectar al servidor WebSocket',
        );
        print('❌ Falló la conexión WebSocket');
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnecting: false,
        lastError: 'Error conectando: $e',
      );
      print('❌ Error en connectToWebSocket: $e');
      return false;
    }
  }

  /// Autentica el usuario actual
  Future<bool> _authenticateCurrentUser() async {
    final authState = _ref.read(authProvider);
    if (authState.usuario == null) return false;

    final user = authState.usuario!;

    // Determinar tipo de usuario basado en roles
    String userType = 'client';
    if (user.roles.contains('admin')) {
      userType = 'admin';
    } else if (user.roles.contains('cobrador')) {
      userType = 'cobrador';
    } else if (user.roles.contains('manager')) {
      userType = 'manager';
    }

    return await _wsService.authenticate(
      userId: user.id.toString(),
      userName: user.nombre,
      userType: userType,
    );
  }

  /// Obtiene la URL por defecto del servidor según la plataforma
  String _getDefaultServerUrl() {
    // Leer la URL del WebSocket desde .env, con fallback
    return dotenv.env['WEBSOCKET_URL'] ?? 'ws://localhost:3001';
  }

  /// Desconecta del WebSocket
  void disconnect() {
    _wsService.disconnect();
    state = state.copyWith(
      isConnected: false,
      isConnecting: false,
      lastError: null,
    );
  }

  /// Envía una notificación de crédito
  void sendCreditNotification({
    required String targetUserId,
    required String title,
    required String message,
    String type = 'credit',
    Map<String, dynamic>? additionalData,
  }) {
    if (!state.isConnected) {
      print('❌ No conectado para enviar notificación');
      return;
    }

    _wsService.sendCreditNotification(
      targetUserId: targetUserId,
      title: title,
      message: message,
      type: type,
      additionalData: additionalData,
    );
  }

  /// Actualiza la ubicación del usuario
  void updateLocation(
    double latitude,
    double longitude, {
    String? address,
    double? accuracy,
  }) {
    if (!state.isConnected) {
      print('❌ No conectado para actualizar ubicación');
      return;
    }

    _wsService.updateLocation(
      latitude,
      longitude,
      address: address,
      accuracy: accuracy,
    );
  }

  /// Notifica una actualización de pago
  void notifyPaymentUpdate({
    required String paymentId,
    required String cobradorId,
    required String clientId,
    required double amount,
    required String status,
    String? notes,
  }) {
    if (!state.isConnected) {
      print('❌ No conectado para notificar pago');
      return;
    }

    _wsService.updatePayment(
      paymentId: paymentId,
      cobradorId: cobradorId,
      clientId: clientId,
      amount: amount,
      status: status,
      notes: notes,
    );
  }

  /// Envía un mensaje directo
  void sendMessage({
    required String recipientId,
    required String message,
    String? messageType,
  }) {
    if (!state.isConnected) {
      print('❌ No conectado para enviar mensaje');
      return;
    }

    _wsService.sendMessage(
      recipientId: recipientId,
      message: message,
      messageType: messageType,
    );
  }

  /// Limpia las notificaciones
  void clearNotifications() {
    state = state.copyWith(notifications: []);
  }

  /// Agrega una notificación de prueba
  void addTestNotification({
    required String title,
    required String message,
    required String type,
  }) {
    final notification = {
      'id': 'test_${DateTime.now().millisecondsSinceEpoch}',
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      'isRead': false,
    };

    final updatedNotifications = [notification, ...state.notifications];
    final trimmedNotifications = updatedNotifications.take(50).toList();

    state = state.copyWith(notifications: trimmedNotifications);
  }

  /// Limpia los mensajes
  void clearMessages() {
    state = state.copyWith(recentMessages: []);
  }

  /// Limpia errores
  void clearError() {
    state = state.copyWith(lastError: null);
  }

  /// Reconecta automáticamente
  Future<void> reconnect() async {
    disconnect();
    await Future.delayed(const Duration(seconds: 2));
    await connectToWebSocket();
  }

  @override
  void dispose() {
    _wsService.dispose();
    super.dispose();
  }
}

/// Provider del WebSocket
final webSocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>((ref) {
      final wsService = WebSocketService();
      return WebSocketNotifier(wsService, ref);
    });

/// Provider para verificar si hay notificaciones no leídas
final unreadNotificationsProvider = Provider<int>((ref) {
  final wsState = ref.watch(webSocketProvider);
  // Por simplicidad, todas las notificaciones se consideran no leídas
  // En una implementación real, tendrías un campo 'isRead' en cada notificación
  return wsState.notifications.length;
});

/// Provider para obtener la última actualización de pago
final lastPaymentUpdateProvider = Provider<Map<String, dynamic>?>((ref) {
  final wsState = ref.watch(webSocketProvider);
  return wsState.lastPaymentUpdate;
});

/// Provider para verificar el estado de conexión
final connectionStatusProvider = Provider<bool>((ref) {
  final wsState = ref.watch(webSocketProvider);
  return wsState.isConnected;
});
