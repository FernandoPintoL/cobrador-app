# Roles y Vistas del Sistema de Cobrador

## Estructura de Roles

El sistema implementa tres roles principales con diferentes niveles de acceso y funcionalidades:

### 1. Administrador (Admin)
**Responsabilidades:**
- Acceso total al sistema
- Soporte técnico
- Gestión de usuarios y roles
- Configuración del sistema
- Reportes y analytics
- Logs del sistema

**Vista:** `AdminDashboardScreen`
- Panel de administración con estadísticas del sistema
- Funciones administrativas completas
- Gestión de usuarios y roles
- Configuración del sistema
- Soporte técnico

### 2. Manager (Gerente)
**Responsabilidades:**
- Crear y gestionar cobradores
- Crear y gestionar clientes
- Controlar y supervisar cobradores
- Asignar rutas y territorios
- Reportes de rendimiento
- Configuración de zonas

**Vista:** `ManagerDashboardScreen`
- Panel de gestión con estadísticas del equipo
- Gestión de cobradores y clientes
- Asignación de rutas
- Control de cobros
- Reportes de cobradores

### 3. Cobrador
**Responsabilidades:**
- Gestionar clientes asignados
- Gestionar préstamos de clientes
- Registrar cobros
- Ver ruta del día
- Acceder a mapas de ubicación
- Generar reportes personales

**Vista:** `CobradorDashboardScreen`
- Panel de cobrador con estadísticas personales
- Gestión de clientes y préstamos
- Ruta del día
- Registro de cobros
- Acceso a mapas

## Pantallas Implementadas

### Pantallas de Dashboard por Rol

1. **AdminDashboardScreen** (`lib/presentacion/pantallas/admin_dashboard_screen.dart`)
   - Estadísticas del sistema
   - Funciones administrativas
   - Gestión de usuarios y roles
   - Soporte técnico

2. **ManagerDashboardScreen** (`lib/presentacion/pantallas/manager_dashboard_screen.dart`)
   - Estadísticas del equipo
   - Gestión de cobradores y clientes
   - Asignación de rutas
   - Control de cobros

3. **CobradorDashboardScreen** (`lib/presentacion/pantallas/cobrador_dashboard_screen.dart`)
   - Estadísticas personales
   - Gestión de clientes
   - Gestión de préstamos
   - Ruta del día

### Pantalla de Detalle de Cliente

**ClienteDetalleScreen** (`lib/presentacion/pantallas/cliente_detalle_screen.dart`)
- Información completa del cliente
- Mapa con ubicación GPS
- Préstamos activos
- Historial de cobros
- Acciones rápidas (llamar, SMS, navegar)

## Características del Mapa

La pantalla de detalle del cliente incluye:
- Visualización de ubicación GPS del cliente
- Estado de ubicación (con/sin coordenadas)
- Botón de navegación al cliente
- Integración con mapas (preparado para Google Maps)

## Navegación por Rol

El sistema automáticamente redirige al usuario a la pantalla correspondiente según su rol:

```dart
Widget _buildDashboardByRole(AuthState authState) {
  if (authState.isAdmin) {
    return const AdminDashboardScreen();
  } else if (authState.isManager) {
    return const ManagerDashboardScreen();
  } else if (authState.isCobrador) {
    return const CobradorDashboardScreen();
  } else {
    return const CobradorDashboardScreen(); // Por defecto
  }
}
```

## Funcionalidades por Rol

### Admin
- ✅ Gestión de usuarios
- ✅ Gestión de roles
- ✅ Configuración del sistema
- ✅ Reportes y analytics
- ✅ Soporte técnico
- ✅ Logs del sistema

### Manager
- ✅ Gestión de cobradores
- ✅ Gestión de clientes
- ✅ Asignación de rutas
- ✅ Control de cobros
- ✅ Reportes de cobradores
- ✅ Configuración de zonas

### Cobrador
- ✅ Gestión de clientes asignados
- ✅ Gestión de préstamos
- ✅ Ruta del día
- ✅ Registro de cobros
- ✅ Mapa de ubicación de clientes
- ✅ Reportes personales

## Próximos Pasos

1. **Implementar mapas reales** con Google Maps o similar
2. **Conectar con API** para datos reales
3. **Implementar funcionalidades específicas** de cada pantalla
4. **Agregar autenticación** por roles
5. **Implementar notificaciones** push
6. **Agregar sincronización offline**

## Estructura de Archivos

```
lib/
├── presentacion/pantallas/
│   ├── admin_dashboard_screen.dart
│   ├── manager_dashboard_screen.dart
│   ├── cobrador_dashboard_screen.dart
│   └── cliente_detalle_screen.dart
├── datos/modelos/
│   └── usuario.dart (actualizado con roles)
└── negocio/providers/
    └── auth_provider.dart (actualizado con getters de roles)
```

## Uso

Para usar las nuevas pantallas:

1. **Login** con usuario que tenga roles específicos
2. **Navegación automática** al dashboard correspondiente
3. **Acceso a funcionalidades** según el rol
4. **Detalle de cliente** con mapa y acciones rápidas

El sistema está preparado para escalar y agregar más funcionalidades específicas por rol. 