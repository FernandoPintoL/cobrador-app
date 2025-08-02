# Sistema de Persistencia de Sesión - Cobrador App

## Descripción General

Se ha implementado un sistema completo de persistencia de sesión para la aplicación móvil Cobrador App, que permite a los usuarios mantener su sesión activa entre diferentes ejecuciones de la aplicación sin necesidad de iniciar sesión constantemente.

## Características Implementadas

### 1. Almacenamiento Local Seguro
- **StorageService**: Servicio dedicado para manejar el almacenamiento local usando SharedPreferences
- **Datos guardados**:
  - Token de autenticación
  - Datos del usuario
  - Preferencia "Recordarme"
  - Fecha del último login

### 2. Login Flexible
- **Soporte para email o teléfono**: Los usuarios pueden iniciar sesión usando su correo electrónico o número de teléfono
- **Campo unificado**: Un solo campo de entrada que acepta ambos tipos de datos
- **Validación inteligente**: El backend detecta automáticamente si es email o teléfono

### 3. Opción "Recordarme"
- **Checkbox en login**: Los usuarios pueden elegir mantener su sesión activa
- **Persistencia configurable**: La preferencia se guarda independientemente de la sesión
- **Experiencia mejorada**: No necesitan recordar si marcaron la opción

### 4. Inicialización Automática
- **Verificación al arranque**: La aplicación verifica automáticamente si hay una sesión válida
- **Pantalla de splash**: Muestra una pantalla de carga mientras se inicializa
- **Navegación automática**: Redirige automáticamente al usuario según su estado de autenticación

### 5. Gestión de Sesión
- **Restauración automática**: Recupera la sesión desde el almacenamiento local
- **Logout seguro**: Limpia todos los datos de sesión al cerrar sesión
- **Manejo de errores**: Gestiona errores de conexión y datos corruptos

## Arquitectura del Sistema

### Servicios Implementados

#### StorageService (`lib/datos/servicios/storage_service.dart`)
```dart
class StorageService {
  // Métodos principales:
  - saveToken(String token)
  - getToken()
  - saveUser(Usuario usuario)
  - getUser()
  - setRememberMe(bool remember)
  - getRememberMe()
  - hasValidSession()
  - clearSession()
}
```

#### ApiService Actualizado (`lib/datos/servicios/api_service.dart`)
```dart
class ApiService {
  // Nuevos métodos:
  - login(String emailOrPhone, String password)
  - checkExists(String emailOrPhone)
  - getLocalUser()
  - hasValidSession()
  - restoreSession()
}
```

#### AuthProvider Mejorado (`lib/negocio/providers/auth_provider.dart`)
```dart
class AuthNotifier {
  // Nuevos métodos:
  - initialize()
  - login(String emailOrPhone, String password, {bool rememberMe})
  - logout()
  - refreshUser()
  - checkExists(String emailOrPhone)
  - getSessionInfo()
}
```

### Flujo de Autenticación

1. **Inicialización de la App**:
   ```
   App inicia → Verificar sesión local → Si existe → Restaurar sesión → Ir a Home
   App inicia → Verificar sesión local → Si no existe → Ir a Login
   ```

2. **Proceso de Login**:
   ```
   Usuario ingresa credenciales → Validar → Llamar API → Guardar datos → Ir a Home
   ```

3. **Persistencia de Sesión**:
   ```
   Login exitoso → Guardar token y datos → Configurar "Recordarme" → Navegar
   ```

4. **Logout**:
   ```
   Usuario hace logout → Limpiar datos locales → Llamar API logout → Ir a Login
   ```

## Pantallas Actualizadas

### LoginScreen (`lib/presentacion/pantallas/login_screen.dart`)
- **Campo unificado**: "Correo electrónico o teléfono"
- **Checkbox "Recordarme"**: Nueva opción para mantener sesión
- **Integración con Riverpod**: Usa AuthProvider para manejo de estado
- **Validación mejorada**: Acepta email o teléfono sin validación estricta

### SplashScreen (`lib/presentacion/pantallas/splash_screen.dart`)
- **Pantalla de carga**: Muestra mientras se inicializa la aplicación
- **Diseño atractivo**: Gradiente y logo de la aplicación
- **Feedback visual**: Indicador de progreso y texto informativo

### HomeScreen (`lib/presentacion/pantallas/home_screen.dart`)
- **Integración con Riverpod**: Usa ConsumerStatefulWidget
- **Perfil mejorado**: Muestra información del usuario y opciones
- **Logout seguro**: Diálogo de confirmación antes de cerrar sesión

### Main App (`lib/main.dart`)
- **ProviderScope**: Configuración de Riverpod
- **Inicialización automática**: Llama a initialize() al arrancar
- **Navegación inteligente**: Determina la pantalla inicial según el estado

## Beneficios del Sistema

### Para el Usuario
1. **Experiencia mejorada**: No necesita iniciar sesión constantemente
2. **Flexibilidad**: Puede usar email o teléfono para login
3. **Control**: Puede elegir si mantener la sesión o no
4. **Seguridad**: Logout seguro con confirmación

### Para el Desarrollador
1. **Código limpio**: Arquitectura bien estructurada
2. **Mantenibilidad**: Servicios separados y reutilizables
3. **Escalabilidad**: Fácil agregar nuevas funcionalidades
4. **Testing**: Fácil de probar con mocks

### Para la Aplicación
1. **Rendimiento**: Inicialización rápida con datos locales
2. **Confiabilidad**: Manejo robusto de errores
3. **Seguridad**: Almacenamiento seguro de credenciales
4. **UX**: Transiciones suaves entre pantallas

## Configuración del Backend

El sistema está diseñado para trabajar con el backend que ya tienes implementado:

### Endpoints Requeridos
- `POST /api/login` - Login con `email_or_phone` y `password`
- `POST /api/logout` - Logout del usuario
- `GET /api/me` - Obtener datos del usuario actual
- `POST /api/check-exists` - Verificar existencia de email/teléfono

### Respuesta Esperada del Login
```json
{
  "token": "jwt_token_here",
  "user": {
    "id": "1",
    "name": "Usuario Ejemplo",
    "email": "usuario@ejemplo.com",
    "phone": "1234567890",
    "address": "Dirección del usuario",
    "roles": ["cobrador"],
    "created_at": "2024-01-01T00:00:00Z",
    "updated_at": "2024-01-01T00:00:00Z"
  }
}
```

## Consideraciones de Seguridad

1. **Almacenamiento local**: Los datos se guardan en SharedPreferences (encriptado en iOS/Android)
2. **Token JWT**: Se almacena el token de autenticación de forma segura
3. **Limpieza automática**: Los datos se limpian al hacer logout
4. **Manejo de errores**: Datos corruptos se eliminan automáticamente

## Próximos Pasos

1. **Implementar refresh token**: Para renovar automáticamente la sesión
2. **Biometría**: Agregar autenticación con huella dactilar/Face ID
3. **Sincronización offline**: Guardar datos para uso sin conexión
4. **Notificaciones push**: Configurar notificaciones para la app
5. **Analytics**: Agregar tracking de eventos de autenticación

## Uso del Sistema

### Para Desarrolladores
1. El sistema se inicializa automáticamente al arrancar la app
2. Usar `ref.watch(authProvider)` para acceder al estado de autenticación
3. Usar `ref.read(authProvider.notifier)` para llamar métodos de autenticación

### Para Usuarios
1. Marcar "Recordarme" para mantener la sesión
2. Usar email o teléfono para iniciar sesión
3. La app recordará la sesión hasta hacer logout
4. Logout desde el perfil con confirmación

## Conclusión

El sistema de persistencia de sesión implementado proporciona una experiencia de usuario fluida y segura, eliminando la necesidad de iniciar sesión constantemente mientras mantiene la seguridad de los datos del usuario. La arquitectura modular permite fácil mantenimiento y extensión de funcionalidades. 