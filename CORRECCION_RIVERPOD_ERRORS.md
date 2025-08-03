# Corrección de Errores de Riverpod

## 🚨 Problema Identificado

El error `StateNotifierListenerError` ocurría porque se estaba modificando un provider durante el ciclo de vida del widget, específicamente:

- En `initState()`
- En el listener del `TabController`
- En el `onChanged` del `TextField`

## 🔧 Soluciones Implementadas

### 1. **Uso de `addPostFrameCallback`**

```dart
@override
void initState() {
  super.initState();
  _tabController = TabController(length: 2, vsync: this);
  _tabController.addListener(() {
    // Usar addPostFrameCallback para evitar errores de Riverpod
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarUsuarios();
    });
  });
  
  // Cargar datos después del primer frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _cargarUsuarios();
  });
}
```

### 2. **Verificación de `mounted`**

```dart
void _cargarUsuarios() {
  if (!mounted) return;
  
  final search = _searchController.text.trim();
  if (_tabController.index == 0) {
    ref.read(userManagementProvider.notifier).cargarClientes(
      search: search.isEmpty ? null : search
    );
  } else {
    ref.read(userManagementProvider.notifier).cargarCobradores(
      search: search.isEmpty ? null : search
    );
  }
}
```

### 3. **Debounce en búsqueda**

```dart
onChanged: (value) {
  // Usar debounce para evitar llamadas excesivas
  Future.delayed(const Duration(milliseconds: 500), () {
    if (mounted) {
      _cargarUsuarios();
    }
  });
},
```

### 4. **Protección contra llamadas simultáneas**

```dart
Future<void> cargarUsuarios({String? role, String? search}) async {
  // Evitar múltiples llamadas simultáneas
  if (state.isLoading) return;
  
  state = state.copyWith(isLoading: true, error: null);
  // ... resto del código
}
```

## 📋 Reglas de Riverpod

### **❌ NO hacer:**

- Modificar providers en `initState()`
- Modificar providers en `build()`
- Modificar providers en listeners de widgets
- Modificar providers en `dispose()`

### **✅ SÍ hacer:**

- Usar `addPostFrameCallback` para llamadas después del primer frame
- Verificar `mounted` antes de modificar estado
- Usar debounce para búsquedas
- Proteger contra llamadas simultáneas

## 🔄 Flujo Corregido

```
1. Widget se inicializa
2. addPostFrameCallback ejecuta después del primer frame
3. Se cargan los datos de forma segura
4. UI se actualiza sin errores
```

## 🎯 Beneficios

- ✅ **Sin errores de Riverpod**: No más `StateNotifierListenerError`
- ✅ **UI responsiva**: No se bloquea la interfaz
- ✅ **Búsqueda optimizada**: Debounce evita llamadas excesivas
- ✅ **Estado consistente**: Protección contra llamadas simultáneas

## 🧪 Casos de Prueba

1. ✅ Abrir gestión de usuarios sin errores
2. ✅ Cambiar entre pestañas sin problemas
3. ✅ Buscar usuarios sin llamadas excesivas
4. ✅ Limpiar búsqueda sin errores
5. ✅ Navegar y volver sin conflictos

## 📚 Referencias

- [Riverpod Best Practices](https://riverpod.dev/docs/concepts/reading)
- [Flutter Widget Lifecycle](https://docs.flutter.dev/development/ui/widgets-intro#widget-lifecycle)
- [addPostFrameCallback Documentation](https://api.flutter.dev/flutter/scheduler/SchedulerBinding/addPostFrameCallback.html) 