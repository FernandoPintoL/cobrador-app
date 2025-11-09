# Configuración de Xcode Cloud / App Store Connect

## Error: "Command exited with non-zero exit-code: 65"

Este error ocurre durante el build en Xcode Cloud o cuando subes a App Store Connect. Aquí están las soluciones:

## Solución 1: Configurar Variables de Entorno en App Store Connect

El error más común es que las **API keys de Google Maps no están configuradas** en el ambiente de CI/CD.

### Pasos:

1. Ve a [App Store Connect](https://appstoreconnect.apple.com/)

2. Selecciona tu app **CeF Pro**

3. Ve a la sección **Xcode Cloud** (en el menú lateral)

4. Click en **Settings** o **Configuración**

5. Busca la sección **Environment Variables** (Variables de Entorno)

6. Agrega las siguientes variables:

   | Variable Name | Value | Secret |
   |---------------|-------|---------|
   | `GOOGLE_MAPS_API_KEY` | Tu API key de Android | ✅ Sí |
   | `GOOGLE_MAPS_API_KEY_IOS` | Tu API key de iOS | ✅ Sí |
   | `BASE_URL` | `https://cobrador-web-production.up.railway.app/api` | ❌ No |
   | `WEBSOCKET_URL` | `wss://websocket-server-cobrador-production.up.railway.app` | ❌ No |
   | `NODE_WEBSOCKET_URL` | `https://websocket-server-cobrador-production.up.railway.app` | ❌ No |

7. Marca las API keys como **Secret** (checkbox)

8. Guarda los cambios

9. Inicia un nuevo build

## Solución 2: Verificar Configuración de Firma de Código

El error también puede ocurrir si la firma de código no está configurada correctamente.

### En Xcode:

1. Abre `ios/Runner.xcworkspace`

2. Selecciona el target **Runner**

3. Ve a **Signing & Capabilities**

4. Asegúrate de que:
   - ✅ **Automatically manage signing** está habilitado
   - ✅ **Team** está seleccionado: `DCQ23C3NQB`
   - ✅ **Bundle Identifier**: `com.fpl.cobrador.cobradorApp`

### En App Store Connect (Xcode Cloud):

1. Ve a **Xcode Cloud** → **Settings**

2. En la sección **Signing**, verifica que:
   - Tu **Development Team** está seleccionado
   - Los **Provisioning Profiles** están correctos

## Solución 3: Usar Xcode Cloud con el Script Post-Clone

He creado un script `ci_scripts/ci_post_clone.sh` que se ejecuta automáticamente en Xcode Cloud.

Este script:
- ✅ Crea el archivo `.env` desde las variables de entorno
- ✅ Configura Flutter
- ✅ Instala dependencias de CocoaPods

**IMPORTANTE**: Para que funcione, debes configurar las variables de entorno en App Store Connect (ver Solución 1).

## Solución 4: Build Local de Archive

Si quieres hacer el archive localmente y subirlo manualmente:

### Paso 1: Preparar el ambiente
```bash
# Asegúrate de que .env está configurado
cat .env

# Debería mostrar tus API keys reales, no los placeholders
```

### Paso 2: Limpiar y preparar
```bash
cd /Users/fpl3001/Documents/cobrador-app

flutter clean
flutter pub get
cd ios
pod install
cd ..
```

### Paso 3: Abrir Xcode
```bash
open ios/Runner.xcworkspace
```

### Paso 4: En Xcode

1. Selecciona **Any iOS Device (arm64)** como destino

2. Ve a **Product** → **Clean Build Folder** (⇧⌘K)

3. Ve a **Product** → **Archive**

4. Cuando termine:
   - Click en **Distribute App**
   - Selecciona **App Store Connect**
   - Sigue el asistente

### Paso 5: Esperar validación

App Store Connect validará el archive. Esto puede tomar 10-30 minutos.

## Solución 5: Verificar que CocoaPods está configurado

```bash
cd ios
pod deintegrate
pod install
```

## Verificar que el build funciona localmente

Antes de subir a App Store Connect, verifica que funciona localmente:

```bash
flutter build ios --release --no-codesign
```

Si este comando falla, el problema está en tu código/configuración local.
Si este comando funciona, el problema está en la configuración de Xcode Cloud.

## Logs de Error Comunes

### Error: "Google Maps API Key is missing"

**Causa**: La variable de entorno `GOOGLE_MAPS_API_KEY_IOS` no está configurada en Xcode Cloud.

**Solución**: Configurar las variables de entorno (Solución 1).

### Error: "The sandbox is not in sync with the Podfile.lock"

**Causa**: Las dependencias de CocoaPods no están actualizadas.

**Solución**: Asegúrate de que `ci_post_clone.sh` se está ejecutando, o ejecuta manualmente:
```bash
cd ios
pod install
```

### Error: "Code signing is required"

**Causa**: La configuración de firma de código no es correcta.

**Solución**: Verificar la configuración de firma (Solución 2).

## Obtener Logs Detallados de Xcode Cloud

1. Ve a App Store Connect

2. Xcode Cloud → **Builds**

3. Click en el build fallido

4. Ve a la pestaña **Logs**

5. Busca líneas con `error:` o `warning:`

6. Los errores específicos te dirán exactamente qué falta

## Recursos Adicionales

- [Xcode Cloud Documentation](https://developer.apple.com/documentation/xcode/xcode-cloud)
- [Environment Variables in Xcode Cloud](https://developer.apple.com/documentation/xcode/environment-variable-reference)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)

## Contacto

Si ninguna de estas soluciones funciona:

1. Copia los logs completos de Xcode Cloud
2. Busca la línea exacta del error (después de "error:")
3. Comparte esos logs para diagnóstico específico
