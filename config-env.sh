#!/bin/bash

# Script para cambiar entre configuraciones de desarrollo y producción

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Configurador de Entorno - Cobrador App${NC}"
echo "======================================="

# Archivos de configuración
ENV_FILE=".env"
ENV_DEV_FILE=".env.development"
ENV_PROD_FILE=".env.production"

# Crear archivos de configuración si no existen
if [ ! -f "$ENV_DEV_FILE" ]; then
    echo -e "${YELLOW}📝 Creando $ENV_DEV_FILE...${NC}"
    cat > "$ENV_DEV_FILE" << EOF
# Configuración de Desarrollo
GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
APP_NAME=Cobrador Dev
APP_VERSION=1.0.0-dev
BASE_URL=http://192.168.5.44:8000/api
WEBSOCKET_URL=ws://192.168.5.44:3001
EOF
fi

if [ ! -f "$ENV_PROD_FILE" ]; then
    echo -e "${YELLOW}📝 Creando $ENV_PROD_FILE...${NC}"
    cat > "$ENV_PROD_FILE" << EOF
# Configuración de Producción
GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
APP_NAME=Cobrador
APP_VERSION=1.0.0
BASE_URL=https://cobrador-web-production.up.railway.app/api
WEBSOCKET_URL=wss://websocket-server-cobrador-production.up.railway.app
EOF
fi

# Mostrar configuración actual
echo -e "${BLUE}📋 Configuración actual:${NC}"
if [ -f "$ENV_FILE" ]; then
    echo "  BASE_URL: $(grep '^BASE_URL=' $ENV_FILE | cut -d'=' -f2-)"
    echo "  WEBSOCKET_URL: $(grep '^WEBSOCKET_URL=' $ENV_FILE | cut -d'=' -f2-)"
fi

echo ""
echo -e "${YELLOW}¿Qué configuración quieres usar?${NC}"
echo "1) Desarrollo (local)"
echo "2) Producción (Railway)"
echo "3) Mostrar configuraciones disponibles"
echo "4) Crear configuración personalizada"
echo "0) Cancelar"

read -p "Selecciona una opción (0-4): " choice

case $choice in
    1)
        echo -e "${GREEN}🔄 Configurando para DESARROLLO...${NC}"
        cp "$ENV_DEV_FILE" "$ENV_FILE"
        echo -e "${GREEN}✅ Configurado para desarrollo${NC}"
        echo "  🌐 API: http://192.168.5.44:8000/api"
        echo "  🔌 WebSocket: ws://192.168.5.44:3001"
        ;;
    2)
        echo -e "${GREEN}🔄 Configurando para PRODUCCIÓN...${NC}"
        cp "$ENV_PROD_FILE" "$ENV_FILE"
        echo -e "${GREEN}✅ Configurado para producción${NC}"
        echo "  🌐 API: https://cobrador-web-production.up.railway.app/api"
        echo "  🔌 WebSocket: wss://websocket-server-cobrador-production.up.railway.app"
        ;;
    3)
        echo -e "${BLUE}📋 Configuraciones disponibles:${NC}"
        echo ""
        echo -e "${YELLOW}DESARROLLO:${NC}"
        cat "$ENV_DEV_FILE"
        echo ""
        echo -e "${YELLOW}PRODUCCIÓN:${NC}"
        cat "$ENV_PROD_FILE"
        ;;
    4)
        echo -e "${YELLOW}📝 Configuración personalizada${NC}"
        read -p "BASE_URL: " base_url
        read -p "WEBSOCKET_URL: " websocket_url
        
        cat > "$ENV_FILE" << EOF
GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
APP_NAME=Cobrador Custom
APP_VERSION=1.0.0-custom
BASE_URL=$base_url
WEBSOCKET_URL=$websocket_url
EOF
        echo -e "${GREEN}✅ Configuración personalizada aplicada${NC}"
        ;;
    0)
        echo -e "${YELLOW}❌ Operación cancelada${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}❌ Opción inválida${NC}"
        exit 1
        ;;
esac

echo ""
echo -e "${BLUE}🔧 Configuración final:${NC}"
cat "$ENV_FILE"

echo ""
echo -e "${GREEN}🚀 ¡Listo! Puedes ejecutar 'flutter run' ahora${NC}"
