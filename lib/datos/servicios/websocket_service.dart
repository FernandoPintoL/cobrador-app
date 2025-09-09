import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../modelos/usuario.dart';
import 'storage_service.dart';
import 'notification_service.dart';

/// Servicio de tiempo real sobre Laravel Reverb (protocolo Pusher)
/// Mantiene la API pública anterior en la medida de lo posible para minimizar cambios.
class WebSocketService {
  // Modo de transporte: 'reverb' (por defecto) o 'socketio' (Node.js Socket.IO)
  static String _transportMode = (dotenv.env['REALTIME_TRANSPORT'] ?? 'reverb').toLowerCase();
  static String _nodeUrl = dotenv.env['NODE_WEBSOCKET_URL'] ?? dotenv.env['WEBSOCKET_NODE_URL'] ?? dotenv.env['WEBSOCKET_URL'] ?? '';
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  // Echo/Pusher
  Echo? _echo;
  PusherChannelsFlutter? _pusher;

    // Socket.IO
    dynamic _socket; // usar tipo dinámico para evitar dependencia dura si no se usa

  // Estado y configuración
  bool _isConnected = false;
  bool _isConnecting = false;

  // Config Reverb
  String _reverbKey = dotenv.env['REVERB_APP_KEY'] ?? 'jadsb4pnyhj87dff3kuh';
  String _host = dotenv.env['REVERB_HOST'] ?? '192.168.100.21';
  int _port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? 6001;
  bool _useTLS = (dotenv.env['REVERB_SCHEME'] ?? '').toLowerCase() == 'https';
  String _cluster = dotenv.env['REVERB_CLUSTER'] ?? 'mt1';
  String _authEndpoint = dotenv.env['REVERB_AUTH_ENDPOINT'] ??
      (dotenv.env['BASE_URL']?.replaceFirst(RegExp(r'/api/?$'), '') ??
          'http://192.168.100.21:8000') +
          '/broadcasting/auth';

  String _sanitizeHost(String h) {
    var host = (h ?? '').trim();
    if (host.isEmpty) return host;
    host = host.replaceFirst(RegExp(r'^https?://', caseSensitive: false), '');
    host = host.split('/').first; // remove any path
    return host;
  }

  // Si hay WEBSOCKET_URL en .env, úsalo para sobreescribir host/puerto/TLS en el arranque
  void _applyWebsocketUrlFromEnvIfPresent() {
    if (_transportMode == 'socketio') {
      // En modo Socket.IO usamos _nodeUrl completo (http(s)://host:port)
      return;
    }
    final wsUrl = dotenv.env['WEBSOCKET_URL'];
    if (wsUrl == null || wsUrl.isEmpty) return;
    final uri = Uri.tryParse(wsUrl);
    if (uri == null || uri.host.isEmpty) {
      print('⚠️ WEBSOCKET_URL inválido: $wsUrl');
      return;
    }
    _host = uri.host;
    _useTLS = uri.scheme.toLowerCase() == 'wss';
    _port = uri.hasPort ? uri.port : (_useTLS ? 443 : 6001);
    if (_port < 1 || _port > 65535) {
      print('⚠️ Puerto inválido en WEBSOCKET_URL (${_port}). Se usará 6001.');
      _port = 6001;
    }
  }

  // Streams para diferentes tipos de eventos
  final _connectionController = StreamController<bool>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _paymentController = StreamController<Map<String, dynamic>>.broadcast();
  final _routeController = StreamController<Map<String, dynamic>>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _locationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Deduplicación simple de eventos para evitar múltiples notificaciones por la misma acción
  final Map<String, DateTime> _recentEventCache = {};
  static const Duration _dedupeWindow = Duration(seconds: 3);
  bool _shouldDropDuplicate(String category, Map<String, dynamic> map) {
    try {
      // Construir una clave estable basada en campos comunes si existen
      final type = (map['type'] ?? map['action'] ?? '').toString();
      final id = (map['payment']?['id'] ?? map['credit']?['id'] ?? map['creditId'] ?? map['id'] ?? '').toString();
      final key = '$category|$type|$id|${map['message'] ?? ''}';
      final now = DateTime.now();
      final last = _recentEventCache[key];
      // Limpieza ligera
      _recentEventCache.removeWhere((_, ts) => now.difference(ts) > const Duration(seconds: 10));
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

  // Info de usuario autenticado (para canales privados)
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

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  String get serverUrlSummary {
      final h = _sanitizeHost(_host);
      return '${_useTLS ? 'wss' : 'ws'}://$h:${_port} (key=$_reverbKey)';
    }

  /// Configuración manual (compatibilidad con la API anterior)
  /// Si te pasan una URL tipo ws(s)://, solo se usará para decidir TLS/host/puerto.
  void configureServer({
    required String url,
    bool isProduction = false,
    String? authToken,
    bool enableSSL = false,
    Duration? timeout,
    int? reconnectAttempts,
    Duration? reconnectDelay,
  }) {
    try {
      // Intentar parsear URL simple ws://host:port
      final uri = Uri.tryParse(url);
      if (uri != null && uri.host.isNotEmpty) {
        _host = uri.host;
        _useTLS = uri.scheme == 'wss' || enableSSL || isProduction;
        _port = uri.hasPort ? uri.port : (_useTLS ? 443 : 6001);
      }

      // Permitir override por .env si están definidos
      _reverbKey = dotenv.env['REVERB_APP_KEY'] ?? _reverbKey;
      final envHost = dotenv.env['REVERB_HOST'];
      if (envHost != null && envHost.isNotEmpty) {
        _host = _sanitizeHost(envHost);
      }
      _port = int.tryParse(dotenv.env['REVERB_PORT'] ?? '') ?? _port;
      _useTLS = (dotenv.env['REVERB_SCHEME'] ?? (_useTLS ? 'https' : 'http'))
              .toLowerCase() ==
          'https';
      _cluster = dotenv.env['REVERB_CLUSTER'] ?? _cluster;
      _authEndpoint = dotenv.env['REVERB_AUTH_ENDPOINT'] ?? _authEndpoint;

      print('🔧 Reverb configurado:');
      print('  - host: $_host');
      print('  - port: $_port');
      print('  - useTLS: $_useTLS');
      print('  - cluster: $_cluster');
      print('  - key: $_reverbKey');
      print('  - authEndpoint: $_authEndpoint');
    } catch (e) {
      print('❌ Error en configureServer: $e');
    }
  }

  /// Inicializa Echo/Pusher y se suscribe a canales básicos.
  Future<bool> connect() async {
      // Seleccionar transporte según .env
      if (_transportMode == 'socketio') {
        return _connectSocketIO();
      }
    // Desktop platforms are not supported by pusher_channels_flutter.
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS)) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      print('ℹ️ WebSocket deshabilitado en escritorio: pusher_channels_flutter no está disponible.');
      return false;
    }
    // Evitar usar pusher_channels_flutter en plataformas no soportadas (desktop)
    // Desktop: Windows, macOS, Linux no tienen implementación del plugin.
    // En esos casos, salimos con estado desconectado pero sin lanzar excepción.
    try {
      // kIsWeb is unavailable here without Flutter import; use environment via String.fromEnvironment? Simpler: rely on defaultTargetPlatform in callers.
    } catch (_) {}
    // Aplicar WEBSOCKET_URL si está presente en .env antes de conectar
    _applyWebsocketUrlFromEnvIfPresent();
    // Asegurar notificaciones
    unawaited(_initializeNotifications());

    if (_isConnected || _isConnecting) {
      print('🔄 Ya conectado o conectando');
      return _isConnected;
    }

    // Conectividad de red
    if (!await _checkNetworkConnectivity()) {
      print('❌ Sin conectividad de red');
      return false;
    }

    _isConnecting = true;
    _connectionController.add(false);

    try {
      // Token y userId desde storage
      final storage = StorageService();
      final token = await storage.getToken();
      final usuario = await storage.getUser();
      _currentUserId = usuario?.id.toString();
      _currentUserName = usuario?.nombre;
      _currentUserType = (usuario?.roles.isNotEmpty ?? false)
          ? usuario!.roles.first
          : null;

      final pusher = PusherChannelsFlutter.getInstance();
      print('🤢 Token baerer $token ...');

      final hostForPusher = _sanitizeHost(_host);
      final wsPort = _useTLS ? null : (_port > 0 ? _port : 6001);
      final wssPort = _useTLS ? (_port > 0 ? _port : 443) : null;

      await pusher.init(
        apiKey: _reverbKey,
        // Nota: Esta versión de pusher_channels_flutter no soporta host/wsPort/wssPort como parámetros.
        // Si necesitas conectarte a un Reverb self-hosted con dominio/puerto custom,
        // considera usar REALTIME_TRANSPORT=socketio en .env para usar el backend Node,
        // o actualiza el plugin a una versión que soporte opciones avanzadas.
        cluster: _cluster, // Reverb ignora cluster; usamos 'mt1' para silenciar warnings
        useTLS: _useTLS,
        authEndpoint: _authEndpoint,
        onAuthorizer: (channelName, socketId, options) async {
          // Autorización de canales privados/presencia hacia Laravel
          try {
            final uri = Uri.parse(_authEndpoint);
            final resp = await http.post(
              uri,
              headers: {
                'Authorization': 'Bearer ${token ?? ''}',
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'socket_id': socketId,
                'channel_name': channelName,
              }),
            );
            if (resp.statusCode != 200) {
              throw Exception('Auth fallo ${resp.statusCode}: ${resp.body}');
            }
            return jsonDecode(resp.body);
          } catch (e) {
            throw Exception('Auth exception: $e');
          }
        },
        onConnectionStateChange: (currentState, previousState) {
          print('🔗 Estado conexión Pusher: $previousState -> $currentState');
        },
        onError: (message, code, exception) {
          print('❌ Pusher error: $message ($code) $exception');
        },
      );

      await pusher.connect();

      _pusher = pusher;

      // Suscribirse a canales por defecto usando Pusher directamente
      _subscribeDefaultChannels(usuario);

      _isConnected = true;
      _isConnecting = false;
      _connectionController.add(true);
      print('✅ Conectado a Reverb (Pusher): ${serverUrlSummary}');
      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _connectionController.add(false);
      print('❌ Error conectando a Reverb: $e');
      return false;
    }
  }

  void _subscribeDefaultChannels(Usuario? usuario) {
    if (_pusher == null) return;

    try {
      // Canal público básico (si tu backend emite eventos públicos)
      _pusher!.subscribe(
        channelName: 'public-channel',
        onEvent: (event) {
          // Si tu backend usa eventos nombrados, puedes filtrar por event.eventName
          _handleNotification(event.data);
        },
      );

      // Canal privado por usuario (si tenemos id)
      if (usuario?.id != null) {
        final userId = usuario!.id.toString();
        // Con pusher_channels_flutter debes incluir el prefijo "private-"
        _pusher!.subscribe(
          channelName: 'private-user.$userId',
          onEvent: (event) {
            final name = (event.eventName ?? '').toLowerCase();
            final data = event.data;
            if (name.contains('payment.received')) {
              _handlePaymentUpdate(data);
            } else if (name.contains('credit.requires.attention')) {
              _handleNotification(data);
            } else if (name.contains('credit.waiting.list.update')) {
              _handleRouteUpdate(data);
            } else if (name.contains('message.received')) {
              _handleMessage(data);
            } else {
              _handleNotification(data);
            }
          },
        );
      }

      // Canales de dominio
      for (final ch in const ['private-payments','private-credits-attention','private-waiting-list']) {
        _pusher!.subscribe(
          channelName: ch,
          onEvent: (event) {
            final name = (event.eventName ?? '').toLowerCase();
            final data = event.data;
            if (name.contains('payment.received')) {
              _handlePaymentUpdate(data);
            } else if (name.contains('credit.requires.attention')) {
              _handleNotification(data);
            } else if (name.contains('credit.waiting.list.update')) {
              _handleRouteUpdate(data);
            } else {
              _handleNotification(data);
            }
          },
        );
      }

      print('🎯 Suscripciones a canales Reverb (Pusher) preparadas');
    } catch (e) {
      print('❌ Error suscribiendo a canales: $e');
    }
  }

  /// NOTA IMPORTANTE (migración):
  /// En Pusher/Reverb el cliente no "emite" eventos arbitrarios al servidor.
  /// Las operaciones de envío (sendCreditNotification, updatePayment, etc.)
  /// deben realizarse vía HTTP hacia la API Laravel, y el backend emite eventos
  /// ShouldBroadcast. Para no romper la app, mantenemos los métodos como no-op
  /// con logs informativos.

  Future<bool> authenticate({required String userId, required String userName, required String userType, String? authToken}) async {
    // Con Echo, la autenticación de privados/presencia ya se maneja con authEndpoint
    _currentUserId = userId;
    _currentUserName = userName;
    _currentUserType = userType;
    if (_transportMode == 'socketio') {
      _currentUserId = userId;
      _currentUserName = userName;
      _currentUserType = userType;
      try {
        _socket?.emit('authenticate', {
          'userId': userId,
          'userType': userType,
          'userName': userName,
        });
      } catch (_) {}
      return true;
    }
    print('ℹ️ Autenticación de canales privados/presencia se realiza vía $_authEndpoint');
    return true;
  }

  void sendCreditNotification({required String targetUserId, required String title, required String message, String type = 'credit', Map<String, dynamic>? additionalData}) {
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
    if (_transportMode == 'socketio') {
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
        return;
      } catch (e) {
        print('❌ Error emitiendo credit_notification: $e');
      }
    }
    // Reverb: mantener no-op
    print('ℹ️ [frontend-blocked] sendCreditNotification: Debe hacerse vía HTTP a la API Laravel. Node emitirá a clientes.');
  }

  void updateLocation(double latitude, double longitude, {String? address, double? accuracy}) {
    Map<String, dynamic> _prune(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        out[k] = v;
      });
      return out;
    }
    if (_transportMode == 'socketio') {
          try {
            final raw = {
              'user_id': _currentUserId,
              'latitude': latitude,
              'longitude': longitude,
              'address': address,
              'accuracy': accuracy,
              'timestamp': DateTime.now().toIso8601String(),
            };
            final payload = _prune(raw);
            _socket?.emit('location_update', payload);
          } catch (e) {
            print('❌ Error emitiendo location_update: $e');
          }
          return;
        }
        print('ℹ️ updateLocation: envía ubicación vía HTTP; el backend broadcast con ShouldBroadcast.');
  }

  void updatePayment({required String paymentId, required String cobradorId, required String clientId, required double amount, required String status, String? notes, Map<String, dynamic>? additionalData}) {
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
    if (_transportMode == 'socketio') {
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
        return;
      } catch (e) {
        print('❌ Error emitiendo payment_update: $e');
      }
    }
    print('ℹ️ [frontend-blocked] updatePayment: Realizar vía API HTTP; Laravel -> Node emitirá notificaciones.');
  }

  void sendMessage({required String recipientId, required String message, String? messageType, String? senderId}) {
    Map<String, dynamic> _prune(Map<String, dynamic> m) {
      final out = <String, dynamic>{};
      m.forEach((k, v) {
        if (v == null) return;
        out[k] = v;
      });
      return out;
    }
    if (_transportMode == 'socketio') {
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
            print('❌ Error emitiendo send_message: $e');
          }
          return;
        }
        print('ℹ️ sendMessage: envía el mensaje por HTTP; Laravel emitirá evento NewMessage.');
  }

  void sendCreditLifecycle({required String action, required String creditId, String? targetUserId, Map<String, dynamic>? credit, String? userType, String? message}) {
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
    if (_transportMode == 'socketio') {
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
        // Si targetUserId es null/"null"/vacío, eliminar la clave para evitar enviar Null
        final tid = payload['targetUserId'];
        if (tid == null || (tid is String && tid.trim().isEmpty) || tid.toString() == 'null') {
          payload.remove('targetUserId');
        }
        _socket?.emit('credit_lifecycle', payload);
        return;
      } catch (e) {
        print('❌ Error emitiendo credit_lifecycle: $e');
      }
    }
    print('ℹ️ [frontend-blocked] sendCreditLifecycle: Realizar vía API; Laravel -> Node disparará evento.');
  }

    // --- Socket.IO (Node) ---
  Future<bool> _connectSocketIO() async {
      try {
        if (_isConnected || _isConnecting) {
          return _isConnected;
        }

        // Comprobar conectividad
        if (!await _checkNetworkConnectivity()) {
          print('❌ Sin conectividad de red');
          return false;
        }

        // Validar URL del servidor Node
        String url = _nodeUrl.isNotEmpty ? _nodeUrl : (dotenv.env['NODE_WEBSOCKET_URL'] ?? '');
        if (url.isEmpty) {
          print('❌ NODE_WEBSOCKET_URL no configurado en .env');
          return false;
        }
        // Normalizar URL: quitar barras finales y agregar esquema si falta
        url = url.trim();
        if (!url.startsWith('http')) {
          // Si el .env solo puso dominio/host, asumimos https en producción
          final isProd = (dotenv.env['APP_ENV'] ?? '').toLowerCase() == 'production' || (dotenv.env['REVERB_SCHEME'] ?? 'https') == 'https';
          url = '${isProd ? 'https' : 'http'}://$url';
        }
        // Socket.IO suele atender en /socket.io por defecto; permitir override por env NODE_WEBSOCKET_PATH o WEBSOCKET_ENDPOINT
        final endpoint = (dotenv.env['NODE_WEBSOCKET_PATH'] ?? dotenv.env['WEBSOCKET_ENDPOINT'] ?? '/socket.io').trim();
        // Construir origin sin barras finales y path normalizado
        final origin = url.replaceAll(RegExp(r'/+$'), '');
        final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
        final logUrl = '$origin$path';

        _isConnecting = true;
        _connectionController.add(false);

        // Cargar user para autenticar al conectar
        final storage = StorageService();
        final usuario = await storage.getUser();
        _currentUserId = usuario?.id?.toString();
        _currentUserName = usuario?.nombre;
        _currentUserType = (usuario?.roles.isNotEmpty ?? false) ? usuario!.roles.first : null;

        // Cargar socket_io_client dinámicamente a través de dart:mirrors no es posible.
        // Lo declaramos como dependencia en pubspec y usamos import diferido? No aquí; asumimos disponibilidad.
        // Para evitar import estático en este archivo mixto, utilizamos package:socket_io_client a través de Function.apply mediante mirrors no disponible.
        // Por simplicidad y compatibilidad, realizaremos un import condicional en comentarios y usaremos dynamic aquí.
        // ignore: avoid_dynamic_calls
        // Construir opciones con socket_io_client directamente
        final optsBuilder = IO.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .setTimeout(10000);
        // Pasar token JWT o datos en query si el servidor lo requiere
        final storageForAuth = StorageService();
        final tokenForAuth = await storageForAuth.getToken();
        if (tokenForAuth != null && tokenForAuth.isNotEmpty) {
          try { optsBuilder.setQuery({'token': tokenForAuth}); } catch (_) {}
          try { optsBuilder.setExtraHeaders({'Authorization': 'Bearer $tokenForAuth'}); } catch (_) {}
        }
        // Establecer path explícitamente si la lib soporta
        try { optsBuilder.setPath(endpoint); } catch (_) {}
        final opts = optsBuilder.build();

        // Si es https, asegurar transporte websocket y certificado válido (confía en CA del dispositivo)
        _socket = IO.io(origin, opts);
        print('🌐 Intentando Socket.IO en: ' + logUrl + ' (origin=' + origin + ', path=' + path + ')');

        // Listeners
        // Listener de depuración para todos los eventos conocidos (si la lib lo soporta no existe wildcard)
        // Agregamos un pequeño puente: si el servidor emite 'debug_event', lo mostraremos.
        _socket.on('debug_event', (data) {
          try {
            print('🐞 debug_event: ' + (data is String ? data : jsonEncode(data)));
          } catch (_) { print('🐞 debug_event (sin datos parseables)'); }
        });

        _socket.on('connect', (_) {
          print('🔗 Conectado a Socket.IO: $url');
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
            print('🔐 Emite authenticate -> ' + jsonEncode(authPayload));
            _socket.emit('authenticate', authPayload);
          } else {
            print('ℹ️ authenticate omitido: faltan userId o userType');
          }
        });

        // Respuestas de autenticación del servidor
        _socket.on('authenticated', (data) {
          try {
            print('✅ Autenticado en Socket.IO: ' + (data is String ? data : jsonEncode(data)));
          } catch (_) { print('✅ Autenticado en Socket.IO'); }
        });
        _socket.on('auth_error', (data) {
          try {
            print('⛔ auth_error: ' + (data is String ? data : jsonEncode(data)));
          } catch (_) { print('⛔ auth_error'); }
        });
        // El servidor emite 'authentication_error' en server.js
        _socket.on('authentication_error', (data) {
          try {
            print('⛔ authentication_error: ' + (data is String ? data : jsonEncode(data)));
          } catch (_) { print('⛔ authentication_error'); }
        });
        _socket.on('error', (data) {
          try {
            print('⛔ error: ' + (data is String ? data : jsonEncode(data)));
          } catch (_) { print('⛔ error (sin datos)'); }
        });

        _socket.on('disconnect', (_) {
          print('🔌 Desconectado de Socket.IO');
          _isConnected = false;
          _connectionController.add(false);
        });

        _socket.on('connect_error', (err) {
          print('❌ Error de conexión Socket.IO: $err');
        });

        // Eventos de negocio
        // Crédtos
        for (final ev in [
          'credit_waiting_approval',
          'credit_approved',
          'credit_rejected',
          'credit_delivered',
          'credit_attention_required',
          'credit_pending_approval',
          'credit_delivered_notification',
          'credit_lifecycle_update',
          'new_credit_notification',
        ]) {
          _socket.on(ev, (data) {
            _handleNotification(data);
          });
        }

        // Pagos
        for (final ev in [
          'payment_received',
          'cobrador_payment_received',
          'payment_update', // alias frecuente
          'payment_updated',
        ]) {
          _socket.on(ev, (data) {
            // payment_received/cobrador_payment_received prefer payment handler
            if (ev == 'payment_updated' || ev == 'payment_received') {
              _handlePaymentUpdate(data);
            } else {
              _handleNotification(data);
            }
          });
        }

        // Rutas y mensajes
        _socket.on('route_updated', (data) => _handleRouteUpdate(data));
        _socket.on('new_message', (data) => _handleMessage(data));
        _socket.on('cobrador_location_update', (data) => _handleLocationUpdate(data));
        _socket.on('notification', (data) {
          print('🔔 notification recibido');
          _handleNotification(data);
        });
        // Alias genéricos comunes
        for (final ev in ['new_notification','notify','broadcast_notification']) {
          _socket.on(ev, (data) {
            print('🔔 ' + ev + ' recibido');
            _handleNotification(data);
          });
        }

        // Autoconectar
        _socket.connect();

        // Inicializar notificaciones locales
        unawaited(_initializeNotifications());

        return true;
      } catch (e) {
        print('❌ Error conectando a Socket.IO: $e');
        _isConnecting = false;
        _isConnected = false;
        _connectionController.add(false);
        return false;
      }
    }
  // Handlers de datos recibidos
  Map<String, dynamic> _deepSanitizeToMap(dynamic data) {
    try {
      if (data == null) return <String, dynamic>{};
      // If it's already a Map<String, dynamic>
      if (data is Map<String, dynamic>) {
        return data.map((key, value) => MapEntry(key.toString(), _deepSanitize(value)));
      }
      // If it's a Map<dynamic, dynamic>
      if (data is Map) {
        final out = <String, dynamic>{};
        data.forEach((k, v) {
          out[k.toString()] = _deepSanitize(v);
        });
        return out;
      }
      // If it's a String json
      if (data is String) {
        final decoded = jsonDecode(data);
        return _deepSanitizeToMap(decoded);
      }
      // Fallback: try jsonEncode/Decode roundtrip
      final tmp = jsonDecode(jsonEncode(data));
      return _deepSanitizeToMap(tmp);
    } catch (_) {
      // As last resort, wrap as message
      return <String, dynamic>{'message': data.toString()};
    }
  }

  dynamic _deepSanitize(dynamic value) {
    try {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        return value.map((k, v) => MapEntry(k, _deepSanitize(v)));
      }
      if (value is Map) {
        final out = <String, dynamic>{};
        value.forEach((k, v) {
          out[k.toString()] = _deepSanitize(v);
        });
        return out;
      }
      if (value is List) {
        return value.map((e) => _deepSanitize(e)).toList();
      }
      if (value is num || value is bool || value is String) return value;
      // Try to convert unknown interop objects via JSON
      try {
        final decoded = jsonDecode(jsonEncode(value));
        return _deepSanitize(decoded);
      } catch (_) {
        return value.toString();
      }
    } catch (_) {
      return value.toString();
    }
  }

  // Handlers de datos recibidos
  void _handleNotification(dynamic data) {
    try {
      final map = _deepSanitizeToMap(data);
      // Dedupe guard
      if (_shouldDropDuplicate('notif', map)) {
        print('🛑 Notificación duplicada descartada');
        return;
      }
      final title = (map['title'] ?? 'Notificación').toString();
      final body = (map['message'] ?? map['body'] ?? '').toString();
      debugPrint("📥 WS notif: title='$title', type='${map['type']}', body='$body'");
      _notificationController.add(map);
      _showLocalNotification(title, body.isEmpty ? 'Tienes una nueva notificación' : body,
          payload: jsonEncode(map));
    } catch (e) {
      print('❌ Error procesando notificación: $e');
    }
  }

  void _handlePaymentUpdate(dynamic data) {
    try {
      final map = _deepSanitizeToMap(data);
      // Dedupe guard
      if (_shouldDropDuplicate('payment', map)) {
        print('🛑 Pago duplicado descartado');
        return;
      }
      _paymentController.add(map);
      final amount = map['amount'] ?? map['payment']?['amount'];
      debugPrint("📥 WS payment: type='${map['type']}', amount='${amount ?? ''}'");
      final title = 'Pago actualizado';
      final body = amount != null ? 'Monto: $amount Bs.' : 'Se actualizó un pago';
      _showLocalNotification(title, body, payload: jsonEncode(map));
    } catch (e) {
      print('❌ Error procesando pago: $e');
    }
  }

  void _handleRouteUpdate(dynamic data) {
    try {
      final map = _deepSanitizeToMap(data);
      _routeController.add(map);
    } catch (e) {
      print('❌ Error procesando ruta: $e');
    }
  }

  void _handleMessage(dynamic data) {
    try {
      final map = _deepSanitizeToMap(data);
      _messageController.add(map);
      final text = map['message']?.toString() ?? '';
      _showLocalNotification('Nuevo mensaje', text.isEmpty ? 'Has recibido un mensaje' : text,
          payload: jsonEncode(map));
    } catch (e) {
      print('❌ Error procesando mensaje: $e');
    }
  }

  void _handleLocationUpdate(dynamic data) {
    try {
      final map = _deepSanitizeToMap(data);
      _locationController.add(map);
    } catch (e) {
      print('❌ Error procesando ubicación: $e');
    }
  }

  // Utilidades
  Future<bool> _checkNetworkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) return;
    try {
      final ok = await NotificationService().initialize();
      _notificationsInitialized = ok;
      if (ok) {
        print('🔔 Notificaciones locales inicializadas');
      }
    } catch (e) {
      print('❌ Error inicializando notificaciones locales: $e');
    }
  }

  Future<void> _showLocalNotification(String title, String body, {String? payload}) async {
    try {
      if (!_notificationsInitialized) {
        await _initializeNotifications();
      }
      await NotificationService().showGeneralNotification(
        title: title,
        body: body,
        type: 'realtime',
        payload: payload,
      );
    } catch (e) {
      print('❌ Error mostrando notificación local: $e');
    }
  }

  void disconnect() {
      if (_transportMode == 'socketio') {
        try {
          _socket?.disconnect();
          _socket = null;
        } catch (_) {}
      }
    print('🔌 Desconectando Reverb...');
    try {
      _echo?.disconnect();
      _pusher?.disconnect();
    } catch (_) {}
    _echo = null;
    _pusher = null;
    _isConnected = false;
    _isConnecting = false;
    _connectionController.add(false);
    print('✅ Desconectado');
  }

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
