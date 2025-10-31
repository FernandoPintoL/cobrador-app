# 🔑 Configuración de API Keys - Google Maps

## 📋 Resumen

Tu app usa **dos API keys diferentes**:
- Una para **Android** (`GOOGLE_MAPS_API_KEY`)
- Una para **iOS** (`GOOGLE_MAPS_API_KEY_IOS`)

## 🎯 Ubicación de las API Keys

### Android
- **Archivo**: `android/app/src/main/AndroidManifest.xml`
- **Variable .env**: `GOOGLE_MAPS_API_KEY`
- **Línea**: `<meta-data android:name="com.google.android.geo.API_KEY" android:value="..." />`

### iOS
- **Archivo**: `ios/Runner/AppDelegate.swift`
- **Variable .env**: `GOOGLE_MAPS_API_KEY_IOS`
- **Línea**: `GMSServices.provideAPIKey("...")`

## 🛠️ Cómo Obtener las API Keys

### 1. Ir a Google Cloud Console
https://console.cloud.google.com/

### 2. Crear o Seleccionar un Proyecto
- Si no tienes proyecto: **New Project**
- Si ya tienes: Selecciónalo del dropdown

### 3. Habilitar las APIs Necesarias

Ve a: **APIs & Services → Library**

Busca y habilita:
- ✅ **Maps SDK for Android**
- ✅ **Maps SDK for iOS**
- ✅ **Geocoding API** (opcional, para direcciones)
- ✅ **Places API** (opcional, para búsqueda de lugares)

### 4. Crear las API Keys

Ve a: **APIs & Services → Credentials**

#### Para Android:
1. Click en **+ CREATE CREDENTIALS → API key**
2. Copia la key generada
3. Click en **RESTRICT KEY**
4. Nombre: "Android Maps Key"
5. **Application restrictions**:
   - Selecciona **"Android apps"**
   - Click **"+ Add an item"**
   - Package name: `com.example.cobradorApp` (verifica en `android/app/build.gradle`)
   - SHA-1: Obtén con: `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`
6. **API restrictions**:
   - Selecciona **"Restrict key"**
   - Marca: Maps SDK for Android, Geocoding API
7. **SAVE**

#### Para iOS:
1. Click en **+ CREATE CREDENTIALS → API key**
2. Copia la key generada
3. Click en **RESTRICT KEY**
4. Nombre: "iOS Maps Key"
5. **Application restrictions**:
   - Selecciona **"iOS apps"**
   - Click **"+ Add an item"**
   - Bundle ID: `com.example.cobradorApp` (verifica en `ios/Runner.xcodeproj/project.pbxproj`)
6. **API restrictions**:
   - Selecciona **"Restrict key"**
   - Marca: Maps SDK for iOS, Geocoding API
7. **SAVE**

### 5. Configurar en tu Proyecto

#### Opción 1: Editar directamente los archivos

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_DE_ANDROID_AQUI" />
```

**iOS** (`ios/Runner/AppDelegate.swift`):
```swift
GMSServices.provideAPIKey("TU_API_KEY_DE_IOS_AQUI")
```

#### Opción 2: Usar variables de entorno (Recomendado)

1. Copia `.env.example` a `.env`
2. Completa las API keys en `.env`:
```env
GOOGLE_MAPS_API_KEY=tu_key_android
GOOGLE_MAPS_API_KEY_IOS=tu_key_ios
```

**Nota**: El `.env` está en `.gitignore` para que no se suba a Git.

## 🔒 Seguridad

### ✅ Buenas Prácticas

1. **Usa restricciones**: Siempre restringe tus API keys por aplicación
2. **Keys separadas**: Usa diferentes keys para Android e iOS
3. **No las subas a Git**: El `.env` debe estar en `.gitignore`
4. **Monitorea el uso**: Revisa regularmente en Google Cloud Console
5. **Activa billing alerts**: Para evitar cargos inesperados

### ❌ Evitar

1. **Keys sin restricciones**: Solo para testing temporal
2. **Misma key para todo**: Android e iOS deben tener keys separadas
3. **Subir a Git público**: Las keys quedan expuestas
4. **No monitorear**: Pueden abusar de tus créditos

## 🧪 Testing

### Desarrollo (Sin restricciones)
Para pruebas rápidas, puedes crear keys sin restricciones:
- **Application restrictions**: None
- **API restrictions**: Don't restrict key

⚠️ **Solo para desarrollo local, nunca en producción**

### Producción (Con restricciones)
Siempre usa las restricciones mencionadas arriba.

## 🚨 Troubleshooting

### Error: "This API project is not authorized to use this API"

**Solución**:
1. Verifica que Maps SDK for Android/iOS esté habilitado
2. Espera 5-10 minutos después de habilitar
3. Limpia y recompila: `flutter clean && flutter run`

### Error: "API key not valid"

**Solución**:
1. Verifica que la key esté correctamente copiada (sin espacios)
2. Verifica las restricciones de Bundle ID / Package Name
3. Verifica el SHA-1 fingerprint (Android)

### El mapa se ve gris/en blanco

**Causas comunes**:
- API key inválida
- Maps SDK no habilitado
- Billing no configurado
- Restricciones muy estrictas

**Solución**:
1. Revisa los logs: `flutter run --verbose`
2. Busca errores de "authorization" o "API key"
3. Prueba temporalmente sin restricciones
4. Verifica que tengas créditos en Google Cloud

## 💰 Costos

Google Maps ofrece:
- **$200 USD de crédito mensual gratis**
- Esto equivale a aproximadamente:
  - 28,000 cargas de mapa móvil
  - 40,000 solicitudes de geocoding

Para la mayoría de apps pequeñas/medianas, esto es suficiente para uso gratuito.

**Recomendación**: Activa alertas de billing para evitar sorpresas.

## 📱 Obtener Identificadores

### Package Name (Android)
Revisa: `android/app/build.gradle`
```gradle
defaultConfig {
    applicationId "com.example.cobradorApp"
    ...
}
```

### Bundle ID (iOS)
Revisa: Xcode → Runner → General → Bundle Identifier
O busca en: `ios/Runner.xcodeproj/project.pbxproj`

### SHA-1 Fingerprint (Android Debug)
```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

Para **Release**:
```bash
keytool -list -v \
  -keystore /ruta/a/tu/keystore.jks \
  -alias tu_alias
```

## 🔄 Sincronizar Cambios

Después de cambiar las API keys:

### Android
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter run
```

### iOS
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

## 📚 Referencias

- [Google Maps Platform](https://developers.google.com/maps)
- [Maps SDK for Android](https://developers.google.com/maps/documentation/android-sdk)
- [Maps SDK for iOS](https://developers.google.com/maps/documentation/ios-sdk)
- [API Key Best Practices](https://developers.google.com/maps/api-key-best-practices)

---

**Última actualización**: 2025-10-31
**Estado**: Configurado ✅

## ✅ Checklist de Configuración

- [ ] Proyecto creado en Google Cloud Console
- [ ] Maps SDK for Android habilitado
- [ ] Maps SDK for iOS habilitado
- [ ] API key de Android creada y restringida
- [ ] API key de iOS creada y restringida
- [ ] Keys agregadas en AndroidManifest.xml
- [ ] Keys agregadas en AppDelegate.swift
- [ ] Keys agregadas en .env
- [ ] .env agregado a .gitignore
- [ ] Billing configurado en Google Cloud
- [ ] Alertas de billing activadas
- [ ] Probado en Android
- [ ] Probado en iOS
