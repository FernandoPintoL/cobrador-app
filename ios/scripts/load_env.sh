#!/bin/bash

# Script para cargar variables de entorno desde .env al build de iOS
ENV_FILE="${SRCROOT}/../../.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Warning: .env file not found at $ENV_FILE"
  echo "GOOGLE_MAPS_API_KEY_IOS=YOUR_API_KEY_HERE"
  exit 0
fi

# Leer la API key de iOS desde .env
GOOGLE_MAPS_API_KEY_IOS=$(grep "^GOOGLE_MAPS_API_KEY_IOS=" "$ENV_FILE" | cut -d '=' -f2)

# Exportar como variable de build
echo "GOOGLE_MAPS_API_KEY_IOS=$GOOGLE_MAPS_API_KEY_IOS"
