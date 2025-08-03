# CRUD Completo de Clientes para Cobradores y Managers

## Resumen

Se ha implementado un sistema completo de gestión de clientes (CRUD) que permite a los usuarios con roles de **cobrador** y **manager** realizar operaciones completas sobre los clientes del sistema.

## Arquitectura Implementada

### 1. Provider de Clientes (`lib/negocio/providers/client_provider.dart`)

**Estado del Provider:**
```dart
class ClientState {
  final List<Usuario> clientes;
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? currentFilter;
}
```

**Funcionalidades Principales:**
- `cargarClientes()` - Carga clientes con filtros opcionales
- `crearCliente()` - Crea nuevos clientes
- `actualizarCliente()` - Actualiza clientes existentes
- `eliminarCliente()` - Elimina clientes
- `asignarClienteACobrador()` - Asigna clientes a cobradores (solo managers)
- `obtenerEstadisticasClientes()` - Obtiene estadísticas de clientes

### 2. Pantalla Principal de Clientes (`lib/presentacion/cliente/clientes_screen.dart`)

**Características:**
- **Pestañas múltiples**: Todos, Con Créditos, Pendientes
- **Búsqueda en tiempo real** con debounce
- **Filtros por rol**: Cobradores solo ven sus clientes asignados
- **CRUD completo** para managers y admins
- **Vista de solo lectura** para cobradores
- **Navegación a detalles** del cliente

**Diferencias por Rol:**
- **Cobradores**: Solo pueden ver sus clientes asignados, sin botón de crear
- **Managers/Admins**: Pueden ver todos los clientes y realizar todas las operaciones CRUD

### 3. Pantalla de Detalle del Cliente (`lib/presentacion/cliente/cliente_detalle_screen.dart`)

**Información Mostrada:**
- Información básica del cliente (nombre, email, teléfono, dirección)
- Ubicación GPS (si está disponible)
- Información del sistema (ID, fechas de creación/actualización)
- Acciones rápidas (ver créditos, historial, registrar cobro, ver en mapa)

**Acciones Disponibles:**
- **Para todos**: Ver créditos, historial de pagos, registrar cobro, ver en mapa
- **Para managers/admins**: Editar, eliminar, asignar a cobrador

### 4. Formulario de Cliente (`lib/presentacion/cliente/cliente_form_screen.dart`)

**Campos del Formulario:**
- Nombre completo (requerido)
- Email (requerido, con validación)
- Teléfono (opcional)
- Dirección (opcional)
- Contraseña (opcional, solo para nuevos clientes)

**Validaciones:**
- Nombre no puede estar vacío
- Email debe tener formato válido
- Contraseña opcional (se genera automáticamente si no se especifica)

## Flujo de Navegación

### Para Cobradores:
1. **Dashboard del Cobrador** → "Gestionar Clientes"
2. **Pantalla de Clientes** → Lista de clientes asignados
3. **Detalle del Cliente** → Información completa y acciones
4. **Acciones disponibles**: Ver créditos, registrar cobros, ver historial

### Para Managers:
1. **Dashboard del Manager** → "Gestión de Clientes"
2. **Pantalla de Clientes** → Lista completa de clientes
3. **Crear Cliente** → Formulario de nuevo cliente
4. **Editar Cliente** → Formulario de edición
5. **Detalle del Cliente** → Información completa y acciones administrativas

## Integración con el Sistema

### 1. Navegación desde Dashboards

**Cobrador Dashboard:**
```dart
void _navigateToClientManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ClientesScreen()),
  );
}
```

**Manager Dashboard:**
```dart
void _navigateToClientManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ClientesScreen()),
  );
}
```

### 2. Control de Acceso por Rol

```dart
// En la pantalla de clientes
floatingActionButton: authState.isManager || authState.isAdmin
    ? FloatingActionButton(
        onPressed: () => _mostrarFormularioCliente(),
        // ...
      )
    : null,

// En las tarjetas de cliente
if (authState.isManager || authState.isAdmin)
  PopupMenuButton<String>(
    // Opciones de editar, eliminar, asignar
  )
else
  const Icon(Icons.arrow_forward_ios, size: 16),
```

### 3. Filtros Automáticos

```dart
void _cargarClientes() {
  final authState = ref.read(authProvider);
  String? assignedTo;
  
  if (authState.isCobrador) {
    // Cobradores solo ven sus clientes asignados
    assignedTo = authState.usuario?.id.toString();
  }
  
  ref.read(clientProvider.notifier).cargarClientes(
    search: search.isEmpty ? null : search,
    filter: filter,
    assignedTo: assignedTo,
  );
}
```

## Características Técnicas

### 1. Gestión de Estado
- **Riverpod** para gestión de estado
- **StateNotifier** para operaciones asíncronas
- **Listeners** para manejo de errores y mensajes de éxito

### 2. UI/UX
- **Material Design 3** con tema personalizado
- **Modo oscuro** compatible
- **Responsive design** para diferentes tamaños de pantalla
- **Loading states** y manejo de errores
- **SnackBars** para feedback al usuario

### 3. Validaciones
- **Validación de formularios** en tiempo real
- **Validación de email** con regex
- **Campos requeridos** claramente marcados
- **Mensajes de error** descriptivos

### 4. API Integration
- **Endpoints RESTful** para todas las operaciones
- **Manejo de errores** de red
- **Retry logic** para operaciones fallidas
- **Cache** de datos para mejor rendimiento

## Funcionalidades Futuras

### 1. Asignación de Cobradores
- Pantalla para seleccionar cobrador al crear/editar cliente
- Lista de cobradores disponibles
- Transferencia de clientes entre cobradores

### 2. Integración con Créditos
- Vista de créditos activos del cliente
- Historial de préstamos
- Estado de pagos

### 3. Funcionalidades de Mapa
- Visualización de ubicación del cliente
- Ruta optimizada para visitas
- Geocodificación de direcciones

### 4. Reportes y Analytics
- Estadísticas de clientes por cobrador
- Métricas de cobro
- Reportes de rendimiento

## Archivos Modificados/Creados

### Nuevos Archivos:
- `lib/negocio/providers/client_provider.dart`
- `lib/presentacion/cliente/cliente_form_screen.dart`
- `lib/presentacion/cliente/cliente_detalle_screen.dart`

### Archivos Modificados:
- `lib/presentacion/cliente/clientes_screen.dart` (completamente reescrito)
- `lib/presentacion/cobrador/cobrador_dashboard_screen.dart`
- `lib/presentacion/manager/manager_dashboard_screen.dart`

## Consideraciones de Seguridad

1. **Control de Acceso**: Solo usuarios autorizados pueden acceder a las funcionalidades
2. **Validación de Datos**: Todos los inputs son validados antes de enviar al servidor
3. **Sanitización**: Los datos se limpian antes de procesar
4. **Auditoría**: Todas las operaciones CRUD quedan registradas

## Testing

### Casos de Prueba Recomendados:
1. **Crear cliente** como manager
2. **Editar cliente** existente
3. **Eliminar cliente** con confirmación
4. **Búsqueda** de clientes
5. **Filtros** por estado
6. **Navegación** entre pantallas
7. **Validaciones** de formularios
8. **Manejo de errores** de red

## Conclusión

La implementación proporciona un sistema completo y robusto para la gestión de clientes que se adapta a las necesidades específicas de cada rol en el sistema. Los cobradores tienen acceso limitado pero funcional, mientras que los managers tienen control total sobre la gestión de clientes.

El código está estructurado de manera modular y escalable, permitiendo futuras extensiones y mejoras sin afectar la funcionalidad existente. 