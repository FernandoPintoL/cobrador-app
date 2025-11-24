#!/bin/bash

# Script para construir y generar IPA para App Store
# Versión 1.0.2

set -e  # Salir si hay algún error

echo "🚀 Iniciando proceso de build para App Store..."
echo "📱 Versión: 1.0.2+3"
echo ""

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Limpiar proyecto
echo -e "${BLUE}🧹 Paso 1: Limpiando proyecto...${NC}"
flutter clean
echo -e "${GREEN}✅ Limpieza completada${NC}"
echo ""

# 2. Obtener dependencias
echo -e "${BLUE}📦 Paso 2: Obteniendo dependencias...${NC}"
flutter pub get
echo -e "${GREEN}✅ Dependencias obtenidas${NC}"
echo ""

# 3. Instalar pods
echo -e "${BLUE}🍎 Paso 3: Instalando CocoaPods...${NC}"
cd ios
pod install
cd ..
echo -e "${GREEN}✅ CocoaPods instalados${NC}"
echo ""

# 4. Verificar que no hay errores de análisis
echo -e "${BLUE}🔍 Paso 4: Analizando código...${NC}"
flutter analyze
echo -e "${GREEN}✅ Análisis completado${NC}"
echo ""

# 5. Build para iOS en modo release
echo -e "${BLUE}🏗️  Paso 5: Construyendo aplicación para iOS (esto puede tardar varios minutos)...${NC}"
flutter build ios --release --no-codesign
echo -e "${GREEN}✅ Build de iOS completado${NC}"
echo ""

# 6. Instrucciones para Xcode
echo -e "${BLUE}📝 Paso 6: Preparación para App Store${NC}"
echo ""
echo "Para generar el archivo IPA y subirlo a App Store, sigue estos pasos:"
echo ""
echo "1. Abre el proyecto en Xcode:"
echo -e "   ${GREEN}open ios/Runner.xcworkspace${NC}"
echo ""
echo "2. En Xcode:"
echo "   - Selecciona 'Any iOS Device (arm64)' como destino"
echo "   - Ve a Product > Archive"
echo "   - Espera a que se complete el archive"
echo ""
echo "3. Cuando se abra el Organizer:"
echo "   - Selecciona el archive que acabas de crear"
echo "   - Click en 'Distribute App'"
echo "   - Selecciona 'App Store Connect'"
echo "   - Selecciona 'Upload'"
echo "   - Sigue los pasos del asistente"
echo ""
echo "4. En App Store Connect (https://appstoreconnect.apple.com):"
echo "   - Ve a tu aplicación"
echo "   - Crea una nueva versión (1.0.2)"
echo "   - Agrega las notas de la versión desde CHANGELOG.md"
echo "   - Selecciona el build que acabas de subir"
echo "   - Envía para revisión"
echo ""
echo -e "${GREEN}✨ ¡Proceso completado con éxito!${NC}"
echo ""
echo -e "${BLUE}📋 Notas de la versión 1.0.2:${NC}"
echo "• Corregido overflow en AppBar de créditos"
echo "• Corregido overflow en pantalla de detalle"
echo "• Mejorado manejo de texto largo en cards"
echo "• Optimización de layouts para pantallas pequeñas"
echo ""
