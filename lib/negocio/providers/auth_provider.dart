import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/servicios/api_service.dart';
import '../../datos/servicios/storage_service.dart';

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
  }) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  bool get isAuthenticated => usuario != null;
  bool get isCobrador => usuario?.esCobrador() ?? false;
  bool get isJefe => usuario?.esJefe() ?? false;
  bool get isCliente => usuario?.esCliente() ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  AuthNotifier() : super(const AuthState());

  // Inicializar la aplicación verificando si hay sesión guardada
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final hasSession = await _storageService.hasValidSession();

      if (hasSession) {
        // Intentar restaurar sesión
        final restored = await _apiService.restoreSession();
        if (restored) {
          // Obtener usuario desde almacenamiento local
          final usuario = await _storageService.getUser();
          if (usuario != null) {
            state = state.copyWith(
              usuario: usuario,
              isLoading: false,
              isInitialized: true,
            );
            return;
          }
        }
      }

      // No hay sesión válida
      state = state.copyWith(isLoading: false, isInitialized: true);
    } catch (e) {
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
      } else {
        usuario = await _storageService.getUser();
      }

      if (usuario != null) {
        state = state.copyWith(usuario: usuario, isLoading: false);
      } else {
        throw Exception('No se pudo obtener información del usuario');
      }
    } catch (e) {
      print('Error en el provider login: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      // Llamar al endpoint de logout si hay conexión
      await _apiService.logout();
    } catch (e) {
      // Si no hay conexión, continuar con el logout local
    } finally {
      // Limpiar sesión local
      await _storageService.clearSession();
      state = const AuthState(isInitialized: true);
    }
  }

  Future<void> refreshUser() async {
    try {
      final response = await _apiService.getMe();
      if (response['user'] != null) {
        final usuario = Usuario.fromJson(response['user']);
        state = state.copyWith(usuario: usuario);
      }
    } catch (e) {
      // Si no se puede actualizar, mantener el usuario actual
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
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
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
