#!/bin/bash

# Script para configurar API keys desde .env para builds de iOS

# Leer el archivo .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
    echo "✅ Variables de entorno cargadas desde .env"
else
    echo "❌ Archivo .env no encontrado"
    exit 1
fi

# Crear archivo con la API key para iOS
echo "GOOGLE_MAPS_API_KEY_IOS=$GOOGLE_MAPS_API_KEY_IOS" > ios/Flutter/ApiKeys.xcconfig

# Agregar al Release.xcconfig si no está incluido
if ! grep -q "ApiKeys.xcconfig" ios/Flutter/Release.xcconfig; then
    echo "#include? \"ApiKeys.xcconfig\"" >> ios/Flutter/Release.xcconfig
    echo "✅ ApiKeys.xcconfig agregado a Release.xcconfig"
fi

# Agregar al Debug.xcconfig si no está incluido
if ! grep -q "ApiKeys.xcconfig" ios/Flutter/Debug.xcconfig; then
    echo "#include? \"ApiKeys.xcconfig\"" >> ios/Flutter/Debug.xcconfig
    echo "✅ ApiKeys.xcconfig agregado a Debug.xcconfig"
fi

echo "✅ Configuración de API keys completada"
echo "📝 API Key iOS: ${GOOGLE_MAPS_API_KEY_IOS:0:20}..."
