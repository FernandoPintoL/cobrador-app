import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
        connectTimeout: const Duration(seconds: 10), // Reducido de 30 a 10
        receiveTimeout: const Duration(seconds: 15), // Reducido de 30 a 15
        sendTimeout: const Duration(seconds: 10), // Agregado timeout de envío
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          debugPrint('🌐 API Request: ${options.method} ${options.uri}');
          // debugPrint('📤 Headers: ${options.headers}');
          if (options.data != null) {
            debugPrint('📤 Data: ${options.data}');
          }

          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          handler.next(options);
        },
        onResponse: (response, handler) async {
          debugPrint('📥 Response Status: ${response.statusCode}');
          if (response.data != null) {
            debugPrint('📥 Response Data: ${response.data}');
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint('❌ Error Response Status: ${error.response?.statusCode}');
          debugPrint('❌ Error Response Data: ${error.response?.data}');
          debugPrint('❌ Error Message: ${error.message}');
          debugPrint('❌ Error Type: ${error.type}');

          // Manejar timeout y errores de conexión más gracefully
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout) {
            debugPrint('⏱️ Timeout detectado, continuando con fallback');
          }

          if (error.response?.statusCode == 401) {
            debugPrint('🔐 Token inválido, limpiando sesión...');
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
    debugPrint('💾 Guardando token: ${token.substring(0, 20)}...');
    await _storageService.saveToken(token);
    _token = token;
    debugPrint('✅ Token guardado exitosamente');
  }

  Future<void> _logout() async {
    debugPrint('🧹 Limpiando token en memoria...');
    _token = null;
    debugPrint('🧹 Limpiando almacenamiento local...');
    await _storageService.clearSession();
    debugPrint('✅ Limpieza local completada');
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

  /// Método genérico para enviar multipart/form-data (múltiples archivos y campos)
  Future<Response<T>> postFormData<T>(String path, FormData formData) async {
    await _loadToken();
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
    // Si no hay imagen, devolver imagen por defecto
    if (profileImage == null || profileImage.isEmpty) {
      return '$baseUrl/images/default-avatar.png';
    }

    // Si ya es una URL completa, devolverla tal como está
    if (profileImage.startsWith('http://') || profileImage.startsWith('https://')) {
      return profileImage;
    }

    // Construir URL completa desde baseUrl
    // Primero obtenemos la URL base del servidor (sin /api)
    final serverUrl = baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

    // Agregar debug logging
    debugPrint('🖼️ Construyendo URL de imagen:');
    debugPrint('  - profileImage recibida: "$profileImage"');
    debugPrint('  - baseUrl: "$baseUrl"');
    debugPrint('  - serverUrl: "$serverUrl"');

    String finalUrl;

    // Verificar si ya incluye storage/ al inicio
    if (profileImage.startsWith('storage/') || profileImage.startsWith('/storage/')) {
      // Ya tiene el prefijo storage, usarla directamente
      finalUrl = profileImage.startsWith('/') ? '$serverUrl$profileImage' : '$serverUrl/$profileImage';
    } else {
      // No tiene storage/, agregarlo
      finalUrl = '$serverUrl/storage/$profileImage';
    }

    debugPrint('  - URL final construida: "$finalUrl"');
    return finalUrl;
  }

  /// Maneja errores de Dio de forma estandarizada
  String handleDioError(DioException e) {
    debugPrint('💥 Error login');
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;

      debugPrint('❌ Error Response Status: $statusCode');
      debugPrint('❌ Error Response Data: $responseData');

      // Intentar extraer mensaje de error del servidor
      String errorMessage = 'Error de conexión';

      if (responseData is Map<String, dynamic>) {
        // Primero intentamos obtener el mensaje principal
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        }

        // Para errores de validación (422), formateamos mejor el mensaje
        if (statusCode == 422 && responseData['errors'] != null) {
          final errors = responseData['errors'];
          if (errors is Map<String, dynamic> && errors.isNotEmpty) {
            final firstErrorField = errors.keys.first;
            final firstError = errors[firstErrorField];

            if (firstError is List && firstError.isNotEmpty) {
              // Agregamos el nombre del campo para más contexto
              final fieldName = firstErrorField.replaceAll('_', ' ');
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
          errorMessage = 'Credenciales incorrectas o sesión expirada';
          break;
        case 403:
          errorMessage = 'No tiene permisos para realizar esta acción';
          break;
        case 422:
          // Ya manejado arriba, pero mantenemos esto como respaldo
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
