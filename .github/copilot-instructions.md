# Instrucciones para Agentes de IA - Cobrador App

## 📱 Arquitectura General

Esta es una aplicación Flutter para la gestión de cobranzas que sigue Clean Architecture:

- **datos/**: Capa de datos (modelos y servicios API)
- **negocio/**: Lógica de negocio y providers para gestión de estado
- **presentacion/**: UI separada por roles de usuario
- **config/**: Configuración global y constantes

## 🔄 Flujos de Trabajo Importantes

### Desarrollo Local

```bash
# Configurar el entorno (copia .env.example a .env primero)
.\config-env.ps1

# Ejecutar en modo debug
flutter run

# Construir APK de debug
.\build_debug.ps1

# Construir APK de producción
.\build_production.ps1
```

### Roles de Usuario

La aplicación tiene 4 roles con distintas capacidades:
- **cobrador**: Gestiona créditos y cobra pagos
- **manager**: Supervisa cobradores y aprueba créditos
- **admin**: Administra toda la aplicación
- **cliente**: Ve sus créditos y pagos

## 🔌 WebSockets y Comunicación en Tiempo Real

La aplicación usa WebSockets para notificaciones en tiempo real:

- Soporta dos transportes: Laravel Reverb/Pusher o Socket.IO
- Configurado mediante variables de entorno en `.env`
- Conexión manejada por `WebSocketManager` para abstraer el transporte
- Autenticación mediante evento `authenticate` con ID y rol del usuario
- Los eventos son específicos según el rol (ver `INTEGRACION_WEBSOCKET_FLUTTER.md`)

### Ejemplo de Conexión a WebSocket:

```dart
// Usar el transporte configurado en .env
final wsManager = ref.read(webSocketManagerProvider);
await wsManager.connect(userData); 
wsManager.onEvent('credit_approved', (data) => handleCreditApproved(data));
```

## 🗺️ Integración con Google Maps

- Requiere API Key configurada en `.env`
- Permisos de ubicación manejados por `permission_handler`
- Ubicación actual por `geolocator`
- El mapa muestra clientes, estado de pagos y rutas optimizadas

## 📊 Gestión de Estado

- **Riverpod/Provider**: Gestión principal del estado
- **Repository Pattern**: Para abstracción del acceso a datos
- Los providers se encuentran en `negocio/providers/`

## 🔒 Seguridad y Autenticación

- Token JWT almacenado en `shared_preferences`
- Auto-logout por inactividad con `AutoLogoutService`
- Validación de permisos por rol con `PermissionService`
- Las credenciales nunca deben guardarse en texto plano

## 🔄 Convenciones de Código

- Nombres de clases en PascalCase
- Nombres de variables/métodos en camelCase
- Archivos en snake_case.dart
- Rutas de navegación definidas en constantes
- Cada pantalla principal en un archivo separado
- Widgets reutilizables en `presentacion/widgets/`

## 🧪 Testing

- Tests unitarios en `/test`
- Scripts de prueba en raíz: `test_*.dart`

## 📱 Build y Despliegue

- Script `build_debug.ps1` para APK debug
- Script `build_production.ps1` para APK release
- La keystore para firma está en `cobrador.keystore`