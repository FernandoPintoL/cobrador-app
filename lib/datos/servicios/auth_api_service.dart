import 'package:dio/dio.dart';
import 'base_api_service.dart';
import '../modelos/usuario.dart';

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
            await saveTokenFromResponse(responseData['token']);
          } else {
            print('❌ Token no encontrado en la respuesta');
            throw Exception('Token no encontrado en la respuesta del servidor');
          }

          // Guardar datos del usuario si están disponibles
          if (responseData['user'] != null) {
            print('👤 Datos de usuario recibidos');
            final usuario = Usuario.fromJson(responseData['user']);
            print('👤 Datos de usuario recibidos: ${usuario.toJson()}');
            await storageService.saveUser(usuario);
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
        throw Exception(handleDioError(e));
      }

      throw Exception('Error de conexión: $e');
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    print('🔐 Iniciando logout en AuthApiService...');
    try {
      print('📡 Llamando al endpoint /logout...');
      await post('/logout');
      print('✅ Logout exitoso en el servidor');
    } catch (e) {
      print('⚠️ Error en logout del servidor: $e');
      // Continuar con limpieza local incluso si falla el servidor
    } finally {
      print('🧹 Limpiando datos locales...');
      await clearSession();
      print('✅ Logout completado en AuthApiService');
    }
  }

  /// Obtiene la información del usuario actual
  Future<Map<String, dynamic>> getMe() async {
    final response = await get('/me');
    final data = response.data as Map<String, dynamic>;

    // Actualizar datos del usuario en almacenamiento local
    if (data['user'] != null) {
      final usuario = Usuario.fromJson(data['user']);
      await storageService.saveUser(usuario);
    }

    return data;
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
