import 'dart:io';
import 'base_api_service.dart';
import '../modelos/usuario.dart';

/// Servicio API para gestión de usuarios y perfiles
class UserApiService extends BaseApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService() => _instance;
  UserApiService._internal();

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
  Future<Map<String, dynamic>> uploadUserProfileImage(
    BigInt userId,
    File imageFile,
  ) async {
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

    String errorMessage = 'Error de conexión';

    // Extraer información más específica del error de Dio
    if (e.toString().contains('422')) {
      errorMessage = 'Los datos proporcionados no son válidos';
    } else if (e.toString().contains('400')) {
      errorMessage = 'Solicitud incorrecta';
    } else if (e.toString().contains('401')) {
      errorMessage = 'No tienes autorización para realizar esta acción';
    } else if (e.toString().contains('403')) {
      errorMessage = 'No tienes permisos para realizar esta acción';
    } else if (e.toString().contains('500')) {
      errorMessage = 'Error interno del servidor. Intenta más tarde';
    } else if (e.toString().contains('connection')) {
      errorMessage = 'No se pudo conectar al servidor. Verifica tu conexión';
    }

    return {'success': false, 'message': errorMessage, 'error': e.toString()};
  }

  /// Actualiza un usuario existente
  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) async {
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
  Future<Map<String, dynamic>> getUsers({
    String? role,
    String? search,
    String? filter,
    int page = 1,
    int perPage = 50,
  }) async {
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
