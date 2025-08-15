import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/servicios/api_service.dart';
import '../../datos/servicios/storage_service.dart';
import 'websocket_provider.dart';

class AuthState {
  final Usuario? usuario;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  const AuthState({
    this.usuario,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  AuthState copyWith({
    Usuario? usuario,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    bool clearError = false,
  }) {
    return AuthState(
      usuario: usuario ?? this.usuario,
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
      final hasSession = await _storageService.hasValidSession();
      print('🔍 DEBUG: hasValidSession = $hasSession');

      if (hasSession) {
        // Obtener usuario desde almacenamiento local primero
        final usuario = await _storageService.getUser();
        /*print('🔍 DEBUG: Usuario recuperado del almacenamiento:');
        print('  - Usuario: ${usuario?.nombre}');
        print('  - Email: ${usuario?.email}');
        print('  - Roles: ${usuario?.roles}');*/

        if (usuario != null && usuario.roles.isNotEmpty) {
          // Intentar restaurar sesión con el servidor
          try {
            final restored = await _apiService.restoreSession();
            print('🔍 DEBUG: restoreSession = $restored');

            if (restored) {
              // Si la restauración fue exitosa, actualizar usuario desde el servidor
              await refreshUser();
            }
          } catch (e) {
            print('⚠️ Error al restaurar sesión con el servidor: $e');
            print('⚠️ Continuando con usuario del almacenamiento local');
          }

          // Usar el usuario del almacenamiento local o el actualizado
          final currentUser = state.usuario ?? usuario;
          state = state.copyWith(
            usuario: currentUser,
            isLoading: false,
            isInitialized: true,
          );

          // Validar la sesión restaurada
          await validateAndFixSession();

          // Conectar WebSocket para sesión restaurada
          _connectWebSocketIfAvailable();

          print('✅ Usuario restaurado exitosamente');
          return;
        } else {
          print('⚠️ Usuario no válido en almacenamiento local');
          await _storageService.clearSession();
        }
      }

      // No hay sesión válida
      print('⚠️ No hay sesión válida, inicializando sin usuario');
      state = state.copyWith(isLoading: false, isInitialized: true);
    } catch (e) {
      print('❌ Error durante la inicialización: $e');
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

      // Obtener usuario desde la respuesta o desde almacenamiento local
      Usuario? usuario;
      if (response['user'] != null) {
        usuario = Usuario.fromJson(response['user']);
        print('🔍 DEBUG: Usuario obtenido de la respuesta del servidor:');
        print('  - Usuario: ${usuario.nombre}');
        print('  - Email: ${usuario.email}');
        print('  - Roles: ${usuario.roles}');
      } else {
        usuario = await _storageService.getUser();
        print('🔍 DEBUG: Usuario obtenido del almacenamiento local:');
        print('  - Usuario: ${usuario?.nombre}');
        print('  - Email: ${usuario?.email}');
        print('  - Roles: ${usuario?.roles}');
      }

      if (usuario != null) {
        print('✅ Login exitoso, guardando usuario en el estado');
        state = state.copyWith(usuario: usuario, isLoading: false);

        // Conectar WebSocket después del login exitoso
        _connectWebSocketIfAvailable();
      } else {
        throw Exception('No se pudo obtener información del usuario');
      }
    } catch (e) {
      print('Error en el provider login: $e');
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
    print('🚪 Iniciando proceso de logout...');
    state = state.copyWith(isLoading: true);

    try {
      // Desconectar WebSocket antes del logout
      _disconnectWebSocket();

      // Llamar al endpoint de logout si hay conexión
      print('📡 Llamando al endpoint de logout...');
      await _apiService.logout();
      print('✅ Logout exitoso en el servidor');
    } catch (e) {
      // Si no hay conexión, continuar con el logout local
      print('⚠️ Error al hacer logout en el servidor: $e');
      print('⚠️ Continuando con logout local...');
    } finally {
      // Limpiar sesión local
      print('🧹 Limpiando sesión local...');
      await _storageService.clearSession();

      // Resetear estado completamente
      state = const AuthState(isInitialized: true);
      print('✅ Logout completado - Estado reseteado');
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiService.getMe();
      if (response['user'] != null) {
        final usuario = Usuario.fromJson(response['user']);
        print('🔄 Usuario actualizado desde el servidor:');
        print('  - Usuario: ${usuario.nombre}');
        print('  - Email: ${usuario.email}');
        print('  - Roles: ${usuario.roles}');

        // Guardar el usuario actualizado en almacenamiento local
        await _storageService.saveUser(usuario);

        state = state.copyWith(usuario: usuario);
        print('✅ Usuario actualizado exitosamente');
      }
    } catch (e) {
      print('⚠️ Error al actualizar usuario desde el servidor: $e');
      print('⚠️ Manteniendo usuario actual del almacenamiento local');
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
    print('🔄 Forzando nuevo login...');
    await clearSession();
    print('✅ Sesión limpiada, usuario debe hacer login nuevamente');
  }

  // Método para validar y corregir sesión si es necesario
  Future<void> validateAndFixSession() async {
    if (state.usuario != null) {
      print('⁉️ Validando sesión actual...');
      print('  - Usuario: ${state.usuario!.nombre}');
      print('  - Roles: ${state.usuario!.roles}');

      // Verificar que el usuario tiene roles válidos
      if (state.usuario!.roles.isEmpty) {
        print('❌ Usuario sin roles, limpiando sesión');
        await clearSession();
        return;
      }

      // Verificar que al menos uno de los roles principales está presente
      final hasValidRole =
          state.usuario!.tieneRol('admin') ||
          state.usuario!.tieneRol('manager') ||
          state.usuario!.tieneRol('cobrador');

      if (!hasValidRole) {
        print('❌ Usuario sin roles válidos, limpiando sesión');
        await clearSession();
        return;
      }

      print('✅ Sesión válida');
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
          userName: user.nombre ?? 'Usuario'
        );
        print('🔌 Iniciando conexión WebSocket para $userType: ${user.nombre}');
      } catch (e) {
        print('⚠️ Error al conectar WebSocket: $e');
      }
    } else {
      print('⚠️ No se puede conectar WebSocket: ref o usuario es null');
    }
  }

  /// Desconectar WebSocket
  void _disconnectWebSocket() {
    if (_ref != null) {
      try {
        final wsNotifier = _ref!.read(webSocketProvider.notifier);
        wsNotifier.disconnect();
        print('🔌 WebSocket desconectado');
      } catch (e) {
        print('⚠️ Error al desconectar WebSocket: $e');
      }
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
