# Cobrador App

Aplicación móvil para gestión de cobranzas desarrollada en Flutter con backend Laravel.

## Características

- **Gestión de Clientes**: Registro de clientes con ubicación GPS
- **Gestión de Créditos**: Creación y seguimiento de créditos con diferentes frecuencias de pago
- **Sistema de Pagos**: Registro de pagos en efectivo, QR y transferencias
- **Mapa de Clientes**: Visualización de clientes en mapa con estado de pagos
- **Dashboard**: Estadísticas y métricas de rendimiento
- **Arqueo de Caja**: Control de caja por cobrador
- **Notificaciones**: Sistema de alertas y notificaciones

## Arquitectura

El proyecto sigue los principios SOLID y utiliza patrones de diseño:

- **Clean Architecture**: Separación de capas (datos, negocio, presentación)
- **Repository Pattern**: Abstracción de acceso a datos
- **Provider Pattern**: Gestión de estado con Riverpod
- **Factory Pattern**: Creación de objetos complejos
- **Strategy Pattern**: Diferentes métodos de pago

## Estructura del Proyecto

```
lib/
├── datos/
│   ├── modelos/
│   │   ├── usuario.dart
│   │   ├── credito.dart
│   │   └── pago.dart
│   ├── repositorios/
│   │   └── usuario_repository.dart
│   └── servicios/
│       └── api_service.dart
├── negocio/
│   └── providers/
│       └── auth_provider.dart
└── presentacion/
    └── pantallas/
        ├── login_screen.dart
        └── home_screen.dart
```

## Instalación

### Prerrequisitos

- Flutter SDK 3.8.1 o superior
- Dart SDK
- Android Studio / VS Code
- Backend Laravel configurado

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone <repository-url>
   cd app-cobrador
   ```

2. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

3. **Configurar el backend**
   - Asegúrate de que tu backend Laravel esté ejecutándose
   - Actualiza la URL base en `lib/datos/servicios/api_service.dart`

4. **Ejecutar la aplicación**
   ```bash
   flutter run
   ```

## Configuración del Backend

El proyecto está diseñado para trabajar con las siguientes rutas de API:

### Autenticación
- `POST /api/login` - Iniciar sesión
- `POST /api/logout` - Cerrar sesión
- `GET /api/me` - Obtener usuario actual

### Usuarios
- `GET /api/users` - Listar usuarios
- `POST /api/users` - Crear usuario
- `GET /api/users/{id}` - Obtener usuario
- `PUT /api/users/{id}` - Actualizar usuario
- `DELETE /api/users/{id}` - Eliminar usuario

### Créditos
- `GET /api/credits` - Listar créditos
- `POST /api/credits` - Crear crédito
- `GET /api/credits/{id}` - Obtener crédito
- `PUT /api/credits/{id}` - Actualizar crédito
- `DELETE /api/credits/{id}` - Eliminar crédito

### Pagos
- `GET /api/payments` - Listar pagos
- `POST /api/payments` - Crear pago
- `GET /api/payments/{id}` - Obtener pago
- `PUT /api/payments/{id}` - Actualizar pago
- `DELETE /api/payments/{id}` - Eliminar pago

### Mapa
- `GET /api/map/clients` - Clientes con ubicaciones
- `GET /api/map/stats` - Estadísticas del mapa

## Modelos de Datos

### Usuario
```dart
class Usuario {
  final BigInt id;
  final String nombre;
  final String email;
  final String telefono;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final List<String> roles;
  // ...
}
```

### Crédito
```dart
class Credito {
  final BigInt id;
  final BigInt clienteId;
  final double monto;
  final double saldo;
  final FrecuenciaPago frecuencia;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final EstadoCredito estado;
  // ...
}
```

### Pago
```dart
class Pago {
  final BigInt id;
  final BigInt clienteId;
  final BigInt cobradorId;
  final BigInt creditoId;
  final double monto;
  final MetodoPago metodoPago;
  final double? latitud;
  final double? longitud;
  final EstadoPago estado;
  // ...
}
```

## Funcionalidades Principales

### 1. Autenticación
- Login con email y contraseña
- Gestión de roles (cobrador, jefe, cliente)
- Persistencia de sesión

### 2. Dashboard
- Estadísticas en tiempo real
- Acciones rápidas
- Métricas de rendimiento

### 3. Gestión de Clientes
- Registro con GPS
- Información de contacto
- Historial de créditos

### 4. Gestión de Créditos
- Creación de créditos
- Diferentes frecuencias de pago
- Seguimiento de saldos

### 5. Sistema de Pagos
- Múltiples métodos de pago
- Registro de ubicación
- Validación de transacciones

### 6. Mapa Interactivo
- Visualización de clientes
- Estado de pagos
- Optimización de rutas

## Próximos Pasos

1. **Instalar dependencias faltantes**
   ```bash
   flutter pub add dio shared_preferences flutter_riverpod
   flutter pub add google_maps_flutter geolocator
   flutter pub add form_builder form_builder_validators
   ```

2. **Configurar permisos de ubicación**
   - Android: `android/app/src/main/AndroidManifest.xml`
   - iOS: `ios/Runner/Info.plist`

3. **Configurar Google Maps**
   - Obtener API key de Google Cloud Console
   - Configurar en `android/app/src/main/AndroidManifest.xml`

4. **Implementar funcionalidades faltantes**
   - Integración completa con API
   - Gestión de estado con Riverpod
   - Funcionalidades de mapa
   - Sistema de notificaciones

## Contribución

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

Este proyecto está bajo la Licencia MIT - ver el archivo [LICENSE](LICENSE) para detalles.

## Contacto

- Desarrollador: [Fernando Pinto Lino]
- Email: [pintolinofernando@gmail..com]
- Proyecto: [https://github.com/FernandoPintoL/cobrador-app]
