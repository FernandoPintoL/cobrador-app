# Guía de Seguridad - API Keys

## ⚠️ IMPORTANTE: API Keys Expuestas

Si llegaste aquí por una alerta de seguridad de GitHub, las API keys que fueron detectadas en commits anteriores **YA NO SON VÁLIDAS** y han sido deshabilitadas.

## Configuración de API Keys (Nuevos Desarrolladores)

### 1. Obtener API Keys de Google Maps

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea o selecciona un proyecto
3. Habilita las APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. Ve a "Credentials" y crea **DOS API keys separadas**:
   - Una para Android
   - Una para iOS

### 2. Configurar Restricciones

#### Android API Key:
- Tipo: Android apps
- Package name: `com.fpl.cobrador.cobrador_app`
- SHA-1 certificate fingerprint: (obtén con `keytool -list -v -keystore ~/.android/debug.keystore`)

#### iOS API Key:
- Tipo: iOS apps
- Bundle ID: `com.fpl.cobrador.cobradorApp`

### 3. Configurar Variables de Entorno

#### Para Android:
Edita `android/local.properties` y agrega:
```properties
GOOGLE_MAPS_API_KEY=tu_api_key_de_android_aqui
```

**NOTA**: `local.properties` está en `.gitignore` y NO se commitea.

#### Para iOS:
Las API keys se cargan desde el archivo `.env` en la raíz del proyecto.

Copia `.env.example` a `.env`:
```bash
cp .env.example .env
```

Edita `.env` y agrega tus API keys:
```bash
GOOGLE_MAPS_API_KEY=tu_api_key_de_android_aqui
GOOGLE_MAPS_API_KEY_IOS=tu_api_key_de_ios_aqui
```

### 4. Configurar Build de iOS en Xcode

1. Abre `ios/Runner.xcworkspace` en Xcode
2. Selecciona el target "Runner"
3. Ve a "Build Settings"
4. Busca "User-Defined" settings
5. Agrega una nueva variable:
   - Key: `GOOGLE_MAPS_API_KEY_IOS`
   - Value: `$(GOOGLE_MAPS_API_KEY_IOS)`

6. Ve a "Build Phases"
7. Agrega un nuevo "Run Script Phase" ANTES de "Compile Sources":
   ```bash
   source "${SRCROOT}/scripts/load_env.sh"
   ```

## Archivos que NUNCA deben commitearse

- `.env`
- `.env.local`
- `.env.production`
- `android/local.properties` (ya está en .gitignore)
- `ios/Runner/GoogleService-Info.plist` (si usas Firebase)

## ¿Qué hacer si expones una API Key?

1. **Inmediatamente** ve a Google Cloud Console
2. Deshabilita o elimina la API key comprometida
3. Crea una nueva API key con restricciones apropiadas
4. Actualiza tus archivos de configuración locales
5. Notifica al equipo

## Construcción de Release

### Android:
```bash
flutter build apk --release
# o
flutter build appbundle --release
```

### iOS:
Antes de crear un archive, asegúrate de que:
1. El archivo `.env` existe con las API keys correctas
2. El script `load_env.sh` tiene permisos de ejecución:
   ```bash
   chmod +x ios/scripts/load_env.sh
   ```

Luego en Xcode:
1. Product → Clean Build Folder
2. Product → Archive

## Preguntas Frecuentes

**P: ¿Por qué mi app muestra "For development purposes only" en el mapa?**
R: Tu API key no tiene las restricciones correctas o está usando una key de desarrollo.

**P: ¿Puedo usar la misma API key para Android e iOS?**
R: No es recomendable. Usa keys separadas con restricciones específicas para cada plataforma.

**P: ¿Cómo obtengo el SHA-1 de mi keystore?**
R: Para debug keystore:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Para release keystore:
```bash
keytool -list -v -keystore /path/to/my-release-key.keystore -alias my-key-alias
```
