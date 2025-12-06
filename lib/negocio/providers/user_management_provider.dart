import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/api_services/user_api_service.dart';

class UserManagementState {
  final List<Usuario> usuarios;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final Map<String, dynamic>? fieldErrors; // Cambio: Ahora es Map para manejar errores por campo
  // Extras para categorías
  final List<Map<String, dynamic>>? clientCategories; // from API
  final Map<String, dynamic>? categoryStatistics;

  UserManagementState({
    this.usuarios = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.fieldErrors,
    this.clientCategories,
    this.categoryStatistics,
  });

  UserManagementState copyWith({
    List<Usuario>? usuarios,
    bool? isLoading,
    String? error,
    String? successMessage,
    Map<String, dynamic>? fieldErrors,
    List<Map<String, dynamic>>? clientCategories,
    Map<String, dynamic>? categoryStatistics,
  }) {
    return UserManagementState(
      usuarios: usuarios ?? this.usuarios,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      clientCategories: clientCategories ?? this.clientCategories,
      categoryStatistics: categoryStatistics ?? this.categoryStatistics,
    );
  }
}

class UserManagementNotifier extends StateNotifier<UserManagementState> {
  final UserApiService _userApiService = UserApiService();

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

      final response = await _userApiService.getUsers(
        role: role,
        search: search,
      );

      // Debug: imprimir la estructura de la respuesta
      print('🔍 DEBUG: Estructura de respuesta:');
      print('Response data: $response');
      print('Response data type: ${response.runtimeType}');
      if (response['data'] != null) {
        print('Data type: ${response['data'].runtimeType}');
        print('Data content: ${response['data']}');
      }

      if (response['success'] == true) {
        List<dynamic> usuariosData;

        // Manejar diferentes estructuras de respuesta
        if (response['data'] is List) {
          usuariosData = response['data'] as List<dynamic>;
        } else if (response['data'] is Map) {
          // Si data es un mapa, buscar la lista de usuarios
          final dataMap = response['data'] as Map<String, dynamic>;
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
          error: response['message'] ?? 'Error al cargar usuarios',
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

  // Cargar managers
  Future<void> cargarManagers({String? search}) async {
    // Evitar múltiples llamadas simultáneas
    if (state.isLoading) return;
    await cargarUsuarios(role: 'manager', search: search);
  }

  // Crear usuario
  Future<bool> crearUsuario({
    required String nombre,
    required String email,
    required String ci,
    String? password,
    required List<String> roles,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
    String? clientCategory, // 'A','B','C' solo para clientes
  }) async {
    state = state.copyWith(isLoading: true, error: null, fieldErrors: null);

    try {
      final data = {
        'name': nombre,
        'email': email,
        'ci': ci,
        'roles': roles,
        if (password != null && password.isNotEmpty) 'password': password,
        if (telefono != null) 'phone': telefono,
        if (direccion != null) 'address': direccion,
        if (latitud != null && longitud != null)
          'location': {
            'type': 'Point',
            'coordinates': [longitud, latitud],
          },
        if (clientCategory != null && roles.contains('client'))
          'client_category': clientCategory,
      };

      final response = await _userApiService.createUser(data);

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Usuario creado exitosamente',
        );
        // Recargar la lista
        await cargarUsuarios();
        return true;
      } else {
        // Manejar errores específicos de validación del backend
        Map<String, dynamic>? fieldErrors;
        if (response['errors'] != null && response['errors'] is Map) {
          fieldErrors = response['errors'] as Map<String, dynamic>;
        }

        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al crear usuario',
          fieldErrors: fieldErrors,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexión: $e',
        fieldErrors: null,
      );
      return false;
    }
  }

  // Crear usuario y subir fotos requeridas (CI anverso/reverso) y opcional perfil
  Future<bool> crearUsuarioConFotos({
    required String nombre,
    required String email,
    required String ci,
    String? password,
    required List<String> roles,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
    String? clientCategory,
    File? idFront, // Ahora opcional
    File? idBack,  // Ahora opcional
    File? profileImage,
  }) async {
    state = state.copyWith(isLoading: true, error: null, fieldErrors: null);

    try {
      final data = {
        'name': nombre,
        'email': email,
        'ci': ci,
        'roles': roles,
        if (password != null && password.isNotEmpty) 'password': password,
        if (telefono != null) 'phone': telefono,
        if (direccion != null) 'address': direccion,
        if (latitud != null && longitud != null)
          'location': {
            'type': 'Point',
            'coordinates': [longitud, latitud],
          },
        if (clientCategory != null && roles.contains('client'))
          'client_category': clientCategory,
      };

      final response = await _userApiService.createUser(data);
      if (response['success'] != true) {
        // Procesar errores del backend (formato: { "errors": { "field": ["message"] } })
        Map<String, dynamic>? fieldErrors;
        if (response['errors'] != null && response['errors'] is Map) {
          fieldErrors = response['errors'] as Map<String, dynamic>;
        }
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al crear usuario',
          fieldErrors: fieldErrors,
        );
        return false;
      }

      // Extraer ID del usuario creado
      dynamic userJson = response['data']?['user'] ?? response['user'] ?? response['data'] ?? response;
      BigInt createdId;
      try {
        final idRaw = userJson['id'];
        if (idRaw is String) {
          createdId = BigInt.parse(idRaw);
        } else if (idRaw is int) {
          createdId = BigInt.from(idRaw);
        } else {
          throw Exception('ID inválido');
        }
      } catch (_) {
        // Como respaldo, recargar lista y tomar último
        await cargarUsuarios();
        if (state.usuarios.isEmpty) throw Exception('No se pudo obtener el ID del usuario creado');
        createdId = state.usuarios.last.id;
      }

      // Subir fotos de CI solo si se proporcionaron (ahora opcional)
      if (idFront != null || idBack != null) {
        try {
          final photos = <File>[];
          final types = <String>[];

          if (idFront != null) {
            photos.add(idFront);
            types.add('id_front');
          }
          if (idBack != null) {
            photos.add(idBack);
            types.add('id_back');
          }

          await _userApiService.uploadUserPhotos(
            createdId,
            photos: photos,
            types: types,
          );
        } catch (photoError) {
          // Si hay error subiendo fotos, loguearlo pero no fallar completamente
          debugPrint('⚠️ Advertencia: No se pudieron subir las fotos de CI: $photoError');
          state = state.copyWith(
            successMessage: 'Usuario creado exitosamente, pero no se pudieron subir las fotos de CI. ${photoError.toString().replaceAll('Exception: ', '')}',
          );
        }
      }

      // Subir foto de perfil si se proporcionó
      if (profileImage != null) {
        try {
          await _userApiService.uploadUserProfileImage(createdId, profileImage);
        } catch (profileError) {
          debugPrint('⚠️ Advertencia: No se pudo subir la foto de perfil: $profileError');
          // No sobrescribir el mensaje anterior si ya existe
          if (!state.successMessage!.contains('pero no se pudieron')) {
            state = state.copyWith(
              successMessage: 'Usuario creado exitosamente, pero no se pudo subir la foto de perfil. ${profileError.toString().replaceAll('Exception: ', '')}',
            );
          }
        }
      }

      // Si no hubo problemas con las fotos, mostrar mensaje de éxito completo
      if (state.successMessage == null || !state.successMessage!.contains('pero no se pud')) {
        state = state.copyWith(
          successMessage: 'Usuario y documentos creados exitosamente',
        );
      }

      state = state.copyWith(isLoading: false);
      await cargarUsuarios();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexión: $e',
        fieldErrors: null,
      );
      return false;
    }
  }

  // Actualizar usuario
  Future<bool> actualizarUsuario({
    required BigInt id,
    required String nombre,
    required String email,
    required String ci,
    String? password,
    List<String>? roles,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
    String? clientCategory, // 'A','B','C' solo para clientes
  }) async {
    state = state.copyWith(isLoading: true, error: null, fieldErrors: null);

    try {
      final data = {
        'name': nombre,
        'email': email,
        'ci': ci,
        if (password != null && password.isNotEmpty) 'password': password,
        if (roles != null) 'roles': roles,
        if (telefono != null) 'phone': telefono,
        if (direccion != null) 'address': direccion,
        if (latitud != null && longitud != null)
          'location': {
            'type': 'Point',
            'coordinates': [longitud, latitud],
          },
        if (clientCategory != null && ((roles ?? []).contains('client')))
          'client_category': clientCategory,
      };

      final response = await _userApiService.updateUser(id.toString(), data);

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Usuario actualizado exitosamente',
        );
        // Recargar la lista
        await cargarUsuarios();
        return true;
      } else {
        // Manejar errores específicos de validación del backend
        Map<String, dynamic>? fieldErrors;
        if (response['errors'] != null && response['errors'] is Map) {
          fieldErrors = response['errors'] as Map<String, dynamic>;
        }

        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al actualizar usuario',
          fieldErrors: fieldErrors,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexión: $e',
        fieldErrors: null,
      );
      return false;
    }
  }

  // Actualizar usuario con fotos (para edición de perfil con documentos)
  Future<bool> actualizarUsuarioConFotos({
    required BigInt id,
    required String nombre,
    required String email,
    required String ci,
    String? password,
    List<String>? roles,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
    String? clientCategory,
    File? idFront,
    File? idBack,
    File? profileImage,
  }) async {
    state = state.copyWith(isLoading: true, error: null, fieldErrors: null);

    try {
      // Primero actualizar los datos del usuario
      final updateSuccess = await actualizarUsuario(
        id: id,
        nombre: nombre,
        email: email,
        ci: ci,
        password: password,
        roles: roles,
        telefono: telefono,
        direccion: direccion,
        latitud: latitud,
        longitud: longitud,
        clientCategory: clientCategory,
      );

      if (!updateSuccess) {
        return false; // Los errores ya están manejados en actualizarUsuario
      }

      // Actualizar fotos si se proporcionaron
      List<File> photosToUpload = [];
      List<String> photoTypes = [];

      if (idFront != null) {
        photosToUpload.add(idFront);
        photoTypes.add('id_front');
      }

      if (idBack != null) {
        photosToUpload.add(idBack);
        photoTypes.add('id_back');
      }

      // Subir fotos de CI si hay alguna
      if (photosToUpload.isNotEmpty) {
        await _userApiService.uploadUserPhotos(
          id,
          photos: photosToUpload,
          types: photoTypes,
        );
      }

      // Subir foto de perfil por separado si se proporcionó
      if (profileImage != null) {
        await _userApiService.uploadUserProfileImage(id, profileImage);
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Usuario y documentos actualizados exitosamente',
      );
      await cargarUsuarios();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al actualizar fotos: $e',
        fieldErrors: null,
      );
      return false;
    }
  }

  // Actualizar solo la contraseña de un usuario
  Future<bool> actualizarContrasena({
    required BigInt id,
    required String nuevaContrasena,
  }) async {
    state = state.copyWith(isLoading: true, error: null, fieldErrors: null);

    try {
      final data = {
        'password': nuevaContrasena,
      };

      final response = await _userApiService.updateUser(id.toString(), data);

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Contraseña actualizada exitosamente',
        );
        return true;
      } else {
        // Manejar errores específicos de validación del backend
        Map<String, dynamic>? fieldErrors;
        if (response['errors'] != null && response['errors'] is Map) {
          fieldErrors = response['errors'] as Map<String, dynamic>;
        }

        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al actualizar contraseña',
          fieldErrors: fieldErrors,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error de conexión: $e',
        fieldErrors: null,
      );
      return false;
    }
  }

  // Eliminar usuario
  Future<bool> eliminarUsuario(BigInt id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _userApiService.deleteUser(id.toString());

      if (response['success'] == true) {
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
          error: response['message'] ?? 'Error al eliminar usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // ===== Categorías de Cliente =====
  Future<Map<String, dynamic>> fetchClientCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    final resp = await _userApiService.getClientCategories();

    // Manejar diferentes estructuras de respuesta del API
    List<Map<String, dynamic>>? categories;

    if (resp['success'] == true) {
      // Caso 1: data es directamente una lista
      if (resp['data'] is List) {
        categories = (resp['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      // Caso 2: data es un objeto que contiene categories
      else if (resp['data'] is Map<String, dynamic>) {
        final dataMap = resp['data'] as Map<String, dynamic>;
        if (dataMap['categories'] is List) {
          categories = (dataMap['categories'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        } else if (dataMap['data'] is List) {
          categories = (dataMap['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      // Caso 3: categories está directamente en el nivel raíz
      else if (resp['categories'] is List) {
        categories = (resp['categories'] as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }

    state = state.copyWith(
      isLoading: false,
      clientCategories: categories,
      error: resp['success'] == true ? null : (resp['message']?.toString()),
    );
    return resp;
  }

  Future<Map<String, dynamic>> updateClientCategoryApi({
    required BigInt clientId,
    required String category,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    final resp = await _userApiService.updateClientCategory(clientId, category);
    state = state.copyWith(
      isLoading: false,
      error: resp['success'] == true ? null : (resp['message']?.toString()),
      successMessage: resp['success'] == true ? 'Categoría actualizada' : null,
    );
    // refrescar usuarios (clientes) si ok
    if (resp['success'] == true) {
      await cargarClientes();
    }
    return resp;
  }

  Future<Map<String, dynamic>> fetchClientsByCategory(String category) async {
    state = state.copyWith(isLoading: true, error: null);
    final resp = await _userApiService.getClientsByCategory(category);
    if (resp['success'] == true) {
      final data = resp['data'];
      List<dynamic> list;
      if (data is List) {
        list = data;
      } else if (data is Map && data['clients'] is List) {
        list = data['clients'];
      } else if (resp['clients'] is List) {
        list = resp['clients'];
      } else {
        list = [];
      }
      final usuarios = list.map((e) => Usuario.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      state = state.copyWith(usuarios: usuarios, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: resp['message']?.toString());
    }
    return resp;
  }

  Future<Map<String, dynamic>> fetchCategoryStatistics() async {
    state = state.copyWith(isLoading: true, error: null);
    final resp = await _userApiService.getClientCategoryStatistics();

    // Manejar diferentes estructuras de respuesta del API
    Map<String, dynamic>? statistics;

    if (resp['success'] == true) {
      // El API devuelve data como una lista de estadísticas
      if (resp['data'] is List) {
        // Convertir la lista a un mapa más útil para mostrar estadísticas
        final dataList = resp['data'] as List<dynamic>;
        statistics = {
          'categories': dataList,
          'total_clients': dataList.fold<int>(
            0,
            (sum, item) => sum + (item['client_count'] as int? ?? 0),
          ),
          'categories_count': dataList.length,
        };
      }
      // Si por alguna razón data es un Map, usarlo directamente
      else if (resp['data'] is Map<String, dynamic>) {
        statistics = Map<String, dynamic>.from(resp['data'] as Map);
      }
    }

    // Si no pudimos procesar las estadísticas, usar la respuesta completa
    statistics ??= Map<String, dynamic>.from(resp);

    state = state.copyWith(
      isLoading: false,
      categoryStatistics: statistics,
      error: resp['success'] == true ? null : (resp['message']?.toString()),
    );
    return resp;
  }

  Future<Map<String, dynamic>> bulkUpdateCategories(List<Map<String, dynamic>> updates) async {
    state = state.copyWith(isLoading: true, error: null);
    final resp = await _userApiService.bulkUpdateClientCategories(updates);
    state = state.copyWith(
      isLoading: false,
      error: resp['success'] == true ? null : (resp['message']?.toString()),
      successMessage: resp['success'] == true ? 'Actualización masiva completa' : null,
    );
    if (resp['success'] == true) {
      await cargarClientes();
    }
    return resp;
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
