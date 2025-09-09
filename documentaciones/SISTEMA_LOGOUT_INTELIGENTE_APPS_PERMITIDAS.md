# Sistema de Logout Inteligente - Aplicaciones Permitidas

## Resumen

El sistema de logout inteligente ha sido mejorado para permitir que los usuarios utilicen aplicaciones específicas (galería, cámara, Google Maps, llamadas y WhatsApp) sin que se cierre automáticamente la sesión cuando la aplicación pasa a segundo plano.

## Características Principales

### 1. Aplicaciones Permitidas
- **Galería**: Acceso a fotos y selección de imágenes
- **Cámara**: Tomar fotos y videos
- **Google Maps**: Navegación y ubicación
- **Llamadas**: Llamadas telefónicas normales
- **WhatsApp**: Mensajería (cuando se abre desde la app)

### 2. Tiempos de Gracia
- **Pantallas internas permitidas**: 10 minutos máximo
- **Pantallas normales**: 30 segundos
- **Estados de llamada/inactivo**: Sin límite de tiempo específico

### 3. Lógica Inteligente
- Detecta el contexto antes de programar logout
- Cancela logout automáticamente cuando se regresa a la app dentro del tiempo permitido
- Aplica diferentes tiempos según el tipo de actividad

## Implementación

### AutoLogoutService Mejorado

El servicio ahora incluye:
- Detección de contextos permitidos
- Control de tiempo en aplicaciones externas
- Manejo inteligente del ciclo de vida de la aplicación

```dart
// Marcar contexto permitido antes de usar una aplicación externa
_autoLogoutService?.markAllowedContext('camera_access_active');

// Limpiar contexto después del uso
_autoLogoutService?.clearAllowedContext();
```

### AllowedAppsHelper

Nuevo servicio auxiliar que proporciona funciones seguras para:

#### Cámara y Galería
```dart
// Abrir cámara con verificación de permisos y contexto
final image = await AllowedAppsHelper.openCameraWithPermissions();

// Abrir galería múltiple
final images = await AllowedAppsHelper.openGalleryMultipleSecurely();
```

#### Google Maps
```dart
// Abrir ubicación en Google Maps
await AllowedAppsHelper.openMapsSecurely(
  latitude: -12.0464,
  longitude: -77.0428,
  label: 'Lima, Perú'
);
```

#### Llamadas Telefónicas
```dart
// Realizar llamada con verificación de permisos
await AllowedAppsHelper.makePhoneCallWithPermissions('+51987654321');
```

#### WhatsApp
```dart
// Abrir WhatsApp con mensaje
await AllowedAppsHelper.openWhatsAppSecurely(
  phoneNumber: '+51987654321',
  message: 'Hola desde la app de cobrador'
);
```

## Flujo de Funcionamiento

### 1. App en Primer Plano
- Sistema activo y monitoreando
- No hay timers de logout activos

### 2. App Pausada (Segundo Plano)
- **En pantalla permitida**: Timer de 10 minutos
- **En pantalla normal**: Timer de 30 segundos
- **Contexto marcado manualmente**: Timer extendido según la aplicación

### 3. App Resumida (Primer Plano)
- Evalúa tiempo transcurrido
- Si < tiempo límite: Cancela logout
- Si > tiempo límite: Mantiene logout programado (5 segundos)

### 4. Estados Especiales
- **Inactive**: No programa logout (llamadas entrantes, notificaciones)
- **Detached**: Logout inmediato por seguridad
- **Hidden**: Timer de 15 segundos (pantalla normal) o 5 minutos (pantalla permitida)

## Uso en la Aplicación

### Para Desarrolladores

1. **Antes de usar aplicaciones externas**, marcar el contexto:
```dart
AllowedAppsHelper.markCameraUsage();
// o usar las funciones seguras directamente
final image = await AllowedAppsHelper.openCameraSecurely();
```

2. **Para acciones que abren aplicaciones externas**, usar las funciones helper:
```dart
// En lugar de usar image_picker directamente
final image = await AllowedAppsHelper.openCameraWithPermissions(
  source: ImageSource.gallery
);
```

3. **Para llamadas o WhatsApp desde la app**:
```dart
// Llamada
await AllowedAppsHelper.makePhoneCallWithPermissions(cliente.telefono);

// WhatsApp
await AllowedAppsHelper.openWhatsAppSecurely(
  phoneNumber: cliente.telefono,
  message: 'Recordatorio de pago'
);
```

### Para Usuarios

El sistema funciona automáticamente:
- Usa la cámara normalmente - no se cerrará la sesión
- Navega con Google Maps - sesión permanece activa
- Recibe y realiza llamadas - sin interrupciones
- Usa WhatsApp (desde la app) - sesión protegida
- Accede a galería de fotos - sin logout automático

## Configuración

### Tiempos (Modificables en AutoLogoutService)
- `_maxAllowedExternalAppTime`: 10 minutos por defecto
- Timer pantallas normales: 30 segundos
- Timer app oculta: 15 segundos (normal) / 5 minutos (permitida)

### Aplicaciones Permitidas (Extensibles)
Agregar nuevas aplicaciones en `_allowedRoutes`, `_allowedScreenNames`, o `_allowedContexts`.

## Seguridad

### Medidas Implementadas
- Verificación constante del estado de autenticación
- Logout forzado si se excede el tiempo máximo
- Limpieza automática de contextos al resumir la app
- Verificación de permisos antes de usar aplicaciones externas

### Casos de Logout Inmediato
- App desconectada/cerrada (`detached`)
- Usuario no autenticado
- Tiempo excedido en aplicaciones no permitidas
- Falla en la verificación de contexto

## Logs y Debug

El sistema genera logs detallados con emojis para facilitar el debug:
- 🔐 Eventos de logout/autenticación
- 📷 🖼️ 🗺️ 📞 💬 Uso de aplicaciones específicas
- ⏰ Información de timers y tiempos
- ✅ ❌ Estados de éxito/error

## Limitaciones

- No puede detectar aplicaciones específicas en segundo plano (Android/iOS)
- Basado en tiempo y contexto, no en detección real de aplicaciones
- Requiere marcar manualmente contextos para aplicaciones no estándar
- Los permisos deben ser concedidos por el usuario
