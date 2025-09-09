import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../datos/servicios/websocket_service.dart';
import '../datos/servicios/notification_service.dart';
import '../ui/utilidades/phone_utils.dart';

/// Centraliza la inicialización de servicios usada por main.dart
/// Mantiene el código de arranque más limpio y evita duplicaciones.
class AppBootstrap {
  AppBootstrap._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Inicializa variables de entorno, configura WebSocket y notificaciones.
  /// Es idempotente: se puede llamar múltiples veces sin efectos secundarios.
  static Future<void> init() async {
    if (_initialized) {
      debugPrint('⚠️ AppBootstrap ya inicializado, saltando...');
      return;
    }

    debugPrint('🔧 Iniciando AppBootstrap...');

    // 1) Cargar .env (si falla, continuar igualmente)
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("✅ Variables de entorno cargadas correctamente");
      debugPrint("📋 BASE_URL: ${dotenv.env['BASE_URL']}");
      debugPrint("📋 WEBSOCKET_URL: ${dotenv.env['WEBSOCKET_URL']}");
    } catch (e) {
      debugPrint("⚠️ Error cargando .env: $e");
    }

    // 2) Configurar Reverb/Echo (Pusher). Se intenta con REVERB_*; si no, se infiere desde BASE_URL.
    try {
      final wsService = WebSocketService();

      final host = dotenv.env['REVERB_HOST'];
      final portStr = dotenv.env['REVERB_PORT'];
      final scheme = dotenv.env['REVERB_SCHEME'];

      if (host != null && host.isNotEmpty) {
        final useTLS = (scheme ?? '').toLowerCase() == 'https';
        final url = '${useTLS ? 'wss' : 'ws'}://$host:${useTLS ? '443' : (portStr ?? '6001')}';
        wsService.configureServer(
          url: url,
          isProduction: useTLS,
          enableSSL: useTLS,
        );
        debugPrint('🔧 Reverb configurado desde REVERB_* => $url');
      } else {
        // 1) Intentar con WEBSOCKET_URL directo si existe
        final wsUrl = dotenv.env['WEBSOCKET_URL'];
        if (wsUrl != null && wsUrl.isNotEmpty) {
          // Normalizar puerto con ceros a la izquierda (p.ej. 001 -> 1)
          final parsed = Uri.tryParse(wsUrl);
          if (parsed != null && parsed.host.isNotEmpty) {
            final scheme = parsed.scheme.toLowerCase();
            var port = parsed.hasPort ? parsed.port : (scheme == 'wss' ? 443 : 6001);
            if (port < 1 || port > 65535) {
              debugPrint('⚠️ Puerto inválido en WEBSOCKET_URL ($port). Usando 6001 por defecto.');
              port = 6001;
            }
            final normalizedUrl = '${scheme}://${parsed.host}:$port';
            wsService.configureServer(
              url: normalizedUrl,
              isProduction: scheme == 'wss',
              enableSSL: scheme == 'wss',
            );
            debugPrint('🔧 Reverb configurado desde WEBSOCKET_URL => $normalizedUrl');
          } else {
            debugPrint('⚠️ WEBSOCKET_URL inválido: $wsUrl');
          }
        } else {
          // 2) Fallback: deducir desde BASE_URL (dominio + TLS)
          final baseUrl = dotenv.env['BASE_URL'];
          if (baseUrl != null && baseUrl.isNotEmpty) {
            final uri = Uri.tryParse(baseUrl);
            if (uri != null && uri.host.isNotEmpty) {
              final useTLS = uri.scheme == 'https';
              final url = '${useTLS ? 'wss' : 'ws'}://${uri.host}:${useTLS ? '443' : '6001'}';
              wsService.configureServer(
                url: url,
                isProduction: useTLS,
                enableSSL: useTLS,
              );
              debugPrint('🔧 Reverb configurado desde BASE_URL => $url');
            }
          } else {
            debugPrint('⚠️ No hay REVERB_*, WEBSOCKET_URL ni BASE_URL válidos; se usará configuración por defecto en el servicio');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error configurando Reverb: $e');
    }

    // 3) Inicializar validación/formateo de teléfonos
    try {
      await PhoneUtils.init(defaultCountry: (dotenv.env['DEFAULT_COUNTRY'] ?? 'BO'));
      debugPrint('📱 PhoneUtils inicializado');
    } catch (e) {
      debugPrint('⚠️ Error inicializando PhoneUtils: $e');
    }

    // 4) Inicializar servicio de notificaciones (idempotente)
    try {
      await NotificationService().initialize();
      debugPrint("🔔 Servicio de notificaciones inicializado");
    } catch (e) {
      debugPrint("⚠️ Error inicializando notificaciones: $e");
    }

    _initialized = true;
    debugPrint('✅ AppBootstrap completado exitosamente');
  }
}
