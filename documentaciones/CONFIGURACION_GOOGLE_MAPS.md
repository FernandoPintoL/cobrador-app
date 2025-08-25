# Configuración de Google Maps API

## Problema Actual
La aplicación muestra un "lienzo crema" en lugar del mapa debido a problemas de autorización con la API de Google Maps.

## Error en Consola
```
E/Google Android Maps SDK: Authorization failure. Please see https://developers.google.com/maps/documentation/android-sdk/start for how to correctly set up the map.
E/Google Android Maps SDK: API Key: AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
E/Google Android Maps SDK: Android Application (<cert_fingerprint>;<package_name>): FB:82:5A:8A:2C:5E:D4:17:00:38:E8:0F:CE:E7:2E:91:1D:13:D1:E7;com.fpl.cobrador.cobrador_app
```

## Información de tu Aplicación
- **Package Name**: `com.fpl.cobrador.cobrador_app`
- **SHA-1 Certificate Fingerprint**: `FB:82:5A:8A:2C:5E:D4:17:00:38:E8:0F:CE:E7:2E:91:1D:13:D1:E7`
- **API Key Actual**: `AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU`

## Pasos para Solucionar

### 1. Acceder a Google Cloud Console
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto o crea uno nuevo

### 2. Habilitar Maps SDK for Android
1. Ve a "APIs & Services" > "Library"
2. Busca "Maps SDK for Android"
3. Haz clic en el resultado y presiona "ENABLE"

### 3. Configurar la API Key
1. Ve a "APIs & Services" > "Credentials"
2. Si no tienes una API Key, crea una nueva:
   - Haz clic en "CREATE CREDENTIALS" > "API key"
3. Si ya tienes la API Key `AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU`:
   - Haz clic en el ícono de editar (lápiz)

### 4. Configurar Restricciones de Android
1. En "Application restrictions", selecciona "Android apps"
2. Haz clic en "ADD AN ITEM"
3. Agrega:
   - **Package name**: `com.fpl.cobrador.cobrador_app`
   - **SHA-1 certificate fingerprint**: `FB:82:5A:8A:2C:5E:D4:17:00:38:E8:0F:CE:E7:2E:91:1D:13:D1:E7`
4. Haz clic en "SAVE"

### 5. Verificar APIs Habilitadas
Asegúrate de que estas APIs estén habilitadas:
- Maps SDK for Android
- Geocoding API (para direcciones)
- Places API (opcional, para autocompletado)

## Alternativa: API Key de Desarrollo (Sin Restricciones)
Para desarrollo rápido, puedes crear una API Key sin restricciones:

1. Crea una nueva API Key
2. En "Application restrictions", selecciona "None"
3. En "API restrictions", selecciona "Restrict key" y marca:
   - Maps SDK for Android
   - Geocoding API

⚠️ **IMPORTANTE**: Las API Keys sin restricciones no deben usarse en producción.

## Verificación
Después de configurar la API Key:

1. Espera 5-10 minutos para que los cambios se propaguen
2. Reinicia la aplicación completamente
3. Verifica que no aparezcan errores de autorización en los logs

## Archivo de Configuración Actual
La API Key está configurada en:
- `android/app/src/main/AndroidManifest.xml`
- `.env.development`

## Comandos de Limpieza
Si los cambios no se aplican:
```bash
flutter clean
flutter pub get
flutter run
```

## Contacto de Soporte
Si el problema persiste, verifica:
1. Que tu cuenta de Google Cloud tenga facturación habilitada
2. Que no hayas excedido las cuotas gratuitas de la API
3. Que tu proyecto tenga las APIs necesarias habilitadas
