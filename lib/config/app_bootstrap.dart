import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../datos/api_services/websocket_service.dart';
import '../datos/api_services/notification_service.dart';
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

    // 2) Configurar WebSocket para Socket.IO
    try {
      final wsService = WebSocketService();

      // ============================================
      // MODO SOCKET.IO (Node.js WebSocket Server)
      // ============================================
      final nodeUrl =
          dotenv.env['NODE_WEBSOCKET_URL'] ?? dotenv.env['WEBSOCKET_URL'] ?? '';

      if (nodeUrl.isEmpty) {
        debugPrint('⚠️ NODE_WEBSOCKET_URL no configurado en .env');
        debugPrint('💡 Agrega: NODE_WEBSOCKET_URL=http://192.168.1.23:3001');
      } else {
        wsService.configureServer(url: nodeUrl);
        debugPrint('✅ Socket.IO configurado: $nodeUrl');
        debugPrint('📌 Eventos disponibles según documentación:');
        debugPrint(
          '   - credit_waiting_approval, credit_approved, credit_rejected',
        );
        debugPrint('   - payment_received, cobrador_payment_received');
        debugPrint('   - cash_balance_reminder (CRÍTICO para cobradores)');
      }
    } catch (e) {
      debugPrint('❌ Error configurando WebSocket: $e');
    }

    // 3) Inicializar validación/formateo de teléfonos
    try {
      await PhoneUtils.init(
        defaultCountry: (dotenv.env['DEFAULT_COUNTRY'] ?? 'BO'),
      );
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
