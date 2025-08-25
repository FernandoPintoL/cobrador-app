# Pantalla Genérica de Clientes - Documentación de Uso

## Descripción
La `ClientesScreen` es una pantalla genérica y reutilizable que se adapta automáticamente según el rol del usuario que la utiliza. Reemplaza las pantallas específicas de clientes que existían previamente para managers y cobradores.

## Ubicación
```
lib/presentacion/pantallas/clientes_screen.dart
```

## Funcionalidades

### 🔄 Adaptación por Rol
La pantalla se adapta automáticamente según el rol:

- **Manager**: 
  - Muestra todos sus clientes del área
  - Puede ver clientes de un cobrador específico
  - Tiene opciones adicionales como "Reasignar Cobrador"

- **Cobrador**: 
  - Muestra solo los clientes asignados a él
  - Funcionalidades básicas de contacto y gestión

### 📊 Características Principales

1. **Header Adaptable**: Muestra información del usuario actual o del cobrador específico
2. **Estadísticas Dinámicas**: Total de clientes, con teléfono, con ubicación
3. **Búsqueda en Tiempo Real**: Filtrar por nombre, email o teléfono
4. **Acciones Contextuales**: Menús específicos según el rol
5. **Navegación a Detalles**: Ver información completa del cliente
6. **Contacto Integrado**: WhatsApp y llamadas directas
7. **Manejo de Estados**: Loading, vacío, error

## Uso

### 1. Para Manager - Ver Todos Sus Clientes
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ClientesScreen(
      userRole: 'manager',
    ),
  ),
);
```

### 2. Para Manager - Ver Clientes de un Cobrador Específico
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ClientesScreen(
      userRole: 'manager',
      cobrador: cobradorSeleccionado,
    ),
  ),
);
```

### 3. Para Cobrador - Ver Sus Clientes Asignados
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ClientesScreen(
      userRole: 'cobrador',
    ),
  ),
);
```

### 4. Detección Automática de Rol (Recomendado)
```dart
// La pantalla detecta automáticamente el rol del usuario autenticado
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ClientesScreen(),
  ),
);
```

## Parámetros del Constructor

| Parámetro | Tipo | Requerido | Descripción |
|-----------|------|-----------|-------------|
| `userRole` | `String?` | No | 'manager' o 'cobrador'. Si no se especifica, se detecta automáticamente |
| `cobrador` | `Usuario?` | No | Usuario cobrador específico (solo para managers) |

## Providers Utilizados

- **authProvider**: Obtiene información del usuario autenticado
- **managerProvider**: Gestiona clientes del manager
- **clientProvider**: Gestiona clientes generales

## Acciones Disponibles

### Para Todos los Roles
- ✅ Ver detalle del cliente
- ✅ Contactar (WhatsApp/Llamada)
- ✅ Ver créditos (en desarrollo)
- ✅ Ver ubicación (en desarrollo)

### Solo para Managers
- ✅ Reasignar cobrador (en desarrollo)

## Estados de la Pantalla

### Loading
- Spinner mientras cargan los datos

### Vacío
- Mensaje contextual según el rol
- Iconografía apropiada

### Con Datos
- Lista de clientes con información completa
- Acciones disponibles según permisos

### Error
- Manejo de errores con retry

## Integración Existente

### Navegación desde Manager Dashboard
```dart
_navigateToTeamClientManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ClientesScreen(userRole: 'manager'),
    ),
  );
}
```

### Navegación desde Cobrador Dashboard
```dart
_navigateToClientManagement(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const ClientesScreen(userRole: 'cobrador'),
    ),
  );
}
```

### Navegación desde Manager de Cobradores
```dart
_navegarAClientesCobrador(Usuario cobrador) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ClientesScreen(
        userRole: 'manager',
        cobrador: cobrador,
      ),
    ),
  );
}
```

## Ventajas de la Implementación

### ✅ Reutilización de Código
- Una sola pantalla para múltiples roles
- Reducción del código duplicado
- Mantenimiento centralizado

### ✅ Consistencia de UI
- Mismo diseño y experiencia para todos los roles
- Comportamiento uniforme
- Iconografía y colores consistentes

### ✅ Escalabilidad
- Fácil agregar nuevos roles
- Extensible para nuevas funcionalidades
- Configuración flexible

### ✅ Mantenimiento
- Un solo archivo para mantener
- Cambios se reflejan en todos los usos
- Testing centralizado

## Archivos Reemplazados

Esta implementación reemplaza:
- ❌ `manager_clientes_screen.dart` (ya no se usa)
- ❌ `cobrador_clientes_screen.dart` (ya no se usa)
- ❌ `cliente/clientes_screen.dart` (reemplazada)

## Próximas Mejoras

### 🚀 En Desarrollo
- Funcionalidad completa de reasignación de cobradores
- Integración con sistema de créditos
- Navegación a mapas con ubicación del cliente
- Filtros avanzados (por estado, fecha, etc.)
- Ordenamiento personalizable

### 🎯 Futuras
- Exportación de datos
- Modo offline
- Sincronización en tiempo real
- Notificaciones push

## Ejemplo Completo

```dart
// En cualquier pantalla donde necesites mostrar clientes
class MiPantalla extends StatelessWidget {
  final Usuario? cobradorEspecifico;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Mi App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ClientesScreen(
                  userRole: 'manager', // Opcional
                  cobrador: cobradorEspecifico, // Opcional
                ),
              ),
            );
          },
          child: Text('Ver Clientes'),
        ),
      ),
    );
  }
}
```

## Troubleshooting

### Problema: No aparecen clientes
**Solución**: Verificar que el provider correspondiente esté cargando datos correctamente.

### Problema: Rol no detectado
**Solución**: Asegurar que el `authProvider` tenga un usuario autenticado con roles válidos.

### Problema: Navegación no funciona
**Solución**: Verificar que los imports estén correctos y que la pantalla esté en la ruta especificada.

---

**Nota**: Esta pantalla es parte de la refactorización para mejorar la reutilización de código y mantener consistencia en la UI de la aplicación.
