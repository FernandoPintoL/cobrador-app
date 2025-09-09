# Guía de configuración del archivo .env

Este proyecto utiliza `flutter_dotenv` para cargar variables de entorno desde un archivo `.env` incluido como asset. A continuación se detalla qué variables admite la aplicación, su propósito y ejemplos para entornos de Desarrollo y Producción.

Importante:
- Después de modificar `.env`, debes reiniciar completamente la app (parar y volver a ejecutar) para que los cambios se apliquen.
- No publiques tu `.env` con datos sensibles (API keys, URLs privadas). Usa `env.example` como plantilla sin secretos.

## Variables soportadas

### 1) Identidad de la app
- APP_NAME: Nombre que se mostrará en algunas partes de la app.
- APP_VERSION: Versión mostrada en pantallas/ajustes.

Ejemplo:
APP_NAME=Cobrador
APP_VERSION=1.0.0

### 2) Google Maps
- GOOGLE_MAPS_API_KEY: Clave de Maps para Android/iOS/Web si aplica.

Ejemplo:
GOOGLE_MAPS_API_KEY=AIza...tu_clave...

### 3) API HTTP (backend Laravel)
- BASE_URL: URL base de la API REST. Debe incluir o no el sufijo /api según esté configurado tu backend.
  - La app intenta deducir el host y si usa TLS desde aquí cuando no se especifica configuración explícita de WebSocket.

Ejemplos:
# Desarrollo (HTTP)
BASE_URL=http://192.168.100.21:8000/api

# Producción (HTTPS)
# BASE_URL=https://tu-dominio.com/api

### 4) Tiempo Real (Laravel Reverb / Pusher Protocol)
Existen dos formas de configurar el WebSocket. La app elegirá en este orden de prioridad:
1. Variables REVERB_* (si REVERB_HOST está definido)
2. WEBSOCKET_URL (si está definido)
3. Deducción automática desde BASE_URL (si nada anterior existe)

Variables disponibles:
- REVERB_APP_KEY: Clave pública de la app Reverb (equivalente a Pusher key). Opcional si el cliente Echo usa instancia preconfigurada, pero recomendable definirla.
- REVERB_HOST: Dominio o IP del servidor de WebSockets (Reverb). Si la defines, se prioriza esta configuración.
- REVERB_PORT: Puerto donde escucha Reverb. Por defecto 6001 para ws y 443 para wss.
- REVERB_SCHEME: http o https. Define si el socket debe usar ws (http) o wss (https). Para TLS usa https.
- REVERB_CLUSTER: Cluster de Pusher (si usas Pusher). Para Reverb suele no importar, deja mt1 por compatibilidad.
- REVERB_AUTH_ENDPOINT: Endpoint HTTP en el backend Laravel para autenticar canales privados/presencia. Por defecto se deduce: <BASE_HTTP_ORIGIN>/broadcasting/auth.
- WEBSOCKET_URL: URL completa del socket si prefieres simplificar. Formato: ws://host:puerto o wss://host:puerto.

Notas y validaciones que hace la app:
- Si usas WEBSOCKET_URL, la app normaliza el puerto y valida rango 1–65535.
- Si REVERB_SCHEME es https, el socket usará wss y el puerto por defecto será 443 si no se define REVERB_PORT.
- Si no defines nada de REVERB_* ni WEBSOCKET_URL, la app intentará construir ws(s)://<host>:(6001|443) a partir de BASE_URL.

Ejemplos desarrollo (sin TLS):
# Opción A: usando REVERB_*
REVERB_APP_KEY=local_key
REVERB_HOST=192.168.100.21
REVERB_PORT=6001
REVERB_SCHEME=http
REVERB_CLUSTER=mt1
# REVERB_AUTH_ENDPOINT=http://192.168.100.21:8000/broadcasting/auth

# Opción B: usando WEBSOCKET_URL
WEBSOCKET_URL=ws://192.168.100.21:6001

Ejemplos producción (con TLS):
# Opción A: usando REVERB_*
REVERB_APP_KEY=prod_key
REVERB_HOST=tu-dominio.com
REVERB_SCHEME=https
# Si tu Reverb escucha en 443, puedes omitir REVERB_PORT; si usa 6002 u otro, defínelo.
# REVERB_PORT=443
REVERB_CLUSTER=mt1
REVERB_AUTH_ENDPOINT=https://tu-dominio.com/broadcasting/auth

# Opción B: usando WEBSOCKET_URL
WEBSOCKET_URL=wss://tu-dominio.com:443

## Buenas prácticas y solución de problemas
- Usa direcciones IP locales reales y puertos correctos. Reverb normalmente escucha en 6001 (ws) y 6002 (opcional) o 443 si está detrás de proxy TLS.
- Si tienes un valor como ws://192.168.100.21:001, el sistema lo interpretará como puerto 1; corrígelo a 6001 si ese es el puerto real.
- Asegúrate que el backend Laravel tenga configurado broadcasting y el endpoint /broadcasting/auth accesible desde la app.
- Si usas HTTPS/WSS, confirma que el certificado sea válido. En Android/iOS, certificados autofirmados pueden bloquear la conexión.
- Cambiar variables requiere reiniciar la app (no basta hot reload) porque `.env` se lee al inicio.

## Archivos útiles
- env.example: plantilla editable sin secretos. Copia su contenido a `.env` y ajusta tus valores.
- config-env.bat / config-env.sh: scripts auxiliares (si los usas en tu flujo) para configurar variables o preparar builds.

## Dónde se usan las variables en el código
- lib/config/app_bootstrap.dart
  - Carga `.env` y define la estrategia de selección para WebSocket (REVERB_* -> WEBSOCKET_URL -> BASE_URL).
- lib/datos/servicios/websocket_service.dart
  - Aplica WEBSOCKET_URL si existe y valida host/puerto.
  - Usa REVERB_APP_KEY, REVERB_HOST, REVERB_PORT, REVERB_SCHEME, REVERB_CLUSTER y REVERB_AUTH_ENDPOINT cuando se proveen.

Si necesitas ayuda para tu entorno específico (Reverb detrás de Nginx, Railway, etc.), comparte tu topología (dominios/puertos) y te doy la plantilla exacta.
