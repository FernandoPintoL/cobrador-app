import 'package:dio/dio.dart';
import 'dart:io';
import 'storage_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Clase base para todos los servicios de API
/// Contiene la configuración común y métodos HTTP básicos
abstract class BaseApiService {
  static final String baseUrl =
      dotenv.env['BASE_URL'] ?? 'http://localhost:8000/api';
  late final Dio _dio;
  final StorageService _storageService = StorageService();
  String? _token;

  BaseApiService() {
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

  // Métodos HTTP básicos
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

  // Getters para acceso a servicios internos
  StorageService get storageService => _storageService;

  // Métodos de utilidad compartidos
  Future<void> saveTokenFromResponse(String token) async {
    await _saveToken(token);
  }

  Future<void> clearSession() async {
    await _logout();
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

  /// Maneja errores de Dio de forma estandarizada
  String handleDioError(DioException e) {
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
          errorMessage = 'Recurso no encontrado';
          break;
        case 500:
          errorMessage = 'Error interno del servidor';
          break;
        default:
          if (errorMessage == 'Error de conexión') {
            errorMessage = 'Error del servidor: $statusCode';
          }
      }

      return errorMessage;
    } else if (e.type == DioExceptionType.connectionTimeout) {
      return 'Tiempo de conexión agotado';
    } else if (e.type == DioExceptionType.receiveTimeout) {
      return 'Tiempo de respuesta agotado';
    } else if (e.type == DioExceptionType.connectionError) {
      return 'Error de conexión al servidor';
    }

    return 'Error de conexión: ${e.message}';
  }
}
