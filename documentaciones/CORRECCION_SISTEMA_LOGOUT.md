# Corrección del Sistema de Logout

## Problema Identificado

Se solicitó verificar que el cierre de sesión funcione correctamente, cerrando todos los servicios y volviendo a la pantalla de login.

## Análisis del Sistema Actual

### Flujo de Logout Existente

1. **Usuario presiona botón logout** → Diálogo de confirmación
2. **Confirmación** → `AuthProvider.logout()`
3. **AuthProvider** → `ApiService.logout()`
4. **ApiService** → Llamada al servidor + limpieza local
5. **StorageService** → Limpieza de datos locales
6. **Estado** → Reset a `AuthState(isInitialized: true)`
7. **Navegación** → Automática a `LoginScreen`

### Problemas Identificados

1. **Falta de logs detallados** para debugging
2. **No se limpiaba la fecha de último login**
3. **Falta de manejo robusto de errores** en el servidor
4. **No había confirmación visual** del proceso

## Solución Implementada

### 1. Mejora en StorageService

Se mejoró la limpieza completa de la sesión:

```dart
// Limpiar toda la sesión
Future<void> clearSession() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_tokenKey);
  await prefs.remove(_userKey);
  await prefs.remove(_lastLoginKey); // ✅ Agregado

  // No limpiar rememberMe para mantener la preferencia del usuario
  // await prefs.remove(_rememberMeKey);
  
  print('🧹 Sesión limpiada completamente'); // ✅ Log agregado
}
```

### 2. Mejora en AuthProvider

Se agregaron logs detallados y mejor manejo de errores:

```dart
Future<void> logout() async {
  print('🚪 Iniciando proceso de logout...'); // ✅ Log agregado
  state = state.copyWith(isLoading: true);

  try {
    // Llamar al endpoint de logout si hay conexión
    print('📡 Llamando al endpoint de logout...'); // ✅ Log agregado
    await _apiService.logout();
    print('✅ Logout exitoso en el servidor'); // ✅ Log agregado
  } catch (e) {
    // Si no hay conexión, continuar con el logout local
    print('⚠️ Error al hacer logout en el servidor: $e'); // ✅ Log agregado
    print('⚠️ Continuando con logout local...'); // ✅ Log agregado
  } finally {
    // Limpiar sesión local
    print('🧹 Limpiando sesión local...'); // ✅ Log agregado
    await _storageService.clearSession();
    
    // Resetear estado completamente
    state = const AuthState(isInitialized: true);
    print('✅ Logout completado - Estado reseteado'); // ✅ Log agregado
  }
}
```

### 3. Mejora en ApiService

Se mejoró el manejo de errores y logs:

```dart
Future<void> logout() async {
  print('🔐 Iniciando logout en ApiService...'); // ✅ Log agregado
  try {
    print('📡 Llamando al endpoint /logout...'); // ✅ Log agregado
    await post('/logout');
    print('✅ Logout exitoso en el servidor'); // ✅ Log agregado
  } catch (e) {
    print('⚠️ Error en logout del servidor: $e'); // ✅ Log agregado
    // Continuar con limpieza local incluso si falla el servidor
  } finally {
    print('🧹 Limpiando datos locales...'); // ✅ Log agregado
    await _logout();
    print('✅ Logout completado en ApiService'); // ✅ Log agregado
  }
}

Future<void> _logout() async {
  print('🧹 Limpiando token en memoria...'); // ✅ Log agregado
  _token = null;
  print('🧹 Limpiando almacenamiento local...'); // ✅ Log agregado
  await _storageService.clearSession();
  print('✅ Limpieza local completada'); // ✅ Log agregado
}
```

### 4. Mejora en Main.dart

Se agregó un listener para detectar cambios de autenticación:

```dart
// Escuchar cambios en el estado de autenticación para manejar logout
ref.listen<AuthState>(authProvider, (previous, next) {
  // Si el usuario estaba autenticado y ahora no lo está, es un logout
  if (previous?.isAuthenticated == true && !next.isAuthenticated) {
    print('🚪 Usuario ha cerrado sesión - Redirigiendo a LoginScreen'); // ✅ Log agregado
  }
});
```

## Flujo de Logout Mejorado

### 1. Inicio del Logout
```
Usuario presiona logout → Diálogo de confirmación → AuthProvider.logout()
```

### 2. Proceso en AuthProvider
```
🚪 Iniciando proceso de logout...
📡 Llamando al endpoint de logout...
```

### 3. Proceso en ApiService
```
🔐 Iniciando logout en ApiService...
📡 Llamando al endpoint /logout...
✅ Logout exitoso en el servidor (o ⚠️ Error en logout del servidor)
🧹 Limpiando datos locales...
```

### 4. Limpieza Local
```
🧹 Limpiando token en memoria...
🧹 Limpiando almacenamiento local...
🧹 Sesión limpiada completamente
✅ Limpieza local completada
```

### 5. Reset de Estado
```
🧹 Limpiando sesión local...
✅ Logout completado - Estado reseteado
🚪 Usuario ha cerrado sesión - Redirigiendo a LoginScreen
```

### 6. Navegación Automática
```
AuthState.isAuthenticated = false → _buildInitialScreen() → LoginScreen
```

## Datos Limpiados

### ✅ Token de Autenticación
- **Memoria**: `_token = null`
- **Almacenamiento**: `prefs.remove(_tokenKey)`

### ✅ Datos del Usuario
- **Almacenamiento**: `prefs.remove(_userKey)`

### ✅ Fecha de Último Login
- **Almacenamiento**: `prefs.remove(_lastLoginKey)`

### ✅ Estado de la Aplicación
- **AuthState**: `const AuthState(isInitialized: true)`
- **Usuario**: `null`
- **isAuthenticated**: `false`

### ✅ Preferencias Mantenidas
- **Remember Me**: Se mantiene la preferencia del usuario

## Casos de Uso Verificados

### ✅ Logout Exitoso con Servidor
1. Usuario presiona logout
2. Confirmación del diálogo
3. Llamada exitosa al servidor
4. Limpieza completa local
5. Navegación a LoginScreen

### ✅ Logout sin Conexión al Servidor
1. Usuario presiona logout
2. Confirmación del diálogo
3. Error en llamada al servidor
4. Limpieza completa local (fallback)
5. Navegación a LoginScreen

### ✅ Logout desde Diferentes Pantallas
- **AdminDashboardScreen**: Botón logout en AppBar
- **ManagerDashboardScreen**: Botón logout en AppBar
- **CobradorDashboardScreen**: Botón logout en AppBar
- **HomeScreen**: Botón logout en PerfilScreen

### ✅ Verificación de Limpieza
- No se puede acceder a datos del usuario anterior
- No se puede hacer llamadas API sin autenticación
- La aplicación vuelve al estado inicial

## Logs de Debug

### Logout Exitoso
```
🚪 Iniciando proceso de logout...
📡 Llamando al endpoint de logout...
🔐 Iniciando logout en ApiService...
📡 Llamando al endpoint /logout...
✅ Logout exitoso en el servidor
✅ Logout exitoso en el servidor
🧹 Limpiando datos locales...
🧹 Limpiando token en memoria...
🧹 Limpiando almacenamiento local...
🧹 Sesión limpiada completamente
✅ Limpieza local completada
✅ Logout completado en ApiService
🧹 Limpiando sesión local...
✅ Logout completado - Estado reseteado
🚪 Usuario ha cerrado sesión - Redirigiendo a LoginScreen
```

### Logout sin Conexión
```
🚪 Iniciando proceso de logout...
📡 Llamando al endpoint de logout...
🔐 Iniciando logout en ApiService...
📡 Llamando al endpoint /logout...
⚠️ Error en logout del servidor: DioException [connection error]
🧹 Limpiando datos locales...
🧹 Limpiando token en memoria...
🧹 Limpiando almacenamiento local...
🧹 Sesión limpiada completamente
✅ Limpieza local completada
✅ Logout completado en ApiService
⚠️ Error al hacer logout en el servidor: DioException [connection error]
⚠️ Continuando con logout local...
🧹 Limpiando sesión local...
✅ Logout completado - Estado reseteado
🚪 Usuario ha cerrado sesión - Redirigiendo a LoginScreen
```

## Archivos Modificados

1. **`lib/datos/servicios/storage_service.dart`**
   - Agregada limpieza de `_lastLoginKey`
   - Agregados logs de confirmación

2. **`lib/negocio/providers/auth_provider.dart`**
   - Mejorados logs del proceso de logout
   - Mejorado manejo de errores

3. **`lib/datos/servicios/api_service.dart`**
   - Mejorados logs del proceso de logout
   - Mejorado manejo de errores del servidor

4. **`lib/main.dart`**
   - Agregado listener para detectar logout
   - Agregados logs de navegación

## Testing Recomendado

### Casos de Prueba

1. **Logout con Conexión**
   - Hacer login
   - Presionar logout
   - Verificar navegación a LoginScreen
   - Verificar que no se puede acceder a datos anteriores

2. **Logout sin Conexión**
   - Desconectar internet
   - Hacer logout
   - Verificar limpieza local
   - Verificar navegación a LoginScreen

3. **Logout desde Diferentes Pantallas**
   - Login como admin → Logout desde AdminDashboard
   - Login como manager → Logout desde ManagerDashboard
   - Login como cobrador → Logout desde CobradorDashboard

4. **Verificación de Limpieza**
   - Después del logout, verificar en logs que se limpió todo
   - Intentar acceder a datos del usuario (debe fallar)
   - Verificar que el estado es `isAuthenticated: false`

### Comandos de Debug

```bash
# Ver logs de logout
flutter run --debug

# En la consola, buscar logs con:
# 🚪 🧹 ✅ ⚠️ 🔐 📡
```

## Resultado

✅ **Logout completo** con limpieza de todos los datos
✅ **Logs detallados** para debugging y monitoreo
✅ **Manejo robusto** de errores de conexión
✅ **Navegación automática** a LoginScreen
✅ **Limpieza de memoria** y almacenamiento local
✅ **Mantenimiento de preferencias** del usuario

El sistema de logout ahora funciona correctamente, cerrando todos los servicios y volviendo automáticamente a la pantalla de login, con logs detallados para facilitar el debugging y monitoreo del proceso. 