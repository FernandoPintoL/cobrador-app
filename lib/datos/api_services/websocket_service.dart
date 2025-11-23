import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'storage_service.dart';

/// Servicio de WebSocket con Socket.IO
/// Gestiona la conexión en tiempo real con el servidor Node.js
class WebSocketService {
  static String _nodeUrl =
      dotenv.env['NODE_WEBSOCKET_URL'] ??
      dotenv.env['WEBSOCKET_NODE_URL'] ??
      dotenv.env['WEBSOCKET_URL'] ??
      '';
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // Socket.IO
  IO.Socket? _socket;

  // Estado y configuración
  bool _isConnected = false;
  bool _isConnecting = false;

  // Streams para diferentes tipos de eventos
  final _connectionController = StreamController<bool>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentController = StreamController<Map<String, dynamic>>.broadcast();
  final _routeController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams para estadísticas en tiempo real
  final _globalStatsController = StreamController<Map<String, dynamic>>.broadcast();
  final _cobradorStatsController = StreamController<Map<String, dynamic>>.broadcast();
  final _managerStatsController = StreamController<Map<String, dynamic>>.broadcast();

  // Stream para notificaciones de cajas (Cash Balance)
  final _cashBalanceController = StreamController<Map<String, dynamic>>.broadcast();

  // Deduplicación simple de eventos para evitar múltiples notificaciones por la misma acción
  final Map<String, DateTime> _recentEventCache = {};
  static const Duration _dedupeWindow = Duration(seconds: 3);

  bool _shouldDropDuplicate(String category, Map<String, dynamic> map) {
    try {
      // Construir una clave estable basada en campos comunes si existen
      final type = (map['type'] ?? map['action'] ?? '').toString();
      final id =
          (map['payment']?['id'] ??
                  map['credit']?['id'] ??
                  map['creditId'] ??
                  map['id'] ??
                  '')
              .toString();
      final key = '$category|$type|$id|${map['message'] ?? ''}';
      final now = DateTime.now();
      final last = _recentEventCache[key];
      // Limpieza ligera
      _recentEventCache.removeWhere(
        (_, ts) => now.difference(ts) > const Duration(seconds: 10),
      );
      if (last != null && now.difference(last) <= _dedupeWindow) {
        return true; // Drop duplicate
      }
      _recentEventCache[key] = now;
      return false;
    } catch (_) {
      return false;
    }
  }

  // Notificaciones locales
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;

  // Info de usuario autenticado
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserType;

  // Getters públicos
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get paymentStream => _paymentController.stream;
  Stream<Map<String, dynamic>> get routeStream => _routeController.stream;
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;
  Stream<Map<String, dynamic>> get locationStream => _locationController.stream;

  // Getters para streams de estadísticas
  Stream<Map<String, dynamic>> get globalStatsStream => _globalStatsController.stream;
  Stream<Map<String, dynamic>> get cobradorStatsStream => _cobradorStatsController.stream;
  Stream<Map<String, dynamic>> get managerStatsStream => _managerStatsController.stream;

  // Getter para stream de cajas (Cash Balance)
  Stream<Map<String, dynamic>> get cashBalanceStream => _cashBalanceController.stream;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get serverUrlSummary => _nodeUrl;

  /// Inicialización de notificaciones locales
  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      await _localNotifications.initialize(initSettings);
      _notificationsInitialized = true;
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
    }
  }

  /// Verificación de conectividad de red
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  /// Configura el servidor WebSocket manualmente (compatibilidad con API anterior)
  void configureServer({
    required String url,
    bool isProduction = false,
    String? authToken,
    bool enableSSL = false,
    Duration? timeout,
    int? reconnectAttempts,
    Duration? reconnectDelay,
  }) {
    // Actualizar URL del nodo para Socket.IO
    if (url.isNotEmpty) {
      _nodeUrl = url;
    }
    print('🔧 Socket.IO configurado: $_nodeUrl');
  }

  /// Conecta al WebSocket usando Socket.IO
  Future<bool> connect() async {
    // Asegurar que las notificaciones están inicializadas
    unawaited(_initializeNotifications());

    if (_isConnected || _isConnecting) {
      print('🔄 Ya conectado o conectando');
      return _isConnected;
    }

    // Comprobar conectividad
    if (!await _checkNetworkConnectivity()) {
      print('❌ Sin conectividad de red');
      return false;
    }

    // Validar URL del servidor Node
    String url = _nodeUrl.isNotEmpty
        ? _nodeUrl
        : (dotenv.env['NODE_WEBSOCKET_URL'] ?? '');
    if (url.isEmpty) {
      print('❌ NODE_WEBSOCKET_URL no configurado en .env');
      return false;
    }

    // Normalizar URL: quitar barras finales y agregar esquema si falta
    url = url.trim();
    if (!url.startsWith('http')) {
      // Si el .env solo puso dominio/host, asumimos https en producción
      final isProd =
          (dotenv.env['APP_ENV'] ?? '').toLowerCase() == 'production';
      url = '${isProd ? 'https' : 'http'}://$url';
    }

    // Socket.IO suele atender en /socket.io por defecto; permitir override por env
    final endpoint =
        (dotenv.env['NODE_WEBSOCKET_PATH'] ??
                dotenv.env['WEBSOCKET_ENDPOINT'] ??
                '/socket.io')
            .trim();

    // Construir origin sin barras finales y path normalizado
    final origin = url.replaceAll(RegExp(r'/+$'), '');
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final logUrl = '$origin$path';

    _isConnecting = true;
    _connectionController.add(false);

    // Cargar user para autenticar al conectar
    final storage = StorageService();
    final usuario = await storage.getUser();
    _currentUserId = usuario?.id.toString();
    _currentUserName = usuario?.nombre;
    _currentUserType = (usuario?.roles.isNotEmpty ?? false)
        ? usuario!.roles.first
        : null;

    try {
      // Construir opciones para Socket.IO
      final optsBuilder = IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .enableAutoConnect()
          .setTimeout(10000);

      // Pasar token JWT o datos en query si el servidor lo requiere
      final storageForAuth = StorageService();
      final tokenForAuth = await storageForAuth.getToken();
      if (tokenForAuth != null && tokenForAuth.isNotEmpty) {
        optsBuilder.setQuery({'token': tokenForAuth});
        optsBuilder.setExtraHeaders({'Authorization': 'Bearer $tokenForAuth'});
      }

      // Establecer path explícitamente si es diferente del predeterminado
      optsBuilder.setPath(endpoint);
      final opts = optsBuilder.build();

      _socket = IO.io(origin, opts);
      print('🌐 Conectando Socket.IO: $logUrl');

      // Configurar listeners para eventos de sistema
      _setupSystemEventListeners();

      // Configurar listeners para eventos de negocio
      _setupBusinessEventListeners();

      // Autoconectar
      _socket?.connect();

      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      print('❌ Error configurando Socket.IO: $e');
      return false;
    }
  }

  /// Configurar listeners para eventos de sistema
  void _setupSystemEventListeners() {
    _socket?.on('connect', (_) {
      print('🔗 Conectado a Socket.IO');
      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);

      // Autenticar inmediatamente si tenemos datos
      if (_currentUserId != null && _currentUserType != null) {
        final authPayload = {
          'userId': _currentUserId,
          'userType': _currentUserType,
          'userName': _currentUserName,
        };
        print('🔐 Autenticando: ${jsonEncode(authPayload)}');
        _socket?.emit('authenticate', authPayload);
      } else {
        print('ℹ️ Autenticación omitida: faltan datos de usuario');
      }
    });

    // Eventos de autenticación
    _socket?.on('authenticated', (data) {
      try {
        print('✅ Autenticado: ${data is String ? data : jsonEncode(data)}');
      } catch (_) {
        print('✅ Autenticado');
      }
    });

    // Solo authentication_error según documentación (auth_error removido por redundancia)
    _socket?.on('authentication_error', (data) {
      try {
        print(
          '⛔ Error de autenticación: ${data is String ? data : jsonEncode(data)}',
        );
      } catch (_) {
        print('⛔ Error de autenticación');
      }
    });

    // Eventos de conexión
    _socket?.on('error', (data) {
      try {
        print('⛔ Error Socket.IO: ${data is String ? data : jsonEncode(data)}');
      } catch (_) {
        print('⛔ Error Socket.IO');
      }
    });

    _socket?.on('disconnect', (_) {
      print('🔌 Desconectado de Socket.IO');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket?.on('connect_error', (err) {
      print('❌ Error de conexión Socket.IO: $err');
    });

    // Eventos de sistema
    _socket?.on('user_connected', (data) {
      try {
        final userName = data['userName'] ?? data['user']?['name'] ?? 'Usuario';
        print('👤 Usuario conectado: $userName');
      } catch (_) {
        print('👤 Usuario conectado');
      }
    });

    _socket?.on('user_disconnected', (data) {
      try {
        final userName = data['userName'] ?? data['user']?['name'] ?? 'Usuario';
        print('👤 Usuario desconectado: $userName');
      } catch (_) {
        print('👤 Usuario desconectado');
      }
    });

    _socket?.on('server_shutdown', (data) {
      print('⚠️ Servidor apagándose - Reconectará automáticamente');
      _handleNotification({
        'title': 'Mantenimiento del servidor',
        'message': 'El servidor se está reiniciando. Reconectando...',
        'type': 'system',
      });
    });

    // Evento de depuración
    _socket?.on('debug_event', (data) {
      try {
        print('🐞 Debug: ${data is String ? data : jsonEncode(data)}');
      } catch (_) {
        print('🐞 Debug (datos no parseables)');
      }
    });
  }

  /// Configurar listeners para eventos de negocio
  /// Optimizado: sin duplicados. El servidor filtra por rol/sala automáticamente.
  void _setupBusinessEventListeners() {
    // --- EVENTOS DE ESTADÍSTICAS EN TIEMPO REAL (NUEVOS) ---

    // Estadísticas globales (Todos los usuarios)
    _socket?.on('stats.global.updated', (data) {
      print('📊 Estadísticas globales actualizadas');
      _handleGlobalStatsUpdate(data);
    });

    // Estadísticas del cobrador (Solo el cobrador específico)
    _socket?.on('stats.cobrador.updated', (data) {
      print('📊 Estadísticas del cobrador actualizadas');
      _handleCobradorStatsUpdate(data);
    });

    // Estadísticas del manager (Solo el manager específico)
    _socket?.on('stats.manager.updated', (data) {
      print('📊 Estadísticas del manager actualizadas');
      _handleManagerStatsUpdate(data);
    });

    // --- EVENTOS DE NOTIFICACIONES EXISTENTES (NUEVOS SEGÚN DOC) ---

    // Notificación de crédito (Unificado: created/approved/rejected/delivered)
    _socket?.on('credit-notification', (data) {
      print('📨 Notificación de crédito');
      _handleNotification(data);
    });

    // Notificación de pago
    _socket?.on('payment-notification', (data) {
      print('📨 Notificación de pago');
      _handlePaymentUpdate(data);
    });

    // --- EVENTOS DE CRÉDITOS (MANAGERS reciben estos del servidor) ---
    _socket?.on('credit_waiting_approval', (data) {
      print('📨 [MANAGER] Crédito pendiente de aprobación');
      _handleNotification(data);
    });

    _socket?.on('credit_pending_approval', (data) {
      print('📨 [MANAGER] Crédito pendiente (socket)');
      _handleNotification(data);
    });

    _socket?.on('credit_delivered', (data) {
      print('📨 [MANAGER] Crédito entregado');
      _handleNotification(data);
    });

    _socket?.on('credit_delivered_notification', (data) {
      print('📨 [MANAGER] Notificación de entrega');
      _handleNotification(data);
    });

    _socket?.on('new_credit_notification', (data) {
      print('📨 Nueva notificación de crédito');
      _handleNotification(data);
    });

    // --- EVENTOS DE CRÉDITOS (COBRADORES reciben estos del servidor) ---
    _socket?.on('credit_approved', (data) {
      print('📨 [COBRADOR] Crédito aprobado');
      _handleNotification(data);
    });

    _socket?.on('credit_rejected', (data) {
      print('📨 [COBRADOR] Crédito rechazado');
      _handleNotification(data);
    });

    _socket?.on('credit_attention_required', (data) {
      print('📨 [COBRADOR] Crédito requiere atención');
      _handleNotification(data);
    });

    _socket?.on('credit_decision', (data) {
      print('📨 [COBRADOR] Decisión sobre crédito');
      _handleNotification(data);
    });

    _socket?.on('credit_lifecycle_update', (data) {
      print('📨 Actualización de ciclo de vida de crédito');
      _handleNotification(data);
    });

    // --- EVENTOS DE PAGOS ---
    _socket?.on('payment_received', (data) {
      print('📨 [COBRADOR] Pago recibido');
      _handlePaymentUpdate(data);
    });

    _socket?.on('cobrador_payment_received', (data) {
      print('📨 [MANAGER] Pago de cobrador recibido');
      _handlePaymentUpdate(data);
    });

    // --- EVENTOS DE CAJAS ---
    _socket?.on('cash_balance_reminder', (data) {
      print('📨 [COBRADOR] Recordatorio de cierre de caja');
      _handleNotification(data);
    });

    // --- EVENTOS DE RUTAS (solo route_updated según documentación) ---
    _socket?.on('route_updated', (data) {
      print('📨 [MANAGER] Ruta actualizada');
      _handleRouteUpdate(data);
    });

    // --- EVENTOS DE UBICACIÓN ---
    _socket?.on('cobrador_location_update', (data) {
      print('📨 [ADMIN/MANAGER] Ubicación de cobrador');
      _handleLocationUpdate(data);
    });

    // --- EVENTOS DE MENSAJES (solo new_message según documentación) ---
    _socket?.on('new_message', (data) {
      print('📨 Nuevo mensaje');
      _handleMessage(data);
    });

    // --- EVENTOS DE CAJAS (CASH BALANCE) ---
    _socket?.on('cash_balance_auto_closed', (data) {
      print('📦 Caja auto-cerrada');
      _handleCashBalanceEvent(data, 'auto_closed');
    });

    _socket?.on('cash_balance_auto_created', (data) {
      print('📦 Caja auto-creada');
      _handleCashBalanceEvent(data, 'auto_created');
    });

    _socket?.on('cash_balance_requires_reconciliation', (data) {
      print('⚠️  Caja requiere conciliación');
      _handleCashBalanceEvent(data, 'requires_reconciliation');
    });
  }

  /// Manejo de notificaciones recibidas
  void _handleNotification(dynamic data) {
    try {
      Map<String, dynamic> notification;
      if (data is String) {
        notification = jsonDecode(data);
      } else if (data is Map) {
        notification = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de notificación no reconocido: $data');
        return;
      }

      if (_shouldDropDuplicate('notification', notification)) {
        print('🔄 Ignorando notificación duplicada');
        return;
      }

      _notificationController.add(notification);

      // Mostrar notificación local si hay título y mensaje
      final title =
          notification['title'] ?? notification['notification']?['title'];
      final message =
          notification['message'] ?? notification['notification']?['message'];

      if (title != null && message != null) {
        _showLocalNotification(
          title.toString(),
          message.toString(),
          notification['type']?.toString() ?? 'notification',
        );
      }
    } catch (e) {
      print('❌ Error procesando notificación: $e');
    }
  }

  /// Manejo de actualizaciones de pagos
  void _handlePaymentUpdate(dynamic data) {
    try {
      Map<String, dynamic> payment;
      if (data is String) {
        payment = jsonDecode(data);
      } else if (data is Map) {
        payment = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de pago no reconocido: $data');
        return;
      }

      if (_shouldDropDuplicate('payment', payment)) {
        print('🔄 Ignorando pago duplicado');
        return;
      }

      _paymentController.add(payment);

      // Mostrar notificación local si hay título o importe
      final title = payment['title'] ?? 'Pago recibido';
      final amount = payment['payment']?['amount'] ?? payment['amount'];
      final message =
          payment['message'] ??
          'Se ha registrado un pago${amount != null ? " de $amount" : ""}';

      _showLocalNotification(title.toString(), message.toString(), 'payment');
    } catch (e) {
      print('❌ Error procesando pago: $e');
    }
  }

  /// Manejo de actualizaciones de rutas
  void _handleRouteUpdate(dynamic data) {
    try {
      Map<String, dynamic> route;
      if (data is String) {
        route = jsonDecode(data);
      } else if (data is Map) {
        route = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de ruta no reconocido: $data');
        return;
      }

      if (_shouldDropDuplicate('route', route)) {
        print('🔄 Ignorando ruta duplicada');
        return;
      }

      _routeController.add(route);
    } catch (e) {
      print('❌ Error procesando ruta: $e');
    }
  }

  /// Manejo de mensajes
  void _handleMessage(dynamic data) {
    try {
      Map<String, dynamic> message;
      if (data is String) {
        message = jsonDecode(data);
      } else if (data is Map) {
        message = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de mensaje no reconocido: $data');
        return;
      }

      if (_shouldDropDuplicate('message', message)) {
        print('🔄 Ignorando mensaje duplicado');
        return;
      }

      _messageController.add(message);

      // Mostrar notificación local
      final sender = message['senderName'] ?? message['senderId'] ?? 'Usuario';
      final content =
          message['message'] ?? message['content'] ?? 'Nuevo mensaje';

      _showLocalNotification(
        'Mensaje de $sender',
        content.toString(),
        'message',
      );
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
    }
  }

  /// Manejo de actualizaciones de ubicación
  void _handleLocationUpdate(dynamic data) {
    try {
      Map<String, dynamic> location;
      if (data is String) {
        location = jsonDecode(data);
      } else if (data is Map) {
        location = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de ubicación no reconocido: $data');
        return;
      }

      if (_shouldDropDuplicate('location', location)) {
        print('🔄 Ignorando ubicación duplicada');
        return;
      }

      _locationController.add(location);
    } catch (e) {
      print('❌ Error procesando ubicación: $e');
    }
  }

  /// Manejo de actualizaciones de estadísticas globales
  void _handleGlobalStatsUpdate(dynamic data) {
    try {
      Map<String, dynamic> stats;
      if (data is String) {
        stats = jsonDecode(data);
      } else if (data is Map) {
        stats = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de estadísticas globales no reconocido: $data');
        return;
      }

      // No aplicar deduplicación a las estadísticas porque siempre queremos la última actualización
      _globalStatsController.add(stats);

      if (kDebugMode) {
        print('📊 Estadísticas globales actualizadas: ${stats['timestamp']}');
      }
    } catch (e) {
      print('❌ Error procesando estadísticas globales: $e');
    }
  }

  /// Manejo de actualizaciones de estadísticas del cobrador
  void _handleCobradorStatsUpdate(dynamic data) {
    try {
      Map<String, dynamic> stats;
      if (data is String) {
        stats = jsonDecode(data);
      } else if (data is Map) {
        stats = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de estadísticas de cobrador no reconocido: $data');
        return;
      }

      // Verificar que el evento es para el usuario actual
      final userId = stats['user_id']?.toString();
      if (userId != null && userId != _currentUserId) {
        if (kDebugMode) {
          print('⚠️ Estadísticas de cobrador para otro usuario: $userId');
        }
        return;
      }

      _cobradorStatsController.add(stats);

      if (kDebugMode) {
        print('📊 Estadísticas del cobrador actualizadas: ${stats['timestamp']}');
      }
    } catch (e) {
      print('❌ Error procesando estadísticas de cobrador: $e');
    }
  }

  /// Manejo de actualizaciones de estadísticas del manager
  void _handleManagerStatsUpdate(dynamic data) {
    try {
      Map<String, dynamic> stats;
      if (data is String) {
        stats = jsonDecode(data);
      } else if (data is Map) {
        stats = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de estadísticas de manager no reconocido: $data');
        return;
      }

      // Verificar que el evento es para el usuario actual
      final userId = stats['user_id']?.toString();
      if (userId != null && userId != _currentUserId) {
        if (kDebugMode) {
          print('⚠️ Estadísticas de manager para otro usuario: $userId');
        }
        return;
      }

      _managerStatsController.add(stats);

      if (kDebugMode) {
        print('📊 Estadísticas del manager actualizadas: ${stats['timestamp']}');
      }
    } catch (e) {
      print('❌ Error procesando estadísticas de manager: $e');
    }
  }

  /// Manejo de eventos de cajas (Cash Balance)
  void _handleCashBalanceEvent(dynamic data, String action) {
    try {
      Map<String, dynamic> cashBalanceData;
      if (data is String) {
        cashBalanceData = jsonDecode(data);
      } else if (data is Map) {
        cashBalanceData = Map<String, dynamic>.from(data);
      } else {
        print('⚠️ Formato de evento de caja no reconocido: $data');
        return;
      }

      // Agregar el tipo de acción al mapa
      cashBalanceData['type'] = action;
      cashBalanceData['action'] = action;

      // Verificar si debemos ignorar duplicados
      if (_shouldDropDuplicate('cash_balance', cashBalanceData)) {
        print('🔄 Ignorando evento de caja duplicado');
        return;
      }

      // Enviar al stream
      _cashBalanceController.add(cashBalanceData);

      // Mostrar notificación local
      final message = cashBalanceData['message'] as String? ?? '';
      String title;
      switch (action) {
        case 'auto_closed':
          title = '📦 Caja Auto-Cerrada';
          break;
        case 'auto_created':
          title = '📦 Caja Virtual Creada';
          break;
        case 'requires_reconciliation':
          title = '⚠️ Conciliación Requerida';
          break;
        default:
          title = '📦 Notificación de Caja';
      }

      _showLocalNotification(
        title,
        message,
        'cash_balance',
      );

      if (kDebugMode) {
        print('📦 Evento de caja procesado: $action');
      }
    } catch (e) {
      print('❌ Error procesando evento de caja: $e');
    }
  }

  /// Mostrar notificación local
  Future<void> _showLocalNotification(
    String title,
    String body,
    String type,
  ) async {
    if (!_notificationsInitialized) await _initializeNotifications();

    try {
      // Diferentes canales según el tipo de notificación
      String channelId = 'cobrador_channel';
      String channelName = 'Cobrador Notifications';
      String channelDescription = 'Notifications for Cobrador App';

      switch (type) {
        case 'payment':
          channelId = 'payment_channel';
          channelName = 'Payment Notifications';
          channelDescription = 'Notifications for payments';
          break;
        case 'credit':
          channelId = 'credit_channel';
          channelName = 'Credit Notifications';
          channelDescription = 'Notifications for credits';
          break;
        case 'message':
          channelId = 'message_channel';
          channelName = 'Message Notifications';
          channelDescription = 'Notifications for messages';
          break;
        case 'cash_balance':
          channelId = 'cash_balance_channel';
          channelName = 'Cash Balance Notifications';
          channelDescription = 'Notifications for cash balance operations';
          break;
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().microsecond, // ID único
        title,
        body,
        details,
      );
    } catch (e) {
      print('❌ Error mostrando notificación local: $e');
    }
  }

  /// Desconecta del WebSocket
  Future<void> disconnect() async {
    if (_socket != null) {
      _socket?.disconnect();
      _socket = null;
    }
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    print('🔌 Desconexión manual del WebSocket');
  }

  /// Autenticación con el servidor
  Future<bool> authenticate({
    required String userId,
    required String userName,
    required String userType,
    String? authToken,
  }) async {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserType = userType;

    try {
      if (_isConnected && _socket != null) {
        _socket?.emit('authenticate', {
          'userId': userId,
          'userType': userType,
          'userName': userName,
        });
        print('🔐 Autenticación enviada');
      } else {
        print('⚠️ No se puede autenticar: WebSocket no conectado');
      }
      return true;
    } catch (e) {
      print('❌ Error en autenticación: $e');
      return false;
    }
  }

  /// Envío de notificaciones de crédito
  void sendCreditNotification({
    required String targetUserId,
    required String title,
    required String message,
    String type = 'credit',
    Map<String, dynamic>? additionalData,
  }) {
    Map<String, dynamic> _prune(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        if (v is Map<String, dynamic>) {
          final x = _prune(v);
          if (x.isNotEmpty) out[k] = x;
        } else {
          out[k] = v;
        }
      });
      return out;
    }

    try {
      final payloadRaw = {
        'targetUserId': targetUserId,
        'notification': {
          'title': title,
          'message': message,
          'type': type,
          ...?additionalData,
        },
        'from': {
          'id': _currentUserId,
          'name': _currentUserName,
          'type': _currentUserType,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = _prune(payloadRaw);
      _socket?.emit('credit_notification', payload);
    } catch (e) {
      print('❌ Error enviando notificación de crédito: $e');
    }
  }

  /// Actualización de ubicación
  /// Solo envía latitude y longitude según documentación del WebSocket
  void updateLocation(
    double latitude,
    double longitude, {
    String? address,
    double? accuracy,
  }) {
    try {
      // Según la documentación, solo enviar latitude y longitude
      // El servidor agregará automáticamente cobradorId, cobradorName y timestamp
      final payload = {
        'latitude': latitude,
        'longitude': longitude,
      };

      _socket?.emit('location_update', payload);
      print('📍 Ubicación actualizada: $latitude, $longitude');
    } catch (e) {
      print('❌ Error enviando actualización de ubicación: $e');
    }
  }

  /// Actualización de pago
  void updatePayment({
    required String paymentId,
    required String cobradorId,
    required String clientId,
    required double amount,
    required String status,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) {
    Map<String, dynamic> _prune(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        if (v is Map<String, dynamic>) {
          final x = _prune(v);
          if (x.isNotEmpty) out[k] = x;
        } else {
          out[k] = v;
        }
      });
      return out;
    }

    try {
      final raw = {
        'payment': {
          'id': paymentId,
          'amount': amount,
          'status': status,
          'notes': notes,
        },
        'cobradorId': cobradorId,
        'clientId': clientId,
        'from': {
          'id': _currentUserId,
          'name': _currentUserName,
          'type': _currentUserType,
        },
        'additional': additionalData,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = _prune(raw);
      _socket?.emit('payment_update', payload);
    } catch (e) {
      print('❌ Error enviando actualización de pago: $e');
    }
  }

  /// Envío de mensajes
  void sendMessage({
    required String recipientId,
    required String message,
    String? messageType,
    String? senderId,
  }) {
    Map<String, dynamic> _prune(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        out[k] = v;
      });
      return out;
    }

    try {
      final raw = {
        'recipientId': recipientId,
        'message': message,
        'senderId': senderId ?? _currentUserId,
        'messageType': messageType,
      };

      final payload = _prune(raw);
      _socket?.emit('send_message', payload);
    } catch (e) {
      print('❌ Error enviando mensaje: $e');
    }
  }

  /// Envío de notificaciones de rutas
  void sendRouteNotification({
    required Map<String, dynamic> routeData,
  }) {
    Map<String, dynamic> _prune(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        if (v is Map<String, dynamic>) {
          final x = _prune(v);
          if (x.isNotEmpty) out[k] = x;
        } else {
          out[k] = v;
        }
      });
      return out;
    }

    try {
      final raw = {
        ...routeData,
        'from': {
          'id': _currentUserId,
          'name': _currentUserName,
          'type': _currentUserType,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      final payload = _prune(raw);
      _socket?.emit('route_notification', payload);
      print('📤 Notificación de ruta enviada');
    } catch (e) {
      print('❌ Error enviando notificación de ruta: $e');
    }
  }

  /// Envío de eventos de ciclo de vida de créditos
  void sendCreditLifecycle({
    required String action,
    required String creditId,
    String? targetUserId,
    Map<String, dynamic>? credit,
    String? userType,
    String? message,
  }) {
    Map<String, dynamic> _pruneNullsMap(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        if (v is Map<String, dynamic>) {
          final pruned = _pruneNullsMap(v);
          if (pruned.isNotEmpty) out[k] = pruned;
        } else if (v is List) {
          final prunedList = v
              .map((e) => e is Map<String, dynamic> ? _pruneNullsMap(e) : e)
              .where((e) => e != null)
              .toList();
          out[k] = prunedList;
        } else {
          out[k] = v;
        }
      });
      return out;
    }

    try {
      final payloadRaw = {
        'action': action,
        'creditId': creditId,
        'targetUserId': targetUserId,
        'userType': userType,
        'credit': credit,
        'message': message,
        'from': {
          'id': _currentUserId,
          'name': _currentUserName,
          'type': _currentUserType,
        },
        'timestamp': DateTime.now().toIso8601String(),
      };

      var payload = _pruneNullsMap(payloadRaw);

      // Si targetUserId es null/"null"/vacío, eliminar la clave
      final tid = payload['targetUserId'];
      if (tid == null ||
          (tid is String && tid.trim().isEmpty) ||
          tid.toString() == 'null') {
        payload.remove('targetUserId');
      }

      _socket?.emit('credit_lifecycle', payload);
    } catch (e) {
      print('❌ Error enviando evento de ciclo de vida de crédito: $e');
    }
  }

  /// Libera recursos al cerrar
  void dispose() {
    disconnect();
    _connectionController.close();
    _notificationController.close();
    _paymentController.close();
    _routeController.close();
    _messageController.close();
    _locationController.close();
    _globalStatsController.close();
    _cobradorStatsController.close();
    _managerStatsController.close();
    _cashBalanceController.close();
  }
}
