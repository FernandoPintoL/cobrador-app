#!/bin/sh

# Xcode Cloud Post-Clone Script
# Este script se ejecuta después de clonar el repositorio en Xcode Cloud
# Configura las API keys y dependencias necesarias para el build

set -e

echo "🚀 Iniciando configuración de CI..."

# Crear archivo .env desde las variables de entorno de Xcode Cloud
# En Xcode Cloud, configura estas variables de entorno en:
# App Store Connect → Tu App → Xcode Cloud → Settings → Environment Variables

if [ -n "$GOOGLE_MAPS_API_KEY" ] && [ -n "$GOOGLE_MAPS_API_KEY_IOS" ]; then
    echo "✅ Creando archivo .env con variables de entorno..."

    cat > "$CI_WORKSPACE/.env" <<EOF
GOOGLE_MAPS_API_KEY=${GOOGLE_MAPS_API_KEY}
GOOGLE_MAPS_API_KEY_IOS=${GOOGLE_MAPS_API_KEY_IOS}
APP_NAME="CeF Pro"
APP_VERSION=1.0.0
BASE_URL=${BASE_URL:-https://cobrador-web-production.up.railway.app/api}
REALTIME_TRANSPORT=socketio
WEBSOCKET_URL=${WEBSOCKET_URL:-wss://websocket-server-cobrador-production.up.railway.app}
NODE_WEBSOCKET_URL=${NODE_WEBSOCKET_URL:-https://websocket-server-cobrador-production.up.railway.app}
EOF

else
    echo "⚠️  Advertencia: Variables de entorno GOOGLE_MAPS_API_KEY y/o GOOGLE_MAPS_API_KEY_IOS no están configuradas"
    echo "   Configúralas en App Store Connect → Xcode Cloud → Environment Variables"
fi

# Instalar Flutter si es necesario (para Xcode Cloud)
if ! command -v flutter &> /dev/null; then
    echo "📦 Instalando Flutter..."

    # Clonar Flutter
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"

    # Agregar Flutter al PATH
    export PATH="$HOME/flutter/bin:$PATH"

    # Configurar Flutter
    flutter config --no-analytics
    flutter precache --ios
fi

# Verificar versión de Flutter
echo "📱 Flutter version:"
flutter --version

# Limpiar y obtener dependencias
echo "📦 Obteniendo dependencias de Flutter..."
cd "$CI_WORKSPACE"
flutter clean
flutter pub get

# Instalar CocoaPods dependencies
echo "📦 Instalando CocoaPods..."
cd "$CI_WORKSPACE/ios"
pod install

echo "✅ Configuración de CI completada!"
