import 'package:dio/dio.dart';
import 'dart:io';
import 'storage_service.dart';
import '../modelos/usuario.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.5.44:8000/api';
  late final Dio _dio;
  final StorageService _storageService = StorageService();
  String? _token;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🌐 API Request: ${options.method} ${options.uri}');
          print('📤 Headers: ${options.headers}');
          print('📤 Data: ${options.data}');

          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          print('📥 Response Status: ${response.statusCode}');
          print('📥 Response Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) async {
          print('❌ Error Response Status: ${error.response?.statusCode}');
          print('❌ Error Response Data: ${error.response?.data}');
          print('❌ Error Message: ${error.message}');

          if (error.response?.statusCode == 401) {
            await _logout();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _loadToken() async {
    _token = await _storageService.getToken();
  }

  Future<void> _saveToken(String token) async {
    print('💾 Guardando token: ${token.substring(0, 20)}...');
    await _storageService.saveToken(token);
    _token = token;
    print('✅ Token guardado exitosamente');
  }

  Future<void> _logout() async {
    print('🧹 Limpiando token en memoria...');
    _token = null;
    print('🧹 Limpiando almacenamiento local...');
    await _storageService.clearSession();
    print('✅ Limpieza local completada');
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _loadToken();
    return _dio.get<T>(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _loadToken();
    return _dio.post<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _loadToken();
    return _dio.put<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    await _loadToken();
    return _dio.patch<T>(path, data: data, queryParameters: queryParameters);
  }

  Future<Response<T>> delete<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _loadToken();
    return _dio.delete<T>(path, queryParameters: queryParameters);
  }

  // Método para subir archivos (imágenes)
  Future<Response<T>> postFile<T>(
    String path, {
    required File file,
    String fieldName = 'image',
    Map<String, dynamic>? additionalData,
  }) async {
    await _loadToken();

    // Crear FormData para subida de archivos
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
      ...?additionalData,
    });

    return _dio.post<T>(
      path,
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
          'Accept': 'application/json',
        },
      ),
    );
  }

  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    try {
      print('🔐 Iniciando login para: $emailOrPhone');

      final response = await post(
        '/login',
        data: {'email_or_phone': emailOrPhone, 'password': password},
      );

      print('📡 Respuesta del servidor: ${response.statusCode}');
      print('📄 Datos de respuesta: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Verificar si la respuesta tiene la estructura esperada
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'] as Map<String, dynamic>;

          // Verificar si el token existe y no es null
          if (responseData['token'] != null) {
            print(
              '✅ Token recibido: ${responseData['token'].toString().substring(0, 20)}...',
            );
            await _saveToken(responseData['token']);
          } else {
            print('❌ Token no encontrado en la respuesta');
            throw Exception('Token no encontrado en la respuesta del servidor');
          }

          // Guardar datos del usuario si están disponibles
          if (responseData['user'] != null) {
            print('👤 Datos de usuario recibidos');
            final usuario = Usuario.fromJson(responseData['user']);
            print('👤 Datos de usuario recibidos: ${usuario.toJson()}');
            await _storageService.saveUser(usuario);
          } else {
            print('⚠️ No se recibieron datos de usuario');
          }

          return data;
        } else {
          print('❌ Estructura de respuesta inesperada: $data');
          throw Exception('Estructura de respuesta inesperada del servidor');
        }
      } else {
        print('❌ Error en el login: ${response.statusCode} - ${response.data}');
        throw Exception('Error en el login: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Error de conexión: $e');
      print('🔍 Stack trace: ${StackTrace.current}');

      // Extraer mensaje de error específico del servidor
      if (e is DioException) {
        if (e.response != null) {
          final statusCode = e.response!.statusCode;
          final responseData = e.response!.data;

          print('📡 Status Code: $statusCode');
          print('📄 Response Data: $responseData');

          // Intentar extraer mensaje de error del servidor
          String errorMessage = 'Error de conexión';

          if (responseData is Map<String, dynamic>) {
            if (responseData['message'] != null) {
              errorMessage = responseData['message'].toString();
            } else if (responseData['error'] != null) {
              errorMessage = responseData['error'].toString();
            } else if (responseData['errors'] != null) {
              // Manejar errores de validación
              final errors = responseData['errors'];
              if (errors is Map<String, dynamic>) {
                final firstError = errors.values.first;
                if (firstError is List && firstError.isNotEmpty) {
                  errorMessage = firstError.first.toString();
                } else if (firstError is String) {
                  errorMessage = firstError;
                }
              }
            }
          }

          // Mensajes específicos según el código de estado
          switch (statusCode) {
            case 401:
              errorMessage = 'Credenciales incorrectas';
              break;
            case 422:
              errorMessage = errorMessage.isNotEmpty
                  ? errorMessage
                  : 'Datos de entrada inválidos';
              break;
            case 404:
              errorMessage = 'Usuario no encontrado';
              break;
            case 500:
              errorMessage = 'Error interno del servidor';
              break;
            default:
              if (errorMessage == 'Error de conexión') {
                errorMessage = 'Error del servidor: $statusCode';
              }
          }

          throw Exception(errorMessage);
        } else if (e.type == DioExceptionType.connectionTimeout) {
          throw Exception('Tiempo de conexión agotado');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          throw Exception('Tiempo de respuesta agotado');
        } else if (e.type == DioExceptionType.connectionError) {
          throw Exception('Error de conexión al servidor');
        }
      }

      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> logout() async {
    print('🔐 Iniciando logout en ApiService...');
    try {
      print('📡 Llamando al endpoint /logout...');
      await post('/logout');
      print('✅ Logout exitoso en el servidor');
    } catch (e) {
      print('⚠️ Error en logout del servidor: $e');
      // Continuar con limpieza local incluso si falla el servidor
    } finally {
      print('🧹 Limpiando datos locales...');
      await _logout();
      print('✅ Logout completado en ApiService');
    }
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await get('/me');
    final data = response.data as Map<String, dynamic>;

    // Actualizar datos del usuario en almacenamiento local
    if (data['user'] != null) {
      final usuario = Usuario.fromJson(data['user']);
      await _storageService.saveUser(usuario);
    }

    return data;
  }

  // Verificar si existe un email o teléfono
  Future<Map<String, dynamic>> checkExists(String emailOrPhone) async {
    try {
      final response = await post(
        '/check-exists',
        data: {'email_or_phone': emailOrPhone},
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Error al verificar existencia');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // Obtener usuario desde almacenamiento local
  Future<Usuario?> getLocalUser() async {
    return await _storageService.getUser();
  }

  // Verificar si hay sesión válida
  Future<bool> hasValidSession() async {
    return await _storageService.hasValidSession();
  }

  // Restaurar sesión desde almacenamiento local
  Future<bool> restoreSession() async {
    final hasSession = await _storageService.hasValidSession();
    if (hasSession) {
      await _loadToken();
      return true;
    }
    return false;
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
          await _storageService.saveUser(usuario);
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

  /// Obtiene la URL completa de la imagen de perfil
  String getProfileImageUrl(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) {
      // URL de imagen por defecto
      return '$baseUrl/images/default-avatar.png';
    }

    // Si ya es una URL completa, la devuelve tal como está
    if (profileImage.startsWith('http://') ||
        profileImage.startsWith('https://')) {
      return profileImage;
    }

    // Si es una ruta relativa, la convierte en URL completa
    if (profileImage.startsWith('/')) {
      return '$baseUrl$profileImage';
    }

    // Si no tiene / al inicio, lo agrega
    return '$baseUrl/$profileImage';
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
          await _storageService.saveUser(usuario);
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

  // ================== MÉTODOS PARA GESTIÓN DE CLIENTES ASIGNADOS ==================

  /// Obtiene todos los clientes asignados a un cobrador específico
  Future<Map<String, dynamic>> getCobradorClients(
    String cobradorId, {
    String? search,
    int? perPage,
  }) async {
    try {
      print('📋 Obteniendo clientes del cobrador: $cobradorId');

      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage;
      }

      final response = await get(
        '/users/$cobradorId/clients',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes del cobrador obtenidos exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener clientes del cobrador: $e');
      throw Exception('Error al obtener clientes del cobrador: $e');
    }
  }

  /// Asigna múltiples clientes a un cobrador
  Future<Map<String, dynamic>> assignClientsToCollector(
    String cobradorId,
    List<String> clientIds,
  ) async {
    try {
      print(
        '👥 Asignando ${clientIds.length} clientes al cobrador: $cobradorId',
      );

      final response = await post(
        '/users/$cobradorId/assign-clients',
        data: {'client_ids': clientIds.map((id) => int.parse(id)).toList()},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes asignados exitosamente');
        return data;
      } else {
        throw Exception('Error al asignar clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al asignar clientes al cobrador: $e');
      throw Exception('Error al asignar clientes al cobrador: $e');
    }
  }

  /// Remueve un cliente de un cobrador
  Future<Map<String, dynamic>> removeClientFromCollector(
    String cobradorId,
    String clientId,
  ) async {
    try {
      print('🗑️ Removiendo cliente $clientId del cobrador: $cobradorId');

      final response = await delete('/users/$cobradorId/clients/$clientId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente removido del cobrador exitosamente');
        return data;
      } else {
        throw Exception('Error al remover cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al remover cliente del cobrador: $e');
      throw Exception('Error al remover cliente del cobrador: $e');
    }
  }

  /// Obtiene el cobrador asignado a un cliente específico
  Future<Map<String, dynamic>> getClientCobrador(String clientId) async {
    try {
      print('👤 Obteniendo cobrador del cliente: $clientId');

      final response = await get('/users/$clientId/cobrador');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cobrador del cliente obtenido exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener cobrador: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener cobrador del cliente: $e');
      throw Exception('Error al obtener cobrador del cliente: $e');
    }
  }

  /// Crea un nuevo cliente (solo para cobradores y managers)
  Future<Map<String, dynamic>> createClient(
    Map<String, dynamic> clientData,
  ) async {
    try {
      print('➕ Creando nuevo cliente...');
      print('📋 Datos a enviar: $clientData');

      final response = await post('/users', data: clientData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente creado exitosamente');
        return data;
      } else {
        // Extraer mensaje de error del servidor si existe
        String errorMessage = 'Error del servidor';

        if (response.data != null && response.data is Map) {
          final errorData = response.data as Map<String, dynamic>;

          // Intentar extraer el mensaje principal
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Error ${response.statusCode}';

          // Si es error 422, intentar extraer errores específicos de validación
          if (response.statusCode == 422 && errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            List<String> errorDetails = [];

            errors.forEach((field, messages) {
              if (messages is List) {
                errorDetails.addAll(messages.map((msg) => '$field: $msg'));
              }
            });

            if (errorDetails.isNotEmpty) {
              errorMessage = errorDetails.join(', ');
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
          'details': response.data,
        };
      }
    } catch (e) {
      print('❌ Error al crear cliente: $e');

      String errorMessage = 'Error de conexión';

      // Extraer información más específica del error de Dio
      if (e.toString().contains('422')) {
        errorMessage = 'Datos de entrada inválidos';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Solicitud incorrecta';
      } else if (e.toString().contains('401')) {
        errorMessage = 'No autorizado';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Sin permisos';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Error interno del servidor';
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }

  /// Actualiza un cliente existente
  Future<Map<String, dynamic>> updateClient(
    String clientId,
    Map<String, dynamic> clientData,
  ) async {
    try {
      print('📝 Actualizando cliente: $clientId');

      final response = await put('/users/$clientId', data: clientData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente actualizado exitosamente');
        return data;
      } else {
        throw Exception('Error al actualizar cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al actualizar cliente: $e');
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Elimina un cliente
  Future<Map<String, dynamic>> deleteClient(String clientId) async {
    try {
      print('🗑️ Eliminando cliente: $clientId');

      final response = await delete('/users/$clientId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente eliminado exitosamente');
        return data;
      } else {
        throw Exception('Error al eliminar cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al eliminar cliente: $e');
      throw Exception('Error al eliminar cliente: $e');
    }
  }
}
