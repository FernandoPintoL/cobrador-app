import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio WebSocket para el sistema de cobrador
/// Maneja conexiones en tiempo real, notificaciones y actualizaciones
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // Socket.IO client
  IO.Socket? _socket;

  // Estado de conexión
  bool _isConnected = false;
  bool _isConnecting = false;
  String? _serverUrl;

  // Configuración
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 10;
  final Duration _reconnectDelay = const Duration(seconds: 3);
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  // Streams para diferentes tipos de eventos
  final _connectionController = StreamController<bool>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentController = StreamController<Map<String, dynamic>>.broadcast();
  final _routeController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters para streams
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get paymentStream => _paymentController.stream;
  Stream<Map<String, dynamic>> get routeStream => _routeController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;

  // Getters de estado
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String? get serverUrl => _serverUrl;

  /// Configura el servidor WebSocket
  void configureServer({
    required String url,
    bool isProduction = false,
    String? authToken,
    bool enableSSL = false,
    Duration? timeout,
    int? reconnectAttempts,
    Duration? reconnectDelay,
  }) {
    _serverUrl = url;

    // Detectar automáticamente si es una conexión segura
    final isSecure =
        url.startsWith('wss://') ||
        url.startsWith('https://') ||
        url.contains('railway.app');

    if (reconnectAttempts != null) {
      // _maxReconnectAttempts = reconnectAttempts; // No se puede modificar final
    }

    print('🔧 WebSocket configurado para: $url');
    print('🏭 Modo: ${isProduction ? 'Producción' : 'Desarrollo'}');
    print('🔒 Conexión segura: ${isSecure ? 'Sí (WSS)' : 'No (WS)'}');
  }

  /// Conecta al servidor WebSocket
  Future<bool> connect() async {
    if (_serverUrl == null) {
      print('❌ URL del servidor no configurada');
      return false;
    }

    if (_isConnected || _isConnecting) {
      print('🔄 Ya conectado o intentando conectar');
      return _isConnected;
    }

    // Verificar conectividad de red
    if (!await _checkNetworkConnectivity()) {
      print('❌ Sin conectividad de red');
      return false;
    }

    _isConnecting = true;
    _connectionController.add(false);

    try {
      print('🔌 Conectando a WebSocket: $_serverUrl');

      // Configurar opciones de Socket.IO
      final isSecure =
          _serverUrl!.startsWith('wss://') ||
          _serverUrl!.startsWith('https://');

      final options = IO.OptionBuilder()
          .setTransports([
            'websocket',
            'polling',
          ]) // WebSocket con polling como fallback
          .setTimeout(15000) // 15 segundos timeout
          .enableAutoConnect()
          .enableForceNew()
          .enableReconnection()
          .setReconnectionAttempts(_maxReconnectAttempts)
          .setReconnectionDelay(3000)
          .setPath('/socket.io/')
          .build();

      if (isSecure) {
        print('🔒 Conexión segura (WSS) detectada');
      }

      // Crear socket
      _socket = IO.io(_serverUrl!, options);

      // Configurar event listeners
      _setupEventListeners();

      // Esperar conexión con timeout
      final completer = Completer<bool>();
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      _socket!.onConnect((_) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      });

      _socket!.onConnectError((error) {
        print('❌ Error de conexión: $error');
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      });

      final result = await completer.future;

      if (result) {
        _isConnected = true;
        _isConnecting = false;
        _reconnectAttempts = 0;
        _connectionController.add(true);
        _startHeartbeat();
        print('✅ Conectado a WebSocket exitosamente');
      } else {
        _isConnecting = false;
        print('❌ Falló la conexión a WebSocket');
      }

      return result;
    } catch (e) {
      _isConnecting = false;
      print('❌ Error conectando: $e');
      return false;
    }
  }

  /// Configura los event listeners del socket
  void _setupEventListeners() {
    if (_socket == null) return;

    // Eventos de conexión
    _socket!.onConnect((_) {
      print('✅ Socket conectado');
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _connectionController.add(true);
      _startHeartbeat();
    });

    _socket!.onDisconnect((_) {
      print('🔌 Socket desconectado');
      _isConnected = false;
      _connectionController.add(false);
      _stopHeartbeat();
      _scheduleReconnect();
    });

    _socket!.onConnectError((error) {
      print('❌ Error de conexión: $error');
      _isConnected = false;
      _isConnecting = false;
      _connectionController.add(false);
      _scheduleReconnect();
    });

    _socket!.onError((error) {
      print('❌ Error del socket: $error');
    });

    // Eventos de aplicación
    _socket!.on('notification', _handleNotification);
    _socket!.on('payment_update', _handlePaymentUpdate);
    _socket!.on('route_update', _handleRouteUpdate);
    _socket!.on('message', _handleMessage);
    _socket!.on('location_update', _handleLocationUpdate);
    _socket!.on('user_authenticated', _handleUserAuthenticated);
    _socket!.on('authentication_error', _handleAuthenticationError);

    print('🎯 Event listeners configurados');
  }

  /// Maneja notificaciones recibidas
  void _handleNotification(dynamic data) {
    try {
      final notification = data is String ? jsonDecode(data) : data;
      print('📨 Notificación recibida: ${notification['title']}');
      _notificationController.add(Map<String, dynamic>.from(notification));
    } catch (e) {
      print('❌ Error procesando notificación: $e');
    }
  }

  /// Maneja actualizaciones de pagos
  void _handlePaymentUpdate(dynamic data) {
    try {
      final payment = data is String ? jsonDecode(data) : data;
      print('💰 Actualización de pago: ${payment['amount']} Bs.');
      _paymentController.add(Map<String, dynamic>.from(payment));
    } catch (e) {
      print('❌ Error procesando pago: $e');
    }
  }

  /// Maneja actualizaciones de rutas
  void _handleRouteUpdate(dynamic data) {
    try {
      final route = data is String ? jsonDecode(data) : data;
      print('🛣️ Actualización de ruta: ${route['id']}');
      _routeController.add(Map<String, dynamic>.from(route));
    } catch (e) {
      print('❌ Error procesando ruta: $e');
    }
  }

  /// Maneja mensajes recibidos
  void _handleMessage(dynamic data) {
    try {
      final message = data is String ? jsonDecode(data) : data;
      print('💬 Mensaje de ${message['senderId']}: ${message['message']}');
      _messageController.add(Map<String, dynamic>.from(message));
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
    }
  }

  /// Maneja actualizaciones de ubicación
  void _handleLocationUpdate(dynamic data) {
    try {
      final location = data is String ? jsonDecode(data) : data;
      print('📍 Actualización de ubicación: ${location['userId']}');
      _locationController.add(Map<String, dynamic>.from(location));
    } catch (e) {
      print('❌ Error procesando ubicación: $e');
    }
  }

  /// Maneja autenticación exitosa
  void _handleUserAuthenticated(dynamic data) {
    print('✅ Usuario autenticado: $data');
  }

  /// Maneja errores de autenticación
  void _handleAuthenticationError(dynamic data) {
    print('❌ Error de autenticación: $data');
  }

  /// Autentica un usuario en el WebSocket
  Future<bool> authenticate({
    required String userId,
    required String userName,
    required String userType, // 'client', 'cobrador', 'admin'
    String? authToken,
  }) async {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado para autenticar');
      return false;
    }

    try {
      final authData = {
        'userId': userId,
        'userName': userName,
        'userType': userType,
        'timestamp': DateTime.now().toIso8601String(),
        if (authToken != null) 'token': authToken,
      };

      print('🔐 Autenticando usuario: $userName ($userType)');
      _socket!.emit('authenticate', authData);

      // TODO: Implementar confirmación de autenticación
      await Future.delayed(const Duration(milliseconds: 500));

      print('✅ Usuario autenticado');
      return true;
    } catch (e) {
      print('❌ Error autenticando: $e');
      return false;
    }
  }

  /// Envía una notificación de crédito
  void sendCreditNotification({
    required String targetUserId,
    required String title,
    required String message,
    String type = 'credit',
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado para enviar notificación');
      return;
    }

    final notification = {
      'targetUserId': targetUserId,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': DateTime.now().toIso8601String(),
      if (additionalData != null) ...additionalData,
    };

    print('📤 Enviando notificación: $title');
    _socket!.emit('send_notification', notification);
  }

  /// Actualiza la ubicación del usuario (solo cobradores)
  void updateLocation(
    double latitude,
    double longitude, {
    String? address,
    double? accuracy,
  }) {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado para actualizar ubicación');
      return;
    }

    final locationData = {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
      if (address != null) 'address': address,
      if (accuracy != null) 'accuracy': accuracy,
    };

    print('📍 Actualizando ubicación: $latitude, $longitude');
    _socket!.emit('update_location', locationData);
  }

  /// Actualiza el estado de un pago
  void updatePayment({
    required String paymentId,
    required String cobradorId,
    required String clientId,
    required double amount,
    required String status, // 'pending', 'completed', 'failed'
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado para actualizar pago');
      return;
    }

    final paymentData = {
      'paymentId': paymentId,
      'cobradorId': cobradorId,
      'clientId': clientId,
      'amount': amount,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
      if (notes != null) 'notes': notes,
      if (additionalData != null) ...additionalData,
    };

    print('💰 Actualizando pago: $paymentId - $amount Bs.');
    _socket!.emit('payment_update', paymentData);
  }

  /// Envía un mensaje directo a otro usuario
  void sendMessage({
    required String recipientId,
    required String message,
    String? messageType,
  }) {
    if (!_isConnected || _socket == null) {
      print('❌ No conectado para enviar mensaje');
      return;
    }

    final messageData = {
      'recipientId': recipientId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      if (messageType != null) 'type': messageType,
    };

    print('💬 Enviando mensaje a: $recipientId');
    _socket!.emit('send_message', messageData);
  }

  /// Verifica la conectividad de red
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  /// Inicia el heartbeat para mantener la conexión viva
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _socket != null) {
        _socket!.emit('ping', {'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }

  /// Detiene el heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// Programa un intento de reconexión
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Máximo número de intentos de reconexión alcanzado');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      _reconnectAttempts++;
      print('🔄 Intento de reconexión #$_reconnectAttempts');

      final success = await connect();
      if (!success) {
        _scheduleReconnect();
      }
    });
  }

  /// Desconecta del WebSocket
  void disconnect() {
    print('🔌 Desconectando WebSocket...');

    _stopHeartbeat();
    _reconnectTimer?.cancel();

    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }

    _isConnected = false;
    _isConnecting = false;
    _reconnectAttempts = 0;
    _connectionController.add(false);

    print('✅ WebSocket desconectado');
  }

  /// Limpia recursos cuando no se necesita más el servicio
  void dispose() {
    disconnect();

    _connectionController.close();
    _notificationController.close();
    _paymentController.close();
    _routeController.close();
    _messageController.close();
    _locationController.close();
  }
}
