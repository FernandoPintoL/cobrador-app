import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';

class AuthState {
  final Usuario? usuario;
  final bool isLoading;
  final String? error;

  const AuthState({this.usuario, this.isLoading = false, this.error});

  AuthState copyWith({Usuario? usuario, bool? isLoading, String? error}) {
    return AuthState(
      usuario: usuario ?? this.usuario,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  bool get isAuthenticated => usuario != null;
  bool get isCobrador => usuario?.esCobrador() ?? false;
  bool get isJefe => usuario?.esJefe() ?? false;
  bool get isCliente => usuario?.esCliente() ?? false;
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // TODO: Implementar con ApiService
      await Future.delayed(const Duration(seconds: 2)); // Simulación

      // Usuario de prueba
      final usuario = Usuario(
        id: BigInt.one,
        nombre: 'Cobrador Test',
        email: email,
        telefono: '123456789',
        direccion: 'Dirección Test',
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        roles: ['cobrador'],
      );

      state = state.copyWith(usuario: usuario, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> logout() async {
    try {
      // TODO: Implementar con ApiService
      await Future.delayed(const Duration(seconds: 1)); // Simulación
    } finally {
      state = const AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
