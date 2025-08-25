import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'base_api_service.dart';
import '../modelos/usuario.dart';

/// Servicio API para gestión de usuarios y perfiles
class UserApiService extends BaseApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;
  UserApiService._internal();

  // ===== GESTIÓN DE FOTOS DE USUARIOS (CI anverso/reverso, otras) =====
  Future<List<Map<String, dynamic>>> listUserPhotos(BigInt userId) async {
    try {
      final response = await get('/users/${userId.toString()}/photos');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final List items = (data['data'] ?? data['photos'] ?? []) as List;
        return items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      throw Exception('Error al listar fotos: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error al listar fotos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> uploadUserPhotos(BigInt userId, {File? photo, String? type, List<File>? photos, List<String>? types, String? notes}) async {
    try {
      final formMap = <String, dynamic>{};

      if (photo != null) {
        formMap['photo'] = await MultipartFile.fromFile(
          photo.path,
          filename: photo.path.split('/').last,
        );
        if (type != null) formMap['type'] = type;
        if (notes != null) formMap['notes'] = notes;
      }

      if (photos != null && photos.isNotEmpty) {
        // Enviar como arrays con sufijo [] para compatibilidad con Laravel
        formMap['photos[]'] = [
          for (final f in photos)
            await MultipartFile.fromFile(
              f.path,
              filename: f.path.split('/').last,
            )
        ];
        if (types != null && types.isNotEmpty) {
          formMap['types[]'] = types;
        }
        if (notes != null) formMap['notes'] = notes;
      }

      if (formMap.isEmpty) {
        throw Exception('No se proporcionaron fotos para subir');
      }

      final formData = FormData.fromMap(formMap);
      final response = await postFormData('/users/${userId.toString()}/photos', formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;

        // Manejar diferentes estructuras de respuesta del API
        List<dynamic> items = [];

        if (data['data'] != null) {
          final responseData = data['data'];
          if (responseData is List) {
            // Caso 1: data es directamente una lista
            items = responseData;
          } else if (responseData is Map<String, dynamic>) {
            // Caso 2: data es un objeto que contiene photos
            if (responseData['photos'] is List) {
              items = responseData['photos'] as List<dynamic>;
            } else if (responseData['data'] is List) {
              items = responseData['data'] as List<dynamic>;
            }
          }
        } else if (data['photos'] is List) {
          // Caso 3: photos está directamente en el nivel raíz
          items = data['photos'] as List<dynamic>;
        }

        return items
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      throw Exception('Error al subir fotos: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ Error en uploadUserPhotos: $e');

      // Manejar específicamente errores de autorización
      if (e.toString().contains('403')) {
        throw Exception('Sin permisos para subir fotos para este usuario. Contacte al administrador.');
      } else if (e.toString().contains('404')) {
        throw Exception('Usuario no encontrado.');
      } else if (e.toString().contains('413')) {
        throw Exception('Las fotos son demasiado grandes. Reduce el tamaño e intenta nuevamente.');
      }

      throw Exception('Error al subir fotos: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  Future<bool> deleteUserPhoto(BigInt userId, BigInt photoId) async {
    try {
      final response = await delete('/users/${userId.toString()}/photos/${photoId.toString()}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error al eliminar foto: $e');
    }
  }

  // ===== MÉTODOS PARA MANEJO DE IMÁGENES DE PERFIL =====

  /// Sube una imagen de perfil para el usuario actual
  Future<Map<String, dynamic>> uploadProfileImage(File imageFile) async {
    try {
      print('📸 Subiendo imagen de perfil...');

      final response = await postFile(
        '/me/profile-image',
        file: imageFile,
        fieldName: 'profile_image',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Actualizar datos del usuario en almacenamiento local
        if (data['user'] != null) {
          final usuario = Usuario.fromJson(data['user']);
          await storageService.saveUser(usuario);
          print('✅ Imagen de perfil actualizada exitosamente');
        }

        return data;
      } else {
        throw Exception(
          'Error al subir imagen de perfil: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al subir imagen de perfil: $e');
      throw Exception('Error al subir imagen de perfil: $e');
    }
  }

  /// Sube una imagen de perfil para un usuario específico (solo admin/manager)
  Future<Map<String, dynamic>> uploadUserProfileImage(BigInt userId, File imageFile) async {
    try {
      print('📸 Subiendo imagen de perfil para usuario $userId...');

      final response = await postFile(
        '/users/$userId/profile-image',
        file: imageFile,
        fieldName: 'profile_image',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Imagen de perfil actualizada exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al subir imagen de perfil: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al subir imagen de perfil: $e');
      throw Exception('Error al subir imagen de perfil: $e');
    }
  }

  /// Elimina la imagen de perfil del usuario actual
  Future<Map<String, dynamic>> deleteProfileImage() async {
    try {
      print('🗑️ Eliminando imagen de perfil...');

      final response = await delete('/me/profile-image');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Actualizar datos del usuario en almacenamiento local
        if (data['user'] != null) {
          final usuario = Usuario.fromJson(data['user']);
          await storageService.saveUser(usuario);
          print('✅ Imagen de perfil eliminada exitosamente');
        }

        return data;
      } else {
        throw Exception(
          'Error al eliminar imagen de perfil: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al eliminar imagen de perfil: $e');
      throw Exception('Error al eliminar imagen de perfil: $e');
    }
  }

  // ===== MÉTODOS PARA GESTIÓN DE USUARIOS =====

  /// Crea un nuevo usuario
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    try {
      print('➕ Creando nuevo usuario...');
      print('📋 Datos a enviar: $userData');

      final response = await post('/users', data: userData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Usuario creado exitosamente');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'crear usuario');
    }
  }

  /// Cambia la contraseña de un usuario específico (solo admin/manager)
  /// - Admins pueden cambiar contraseñas de managers y cobradores
  /// - Managers solo pueden cambiar contraseñas de cobradores asignados a ellos
  /// - Los usuarios no pueden cambiar su propia contraseña por este endpoint
  Future<Map<String, dynamic>> changeUserPassword(String userId, {
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    try {
      print('🔐 Cambiando contraseña de usuario: $userId');

      final requestData = {
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      };

      final response = await patch('/users/$userId/change-password', data: requestData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Contraseña cambiada exitosamente');
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña cambiada exitosamente',
          'data': data['data'],
        };
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'cambiar contraseña');
    }
  }

  /// Maneja las respuestas de error del servidor
  Map<String, dynamic> _handleErrorResponse(dynamic response) {
    String errorMessage = 'Error del servidor';
    List<String> fieldErrors = [];

    if (response.data != null && response.data is Map) {
      final errorData = response.data as Map<String, dynamic>;

      // Mensaje principal del error
      errorMessage =
          errorData['message'] ??
          errorData['error'] ??
          'Error ${response.statusCode}';

      // Si es error 422, extraer errores específicos de validación
      if (response.statusCode == 422 && errorData['errors'] != null) {
        final errors = errorData['errors'] as Map<String, dynamic>;

        errors.forEach((field, messages) {
          if (messages is List) {
            for (String message in messages) {
              // Crear mensajes más amigables
              String friendlyMessage = _createFriendlyErrorMessage(
                field,
                message,
              );
              fieldErrors.add(friendlyMessage);
            }
          }
        });

        // Si tenemos errores específicos, usarlos en lugar del mensaje genérico
        if (fieldErrors.isNotEmpty) {
          errorMessage = fieldErrors.join('\n• ');
          errorMessage = '• $errorMessage'; // Agregar bullet al inicio
        }
      }
    }

    print('❌ Error del servidor: $errorMessage (${response.statusCode})');
    print('❌ Error Response Status: ${response.statusCode}');
    print('❌ Error Response Data: ${response.data}');

    return {
      'success': false,
      'message': errorMessage,
      'status_code': response.statusCode,
      'field_errors': fieldErrors,
      'details': response.data,
    };
  }

  /// Crea mensajes de error más amigables para el usuario
  String _createFriendlyErrorMessage(String field, String message) {
    // Mapear nombres de campos técnicos a nombres amigables
    Map<String, String> fieldNames = {
      'name': 'Nombre',
      'email': 'Correo electrónico',
      'phone': 'Teléfono',
      'password': 'Contraseña',
      'address': 'Dirección',
      'roles': 'Roles',
      'ci': 'CI',
    };

    String friendlyField = fieldNames[field] ?? field;

    // Mapear mensajes comunes a versiones más amigables
    if (message.contains('ya está en uso') ||
        message.contains('already taken')) {
      return '$friendlyField ya está registrado en el sistema';
    } else if (message.contains('requerido') || message.contains('required')) {
      return '$friendlyField es obligatorio';
    } else if (message.contains('formato') ||
        message.contains('format') ||
        message.contains('valid')) {
      return '$friendlyField tiene un formato inválido';
    } else if (message.contains('mínimo') || message.contains('min')) {
      return '$friendlyField es demasiado corto';
    } else if (message.contains('máximo') || message.contains('max')) {
      return '$friendlyField es demasiado largo';
    } else {
      return '$friendlyField: $message';
    }
  }

  /// Maneja las excepciones durante las peticiones
  Map<String, dynamic> _handleException(dynamic e, String operation) {
    print('❌ Error al $operation: $e');

    // Si es un error de Dio con respuesta, delegar a _handleErrorResponse para extraer errores de validación
    if (e is DioException && e.response != null) {
      try {
        return _handleErrorResponse(e.response!);
      } catch (_) {
        // si falla el parseo, continuamos con el fallback
      }
    }

    String errorMessage = 'Error de conexión';

    // Extraer información más específica del error de Dio (fallback)
    final text = e.toString();
    if (text.contains('422')) {
      errorMessage = 'Los datos proporcionados no son válidos';
    } else if (text.contains('400')) {
      errorMessage = 'Solicitud incorrecta';
    } else if (text.contains('401')) {
      errorMessage = 'No tienes autorización para realizar esta acción';
    } else if (text.contains('403')) {
      errorMessage = 'No tienes permisos para realizar esta acción';
    } else if (text.contains('500')) {
      errorMessage = 'Error interno del servidor. Intenta más tarde';
    } else if (text.contains('connection')) {
      errorMessage = 'No se pudo conectar al servidor. Verifica tu conexión';
    }

    return {'success': false, 'message': errorMessage, 'error': e.toString()};
  }

  /// Actualiza un usuario existente
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      print('📝 Actualizando usuario: $userId');

      final response = await put('/users/$userId', data: userData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Usuario actualizado exitosamente');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'actualizar usuario');
    }
  }

  /// Elimina un usuario
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      print('🗑️ Eliminando usuario: $userId');

      final response = await delete('/users/$userId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Usuario eliminado exitosamente');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'eliminar usuario');
    }
  }

  /// Obtiene un usuario específico
  Future<Map<String, dynamic>> getUser(String userId) async {
    try {
      print('👤 Obteniendo usuario: $userId');

      final response = await get('/users/$userId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Usuario obtenido exitosamente');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener usuario');
    }
  }

  /// Obtiene lista de usuarios con filtros
  Future<Map<String, dynamic>> getUsers({String? role, String? search, String? filter, int page = 1, int perPage = 50}) async {
    try {
      print('📋 Obteniendo usuarios...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (role != null && role.isNotEmpty) queryParams['role'] = role;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (filter != null && filter.isNotEmpty) queryParams['filter'] = filter;

      final response = await get('/users', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Usuarios obtenidos exitosamente');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener usuarios');
    }
  }
}


// ===== CLIENT CATEGORIES (A, B, C) =====
extension ClientCategoriesApi on UserApiService {
  Future<Map<String, dynamic>> getClientCategories() async {
    try {
      final response = await get('/client-categories');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener categorías de clientes');
    }
  }

  Future<Map<String, dynamic>> updateClientCategory(BigInt clientId, String category) async {
    try {
      final response = await patch('/users/${clientId.toString()}/category', data: {'category': category});
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'actualizar categoría de cliente');
    }
  }

  Future<Map<String, dynamic>> getClientsByCategory(String category) async {
    try {
      final response = await get('/clients/by-category', queryParameters: {'category': category});
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'filtrar clientes por categoría');
    }
  }

  Future<Map<String, dynamic>> getClientCategoryStatistics() async {
    try {
      final response = await get('/client-categories/statistics');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'estadísticas de categorías');
    }
  }

  Future<Map<String, dynamic>> bulkUpdateClientCategories(List<Map<String, dynamic>> updates) async {
    try {
      final response = await post('/clients/bulk-update-categories', data: {
        'updates': updates,
      });
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data as Map);
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'actualización masiva de categorías');
    }
  }
}
