import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'base_api_service.dart';
import '../modelos/usuario.dart';
import '../modelos/dashboard_statistics.dart';

/// Servicio API para autenticación y gestión de sesiones
class AuthApiService extends BaseApiService {
  static final AuthApiService _instance = AuthApiService._internal();
  factory AuthApiService() => _instance;
  AuthApiService._internal();

  /// Inicia sesión con email/teléfono y contraseña
  Future<Map<String, dynamic>> login(
    String emailOrPhone,
    String password,
  ) async {
    try {
      // debugPrint('🔐 Iniciando login para: $emailOrPhone');

      final response = await post(
        '/login',
        data: {'email_or_phone': emailOrPhone, 'password': password},
      );

      /*debugPrint('📡 Respuesta del servidor: ${response.statusCode}');
      debugPrint('📄 Datos de respuesta: ${response.data}');*/

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Verificar si la respuesta tiene la estructura esperada
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'] as Map<String, dynamic>;

          // Verificar si el token existe y no es null
          if (responseData['token'] != null) {
            debugPrint(
              '✅ Token recibido: ${responseData['token'].toString().substring(0, 20)}...',
            );
            await saveTokenFromResponse(responseData['token']);
          } else {
            debugPrint('❌ Token no encontrado en la respuesta');
            throw Exception('Token no encontrado en la respuesta del servidor');
          }

          // Guardar datos del usuario si están disponibles
          if (responseData['user'] != null) {
            debugPrint('👤 Datos de usuario recibidos');
            final usuario = Usuario.fromJson(responseData['user']);
            debugPrint('👤 Datos de usuario recibidos: ${usuario.toJson()}');
            await storageService.saveUser(usuario);
          } else {
            debugPrint('⚠️ No se recibieron datos de usuario');
          }

          // Guardar estadísticas del dashboard si están disponibles
          if (responseData['statistics'] != null) {
            debugPrint('📊 Estadísticas del dashboard recibidas');
            final statistics = DashboardStatistics.fromJson(
              responseData['statistics'] as Map<String, dynamic>,
            );
            debugPrint('📊 Guardando estadísticas: $statistics');
            await storageService.saveDashboardStatistics(statistics);
          } else {
            debugPrint('ℹ️ No se recibieron estadísticas del dashboard');
          }

          return data;
        } else {
          debugPrint('❌ Estructura de respuesta inesperada: $data');
          throw Exception('Estructura de respuesta inesperada del servidor');
        }
      } else {
        debugPrint(
          '❌ Error en el login: ${response.statusCode} - ${response.data}',
        );
        throw Exception('Error en el login: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('💥 Error de conexión: $e');
      debugPrint('🔍 Stack trace: ${StackTrace.current}');

      // Extraer mensaje de error específico del servidor
      if (e is DioException) {
        throw Exception(handleDioError(e));
      }

      throw Exception('Error de conexión: $e');
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    debugPrint('🔐 Iniciando logout en AuthApiService...');
    try {
      debugPrint('📡 Llamando al endpoint /logout...');
      await post('/logout');
      debugPrint('✅ Logout exitoso en el servidor');
    } catch (e) {
      debugPrint('⚠️ Error en logout del servidor: $e');
      // Continuar con limpieza local incluso si falla el servidor
    } finally {
      debugPrint('🧹 Limpiando datos locales...');
      await clearSession();
      debugPrint('✅ Logout completado en AuthApiService');
    }
  }

  /// Obtiene la información del usuario actual
  /// También guarda estadísticas del dashboard si están disponibles
  Future<Map<String, dynamic>> getMe() async {
    final response = await get('/me');
    final data = response.data as Map<String, dynamic>;
    // La respuesta real viene anidada bajo la clave 'data'
    final payload = (data['data'] is Map<String, dynamic>)
        ? data['data'] as Map<String, dynamic>
        : <String, dynamic>{};

    // Actualizar datos del usuario en almacenamiento local
    if (payload['user'] != null) {
      final usuario = Usuario.fromJson(payload['user']);
      await storageService.saveUser(usuario);
    }

    // ✅ NUEVO: Guardar estadísticas del dashboard si están disponibles
    // Esto es importante cuando la app se recupera o se reinicia
    if (payload['statistics'] != null) {
      debugPrint('📊 Estadísticas del dashboard recibidas en /api/me');
      final statistics = DashboardStatistics.fromJson(
        payload['statistics'] as Map<String, dynamic>,
      );
      debugPrint('📊 Guardando estadísticas desde /api/me: $statistics');
      await storageService.saveDashboardStatistics(statistics);
    } else {
      debugPrint('ℹ️ No se recibieron estadísticas en /api/me');
    }

    return payload.isNotEmpty ? payload : data;
  }

  /// Verifica si existe un email o teléfono
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

  /// Obtiene usuario desde almacenamiento local
  Future<Usuario?> getLocalUser() async {
    return await storageService.getUser();
  }

  /// Verifica si hay sesión válida
  Future<bool> hasValidSession() async {
    return await storageService.hasValidSession();
  }

  /// Restaura sesión desde almacenamiento local
  Future<bool> restoreSession() async {
    final hasSession = await storageService.hasValidSession();
    if (hasSession) {
      // El token se carga automáticamente en _loadToken()
      return true;
    }
    return false;
  }
}
