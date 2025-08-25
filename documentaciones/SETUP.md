# Configuración Paso a Paso - Cobrador App

## 1. Instalar Dependencias Faltantes

Ejecuta los siguientes comandos para instalar todas las dependencias necesarias:

```bash
# Dependencias principales
flutter pub add dio
flutter pub add shared_preferences
flutter pub add flutter_riverpod
flutter pub add riverpod

# GPS y ubicación
flutter pub add geolocator
flutter pub add geocoding

# Mapas
flutter pub add google_maps_flutter
flutter pub add flutter_map

# UI y componentes
flutter pub add flutter_svg
flutter pub add cached_network_image
flutter pub add shimmer

# Formularios
flutter pub add form_builder
flutter pub add form_builder_validators

# Fechas
flutter pub add intl

# Almacenamiento local
flutter pub add hive
flutter pub add hive_flutter

# QR y códigos
flutter pub add qr_flutter
flutter pub add mobile_scanner

# Notificaciones
flutter pub add flutter_local_notifications

# Utilidades
flutter pub add permission_handler
flutter pub add image_picker
flutter pub add path_provider
flutter pub add url_launcher

# Dependencias de desarrollo
flutter pub add --dev hive_generator
flutter pub add --dev build_runner
```

## 2. Configurar Permisos de Ubicación

### Android (`android/app/src/main/AndroidManifest.xml`)

Agrega estos permisos dentro del tag `<manifest>`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
```

### iOS (`ios/Runner/Info.plist`)

Agrega estas claves dentro del tag `<dict>`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Esta aplicación necesita acceso a la ubicación para registrar clientes y pagos.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Esta aplicación necesita acceso a la ubicación para registrar clientes y pagos.</string>
<key>NSCameraUsageDescription</key>
<string>Esta aplicación necesita acceso a la cámara para escanear códigos QR.</string>
```

## 3. Configurar Google Maps

### 1. Obtener API Key
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. Habilita las APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Places API
   - Geocoding API
4. Crea credenciales (API Key)

### 2. Configurar en Android

En `android/app/src/main/AndroidManifest.xml`, dentro del tag `<application>`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />
```

### 3. Configurar en iOS

En `ios/Runner/AppDelegate.swift`, agrega:

```swift
import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("TU_API_KEY_AQUI")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## 4. Configurar Hive (Almacenamiento Local)

### 1. Generar archivos Hive

Ejecuta este comando para generar los archivos necesarios:

```bash
flutter packages pub run build_runner build
```

### 2. Inicializar Hive

En `lib/main.dart`, agrega la inicialización:

```dart
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Registrar adaptadores
  Hive.registerAdapter(UsuarioAdapter());
  
  runApp(const CobradorApp());
}
```

## 5. Configurar URL del Backend

En `lib/datos/servicios/api_service.dart`, actualiza la URL base:

```dart
class ApiService {
  // Cambia esta URL por la de tu backend Laravel
  static const String baseUrl = 'http://tu-backend-laravel.com/api';
  // ...
}
```

## 6. Configurar Notificaciones

### Android

En `android/app/src/main/AndroidManifest.xml`, agrega:

```xml
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED"/>
        <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    </intent-filter>
</receiver>
```

### iOS

En `ios/Runner/AppDelegate.swift`, agrega:

```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```

## 7. Ejecutar la Aplicación

```bash
flutter clean
flutter pub get
flutter run
```

## 8. Solucionar Errores Comunes

### Error: "Target of URI doesn't exist"
- Ejecuta `flutter pub get` nuevamente
- Reinicia el IDE
- Ejecuta `flutter clean` y luego `flutter pub get`

### Error: "Permission denied"
- Verifica que los permisos estén configurados correctamente
- En Android, asegúrate de que el usuario haya dado permisos manualmente

### Error: "Google Maps not working"
- Verifica que la API key sea correcta
- Asegúrate de que las APIs estén habilitadas en Google Cloud Console
- Verifica que la facturación esté habilitada

## 9. Próximos Pasos

1. **Implementar funcionalidades faltantes**:
   - Integración completa con el backend
   - Gestión de estado con Riverpod
   - Funcionalidades de mapa
   - Sistema de notificaciones

2. **Testing**:
   - Crear tests unitarios
   - Crear tests de widgets
   - Crear tests de integración

3. **Deployment**:
   - Configurar signing para Android
   - Configurar certificados para iOS
   - Publicar en stores

## 10. Comandos Útiles

```bash
# Limpiar y reinstalar
flutter clean && flutter pub get

# Generar archivos Hive
flutter packages pub run build_runner build

# Ejecutar tests
flutter test

# Construir APK
flutter build apk

# Construir para iOS
flutter build ios
```

## 11. Estructura Final Esperada

```
app-cobrador/
├── lib/
│   ├── datos/
│   │   ├── modelos/
│   │   ├── repositorios/
│   │   └── servicios/
│   ├── negocio/
│   │   └── providers/
│   └── presentacion/
│       └── pantallas/
├── android/
├── ios/
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── pubspec.yaml
├── README.md
└── SETUP.md
```

¡Con estos pasos tendrás una aplicación Flutter completamente funcional para gestión de cobranzas! 