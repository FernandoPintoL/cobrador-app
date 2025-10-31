# 🍎 Configuración de Google Maps para iOS

## ✅ Cambios Realizados

### 1. AppDelegate.swift
Se agregó la inicialización de Google Maps:

```swift
import GoogleMaps

GMSServices.provideAPIKey("AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU")
```

### 2. Info.plist
Se agregaron los permisos de ubicación necesarios:

- `NSLocationWhenInUseUsageDescription`: Para usar ubicación mientras la app está activa
- `NSLocationAlwaysAndWhenInUseUsageDescription`: Para acceso continuo
- `NSLocationAlwaysUsageDescription`: Para background location
- `NSCameraUsageDescription`: Para fotos de perfil
- `NSPhotoLibraryUsageDescription`: Para seleccionar fotos

## 🔑 Configuración de la API Key

Tu API key actual para iOS: `AIzaSyDu3Gw25vNkS9VFu-ZItz5TrU8qvVn446s`

**Nota**: Esta key está configurada en:
- Archivo `.env` como `GOOGLE_MAPS_API_KEY_IOS`
- Archivo `ios/Runner/AppDelegate.swift` (hardcoded por limitaciones de Swift)

### Pasos en Google Cloud Console:

1. **Ir a**: https://console.cloud.google.com/

2. **Seleccionar tu proyecto**

3. **Habilitar las APIs necesarias**:
   - ✅ Maps SDK for Android (ya habilitado)
   - ✅ **Maps SDK for iOS** (necesitas habilitar esto)

4. **Configurar restricciones de la API key**:

   Ve a: APIs & Services → Credentials → Tu API Key

   **Restricciones de aplicación**:
   - Opción 1 (Desarrollo): "None" (sin restricciones)
   - Opción 2 (Producción): "iOS apps" y agregar Bundle ID

   **Bundle ID de tu app**: `com.example.cobradorApp` (verificar en Xcode)

   **Restricciones de API**:
   - Maps SDK for Android
   - Maps SDK for iOS
   - Geocoding API (opcional)
   - Places API (opcional)

## 🧪 Pruebas

### Para probar en el simulador de iOS:

```bash
# Limpiar build anterior
flutter clean

# Instalar pods de iOS
cd ios
pod install
cd ..

# Ejecutar en simulador iOS
flutter run
```

### Verificar permisos de ubicación:

1. Abre la app en el simulador
2. Ve a la pantalla de mapas
3. Debe aparecer un popup pidiendo permiso de ubicación
4. Acepta el permiso
5. El mapa debe cargar correctamente

### Simular ubicación en iOS:

En el simulador:
1. Menú: **Features → Location → Custom Location**
2. Ingresa coordenadas:
   - Latitude: -12.0464 (Lima, Perú)
   - Longitude: -77.0428

O usa ubicaciones predefinidas:
- **Features → Location → Apple**
- **Features → Location → City Run**

## 🚨 Errores Comunes

### Error: "Google Maps SDK for iOS not found"

**Solución**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter run
```

### Error: "API key not authorized"

**Solución**:
1. Verifica que Maps SDK for iOS esté habilitado
2. Verifica que la API key no tenga restricciones que bloqueen iOS
3. Espera 5-10 minutos después de cambios en Google Cloud Console

### Error: "Location permission denied"

**Solución**:
1. Verifica que Info.plist tenga las descripciones de permisos
2. Resetea permisos del simulador:
   ```
   Simulador → Device → Erase All Content and Settings
   ```

### Error: El mapa se ve en blanco/gris

**Causas**:
- API key inválida o sin permisos
- Maps SDK for iOS no habilitado
- Sin conexión a internet
- Billing no configurado en Google Cloud

## 📱 Diferencias iOS vs Android

| Característica | iOS | Android |
|----------------|-----|---------|
| **Configuración API Key** | AppDelegate.swift | AndroidManifest.xml |
| **Permisos** | Info.plist | AndroidManifest.xml |
| **Pods** | ✅ Requiere `pod install` | ❌ No requiere |
| **Bundle ID** | Debe coincidir en restricciones | Package name |
| **Simulador** | ✅ Funciona bien | ⚠️ Requiere Google Play |

## 🎯 Próximos Pasos

1. **Habilitar Maps SDK for iOS** en Google Cloud Console
2. **Ejecutar**: `cd ios && pod install`
3. **Limpiar**: `flutter clean`
4. **Ejecutar**: `flutter run`
5. **Probar** la pantalla de mapas en el simulador

## 📝 Notas Importantes

- ⚠️ La API key está hardcodeada en el código (no es ideal para producción)
- 💡 Considera usar `.env` o configuración por ambiente
- 🔒 En producción, agrega restricciones de Bundle ID
- 💰 Verifica que tengas créditos en Google Cloud (billing activo)

## 🆘 ¿Todavía no funciona?

Si después de seguir todos los pasos el mapa sigue sin funcionar:

1. **Verifica los logs de Xcode**:
   ```bash
   flutter run --verbose
   ```

2. **Busca errores relacionados con**:
   - "Google Maps"
   - "API key"
   - "Authorization"

3. **Crea una nueva API key**:
   - A veces es más rápido crear una nueva key sin restricciones
   - Úsala solo para desarrollo/testing

4. **Revisa el código del error** en la pantalla que agregamos
   - El error técnico te dirá exactamente qué está fallando

---

**Última actualización**: 2025-10-31
**Estado**: Configuración completada ✅
