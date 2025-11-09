#!/bin/bash

# Script de configuración de API keys
# Este script ayuda a configurar las API keys de Google Maps de forma segura

set -e

echo "🔐 Configuración de API Keys - Cobrador App"
echo "============================================"
echo ""

# Verificar que existe .env
if [ ! -f ".env" ]; then
    echo "❌ Error: No se encontró el archivo .env"
    echo "   Crea uno copiando .env.example:"
    echo "   cp .env.example .env"
    echo ""
    echo "   Luego edita .env y agrega tus API keys de Google Maps"
    exit 1
fi

# Leer API keys desde .env
ANDROID_KEY=$(grep "^GOOGLE_MAPS_API_KEY=" .env | cut -d '=' -f2)
IOS_KEY=$(grep "^GOOGLE_MAPS_API_KEY_IOS=" .env | cut -d '=' -f2)

# Validar que las keys no sean los placeholders
if [ "$ANDROID_KEY" = "YOUR_ANDROID_GOOGLE_MAPS_API_KEY_HERE" ] || [ -z "$ANDROID_KEY" ]; then
    echo "⚠️  Advertencia: GOOGLE_MAPS_API_KEY no está configurada en .env"
    echo "   Edita el archivo .env y configura tu API key de Android"
fi

if [ "$IOS_KEY" = "YOUR_IOS_GOOGLE_MAPS_API_KEY_HERE" ] || [ -z "$IOS_KEY" ]; then
    echo "⚠️  Advertencia: GOOGLE_MAPS_API_KEY_IOS no está configurada en .env"
    echo "   Edita el archivo .env y configura tu API key de iOS"
fi

# Configurar Android local.properties
if [ ! -z "$ANDROID_KEY" ] && [ "$ANDROID_KEY" != "YOUR_ANDROID_GOOGLE_MAPS_API_KEY_HERE" ]; then
    echo "✅ Configurando API key de Android en local.properties..."

    # Verificar si ya existe la key en local.properties
    if grep -q "^GOOGLE_MAPS_API_KEY=" android/local.properties 2>/dev/null; then
        # Reemplazar la existente
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s/^GOOGLE_MAPS_API_KEY=.*/GOOGLE_MAPS_API_KEY=$ANDROID_KEY/" android/local.properties
        else
            sed -i "s/^GOOGLE_MAPS_API_KEY=.*/GOOGLE_MAPS_API_KEY=$ANDROID_KEY/" android/local.properties
        fi
    else
        # Agregar nueva
        echo "" >> android/local.properties
        echo "# Google Maps API Key - NO COMMITEAR ESTE ARCHIVO" >> android/local.properties
        echo "GOOGLE_MAPS_API_KEY=$ANDROID_KEY" >> android/local.properties
    fi
fi

echo ""
echo "✅ Configuración completada!"
echo ""
echo "📝 Próximos pasos:"
echo "   1. Verifica que tus API keys tengan las restricciones correctas en Google Cloud Console"
echo "   2. Android: Restricción por package name (com.fpl.cobrador.cobrador_app)"
echo "   3. iOS: Restricción por bundle ID (com.fpl.cobrador.cobradorApp)"
echo ""
echo "   Para más información, consulta SECURITY.md"
echo ""
