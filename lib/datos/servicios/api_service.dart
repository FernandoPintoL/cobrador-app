import 'dart:convert';
import 'package:dio/dio.dart';
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
    await _storageService.clearSession();
    _token = null;
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
      throw Exception('Error de conexión: $e');
    }
  }

  Future<void> logout() async {
    try {
      await post('/logout');
    } finally {
      await _logout();
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
}
