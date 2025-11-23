# Cámara In-App - Documentación

## Descripción

Se ha implementado una cámara integrada dentro de la aplicación para evitar el cierre de sesión automático que ocurría al cambiar a la app de cámara del sistema.

## Problema Resuelto

**Problema anterior:**
- Al abrir la cámara del sistema (iPhone o Android), la app detectaba un cambio de aplicación
- El sistema de seguridad cerraba la sesión automáticamente
- Los usuarios perdían los datos del formulario al regresar

**Solución implementada:**
- Cámara integrada dentro de la app (no cambia de aplicación)
- No se cierra sesión al tomar fotos
- Mejor experiencia de usuario con vista previa y confirmación

## Archivos Creados

### 1. Widget Principal de Cámara
**Ubicación:** `lib/presentacion/widgets/camera/in_app_camera_screen.dart`

**Características:**
- ✅ Vista previa en tiempo real de la cámara
- ✅ Cambio entre cámara frontal y trasera
- ✅ Control de flash (Off/Auto/On)
- ✅ Captura en alta resolución (configurable)
- ✅ Pantalla de confirmación con vista previa de la foto
- ✅ Manejo del ciclo de vida de la app
- ✅ Orientación bloqueada en portrait durante el uso
- ✅ Manejo de errores con reintentos

**Widget de confirmación integrado:**
- `_PhotoPreviewScreen`: Permite al usuario ver la foto antes de confirmarla
- Botones: "Reintentar" (tomar otra foto) y "Usar Foto" (confirmar)

## Integración en Formularios

### Formularios Actualizados:

#### 1. Formulario de Cobradores
**Archivo:** `lib/presentacion/cobrador/cobrador_form_screen.dart`

**Cambios realizados:**
- ✅ Importado `InAppCameraScreen`
- ✅ Removida dependencia de `AllowedAppsHelper`
- ✅ Método `_pickImage` actualizado para usar cámara in-app
- ✅ Textos de ayuda personalizados según tipo de foto:
  - CI Anverso: "Asegúrate de que la foto sea clara y legible"
  - CI Reverso: "Captura el reverso del documento de identidad"
  - Perfil: "Toma una foto clara del rostro del cobrador"

#### 2. Formulario de Clientes
**Archivo:** `lib/presentacion/cliente/cliente_form_screen.dart`

**Cambios realizados:**
- ✅ Importado `InAppCameraScreen`
- ✅ Removida dependencia de `AllowedAppsHelper`
- ✅ Método `_pickImage` actualizado para usar cámara in-app
- ✅ Textos de ayuda personalizados según tipo de foto:
  - CI Anverso: "Asegúrate de que la foto sea clara y legible"
  - CI Reverso: "Captura el reverso del documento de identidad"
  - Perfil: "Toma una foto clara del rostro del cliente"

## Permisos Configurados

### Android
**Archivo:** `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

Ya estaba configurado correctamente.

### iOS
**Archivo:** `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para tomar fotos de documentos de identidad y fotos de perfil de clientes.</string>
```

Actualizado con descripción mejorada.

## Dependencias

### Paquete Utilizado
```yaml
dependencies:
  camera: ^0.11.2
```

Ya estaba instalado en el proyecto. Es el paquete oficial de Flutter Team.

## Cómo Usar

### Uso Básico en un Formulario

```dart
import '../widgets/camera/in_app_camera_screen.dart';

// En tu método de captura de imagen:
Future<void> _pickImage() async {
  final File? capturedImage = await Navigator.of(context).push<File>(
    MaterialPageRoute(
      builder: (context) => InAppCameraScreen(
        title: 'Tomar Foto',
        helpText: 'Asegúrate de que la foto sea clara',
      ),
    ),
  );

  if (capturedImage != null) {
    // Usar la imagen capturada
    setState(() {
      _myImage = capturedImage;
    });
  }
}
```

### Parámetros Disponibles

```dart
InAppCameraScreen(
  title: 'Título de la Pantalla',           // Título en el AppBar
  helpText: 'Texto de ayuda opcional',      // Mensaje de ayuda (opcional)
  resolution: ResolutionPreset.high,        // Calidad de foto (default: high)
)
```

### Opciones de Resolución
- `ResolutionPreset.low` - Baja calidad (más rápido)
- `ResolutionPreset.medium` - Calidad media
- `ResolutionPreset.high` - Alta calidad (recomendado)
- `ResolutionPreset.veryHigh` - Muy alta calidad
- `ResolutionPreset.ultraHigh` - Ultra alta calidad
- `ResolutionPreset.max` - Máxima calidad del dispositivo

## Flujo de Usuario

1. Usuario toca el botón para tomar foto
2. Aparece diálogo: "Cámara" o "Galería"
3. Si elige "Cámara":
   - Se abre `InAppCameraScreen` (dentro de la app)
   - Vista previa en tiempo real
   - Puede cambiar entre cámara frontal/trasera
   - Puede ajustar el flash
   - Toca el botón de captura
4. Se muestra pantalla de confirmación:
   - Vista previa de la foto capturada
   - Botón "Reintentar": vuelve a la cámara
   - Botón "Usar Foto": confirma y retorna la imagen
5. La imagen se comprime automáticamente a menos de 1MB
6. Se actualiza el formulario con la imagen

## Ventajas vs Cámara del Sistema

| Característica | Cámara del Sistema | Cámara In-App |
|----------------|-------------------|---------------|
| Cambia de app | ✅ Sí | ❌ No |
| Cierra sesión | ✅ Sí | ❌ No |
| Vista previa antes de usar | ❌ No | ✅ Sí |
| Textos de ayuda personalizados | ❌ No | ✅ Sí |
| UI consistente con la app | ❌ No | ✅ Sí |
| Control de flash | ✅ Sí | ✅ Sí |
| Cambio de cámara | ✅ Sí | ✅ Sí |
| Velocidad | Similar | Similar |

## Compatibilidad

- ✅ iOS (iPhone/iPad)
- ✅ Android
- ✅ Maneja correctamente el ciclo de vida de la app
- ✅ Restaura orientación original al salir
- ✅ Libera recursos de cámara correctamente

## Manejo de Errores

La cámara maneja automáticamente:
- ✅ No hay cámaras disponibles
- ✅ Permisos denegados
- ✅ Error al inicializar cámara
- ✅ Error al cambiar de cámara
- ✅ Error al capturar foto
- ✅ Usuario cancela la operación

## Próximos Pasos (Opcional)

### Mejoras Futuras Posibles:
1. **Zoom**: Agregar control de zoom con gestos
2. **Grid de composición**: Líneas guía para mejor encuadre
3. **Detección de documentos**: Auto-crop de CI usando ML
4. **Modo nocturno**: Mejores fotos en baja luz
5. **Múltiples fotos**: Capturar varias fotos de una vez
6. **Video**: Soporte para grabar videos cortos

## Testing

### Probar en Dispositivos Reales

**iOS:**
```bash
flutter run -d <iPhone-ID>
```

**Android:**
```bash
flutter run -d <Android-ID>
```

### Casos de Prueba Recomendados:

1. ✅ Tomar foto con cámara trasera
2. ✅ Tomar foto con cámara frontal
3. ✅ Cambiar entre cámaras durante el uso
4. ✅ Probar flash en diferentes modos
5. ✅ Cancelar sin tomar foto
6. ✅ Tomar foto y reintentar
7. ✅ Tomar foto y confirmar
8. ✅ Minimizar app mientras la cámara está abierta
9. ✅ Rotar el dispositivo
10. ✅ Denegar permisos de cámara

## Notas Técnicas

### Gestión de Memoria
- La cámara se libera automáticamente al salir
- Preview se pausa cuando la app va a background
- Se reinicia automáticamente al volver

### Orientación
- Bloqueada en portrait mientras la cámara está activa
- Se restaura la orientación original al salir

### BuildContext Seguro
- Todas las operaciones async verifican `mounted` antes de usar `context`
- Previene errores de "BuildContext across async gaps"

## Soporte

Si encuentras problemas:
1. Verifica que los permisos estén configurados correctamente
2. Revisa los logs de Flutter para errores de cámara
3. Asegúrate de probar en dispositivo real (no simulador para cámara completa)
4. Verifica que el paquete `camera` esté actualizado

---

**Implementado:** 2025-01-23
**Versión de Flutter:** 3.8.1
**Paquete Camera:** 0.11.2
**Plataformas Soportadas:** iOS, Android
