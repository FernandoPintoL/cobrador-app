# Guía rápida: Conectar Flutter a Laravel (Reverb / Pusher protocol)

Esta guía resume las recomendaciones prácticas para que tu app Flutter se conecte a los eventos de Laravel mediante el protocolo Pusher (compatible con Laravel Reverb y con Pusher oficial). Si ya estás usando un servidor WebSocket Node propio, revisa también `documentaciones/FLUTTER_WEBSOCKET_INTEGRATION.md` para integración vía socket.io.

## 1) Elegir el modo de conexión
Tienes dos caminos compatibles con tu backend actual:

- Modo 1: Protocolo Pusher (recomendado con Laravel Reverb) — ideal para usar las emisiones nativas de tus eventos `ShouldBroadcast` y canales privados definidos en `routes/channels.php`.
- Modo 2: Servidor WebSocket externo (socket.io) — si decides consumir los endpoints puente creados en tu backend y un servidor Node.

Esta guía cubre el Modo 1 (Pusher/Reverb) con ejemplos listos para Flutter.

## 2) Paquetes Flutter
En `pubspec.yaml` agrega uno de los paquetes compatibles con Pusher protocol.

Opción A (recomendada por simplicidad):

```
dependencies:
  flutter:
    sdk: flutter
  pusher_channels_flutter: ^2.4.0
  dio: ^5.4.0
```

Opción B (alternativa con Echo):

```
dependencies:
  flutter:
    sdk: flutter
  laravel_echo: ^1.0.0-beta.1
  pusher_client: ^2.0.0
  dio: ^5.4.0
```

## 3) Variables del backend/cliente que debes conocer
Configurar `.env` en Flutter (este repo ya lo tiene preparado):

```
BROADCAST_DRIVER=reverb
REVERB_HOST=192.168.100.21
REVERB_PORT=6001
REVERB_SCHEME=http
REVERB_APP_KEY=jadsb4pnyhj87dff3kuh
APP_URL=http://192.168.100.21:8000
REVERB_AUTH_ENDPOINT=http://192.168.100.21:8000/broadcasting/auth
# opcional: WEBSOCKET_URL=ws://192.168.100.21:6001
```

Canales que se usan hoy (en Laravel):
- `user.{id}`
- `payments`
- `credits-attention`
- `waiting-list`

Importante: Con `pusher_channels_flutter` el nombre final lleva prefijo `private-` (ej. `private-user.{id}`). Con `laravel_echo` NO agregues `private-` (la librería lo hace por ti).

## 4) Configuración en Flutter (pusher_channels_flutter)
Servicio básico para inicializar la conexión y manejar la autenticación privada contra tu API Laravel.

```dart
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:dio/dio.dart';

class ReverbService {
  final _pusher = PusherChannelsFlutter.getInstance();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.100.21:8000',
    validateStatus: (s) => s != null && s >= 200 && s < 500,
  ));

  static const String appKey = 'jadsb4pnyhj87dff3kuh';
  static const String host = '192.168.100.21';
  static const int port = 6001; // REVERB_PORT
  static const bool isTLS = false; // http => false, https => true

  Future connect({
    required String bearerToken,
    required int userId,
  }) async {
    await _pusher.init(
      apiKey: appKey,
      cluster: 'mt1',
      host: host,
      port: port,
      encrypted: isTLS,
      useTLS: isTLS,
      authEndpoint: 'http://192.168.100.21:8000/broadcasting/auth',
      onAuthorizer: (channelName, socketId, options) async {
        final resp = await _dio.post(
          '/broadcasting/auth',
          data: {
            'socket_id': socketId,
            'channel_name': channelName,
          },
          options: Options(headers: {
            'Authorization': 'Bearer $bearerToken',
            'Accept': 'application/json',
          }),
        );
        if (resp.statusCode != 200) {
          throw Exception('Auth fallo: ${resp.statusCode} ${resp.data}');
        }
        return resp.data; // debe ser JSON {auth: "..."}
      },
    );

    await _pusher.connect();

    // Suscribir a tus canales (con pusher_channels_flutter debes poner el prefijo private-)
    await _pusher.subscribe(channelName: 'private-user.$userId', onEvent: (e){});
    for (final ch in ['private-payments','private-credits-attention','private-waiting-list']) {
      await _pusher.subscribe(channelName: ch, onEvent: (e){});
    }
  }

  Future disconnect() async => _pusher.disconnect();
}
```

## 5) Escuchar eventos emitidos desde Laravel
Tus eventos pueden emitir con `broadcastAs()` por ejemplo:
- `payment.received`
- `credit.requires.attention`
- `credit.waiting.list.update`

En Flutter, dentro del callback `onEvent` (pusher_channels_flutter) o `listen` (Echo), compara `eventName` y parsea `data`.

## 6) Prueba rápida paso a paso
Laravel:
- `BROADCAST_DRIVER=reverb`
- Reverb en marcha (`php artisan reverb:start`) o servicio en producción
- `routes/channels.php` contiene `user.{id}`, `payments`, `credits-attention`, `waiting-list`
- Un usuario autenticado puede llamar a `POST /broadcasting/auth`

Flutter:
- Obtén `bearerToken` tras login contra tu API
- Llama `WebSocketService().connect()` o el `ReverbService` del ejemplo
- Verifica que la suscripción a `private-user.{id}` recibe eventos cuando en Laravel `dispatch(new PaymentReceived(...))`

Debug útil:
- Revisa `storage/logs/laravel.log` si la auth de broadcast falla
- Usa logs de la app; este repo imprime estados de conexión

## 7) Alternativa con laravel_echo + pusher_client
Con Echo NO agregues `private-`, usa los nombres tal como están en Laravel:

```dart
import 'package:laravel_echo/laravel_echo.dart';
import 'package:pusher_client/pusher_client.dart';

class EchoService {
  late final Echo echo;

  Future connect({required String bearerToken, required int userId}) async {
    final pusher = PusherClient(
      'jadsb4pnyhj87dff3kuh',
      PusherOptions(host: '192.168.100.21', port: 6001, encrypted: false),
      enableLogging: true,
    );

    echo = Echo(
      broadcaster: 'pusher',
      client: pusher,
      auth: {
        'headers': {
          'Authorization': 'Bearer $bearerToken',
          'Accept': 'application/json',
        }
      },
      authEndpoint: 'http://192.168.100.21:8000/broadcasting/auth',
    );

    echo.private('user.$userId').listen('payment.received', (e) {});
    echo.private('payments').listen('payment.received', (e) {});
    echo.private('credits-attention').listen('credit.requires.attention', (e) {});
    echo.private('waiting-list').listen('credit.waiting.list.update', (e) {});
  }
}
```

## 8) Checklist de red y CORS
- HTTP (no TLS) => `encrypted: false` y conecta a `ws://`
- HTTPS => `wss://` con certificados válidos
- Android 9+: si usas HTTP claro, agrega `network_security_config` para permitir tráfico no seguro a tu host de desarrollo
- Verifica que el puerto de Reverb sea accesible desde el dispositivo

## 9) Seguridad y autorización
- Canales privados ya tienen callbacks en `routes/channels.php` para `user.{id}`, `payments`, `credits-attention`, `waiting-list`
- El backend valida que el `user_id` del token sea el dueño del canal `user.{id}`
- No expongas `REVERB_APP_SECRET` al cliente; sólo usa `APP_KEY`

## 10) Errores comunes
- 401 al suscribirte: Bearer token inválido o falta enviar encabezados en authorizer
- 404/405 en `/broadcasting/auth`: ruta distinta o método incorrecto (debe ser POST)
- Conexión pero sin eventos: revisa `BROADCAST_DRIVER` y que se estén `dispatch` eventos
- En producción con proxy/Nginx: permite Upgrade/Connection hacia el puerto de Reverb

## 11) Cómo está implementado en este repo
- Archivo `.env` con `REVERB_*` ya incluido
- `lib/config/app_bootstrap.dart` detecta REVERB_* o `WEBSOCKET_URL` y configura el `WebSocketService`
- `lib/datos/servicios/websocket_service.dart` conecta con `pusher_channels_flutter` + `laravel_echo`, autoriza contra `/broadcasting/auth` usando el Bearer token almacenado
- Channels en Echo: `user.{id}` y dominios (sin prefijo `private-`), acorde a Echo

Si necesitas adaptar IP/puertos/domino para producción, ajusta `.env` y recompila la app.
