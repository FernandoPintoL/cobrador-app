# Configuración Segura de API Keys

## Problema
La API key de Google Maps estaba expuesta en el código fuente, lo cual representa una vulnerabilidad de seguridad.

## Solución Implementada

### 1. Variables de Entorno para Desarrollo
- Se utiliza `flutter_dotenv` para manejar variables de entorno en desarrollo
- Las API keys se almacenan en archivos `.env` que NO se suben a Git
- Para producción, la API key se maneja directamente en el AndroidManifest

### 2. Configuración para Desarrollo

1. **Crear archivo `.env` en la raíz del proyecto:**
```bash
# API Keys
GOOGLE_MAPS_API_KEY=tu_api_key_aqui

# Configuración de la aplicación
APP_NAME=Cobrador
APP_VERSION=1.0.0
```

2. **Instalar dependencias:**
```bash
flutter pub get
```

### 3. Configuración para Producción

Para builds de producción, la API key se maneja directamente en el `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="tu_api_key_aqui" />
```

### 4. Archivos de Configuración

- `env.example`: Archivo de ejemplo con la estructura de variables
- `lib/config/env_config.dart`: Clase para acceder a las variables de entorno
- `.gitignore`: Configurado para ignorar archivos `.env`
- `android/app/src/main/AndroidManifest.xml`: Configuración para producción

### 5. Uso en el Código

```dart
import 'package:tu_app/config/env_config.dart';

// Obtener la API key
String apiKey = EnvConfig.googleMapsApiKey;
```

## Seguridad

✅ **Archivos `.env` están en `.gitignore`**  
✅ **API keys de desarrollo no se suben al repositorio**  
✅ **Configuración simplificada para producción**  
✅ **Builds funcionan correctamente**

## Pasos para Configurar

1. Copia `env.example` a `.env`
2. Reemplaza `your_google_maps_api_key_here` con tu API key real
3. Ejecuta `flutter pub get`
4. Para producción, actualiza la API key en `AndroidManifest.xml`
5. ¡Listo! Tu API key está segura

## Notas Importantes

- **NUNCA** subas el archivo `.env` al repositorio
- **SIEMPRE** usa `env.example` como plantilla
- Para producción, actualiza manualmente la API key en `AndroidManifest.xml`
- El enfoque simplificado evita problemas de build complejos
- Si tienes problemas de codificación UTF-8, usa el script `verificar_env.ps1`

## Solución de Problemas

### Error de Codificación UTF-8
Si ves el error `FormatException: Invalid UTF-8 byte`, ejecuta:
```bash
.\verificar_env.ps1
```

### Verificación de Archivos
- `verificar_env.ps1`: Script para verificar y corregir el archivo `.env`
- `build_production.ps1`: Script para builds de producción 