#!/bin/sh

# Xcode Cloud Pre-Build Script
# Este script se ejecuta ANTES de que Xcode construya el proyecto
# Configura las variables de build de Xcode

set -e

echo "🔧 Configurando variables de build de Xcode..."

# Verificar que las variables de entorno estén configuradas
if [ -z "$GOOGLE_MAPS_API_KEY_IOS" ]; then
    echo "❌ Error: GOOGLE_MAPS_API_KEY_IOS no está configurada"
    echo "   Configúrala en App Store Connect → Xcode Cloud → Environment Variables"
    exit 1
fi

# Exportar la variable para que esté disponible durante el build
export GOOGLE_MAPS_API_KEY_IOS="$GOOGLE_MAPS_API_KEY_IOS"

echo "✅ GOOGLE_MAPS_API_KEY_IOS configurada (primeros 10 caracteres: ${GOOGLE_MAPS_API_KEY_IOS:0:10}...)"

# Configurar otras variables de build si es necesario
if [ -n "$CI_WORKSPACE" ]; then
    # Estamos en Xcode Cloud
    echo "📱 Ejecutando en Xcode Cloud"
    echo "   Workspace: $CI_WORKSPACE"
    echo "   Build Number: $CI_BUILD_NUMBER"
fi

echo "✅ Pre-build completado!"
