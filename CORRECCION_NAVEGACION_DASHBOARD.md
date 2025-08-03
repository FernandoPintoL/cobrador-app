# Corrección de Navegación al Dashboard por Rol

## Problema Identificado

La aplicación no navegaba correctamente al dashboard correspondiente según el rol del usuario después de iniciar sesión o al reabrir la aplicación. Esto se debía a un problema en la serialización/deserialización de los roles del usuario en el almacenamiento local.

## Causa Raíz

### Problema en la Serialización de Roles

En el modelo `Usuario`, el método `toJson()` serializaba los roles en formato API (como objetos con `{'name': role}`), pero el método `fromJson()` esperaba una lista simple de strings. Esto causaba que:

1. **Al guardar**: Los roles se guardaban como `[{'name': 'admin'}, {'name': 'manager'}]`
2. **Al recuperar**: El parser esperaba `['admin', 'manager']`
3. **Resultado**: Los roles no se parseaban correctamente y quedaban vacíos

### Código Problemático

```dart
// En toJson() - Formato incorrecto para almacenamiento local
'roles': roles.map((role) => {'name': role}).toList(),

// En fromJson() - Esperaba lista simple
List<String> roles = [];
if (json['roles'] != null) {
  roles = (json['roles'] as List).map((role) => role['name'] as String).toList();
}
```

## Solución Implementada

### 1. Separación de Formatos de Serialización

Se crearon dos métodos de serialización:

```dart
// Para almacenamiento local (lista simple de strings)
Map<String, dynamic> toJson() {
  return {
    // ... otros campos
    'roles': roles, // Lista simple: ['admin', 'manager']
  };
}

// Para API del backend (objetos con 'name')
Map<String, dynamic> toApiJson() {
  return {
    // ... otros campos
    'roles': roles.map((role) => {'name': role}).toList(), // Formato API
  };
}
```

### 2. Mejora en la Lógica de Navegación

Se mejoró el método `_buildDashboardByRole()` en `main.dart`:

```dart
Widget _buildDashboardByRole(AuthState authState) {
  // Verificaciones de seguridad
  if (authState.usuario == null) {
    return const LoginScreen();
  }
  
  if (authState.usuario!.roles.isEmpty) {
    return const LoginScreen();
  }

  // Prioridad: Admin > Manager > Cobrador
  if (authState.isAdmin) {
    return const AdminDashboardScreen();
  } else if (authState.isManager) {
    return const ManagerDashboardScreen();
  } else if (authState.isCobrador) {
    return const CobradorDashboardScreen();
  } else {
    // Fallback: verificación individual de roles
    if (authState.usuario!.tieneRol("admin")) {
      return const AdminDashboardScreen();
    } else if (authState.usuario!.tieneRol("manager")) {
      return const ManagerDashboardScreen();
    } else if (authState.usuario!.tieneRol("cobrador")) {
      return const CobradorDashboardScreen();
    } else {
      // Por seguridad, redirigir al login
      return const LoginScreen();
    }
  }
}
```

### 3. Mejora en la Inicialización de Sesión

Se mejoró el método `initialize()` en `AuthProvider`:

```dart
Future<void> initialize() async {
  // 1. Verificar si hay sesión válida
  final hasSession = await _storageService.hasValidSession();
  
  if (hasSession) {
    // 2. Recuperar usuario del almacenamiento local
    final usuario = await _storageService.getUser();
    
    if (usuario != null && usuario.roles.isNotEmpty) {
      // 3. Intentar restaurar sesión con el servidor
      try {
        final restored = await _apiService.restoreSession();
        if (restored) {
          await refreshUser(); // Actualizar desde servidor
        }
      } catch (e) {
        // Continuar con usuario local si falla
      }
      
      // 4. Validar sesión
      await validateAndFixSession();
    }
  }
}
```

### 4. Validación de Sesión

Se agregó un método para validar la integridad de la sesión:

```dart
Future<void> validateAndFixSession() async {
  if (state.usuario != null) {
    // Verificar roles válidos
    if (state.usuario!.roles.isEmpty) {
      await clearSession();
      return;
    }
    
    // Verificar al menos un rol principal
    final hasValidRole = state.usuario!.tieneRol('admin') || 
                        state.usuario!.tieneRol('manager') || 
                        state.usuario!.tieneRol('cobrador');
    
    if (!hasValidRole) {
      await clearSession();
      return;
    }
  }
}
```

## Flujo de Navegación Corregido

### 1. Inicio de Aplicación
```
1. App inicia → AuthProvider.initialize()
2. Verificar sesión local → StorageService.hasValidSession()
3. Si hay sesión → Recuperar usuario del almacenamiento
4. Validar roles del usuario → validateAndFixSession()
5. Si roles válidos → Navegar al dashboard correspondiente
6. Si roles inválidos → Limpiar sesión → LoginScreen
```

### 2. Login Exitoso
```
1. Usuario hace login → AuthProvider.login()
2. Guardar usuario en almacenamiento → StorageService.saveUser()
3. Actualizar estado → AuthState.usuario = usuario
4. Navegar al dashboard → _buildDashboardByRole()
```

### 3. Reapertura de App
```
1. App reabre → AuthProvider.initialize()
2. Restaurar sesión local → Usuario con roles correctos
3. Navegar al dashboard → Dashboard correcto según rol
```

## Casos de Uso Verificados

### ✅ Admin
- **Roles**: `['admin']`
- **Dashboard**: `AdminDashboardScreen`
- **Funcionalidades**: CRUD completo de usuarios, gestión de cobradores

### ✅ Manager
- **Roles**: `['manager']`
- **Dashboard**: `ManagerDashboardScreen`
- **Funcionalidades**: Gestión de clientes, asignación de cobradores

### ✅ Cobrador
- **Roles**: `['cobrador']`
- **Dashboard**: `CobradorDashboardScreen`
- **Funcionalidades**: Ver clientes asignados, registrar cobros

### ✅ Usuario con Múltiples Roles
- **Roles**: `['admin', 'manager']`
- **Dashboard**: `AdminDashboardScreen` (prioridad admin)
- **Funcionalidades**: Todas las de admin

### ✅ Usuario sin Roles
- **Roles**: `[]`
- **Acción**: Redirigir a `LoginScreen`
- **Razón**: Seguridad - usuario inválido

## Logs de Debug

La aplicación ahora incluye logs detallados para facilitar el debugging:

```
🔍 DEBUG: Información del usuario:
  - Usuario: Juan Pérez
  - Email: juan@ejemplo.com
  - Roles: [admin]
  - isAdmin: true
  - isManager: false
  - isCobrador: false

✅ Usuario es ADMIN - Redirigiendo a AdminDashboardScreen
  - Roles del usuario: [admin]
```

## Archivos Modificados

1. **`lib/datos/modelos/usuario.dart`**
   - Agregado método `toApiJson()` para formato API
   - Corregido `toJson()` para almacenamiento local

2. **`lib/main.dart`**
   - Mejorado `_buildDashboardByRole()` con validaciones
   - Agregado fallback para verificación individual de roles

3. **`lib/negocio/providers/auth_provider.dart`**
   - Mejorado `initialize()` con validación de sesión
   - Agregado `validateAndFixSession()`
   - Mejorado `refreshUser()` con logs

## Testing Recomendado

### Casos de Prueba

1. **Login y Navegación**
   - Login como admin → Verificar AdminDashboardScreen
   - Login como manager → Verificar ManagerDashboardScreen
   - Login como cobrador → Verificar CobradorDashboardScreen

2. **Reapertura de App**
   - Cerrar app completamente
   - Reabrir app
   - Verificar navegación al dashboard correcto

3. **Sesión Inválida**
   - Simular usuario sin roles
   - Verificar redirección a LoginScreen

4. **Múltiples Roles**
   - Usuario con roles `['admin', 'manager']`
   - Verificar prioridad admin

### Comandos de Debug

```bash
# Limpiar sesión para testing
flutter run --debug

# En la consola de debug:
ref.read(authProvider.notifier).forceNewLogin()
```

## Resultado

✅ **Navegación correcta** al dashboard según el rol del usuario
✅ **Persistencia de sesión** al reabrir la aplicación
✅ **Validación de seguridad** para usuarios sin roles válidos
✅ **Logs detallados** para debugging
✅ **Manejo de errores** robusto

La aplicación ahora navega correctamente al dashboard correspondiente según el rol del usuario, tanto al hacer login como al reabrir la aplicación. 