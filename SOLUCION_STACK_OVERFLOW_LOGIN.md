# Solución: Stack Overflow en el Login

## Problema Identificado

La aplicación experimentaba un **Stack Overflow** cuando ocurrían errores durante el proceso de login. El error se manifestaba de la siguiente manera:

```
E/flutter: [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: Stack Overflow
E/flutter: #68131  AuthNotifier.clearError (package:cobrador_app/negocio/providers/auth_provider.dart:213:5)
E/flutter: #68132  _LoginScreenState.build.<anonymous closure> (package:cobrador_app/presentacion/pantallas/login_screen.dart:46:41)
```

Este error se repetía miles de veces hasta causar el colapso de la aplicación.

## Causa Raíz

El problema era un **ciclo infinito** en el listener del `LoginScreen` que causaba las siguientes acciones en bucle:

1. El listener detecta un error en `AuthState.error`
2. Llama inmediatamente a `ref.read(authProvider.notifier).clearError()`
3. `clearError()` modifica el estado y notifica a los listeners
4. El listener se ejecuta nuevamente, detectando el cambio de estado
5. **CICLO INFINITO**: El proceso se repite indefinidamente

### Código Problemático Original

```dart
// En LoginScreen - PROBLEMÁTICO
ref.listen<AuthState>(authProvider, (previous, next) {
  if (next.error != null && mounted) {
    ScaffoldMessenger.of(context).showSnackBar(/* ... */);
    // ❌ PROBLEMA: Llamada inmediata a clearError causa ciclo infinito
    ref.read(authProvider.notifier).clearError();
  }
});
```

```dart
// En AuthProvider - PROBLEMÁTICO  
AuthState copyWith({
  Usuario? usuario,
  bool? isLoading,
  String? error,           // ❌ PROBLEMA: No distingue entre null y limpiar
  bool? isInitialized,
}) {
  return AuthState(
    error: error ?? this.error,  // ❌ PROBLEMA: ?? siempre mantiene el error existente
  );
}
```

## Solución Implementada

### 1. Mejorar el Método `copyWith` en `AuthState`

Se agregó un parámetro `clearError` para distinguir entre null y limpiar explícitamente:

```dart
AuthState copyWith({
  Usuario? usuario,
  bool? isLoading,
  String? error,
  bool? isInitialized,
  bool clearError = false,  // ✅ NUEVO: Parámetro para limpiar explícitamente
}) {
  return AuthState(
    usuario: usuario ?? this.usuario,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : (error ?? this.error),  // ✅ ARREGLADO
    isInitialized: isInitialized ?? this.isInitialized,
  );
}
```

### 2. Actualizar el Método `clearError`

```dart
void clearError() {
  state = state.copyWith(clearError: true);  // ✅ ARREGLADO: Uso explícito
}
```

### 3. Prevenir Ciclos Infinitos en el Listener

Se implementó una lógica robusta para evitar mostrar el mismo error repetidamente:

```dart
class _LoginScreenState extends ConsumerState<LoginScreen> {
  String? _lastShownError; // ✅ NUEVO: Para rastrear errores mostrados

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.error != null && 
          next.error != _lastShownError &&  // ✅ NUEVO: Evitar repetición
          mounted) {
        
        _lastShownError = next.error;  // ✅ NUEVO: Marcar como mostrado
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(authProvider.notifier).clearError();
                _lastShownError = null;  // ✅ NUEVO: Reset al cerrar
              },
            ),
          ),
        );
        
        // ✅ NUEVO: Limpieza automática con delay
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && ref.read(authProvider).error == next.error) {
            ref.read(authProvider.notifier).clearError();
            _lastShownError = null;
          }
        });
      } else if (next.error == null) {
        _lastShownError = null;  // ✅ NUEVO: Reset cuando no hay error
      }
    });
    
    // ... resto del build
  }
}
```

## Beneficios de la Solución

### ✅ Eliminación del Stack Overflow
- **Antes**: La aplicación se colgaba con Stack Overflow
- **Después**: Funciona sin problemas, sin ciclos infinitos

### ✅ Mejor Experiencia de Usuario
- **Antes**: Aplicación se congelaba al intentar login incorrecto
- **Después**: Muestra errores claros y permite continuar usando la app

### ✅ Manejo Robusto de Errores
- **Evita duplicación**: No muestra el mismo error múltiples veces
- **Limpieza automática**: Los errores se limpian automáticamente después de 4 segundos
- **Control manual**: El usuario puede cerrar el error manualmente

### ✅ Código Más Mantenible
- **Separación clara**: Distingue entre null y limpiar explícitamente
- **Estado consistente**: El estado del error se maneja de forma predecible
- **Debug mejorado**: Easier para depurar problemas futuros

## Archivos Modificados

### 1. `lib/negocio/providers/auth_provider.dart`
- ✅ Mejorado método `copyWith` 
- ✅ Actualizado método `clearError`

### 2. `lib/presentacion/pantallas/login_screen.dart`
- ✅ Agregado control de errores duplicados
- ✅ Implementado limpieza automática con timeout
- ✅ Mejorado listener del AuthProvider

## Testing Realizado

### ✅ Casos de Prueba Exitosos

1. **Login con credenciales correctas**
   - ✅ Funciona sin problemas
   - ✅ Navega correctamente al dashboard

2. **Login con credenciales incorrectas**
   - ✅ Muestra mensaje de error claro
   - ✅ No causa Stack Overflow
   - ✅ Permite reintentar login

3. **Manejo de errores de conexión**
   - ✅ Muestra mensajes específicos
   - ✅ Se limpia automáticamente

4. **Interfaz de usuario**
   - ✅ SnackBar se muestra correctamente
   - ✅ Botón "Cerrar" funciona
   - ✅ No hay duplicación de mensajes

## Impacto en el Rendimiento

### ✅ Mejoras Significativas
- **Memoria**: Eliminó el crecimiento descontrolado del stack
- **CPU**: Eliminó el bucle infinito que consumía recursos
- **Responsividad**: La UI ya no se congela durante errores
- **Estabilidad**: La aplicación es más estable y confiable

## Conclusiones

La solución implementada resolvió completamente el problema de Stack Overflow mientras mejoró significativamente el manejo de errores y la experiencia de usuario. El código es ahora más robusto, mantenible y eficiente.

### Puntos Clave de la Solución:
1. **Prevención de ciclos infinitos** mediante control de estado
2. **Mejor UX** con mensajes de error claros y no repetitivos  
3. **Limpieza automática** para evitar errores persistentes
4. **Código más robusto** con manejo explícito de estados

La aplicación ahora maneja errores de login de forma elegante sin comprometer la estabilidad o el rendimiento.
