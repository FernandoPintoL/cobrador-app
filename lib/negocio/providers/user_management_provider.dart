import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/servicios/api_service.dart';

class UserManagementState {
  final List<Usuario> usuarios;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  UserManagementState({
    this.usuarios = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  UserManagementState copyWith({
    List<Usuario>? usuarios,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return UserManagementState(
      usuarios: usuarios ?? this.usuarios,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final ApiService _apiService = ApiService();

  UserManagementNotifier() : super(UserManagementState());

  // Cargar usuarios por rol
  Future<void> cargarUsuarios({String? role, String? search}) async {
    // Evitar múltiples llamadas simultáneas
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final queryParams = <String, dynamic>{};
      if (role != null) queryParams['role'] = role;
      if (search != null) queryParams['search'] = search;

      final response = await _apiService.get(
        '/users',
        queryParameters: queryParams,
      );

      // Debug: imprimir la estructura de la respuesta
      print('🔍 DEBUG: Estructura de respuesta:');
      print('Response data: ${response.data}');
      print('Response data type: ${response.data.runtimeType}');
      if (response.data['data'] != null) {
        print('Data type: ${response.data['data'].runtimeType}');
        print('Data content: ${response.data['data']}');
      }

      if (response.data['success'] == true) {
        List<dynamic> usuariosData;

        // Manejar diferentes estructuras de respuesta
        if (response.data['data'] is List) {
          usuariosData = response.data['data'] as List<dynamic>;
        } else if (response.data['data'] is Map) {
          // Si data es un mapa, buscar la lista de usuarios
          final dataMap = response.data['data'] as Map<String, dynamic>;
          if (dataMap['users'] is List) {
            usuariosData = dataMap['users'] as List<dynamic>;
          } else if (dataMap['data'] is List) {
            usuariosData = dataMap['data'] as List<dynamic>;
          } else {
            // Si no encontramos una lista, crear una lista vacía
            usuariosData = [];
          }
        } else {
          // Si data no es ni lista ni mapa, crear lista vacía
          usuariosData = [];
        }

        final usuarios = usuariosData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(usuarios: usuarios, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al cargar usuarios',
        );
      }
    } catch (e) {
      print('❌ ERROR en cargarUsuarios: $e');
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  // Cargar clientes
  Future<void> cargarClientes({String? search}) async {
    // Evitar múltiples llamadas simultáneas
    if (state.isLoading) return;
    await cargarUsuarios(role: 'client', search: search);
  }

  // Cargar cobradores
  Future<void> cargarCobradores({String? search}) async {
    // Evitar múltiples llamadas simultáneas
    if (state.isLoading) return;
    await cargarUsuarios(role: 'cobrador', search: search);
  }

  // Crear usuario
  Future<bool> crearUsuario({
    required String nombre,
    required String email,
    String? password,
    required List<String> roles,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = {
        'name': nombre,
        'email': email,
        'roles': roles,
        if (password != null && password.isNotEmpty) 'password': password,
        if (telefono != null) 'phone': telefono,
        if (direccion != null) 'address': direccion,
        if (latitud != null && longitud != null)
          'location': {
            'type': 'Point',
            'coordinates': [longitud, latitud],
          },
      };

      final response = await _apiService.post('/users', data: data);

      if (response.data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Usuario creado exitosamente',
        );
        // Recargar la lista
        await cargarUsuarios();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al crear usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // Actualizar usuario
  Future<bool> actualizarUsuario({
    required BigInt id,
    required String nombre,
    required String email,
    String? password,
    List<String>? roles,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = {
        'name': nombre,
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
        if (roles != null) 'roles': roles,
        if (telefono != null) 'phone': telefono,
        if (direccion != null) 'address': direccion,
        if (latitud != null && longitud != null)
          'location': {
            'type': 'Point',
            'coordinates': [longitud, latitud],
          },
      };

      final response = await _apiService.put('/users/$id', data: data);

      if (response.data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Usuario actualizado exitosamente',
        );
        // Recargar la lista
        await cargarUsuarios();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al actualizar usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // Eliminar usuario
  Future<bool> eliminarUsuario(BigInt id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.delete('/users/$id');

      if (response.data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Usuario eliminado exitosamente',
        );
        // Recargar la lista
        await cargarUsuarios();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al eliminar usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // Limpiar mensajes
  void limpiarMensajes() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final userManagementProvider =
    StateNotifierProvider<UserManagementNotifier, UserManagementState>(
      (ref) => UserManagementNotifier(),
    );
