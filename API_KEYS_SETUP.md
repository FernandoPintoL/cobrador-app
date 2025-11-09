# Configuración Rápida de API Keys

## Para desarrolladores nuevos

### 1. Configurar variables de entorno

```bash
# Copiar el archivo de ejemplo
cp .env.example .env

# Ejecutar el script de configuración
./setup_api_keys.sh
```

### 2. Editar `.env` con tus API keys

Abre `.env` y reemplaza los placeholders:

```bash
GOOGLE_MAPS_API_KEY=tu_api_key_de_android_aqui
GOOGLE_MAPS_API_KEY_IOS=tu_api_key_de_ios_aqui
```

### 3. Ejecutar el script de configuración nuevamente

```bash
./setup_api_keys.sh
```

Esto copiará automáticamente las API keys a los archivos de configuración correctos.

## ¿Dónde obtener las API Keys?

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto (o crea uno nuevo)
3. Habilita estas APIs:
   - Maps SDK for Android
   - Maps SDK for iOS
4. Ve a **Credentials** → **Create Credentials** → **API Key**
5. Crea **DOS API keys separadas** (una para Android, una para iOS)

### Configurar restricciones de seguridad

#### Para Android:
- Tipo de restricción: **Android apps**
- Package name: `com.fpl.cobrador.cobrador_app`
- SHA-1 fingerprint: Ejecuta este comando y copia el resultado:
  ```bash
  # Para debug
  keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep SHA1

  # Para release (cuando tengas tu keystore)
  keytool -list -v -keystore /path/to/release.keystore -alias your-alias | grep SHA1
  ```

#### Para iOS:
- Tipo de restricción: **iOS apps**
- Bundle ID: `com.fpl.cobrador.cobradorApp`

## Construcción del proyecto

### Android
```bash
flutter build apk --release
# o para App Bundle (Google Play)
flutter build appbundle --release
```

### iOS
1. Asegúrate de que `.env` está configurado correctamente
2. Abre Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
3. Configura las User-Defined Settings:
   - Selecciona el target **Runner**
   - Ve a **Build Settings**
   - Busca "User-Defined"
   - Agrega: `GOOGLE_MAPS_API_KEY_IOS` = valor desde tu .env

4. Agrega un Run Script Phase:
   - Ve a **Build Phases**
   - Click **+** → **New Run Script Phase**
   - Arrastra el nuevo script phase ANTES de "Compile Sources"
   - Pega este código:
     ```bash
     source "${SRCROOT}/scripts/load_env.sh"
     ```

5. Construye:
   - **Product** → **Clean Build Folder** (⇧⌘K)
   - **Product** → **Archive**

## Troubleshooting

### "For development purposes only" en el mapa

**Causa**: Tu API key no tiene restricciones configuradas o está usando una key sin las APIs habilitadas.

**Solución**:
1. Ve a Google Cloud Console
2. Verifica que Maps SDK for Android/iOS esté habilitado
3. Configura las restricciones correctamente
4. Espera unos minutos para que los cambios se propaguen

### Error al construir iOS

**Causa**: El script `load_env.sh` no tiene permisos de ejecución.

**Solución**:
```bash
chmod +x ios/scripts/load_env.sh
```

### Android no encuentra la API key

**Causa**: `local.properties` no tiene la API key.

**Solución**:
```bash
./setup_api_keys.sh
```

O edita manualmente `android/local.properties` y agrega:
```properties
GOOGLE_MAPS_API_KEY=tu_api_key_aqui
```

## ⚠️ Seguridad

**NUNCA** commitees estos archivos:
- `.env`
- `android/local.properties`
- `ios/Runner/GoogleService-Info.plist`

Estos archivos ya están en `.gitignore` para protegerte.

Si accidentalmente expones una API key:
1. Ve inmediatamente a Google Cloud Console
2. **Deshabilita** la API key comprometida
3. Crea una nueva con las restricciones apropiadas
4. Actualiza tu `.env` local
5. Ejecuta `./setup_api_keys.sh`

## Más información

Ver [SECURITY.md](./SECURITY.md) para una guía completa de seguridad.
