import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../providers/auth_provider.dart';

/// Observer para detectar cambios de rutas/pantallas
class AutoLogoutNavigatorObserver extends NavigatorObserver {
  final void Function(String? routeName) onScreenChange;
  String? lastRouteName;

  AutoLogoutNavigatorObserver(this.onScreenChange);

  String? _routeName(Route<dynamic>? route) {
    try {
      return route?.settings.name;
    } catch (_) {
      return null;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    lastRouteName = _routeName(route);
    onScreenChange(lastRouteName);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    lastRouteName = _routeName(previousRoute);
    onScreenChange(lastRouteName);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    lastRouteName = _routeName(newRoute);
    onScreenChange(lastRouteName);
  }
}

/// Servicio que maneja el cierre de sesión automático cuando el usuario
/// cambia de pantalla o aplicación, excepto para aplicaciones/pantallas específicas permitidas
class AutoLogoutService extends WidgetsBindingObserver {
  final Ref ref;
  bool _isEnabled = true;
  Timer? _logoutTimer;
  String? _currentRoute;
  DateTime? _lastPausedTime;
  bool _wasInAllowedContext = false;

  // Pantallas/rutas internas permitidas: se permite TODA pantalla interna
  static const Set<String> _allowedRoutes = {
    // Nota: Todas las rutas internas están permitidas por política actual
  };

  // Nombres de pantallas internas permitidas: TODAS las pantallas internas
  static const Set<String> _allowedScreenNames = {
    // Nota: Todas las pantallas internas están permitidas por política actual
  };

  // Contextos que sugieren uso de aplicaciones permitidas
  static const Set<String> _allowedContexts = {
    'image_picker_in_progress',
    'camera_access_active',
    'maps_navigation_active',
    'phone_call_active',
    'gallery_access_active',
    'whatsapp_usage_active',
  };

  // Tiempo de gracia mínimo para aplicaciones permitidas (en segundos)
  static const int _graceTimeSeconds = 30;

  AutoLogoutService(this.ref) {
    WidgetsBinding.instance.addObserver(this);
    debugPrint('🔐 AutoLogoutService inicializado con logout inmediato');
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoutTimer?.cancel();
    debugPrint('🔐 AutoLogoutService desechado');
  }

  /// Habilita o deshabilita el auto logout
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    debugPrint('🔐 AutoLogout ${enabled ? 'habilitado' : 'deshabilitado'}');
    if (!enabled) {
      _cancelScheduledLogout();
    }
  }

  /// Marca que estamos en un contexto de aplicación permitida
  void markAllowedContext(String context) {
    debugPrint('✅ Contexto permitido marcado: $context');
    _wasInAllowedContext = true;
    _cancelScheduledLogout();
  }

  /// Limpia el contexto de aplicación permitida
  void clearAllowedContext() {
    debugPrint('🧹 Limpiando contexto permitido');
    _wasInAllowedContext = false;
  }

  /// Notifica un cambio de pantalla
  void onScreenChanged([String? routeName]) {
    if (!_isEnabled) return;

    _currentRoute = routeName;
    debugPrint('🧭 Cambio de pantalla detectado. Ruta: ${_currentRoute ?? '(desconocida)'}');

    // Verificar si el usuario está autenticado antes de programar logout
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      debugPrint('ℹ️ Usuario no autenticado, no se requiere logout');
      return;
    }

    // ✅ CAMBIO PRINCIPAL: Solo cancelar logout programado si existe
    // No programar logout por cambios de pantalla INTERNOS de la app
    debugPrint('📱 Navegación interna de la app - NO programar logout');
    _cancelScheduledLogout(); // Cancelar cualquier logout programado por cambios externos
  }

  /// Verifica si estamos en un contexto permitido de app externa
  bool _isInAllowedScreen() {
    // Solo consideramos permitido si fue marcado explícitamente por AllowedAppsHelper
    if (_wasInAllowedContext) {
      debugPrint('✅ Contexto permitido activo (marcado manualmente)');
      return true;
    }
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Solo ejecutar si el servicio está habilitado
    if (!_isEnabled) {
      debugPrint('🔐 AutoLogout deshabilitado, ignorando cambio de ciclo: $state');
      return;
    }

    // Verificar si el usuario está autenticado
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      debugPrint('ℹ️ Usuario no autenticado, ignorando cambio de ciclo: $state');
      return;
    }

    debugPrint('🔄 Cambio de ciclo de vida detectado: $state');

    switch (state) {
      case AppLifecycleState.paused:
        _lastPausedTime = DateTime.now();
        debugPrint('⏸️ App pausada - EVALUANDO LOGOUT INMEDIATO');

        // Verificar si estamos en una pantalla interna permitida
        if (_wasInAllowedContext) {
          debugPrint('✅ App pausada en contexto permitido, NO cerrar sesión');
          _cancelScheduledLogout();
        } else {
          // Logout inmediato si se cambia a app NO permitida
          debugPrint('🔐 App pausada fuera de contexto permitido - LOGOUT INMEDIATO');
          _performLogout();
        }
        break;

      case AppLifecycleState.resumed:
        debugPrint('▶️ App resumida - cancelando logout programado');
        // App volvió al primer plano - cancelar logout siempre
        _cancelScheduledLogout();
        // Limpiar contextos temporales
        _wasInAllowedContext = false;
        break;

      case AppLifecycleState.inactive:
        debugPrint('🔕 App inactiva - posible llamada entrante, NO programando logout');
        // No programar logout para llamadas entrantes o notificaciones
        // Este estado es temporal y no indica cambio de app
        break;

      case AppLifecycleState.detached:
        debugPrint('🚪 App desconectada - LOGOUT INMEDIATO por seguridad');
        // La app se está cerrando/desconectando - logout inmediato
        _performLogout();
        break;

      case AppLifecycleState.hidden:
        debugPrint('👁️ App oculta - evaluar logout');
        // No hacer logout instantáneo: respetar contexto permitido o dar gracia
        if (_wasInAllowedContext) {
          debugPrint('✅ App oculta en contexto permitido (camara/galeria/maps/whatsapp/llamada) - NO cerrar sesión');
          _cancelScheduledLogout();
        } else {
          debugPrint('🔐 App oculta fuera de contexto permitido - LOGOUT INMEDIATO');
          _performLogout();
        }
        break;
    }
  }

  void _scheduleLogout({Duration delay = const Duration(seconds: 1)}) {
    // Cancelar timer anterior si existe
    _cancelScheduledLogout();

    final delayText = delay.inSeconds < 1
        ? '${delay.inMilliseconds} milisegundos'
        : '${delay.inSeconds} segundos';

    debugPrint('⏰ Programando logout INMEDIATO en $delayText...');
    _logoutTimer = Timer(delay, () {
      // Verificar nuevamente el contexto antes de hacer logout
      final authState = ref.read(authProvider);
      if (!authState.isAuthenticated) {
        debugPrint('ℹ️ Usuario ya no está autenticado, cancelando logout');
        return;
      }

      // Si regresamos a la app durante el timer muy corto, no hacer logout
      final currentState = WidgetsBinding.instance.lifecycleState;
      if (currentState == AppLifecycleState.resumed) {
        debugPrint('✅ App activa nuevamente durante timer, cancelando logout automático');
        return;
      }

      // Ejecutar logout inmediatamente si seguimos fuera de la app
      debugPrint('🔐 EJECUTANDO LOGOUT INMEDIATO - usuario cambió a otra aplicación');
      _performLogout();
    });
  }

  void _cancelScheduledLogout() {
    if (_logoutTimer != null) {
      debugPrint('❌ Cancelando logout programado');
      _logoutTimer?.cancel();
      _logoutTimer = null;
    }
  }

  void _performLogout() {
    try {
      final authState = ref.read(authProvider);
      if (authState.isAuthenticated) {
        debugPrint('🔐 EJECUTANDO LOGOUT PARCIAL INMEDIATO por cambio de aplicación');
        ref.read(authProvider.notifier).partialLogout();
      }
    } catch (e) {
      debugPrint('❌ Error ejecutando auto-logout inmediato: $e');
    }
  }
}

/// Provider para el servicio de auto-logout
final autoLogoutServiceProvider = Provider<AutoLogoutService>((ref) {
  return AutoLogoutService(ref);
});
