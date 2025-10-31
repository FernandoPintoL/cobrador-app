import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../datos/modelos/usuario.dart';
import '../../datos/modelos/dashboard_statistics.dart';
import '../../datos/api_services/api_service.dart';
import '../../datos/api_services/storage_service.dart';
import 'websocket_provider.dart';

class AuthState {
  final Usuario? usuario;
  final DashboardStatistics? statistics;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.usuario,
    this.statistics,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    Usuario? usuario,
    DashboardStatistics? statistics,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearError = false,
    bool clearStatistics = false,
  }) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      statistics: clearStatistics ? null : (statistics ?? this.statistics),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get isAuthenticated => usuario != null;
  bool get isCobrador => usuario?.esCobrador() ?? false;
  bool get isJefe => usuario?.esJefe() ?? false;
  bool get isCliente => usuario?.esCliente() ?? false;
  bool get isAdmin => usuario?.esAdmin() ?? false;
  bool get isManager => usuario?.esManager() ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  Ref? _ref;

  AuthNotifier([this._ref]) : super(const AuthState());

  // Inicializar la aplicación verificando si hay sesión guardada
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      // Si se requiere re-autenticación (por logout parcial), no restaurar sesión
      final requiresReauth = await _storageService.getRequiresReauth();
      if (requiresReauth) {
        debugPrint(
          '🔐 requiresReauth=true: mostrando Login (solo contraseña si hay identificador)',
        );
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          usuario: null,
        );
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error verificando requiresReauth: $e');
    }

    try {
      final hasSession = await _storageService.hasValidSession();
      debugPrint('🔍 DEBUG: hasValidSession = $hasSession');

      if (hasSession) {
        // Obtener usuario desde almacenamiento local primero
        final usuario = await _storageService.getUser();
        // Obtener estadísticas del dashboard desde almacenamiento local
        final statistics = await _storageService.getDashboardStatistics();
        /*print('🔍 DEBUG: Usuario recuperado del almacenamiento:');
        print('  - Usuario: ${usuario?.nombre}');
        print('  - Email: ${usuario?.email}');
        print('  - Roles: ${usuario?.roles}');*/

        if (usuario != null && usuario.roles.isNotEmpty) {
          // Intentar restaurar sesión con el servidor
          try {
            final restored = await _apiService.restoreSession();
            debugPrint('🔍 DEBUG: restoreSession = $restored');

            if (restored) {
              // Si la restauración fue exitosa, actualizar usuario desde el servidor
              await refreshUser();
            }
          } catch (e) {
            debugPrint('⚠️ Error al restaurar sesión con el servidor: $e');
            debugPrint('⚠️ Continuando con usuario del almacenamiento local');
          }

          // Usar el usuario del almacenamiento local o el actualizado
          final currentUser = state.usuario ?? usuario;
          state = state.copyWith(
            usuario: currentUser,
            statistics: statistics,
            isLoading: false,
            isInitialized: true,
          );

          // Validar la sesión restaurada
          await validateAndFixSession();

          // Conectar WebSocket para sesión restaurada
          _connectWebSocketIfAvailable();

          debugPrint('✅ Usuario restaurado exitosamente');
          return;
        } else {
          debugPrint('⚠️ Usuario no válido en almacenamiento local');
          await _storageService.clearSession();
        }
      }

      // No hay sesión válida
      debugPrint('⚠️ No hay sesión válida, inicializando sin usuario');
      state = state.copyWith(isLoading: false, isInitialized: true);
    } catch (e) {
      debugPrint('❌ Error durante la inicialización: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isInitialized: true,
      );
    }
  }

  Future<void> login(
    String emailOrPhone,
    String password, {
    bool rememberMe = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.login(emailOrPhone, password);

      // Guardar preferencia "Recordarme"
      await _storageService.setRememberMe(rememberMe);

      // Guardar fecha de último login
      await _storageService.setLastLogin(DateTime.now());

      // Guardar identificador para login rápido (para mostrar solo contraseña luego)
      await _storageService.setSavedIdentifier(emailOrPhone);

      // Obtener usuario desde la respuesta o desde almacenamiento local
      Usuario? usuario;
      if (response['user'] != null) {
        usuario = Usuario.fromJson(response['user']);
        debugPrint('🔍 DEBUG: Usuario obtenido de la respuesta del servidor:');
        debugPrint('  - Usuario: ${usuario.nombre}');
        debugPrint('  - Email: ${usuario.email}');
        debugPrint('  - Roles: ${usuario.roles}');
      } else {
        usuario = await _storageService.getUser();
        debugPrint('🔍 DEBUG: Usuario obtenido del almacenamiento local:');
        debugPrint('  - Usuario: ${usuario?.nombre}');
        debugPrint('  - Email: ${usuario?.email}');
        debugPrint('  - Roles: ${usuario?.roles}');
      }

      if (usuario != null) {
        debugPrint('✅ Login exitoso, guardando usuario en el estado');

        // Cargar estadísticas del dashboard desde almacenamiento local
        final statistics = await _storageService.getDashboardStatistics();
        if (statistics != null) {
          debugPrint('📊 Estadísticas cargadas desde almacenamiento local');
        }

        state = state.copyWith(
          usuario: usuario,
          statistics: statistics,
          isLoading: false,
        );

        // Conectar WebSocket después del login exitoso
        _connectWebSocketIfAvailable();

        // Limpiar flag de re-autenticación tras login exitoso
        await _storageService.clearRequiresReauth();
      } else {
        throw Exception('No se pudo obtener información del usuario');
      }
    } catch (e) {
      debugPrint('Error en el provider login: $e');
      // Extraer solo el mensaje de la excepción, no toda la información de stack
      String errorMessage = 'Error desconocido';

      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e is String) {
        errorMessage = e;
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> logout() async {
    debugPrint('🚪 Iniciando proceso de logout...');
    state = state.copyWith(isLoading: true);

    try {
      // Desconectar WebSocket antes del logout
      _disconnectWebSocket();

      // Llamar al endpoint de logout si hay conexión
      debugPrint('📡 Llamando al endpoint de logout...');
      await _apiService.logout();
      debugPrint('✅ Logout exitoso en el servidor');
    } catch (e) {
      // Si no hay conexión, continuar con el logout local
      debugPrint('⚠️ Error al hacer logout en el servidor: $e');
      debugPrint('⚠️ Continuando con logout local...');
    } finally {
      // Limpiar sesión local
      debugPrint('🧹 Limpiando sesión local...');
      await _storageService.clearSession();

      // Resetear estado completamente
      state = const AuthState(isInitialized: true);
      debugPrint('✅ Logout completado - Estado reseteado');
    }
  }

  /// Cierre de sesión parcial: se elimina solo el usuario local, conservando token
  /// y el identificador guardado para que el login pida solo contraseña.
  Future<void> partialLogout() async {
    debugPrint('🚪 Cerrando sesión parcialmente (LOGOUT INMEDIATO)...');
    try {
      // Desconectar WebSocket inmediatamente
      _disconnectWebSocket();

      // Limpiar completamente la sesión actual pero preservar identificador
      String? savedIdentifier = await _storageService.getSavedIdentifier();
      debugPrint('📧 Identificador a preservar: $savedIdentifier');

      // Limpiar TODO (incluyendo token) para forzar re-autenticación completa
      await _storageService.clearSession();

      // Restaurar solo el identificador si existía
      if (savedIdentifier != null && savedIdentifier.isNotEmpty) {
        await _storageService.setSavedIdentifier(savedIdentifier);
        debugPrint('✅ Identificador restaurado: $savedIdentifier');
      }

      // Marcar que se requiere re-autenticación completa
      await _storageService.setRequiresReauth(true);

      // Limpiar estado completamente
      state = const AuthState(isInitialized: true, usuario: null);

      debugPrint('✅ LOGOUT PARCIAL COMPLETADO - Session cerrada completamente');
      debugPrint('🔐 Usuario debe re-autenticarse completamente');
    } catch (e) {
      debugPrint('❌ Error en logout parcial: $e');
      // En caso de error, forzar limpieza completa
      await _storageService.clearSession();
      state = const AuthState(isInitialized: true, usuario: null);
    }
  }

  /// Cierre de sesión completo para cambiar de cuenta. Limpia todo e incluye
  /// el identificador guardado para forzar ingresar email/teléfono nuevamente.
  Future<void> logoutFull() async {
    debugPrint('🚪 Iniciando logout FULL (cambio de cuenta)...');
    state = state.copyWith(isLoading: true);
    try {
      _disconnectWebSocket();
      debugPrint('📡 Llamando al endpoint de logout (full)...');
      await _apiService.logout();
    } catch (e) {
      debugPrint('⚠️ Error al hacer logout full en el servidor: $e');
    } finally {
      debugPrint('🧹 Limpiando sesión local (full)...');
      await _storageService.clearSession();
      await _storageService.clearSavedIdentifier();
      // Asegurar que no quede el flag de re-autenticación de un logout parcial previo
      await _storageService.clearRequiresReauth();
      state = const AuthState(isInitialized: true);
      debugPrint('✅ Logout FULL completado - Estado reseteado');
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiService.getMe();
      if (response['user'] != null) {
        final usuario = Usuario.fromJson(response['user']);
        debugPrint('🔄 Usuario actualizado desde el servidor:');
        debugPrint('  - Usuario: ${usuario.nombre}');
        debugPrint('  - Email: ${usuario.email}');
        debugPrint('  - Roles: ${usuario.roles}');

        // Guardar el usuario actualizado en almacenamiento local
        await _storageService.saveUser(usuario);

        // ✅ NUEVO: Recuperar estadísticas si están disponibles
        DashboardStatistics? statistics;
        if (response['statistics'] != null) {
          statistics = DashboardStatistics.fromJson(
            response['statistics'] as Map<String, dynamic>,
          );
          debugPrint('📊 Estadísticas actualizadas desde /api/me');
          debugPrint('  - Total clientes: ${statistics.totalClientes}');
          debugPrint('  - Créditos activos: ${statistics.creditosActivos}');

          // ✅ NUEVO: Guardar estadísticas en almacenamiento local
          await _storageService.saveDashboardStatistics(statistics);
        }

        state = state.copyWith(usuario: usuario, statistics: statistics);
        debugPrint('✅ Usuario y estadísticas actualizados exitosamente');
      }
    } catch (e) {
      debugPrint('⚠️ Error al actualizar usuario desde el servidor: $e');
      debugPrint('⚠️ Manteniendo usuario actual del almacenamiento local');
      // Si no se puede actualizar, mantener el usuario actual
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Verificar si existe un email o teléfono
  Future<Map<String, dynamic>> checkExists(String emailOrPhone) async {
    try {
      return await _apiService.checkExists(emailOrPhone);
    } catch (e) {
      throw Exception('Error al verificar existencia: $e');
    }
  }

  // Obtener información de la sesión
  Future<Map<String, dynamic>> getSessionInfo() async {
    return await _storageService.getSessionInfo();
  }

  // Limpiar toda la sesión
  Future<void> clearSession() async {
    await _storageService.clearSession();
    state = const AuthState(isInitialized: true);
  }

  // Método para debug: limpiar sesión y forzar nuevo login
  Future<void> forceNewLogin() async {
    debugPrint('🔄 Forzando nuevo login...');
    await clearSession();
    debugPrint('✅ Sesión limpiada, usuario debe hacer login nuevamente');
  }

  // Método para validar y corregir sesión si es necesario
  Future<void> validateAndFixSession() async {
    if (state.usuario != null) {
      debugPrint('⁉️ Validando sesión actual...');
      debugPrint('  - Usuario: ${state.usuario!.nombre}');
      debugPrint('  - Roles: ${state.usuario!.roles}');

      // Verificar que el usuario tiene roles válidos
      if (state.usuario!.roles.isEmpty) {
        debugPrint('❌ Usuario sin roles, limpiando sesión');
        await clearSession();
        return;
      }

      // Verificar que al menos uno de los roles principales está presente
      final hasValidRole =
          state.usuario!.tieneRol('admin') ||
          state.usuario!.tieneRol('manager') ||
          state.usuario!.tieneRol('cobrador');

      if (!hasValidRole) {
        debugPrint('❌ Usuario sin roles válidos, limpiando sesión');
        await clearSession();
        return;
      }

      debugPrint('✅ Sesión válida');
    }
  }

  /// Conectar WebSocket si está disponible
  void _connectWebSocketIfAvailable() {
    if (_ref != null && state.usuario != null) {
      try {
        final wsNotifier = _ref!.read(webSocketProvider.notifier);
        final user = state.usuario!;
        // Determinar tipo de usuario según roles
        String userType = 'client';
        if (user.roles.contains('admin')) {
          userType = 'admin';
        } else if (user.roles.contains('manager')) {
          userType = 'manager';
        } else if (user.roles.contains('cobrador')) {
          userType = 'cobrador';
        }

        wsNotifier.connectWithUser(
          userId: user.id.toString(),
          userType: userType,
          userName: user.nombre,
        );
        debugPrint(
          '🔌 Iniciando conexión WebSocket para $userType: ${user.nombre}',
        );
      } catch (e) {
        debugPrint('⚠️ Error al conectar WebSocket: $e');
      }
    } else {
      debugPrint('⚠️ No se puede conectar WebSocket: ref o usuario es null');
    }
  }

  /// Desconectar WebSocket
  void _disconnectWebSocket() {
    if (_ref != null) {
      try {
        final wsNotifier = _ref!.read(webSocketProvider.notifier);
        wsNotifier.disconnect();
        debugPrint('🔌 WebSocket desconectado');
      } catch (e) {
        debugPrint('⚠️ Error al desconectar WebSocket: $e');
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
