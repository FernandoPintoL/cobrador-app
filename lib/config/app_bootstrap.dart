import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../datos/servicios/websocket_service.dart';
import '../datos/servicios/notification_service.dart';

/// Centraliza la inicialización de servicios usada por main.dart
/// Mantiene el código de arranque más limpio y evita duplicaciones.
class AppBootstrap {
  AppBootstrap._();

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  /// Inicializa variables de entorno, configura WebSocket y notificaciones.
  /// Es idempotente: se puede llamar múltiples veces sin efectos secundarios.
  static Future<void> init() async {
    if (_initialized) return;

    // 1) Cargar .env (si falla, continuar igualmente)
    try {
      await dotenv.load(fileName: ".env");
      debugPrint("✅ Variables de entorno cargadas correctamente");
    } catch (e) {
      debugPrint("⚠️ Error cargando .env: $e");
    }

    // 2) Configurar WebSocket a partir de la URL (si existe)
    try {
      final websocketUrl = dotenv.env['WEBSOCKET_URL'];
      if (websocketUrl != null && websocketUrl.isNotEmpty) {
        final wsService = WebSocketService();
        final isProduction = websocketUrl.contains('railway.app') || websocketUrl.startsWith('wss://');
        wsService.configureServer(
          url: websocketUrl,
          isProduction: isProduction,
          enableSSL: websocketUrl.startsWith('wss://'),
        );
        debugPrint("🔧 WebSocket configurado con URL: $websocketUrl");
        debugPrint("🏭 Modo: ${isProduction ? 'Producción' : 'Desarrollo'}");
      } else {
        debugPrint("⚠️ WEBSOCKET_URL no encontrada en .env");
      }
    } catch (e) {
      debugPrint("❌ Error configurando WebSocket: $e");
    }

    // 3) Inicializar servicio de notificaciones (idempotente)
    try {
      await NotificationService().initialize();
      debugPrint("🔔 Servicio de notificaciones inicializado");
    } catch (e) {
      debugPrint("⚠️ Error inicializando notificaciones: $e");
    }

    _initialized = true;
  }
}
