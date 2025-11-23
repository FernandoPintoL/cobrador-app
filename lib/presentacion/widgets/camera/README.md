# Widgets de Cámara con Detección ML

Este módulo contiene widgets de cámara con detección automática de rostros y documentos usando Google ML Kit.

## 📦 Instalación

1. Las dependencias ya están agregadas en `pubspec.yaml`:
   - `google_mlkit_face_detection: ^0.11.1`
   - `google_mlkit_text_recognition: ^0.13.1`
2. Ejecutar: `flutter pub get` ✅
3. Configurar permisos en cada plataforma

### Permisos iOS (ios/Runner/Info.plist)

```xml
<key>NSCameraUsageDescription</key>
<string>Necesitamos acceso a la cámara para capturar fotos de documentos y rostros</string>
```

### Permisos Android (android/app/src/main/AndroidManifest.xml)

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-feature android:name="android.hardware.camera" android:required="false" />
```

También agregar en `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

## 🚀 Uso

### 1. Cámara con Detección de Rostros

```dart
import 'package:cobrador_app/presentacion/widgets/camera/camera_with_face_detection_screen.dart';

// Captura manual
final File? photo = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraWithFaceDetectionScreen(
      title: 'Capturar Selfie',
      helpText: 'Centra tu rostro en el óvalo',
    ),
  ),
);

// Captura automática cuando detecta el rostro
final File? photo = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraWithFaceDetectionScreen(
      title: 'Verificación de Identidad',
      helpText: 'Centra tu rostro - Se capturará automáticamente',
      autoCapture: true, // ✨ Captura automática
    ),
  ),
);
```

### 2. Cámara con Detección de Documentos

```dart
import 'package:cobrador_app/presentacion/widgets/camera/camera_with_document_detection_screen.dart';

// Captura manual
final File? photo = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraWithDocumentDetectionScreen(
      title: 'Capturar Cédula',
      helpText: 'Coloca tu cédula dentro del marco',
    ),
  ),
);

// Captura automática cuando detecta el documento
final File? photo = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const CameraWithDocumentDetectionScreen(
      title: 'Capturar DNI',
      helpText: 'Coloca el documento - Se capturará automáticamente',
      autoCapture: true, // ✨ Captura automática
    ),
  ),
);
```

### 3. Cámara Simple (sin detección)

```dart
import 'package:cobrador_app/presentacion/widgets/camera/in_app_camera_screen.dart';

final File? photo = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const InAppCameraScreen(
      title: 'Tomar Foto',
      helpText: 'Captura una foto clara del comprobante',
    ),
  ),
);
```

## 📸 Procesamiento de la Foto Capturada

```dart
if (photo != null) {
  // La foto está lista para usar
  print('Foto capturada: ${photo.path}');

  // Comprimir si es necesario
  final compressedFile = await FlutterImageCompress.compressAndGetFile(
    photo.path,
    '${photo.path}_compressed.jpg',
    quality: 85,
  );

  // Subir al servidor
  await uploadPhoto(compressedFile);
}
```

## 🎨 Características

### Detección de Rostros
- ✅ Overlay oval para guiar al usuario
- ✅ Detección en tiempo real usando ML Kit Face Detection
- ✅ Indicador visual cuando detecta un rostro
- ✅ Auto-captura opcional cuando el rostro está bien posicionado
- ✅ Borde verde cuando detecta correctamente

### Detección de Documentos
- ✅ Overlay rectangular para documentos
- ✅ Detección basada en reconocimiento de texto (OCR)
- ✅ Indicador visual cuando detecta suficiente texto
- ✅ Auto-captura opcional cuando detecta el documento
- ✅ Borde verde cuando detecta correctamente
- ✅ Control de flash para mejor iluminación

### Ambas Cámaras
- ✅ Vista previa antes de confirmar
- ✅ Cambio entre cámara frontal y trasera
- ✅ Manejo de orientación
- ✅ Manejo del ciclo de vida de la app
- ✅ Interfaz moderna y limpia

## ⚙️ Configuración Avanzada

### Cambiar la Resolución

```dart
CameraWithFaceDetectionScreen(
  resolution: ResolutionPreset.ultraHigh, // max, veryHigh, high, medium, low
)
```

### Personalizar Detección de Rostros

Editar `camera_with_face_detection_screen.dart:42`:

```dart
final FaceDetector _faceDetector = FaceDetector(
  options: FaceDetectorOptions(
    enableContours: true,      // Activar contornos del rostro
    enableLandmarks: true,      // Activar puntos faciales
    enableClassification: true, // Detectar sonrisa, ojos abiertos
    performanceMode: FaceDetectorMode.accurate, // Cambiar a modo preciso
  ),
);
```

## 🔧 Troubleshooting

### En iOS Simulator
- **Face Detection NO funciona** en simulador iOS, solo en dispositivos reales
- Puedes probar la interfaz pero la detección no será funcional

### En Android Emulator
- Asegúrate de habilitar la cámara virtual en AVD Manager
- La detección funciona pero puede ser más lenta

### "No se detecta el documento"
- Asegura buena iluminación
- El documento debe tener texto legible
- Ajusta el umbral en `camera_with_document_detection_screen.dart:145`:
  ```dart
  final hasEnoughText = recognizedText.blocks.length >= 2; // Cambiar de 3 a 2
  ```

### "No se detecta el rostro"
- Usa la cámara frontal
- Mejora la iluminación
- Centra bien el rostro en el óvalo

## 📱 Compatibilidad

- ✅ iOS 10.0+
- ✅ Android API 21+ (Android 5.0 Lollipop)
- ✅ Funciona offline (ML Kit on-device)

## 🎯 Próximas Mejoras Sugeridas

1. **Detección de bordes de documentos** usando OpenCV
2. **Corrección de perspectiva** automática del documento
3. **Validación de calidad** de la imagen (nitidez, iluminación)
4. **Guías animadas** para mejorar UX
5. **Crop automático** del documento detectado
