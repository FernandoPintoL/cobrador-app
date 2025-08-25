# Corrección del Manejo de Errores en el Login

## Problema Identificado

Al intentar hacer login con credenciales incorrectas, la aplicación mostraba un error genérico y confuso en lugar del mensaje específico del servidor:

```
I/flutter (22688): <asynchronous suspension>
I/flutter (22688): #2      _LoginScreenState._handleLogin (package:cobrador_app/presentacion/pantallas/login_screen.dart:223:9)
I/flutter (22688): Error en el provider login: Exception: Error de conexión: DioException [bad response]: This exception was thrown because the response has a status code of 422 and RequestOptions.validateStatus was configured to throw for this status code.
```

## Causa Raíz

### Problema en el Manejo de Errores HTTP

1. **ApiService**: Capturaba todas las excepciones y las convertía en un mensaje genérico "Error de conexión"
2. **AuthProvider**: No extraía correctamente el mensaje específico del servidor
3. **LoginScreen**: No mostraba los errores de manera clara y consistente

### Código Problemático

```dart
// En ApiService - Manejo genérico de errores
} catch (e) {
  print('💥 Error de conexión: $e');
  throw Exception('Error de conexión: $e');
}

// En AuthProvider - No extraía mensaje específico
} catch (e) {
  state = state.copyWith(isLoading: false, error: e.toString());
}
```

## Solución Implementada

### 1. Mejora en el Manejo de Errores HTTP (ApiService)

Se implementó un manejo específico de errores HTTP con `DioException`:

```dart
} catch (e) {
  // Extraer mensaje de error específico del servidor
  if (e is DioException) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;
      
      // Intentar extraer mensaje de error del servidor
      String errorMessage = 'Error de conexión';
      
      if (responseData is Map<String, dynamic>) {
        if (responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else if (responseData['error'] != null) {
          errorMessage = responseData['error'].toString();
        } else if (responseData['errors'] != null) {
          // Manejar errores de validación
          final errors = responseData['errors'];
          if (errors is Map<String, dynamic>) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMessage = firstError.first.toString();
            } else if (firstError is String) {
              errorMessage = firstError;
            }
          }
        }
      }
      
      // Mensajes específicos según el código de estado
      switch (statusCode) {
        case 401:
          errorMessage = 'Credenciales incorrectas';
          break;
        case 422:
          errorMessage = errorMessage.isNotEmpty ? errorMessage : 'Datos de entrada inválidos';
          break;
        case 404:
          errorMessage = 'Usuario no encontrado';
          break;
        case 500:
          errorMessage = 'Error interno del servidor';
          break;
        default:
          if (errorMessage == 'Error de conexión') {
            errorMessage = 'Error del servidor: $statusCode';
          }
      }
      
      throw Exception(errorMessage);
    } else if (e.type == DioExceptionType.connectionTimeout) {
      throw Exception('Tiempo de conexión agotado');
    } else if (e.type == DioExceptionType.receiveTimeout) {
      throw Exception('Tiempo de respuesta agotado');
    } else if (e.type == DioExceptionType.connectionError) {
      throw Exception('Error de conexión al servidor');
    }
  }
  
  throw Exception('Error de conexión: $e');
}
```

### 2. Mejora en el AuthProvider

Se mejoró la extracción del mensaje de error:

```dart
} catch (e) {
  print('Error en el provider login: $e');
  // Extraer solo el mensaje de la excepción, no toda la información de stack
  String errorMessage = 'Error desconocido';
  
  if (e is Exception) {
    errorMessage = e.toString().replaceAll('Exception: ', '');
  } else if (e is String) {
    errorMessage = e;
  } else {
    errorMessage = e.toString();
  }
  
  state = state.copyWith(isLoading: false, error: errorMessage);
}
```

### 3. Mejora en el LoginScreen

Se implementó un listener para mostrar errores automáticamente:

```dart
@override
Widget build(BuildContext context) {
  // Escuchar cambios en el estado de autenticación para mostrar errores
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.error != null && mounted) {
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
            },
          ),
        ),
      );
      // Limpiar el error después de mostrarlo
      ref.read(authProvider.notifier).clearError();
    }
  });

  // ... resto del build
}
```

## Tipos de Errores Manejados

### ✅ Errores HTTP Específicos

| Código | Mensaje | Descripción |
|--------|---------|-------------|
| 401 | "Credenciales incorrectas" | Usuario o contraseña incorrectos |
| 422 | Mensaje del servidor o "Datos de entrada inválidos" | Errores de validación |
| 404 | "Usuario no encontrado" | Usuario no existe |
| 500 | "Error interno del servidor" | Error del backend |

### ✅ Errores de Conexión

| Tipo | Mensaje | Descripción |
|------|---------|-------------|
| `connectionTimeout` | "Tiempo de conexión agotado" | No se pudo conectar al servidor |
| `receiveTimeout` | "Tiempo de respuesta agotado" | El servidor tardó demasiado en responder |
| `connectionError` | "Error de conexión al servidor" | Problema de red |

### ✅ Errores de Validación

- **Campos vacíos**: "Por favor ingresa tu correo o teléfono"
- **Contraseña corta**: "La contraseña debe tener al menos 6 caracteres"
- **Errores del servidor**: Mensajes específicos del backend

## Flujo de Manejo de Errores

### 1. Error en el Servidor
```
1. Servidor responde con error (ej: 422)
2. ApiService captura DioException
3. Extrae mensaje específico del response
4. Lanza Exception con mensaje claro
```

### 2. Error en el Provider
```
1. AuthProvider captura Exception
2. Extrae solo el mensaje (sin stack trace)
3. Actualiza estado con error
4. Limpia loading
```

### 3. Error en la UI
```
1. LoginScreen escucha cambios en AuthState
2. Detecta error no null
3. Muestra SnackBar con mensaje
4. Limpia error del estado
```

## Ejemplos de Mensajes de Error

### Antes (Confuso)
```
Error: Exception: Error de conexión: DioException [bad response]: This exception was thrown because the response has a status code of 422...
```

### Después (Claro)
```
Credenciales incorrectas
```

### Otros Ejemplos
- "El correo electrónico ya está registrado"
- "La contraseña debe tener al menos 8 caracteres"
- "Tiempo de conexión agotado"
- "Error interno del servidor"

## Archivos Modificados

1. **`lib/datos/servicios/api_service.dart`**
   - Mejorado manejo de `DioException`
   - Extracción de mensajes específicos del servidor
   - Manejo de diferentes códigos de estado HTTP

2. **`lib/negocio/providers/auth_provider.dart`**
   - Mejorada extracción de mensajes de error
   - Eliminación de información de stack trace

3. **`lib/presentacion/pantallas/login_screen.dart`**
   - Agregado listener para mostrar errores automáticamente
   - Simplificado método `_handleLogin`
   - Mejorada experiencia de usuario

## Testing Recomendado

### Casos de Prueba

1. **Credenciales Incorrectas**
   - Email válido, contraseña incorrecta
   - Email inexistente
   - Ambos campos incorrectos

2. **Errores de Validación**
   - Campos vacíos
   - Contraseña muy corta
   - Email con formato inválido

3. **Errores de Conexión**
   - Sin conexión a internet
   - Servidor no disponible
   - Timeout de conexión

4. **Errores del Servidor**
   - Error 500
   - Error 404
   - Error 422 con mensaje específico

### Comandos de Debug

```bash
# Simular error de conexión
# Desconectar internet y intentar login

# Ver logs de error
flutter run --debug
# Intentar login con credenciales incorrectas
```

## Resultado

✅ **Mensajes de error claros** y específicos
✅ **Mejor experiencia de usuario** con feedback inmediato
✅ **Manejo robusto** de diferentes tipos de errores
✅ **Logs detallados** para debugging
✅ **UI consistente** con SnackBars informativos

La aplicación ahora muestra mensajes de error claros y específicos cuando el usuario ingresa credenciales incorrectas o hay problemas de conexión, mejorando significativamente la experiencia de usuario. 