# 🚀 Cómo Probar las Cámaras con ML

## ✅ Instalación Completada

Las dependencias ya están instaladas:
```bash
flutter pub get  # ✓ Completado
```

## 📱 Probar en Dispositivo Real

### Opción 1: Navegación Directa (Más Rápido)

En cualquier parte de tu app donde quieras probar, agrega este botón:

```dart
import 'package:cobrador_app/presentacion/widgets/camera/test_camera_ml.dart';

// En cualquier parte de tu UI
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TestCameraMLScreen(),
      ),
    );
  },
  child: const Text('Probar Cámaras ML'),
)
```

### Opción 2: Agregar a tu Router

Si usas `go_router`, agrega esta ruta:

```dart
GoRoute(
  path: '/test-cameras-ml',
  builder: (context, state) => const TestCameraMLScreen(),
),
```

### Opción 3: Uso Directo (Sin pantalla de test)

```dart
import 'package:cobrador_app/presentacion/widgets/camera/camera_with_face_detection_screen.dart';
import 'package:cobrador_app/presentacion/widgets/camera/camera_with_document_detection_screen.dart';

// Para capturar rostro
final File? selfie = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraWithFaceDetectionScreen(
      title: 'Selfie',
      autoCapture: true,  // Auto-captura
    ),
  ),
);

// Para capturar documento
final File? documento = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraWithDocumentDetectionScreen(
      title: 'Cédula',
      autoCapture: true,  // Auto-captura
    ),
  ),
);
```

## 🔧 Ejecutar en Dispositivo

### Android:
```bash
flutter run
```

### iOS (desde macOS):
```bash
flutter run
```

### iOS Específico:
```bash
flutter run -d <device-id>
```

Para ver dispositivos disponibles:
```bash
flutter devices
```

## ⚠️ Importante

### ✅ Funcionará en:
- ✓ Dispositivos Android reales (API 21+)
- ✓ Dispositivos iOS reales (iOS 10.0+)
- ✓ Emuladores Android (pero más lento)

### ❌ NO funcionará en:
- ✗ Simulador iOS (Face Detection no funciona)
- ✗ Navegador web

## 🎯 Qué Esperar

### Detección de Rostros:
1. Abre la cámara frontal
2. Muestra un óvalo guía
3. Cuando centras tu rostro, el borde se pone **verde**
4. Con `autoCapture: true`, se toma la foto automáticamente después de 1.5 segundos
5. Con `autoCapture: false`, debes presionar el botón manualmente

### Detección de Documentos:
1. Abre la cámara trasera (puedes cambiarla)
2. Muestra un marco rectangular
3. Cuando detecta texto (CI/DNI/Pasaporte), el borde se pone **verde**
4. Con `autoCapture: true`, se toma la foto automáticamente después de 2 segundos
5. Con `autoCapture: false`, debes presionar el botón manualmente

## 🐛 Troubleshooting

### "No se detecta el rostro"
- Asegúrate de usar un dispositivo real (no simulador iOS)
- Mejora la iluminación
- Centra bien tu rostro en el óvalo

### "No se detecta el documento"
- Mejora la iluminación
- Asegúrate de que el documento tenga texto legible
- El documento debe estar dentro del marco
- Si sigue sin detectar, ajusta el umbral en `camera_with_document_detection_screen.dart:145`

### "Errores de compilación"
```bash
flutter clean
flutter pub get
flutter run
```

## 📸 Después de Capturar

La foto se devuelve como `File?`:

```dart
if (photo != null) {
  // Tienes la foto lista para usar
  print('Foto: ${photo.path}');

  // Comprimir si necesitas
  // Subir al servidor
  // Mostrar en UI
  // etc.
}
```

## 🎨 Personalizar

### Cambiar el tiempo de auto-captura:

En `camera_with_face_detection_screen.dart:162`:
```dart
await Future.delayed(const Duration(milliseconds: 1500)); // Cambiar a 3000 para 3 segundos
```

En `camera_with_document_detection_screen.dart:156`:
```dart
await Future.delayed(const Duration(milliseconds: 2000)); // Cambiar a 4000 para 4 segundos
```

### Cambiar el umbral de detección de documentos:

En `camera_with_document_detection_screen.dart:145`:
```dart
final hasEnoughText = recognizedText.blocks.length >= 3; // Cambiar a 2 si necesitas menos texto
```

## 📚 Ejemplos Adicionales

Ver archivo completo de ejemplos:
- `lib/presentacion/widgets/camera/ejemplo_uso.dart`
- `lib/presentacion/widgets/camera/README.md`

## ✨ Listo!

Ya puedes probar las cámaras con detección ML en tu dispositivo real.
