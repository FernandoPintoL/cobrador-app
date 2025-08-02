# Script para builds de producción
# Uso: .\build_production.ps1

Write-Host "🔧 Iniciando build de producción..." -ForegroundColor Green

# Limpiar build anterior
Write-Host "🧹 Limpiando build anterior..." -ForegroundColor Yellow
flutter clean

# Obtener dependencias
Write-Host "📦 Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

# Build para Android
Write-Host "🏗️ Construyendo APK de producción..." -ForegroundColor Yellow
flutter build apk --release

Write-Host "✅ Build completado exitosamente!" -ForegroundColor Green
Write-Host "📱 APK disponible en: build/app/outputs/flutter-apk/app-release.apk" -ForegroundColor Cyan

Write-Host "⚠️  Nota: Para cambiar la API key de Google Maps, edita:" -ForegroundColor Yellow
Write-Host "   android/app/src/main/AndroidManifest.xml" -ForegroundColor Cyan 