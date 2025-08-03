# CRUD Completo de Usuarios - Panel de Administración

## 📋 Descripción

Se ha implementado un sistema completo de gestión de usuarios (CRUD) desde el panel de administración, permitiendo crear, leer, actualizar y eliminar clientes y cobradores.

## 🚀 Funcionalidades Implementadas

### 1. **Gestión de Usuarios**
- ✅ Listar clientes y cobradores
- ✅ Crear nuevos usuarios
- ✅ Editar usuarios existentes
- ✅ Eliminar usuarios
- ✅ Búsqueda de usuarios por nombre
- ✅ Estadísticas en tiempo real

### 2. **Interfaz de Usuario**
- ✅ Pantalla principal con pestañas (Clientes/Cobradores)
- ✅ Formulario de creación/edición
- ✅ Barra de búsqueda
- ✅ Confirmación de eliminación
- ✅ Mensajes de éxito/error
- ✅ Indicadores de carga

## 📱 Pantallas Implementadas

### **1. UserManagementScreen**
- **Ubicación**: `lib/presentacion/pantallas/user_management_screen.dart`
- **Funcionalidad**: Pantalla principal de gestión de usuarios
- **Características**:
  - Pestañas para separar clientes y cobradores
  - Barra de búsqueda en tiempo real
  - Lista de usuarios con opciones de editar/eliminar
  - Botón flotante para crear nuevos usuarios

### **2. UserFormScreen**
- **Ubicación**: `lib/presentacion/pantallas/user_form_screen.dart`
- **Funcionalidad**: Formulario para crear y editar usuarios
- **Características**:
  - Validación de campos requeridos
  - Validación de formato de email
  - Validación de contraseña (mínimo 8 caracteres)
  - Campo de contraseña con visibilidad toggle
  - Campos opcionales (teléfono, dirección)

### **3. UserStatsWidget**
- **Ubicación**: `lib/presentacion/widgets/user_stats_widget.dart`
- **Funcionalidad**: Widget para mostrar estadísticas de usuarios
- **Características**:
  - Estadísticas en tiempo real
  - Carga automática de datos
  - Diseño responsive

## 🔧 Provider Implementado

### **UserManagementProvider**
- **Ubicación**: `lib/negocio/providers/user_management_provider.dart`
- **Funcionalidades**:
  - Estado de carga, error y éxito
  - Métodos CRUD completos
  - Gestión de mensajes
  - Integración con API

## 🌐 Endpoints Utilizados

### **Listar Usuarios**
```bash
# Obtener clientes
GET /api/users?role=client

# Obtener cobradores
GET /api/users?role=cobrador

# Buscar usuarios
GET /api/users?role=client&search=nombre
```

### **Crear Usuario**
```bash
POST /api/users
{
    "name": "Juan Pérez",
    "email": "juan@example.com",
    "password": "password123",
    "roles": ["client"],
    "phone": "123456789",
    "address": "Calle 123"
}
```

### **Actualizar Usuario**
```bash
PUT /api/users/{id}
{
    "name": "Juan Pérez Actualizado",
    "email": "juan.nuevo@example.com",
    "phone": "987654321",
    "address": "Nueva Dirección",
    "roles": ["client"]
}
```

### **Eliminar Usuario**
```bash
DELETE /api/users/{id}
```

## 🎯 Cómo Usar

### **1. Acceder a la Gestión de Usuarios**
1. Inicia sesión como administrador
2. Ve al panel de administración
3. Toca "Gestión de Usuarios"

### **2. Crear un Nuevo Usuario**
1. En la pantalla de gestión, toca el botón "+"
2. Completa el formulario con los datos requeridos
3. Toca "Crear" para guardar

### **3. Editar un Usuario**
1. En la lista de usuarios, toca el menú (⋮) del usuario
2. Selecciona "Editar"
3. Modifica los campos necesarios
4. Toca "Actualizar" para guardar

### **4. Eliminar un Usuario**
1. En la lista de usuarios, toca el menú (⋮) del usuario
2. Selecciona "Eliminar"
3. Confirma la eliminación en el diálogo

### **5. Buscar Usuarios**
1. Usa la barra de búsqueda en la parte superior
2. Escribe el nombre del usuario
3. Los resultados se filtran automáticamente

## 🔒 Validaciones Implementadas

### **Campos Requeridos**
- ✅ Nombre (mínimo 2 caracteres)
- ✅ Email (formato válido)
- ✅ Contraseña (mínimo 8 caracteres, solo para crear)

### **Campos Opcionales**
- ✅ Teléfono (mínimo 7 dígitos si se proporciona)
- ✅ Dirección (sin restricciones)

### **Validaciones de Negocio**
- ✅ Email único en el sistema
- ✅ Roles válidos (client, cobrador)
- ✅ Permisos según rol del usuario actual

## 🎨 Características de UI/UX

### **Diseño Responsive**
- ✅ Adaptable a diferentes tamaños de pantalla
- ✅ Grid layout para estadísticas
- ✅ Lista scrolleable para usuarios

### **Feedback Visual**
- ✅ Indicadores de carga
- ✅ Mensajes de éxito/error
- ✅ Confirmaciones para acciones destructivas
- ✅ Estados vacíos informativos

### **Accesibilidad**
- ✅ Iconos descriptivos
- ✅ Textos claros y concisos
- ✅ Contraste adecuado
- ✅ Tamaños de texto legibles

## 🔄 Flujo de Datos

```
Admin Dashboard → UserManagementScreen → UserFormScreen
                    ↓
              UserManagementProvider → ApiService → Backend
```

## 📊 Estadísticas en Tiempo Real

El widget `UserStatsWidget` muestra:
- **Total de Clientes**: Número actual de usuarios con rol "client"
- **Total de Cobradores**: Número actual de usuarios con rol "cobrador"

Las estadísticas se actualizan automáticamente después de cada operación CRUD.

## 🚨 Manejo de Errores

### **Errores de Red**
- ✅ Timeout de conexión
- ✅ Servidor no disponible
- ✅ Errores de autenticación

### **Errores de Validación**
- ✅ Campos requeridos vacíos
- ✅ Formato de email inválido
- ✅ Contraseña muy corta
- ✅ Email ya existe

### **Errores de Negocio**
- ✅ Permisos insuficientes
- ✅ Usuario no encontrado
- ✅ Error del servidor

## 🔧 Configuración

### **Variables de Entorno**
Asegúrate de que la URL de la API esté configurada correctamente en:
```dart
// lib/datos/servicios/api_service.dart
static const String baseUrl = 'http://192.168.5.44:8000/api';
```

### **Dependencias**
El sistema utiliza:
- `flutter_riverpod` para gestión de estado
- `dio` para llamadas HTTP
- `shared_preferences` para almacenamiento local

## 🧪 Pruebas

### **Casos de Prueba Recomendados**
1. ✅ Crear un nuevo cliente
2. ✅ Crear un nuevo cobrador
3. ✅ Editar información de usuario
4. ✅ Eliminar usuario
5. ✅ Buscar usuarios por nombre
6. ✅ Validar campos requeridos
7. ✅ Probar con datos inválidos
8. ✅ Verificar estadísticas en tiempo real

## 📈 Mejoras Futuras

### **Funcionalidades Adicionales**
- [ ] Subida de imágenes de perfil
- [ ] Filtros avanzados (por fecha, estado)
- [ ] Exportar lista de usuarios
- [ ] Paginación para listas grandes
- [ ] Búsqueda por email o teléfono

### **Optimizaciones**
- [ ] Cache de datos
- [ ] Actualización en tiempo real
- [ ] Notificaciones push
- [ ] Modo offline

## 🎯 Conclusión

El sistema CRUD de usuarios está completamente funcional y listo para producción. Incluye todas las operaciones básicas (Crear, Leer, Actualizar, Eliminar) con una interfaz intuitiva y validaciones robustas.

La implementación sigue las mejores prácticas de Flutter y proporciona una experiencia de usuario excepcional para la gestión de usuarios desde el panel de administración. 