import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos/usuario.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _rememberMeKey = 'remember_me';
  static const String _lastLoginKey = 'last_login';

  // Guardar token de autenticación
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Obtener token de autenticación
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Guardar datos del usuario
  Future<void> saveUser(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = usuario.toJson();
    await prefs.setString(_userKey, jsonEncode(userJson));
  }

  // Obtener datos del usuario
  Future<Usuario?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return Usuario.fromJson(userMap);
      } catch (e) {
        print('Error al parsear usuario desde almacenamiento: $e');
        return null;
      }
    }
    return null;
  }

  // Guardar preferencia "Recordarme"
  Future<void> setRememberMe(bool rememberMe) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
  }

  // Obtener preferencia "Recordarme"
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  // Guardar fecha de último login
  Future<void> setLastLogin(DateTime dateTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastLoginKey, dateTime.toIso8601String());
  }

  // Obtener fecha de último login
  Future<DateTime?> getLastLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = prefs.getString(_lastLoginKey);
    if (dateString != null) {
      try {
        return DateTime.parse(dateString);
      } catch (e) {
        print('Error al parsear fecha de último login: $e');
        return null;
      }
    }
    return null;
  }

  // Verificar si hay una sesión válida
  Future<bool> hasValidSession() async {
    final token = await getToken();
    final user = await getUser();
    return token != null && user != null;
  }

  // Limpiar toda la sesión
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    
    // No limpiar rememberMe para mantener la preferencia del usuario
    // await prefs.remove(_rememberMeKey);
  }

  // Obtener información de la sesión
  Future<Map<String, dynamic>> getSessionInfo() async {
    final token = await getToken();
    final user = await getUser();
    final rememberMe = await getRememberMe();
    final lastLogin = await getLastLogin();

    return {
      'hasToken': token != null,
      'hasUser': user != null,
      'rememberMe': rememberMe,
      'lastLogin': lastLogin?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}
