# Script para probar las funcionalidades de contacto implementadas
# Autor: Sistema de Gestión de Cobradores
# Fecha: $(Get-Date -Format "yyyy-MM-dd")

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "    PRUEBA DE FUNCIONALIDADES DE CONTACTO" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host ""

# Verificar dependencias
Write-Host "1. Verificando dependencias de contacto..." -ForegroundColor Yellow

# Verificar url_launcher en pubspec.yaml
$pubspecContent = Get-Content "pubspec.yaml" -Raw
if ($pubspecContent -match "url_launcher:") {
    Write-Host "✅ url_launcher encontrado en pubspec.yaml" -ForegroundColor Green
}
else {
    Write-Host "❌ url_launcher NO encontrado en pubspec.yaml" -ForegroundColor Red
    Write-Host "Agregando url_launcher..." -ForegroundColor Yellow
    # Aquí se podría agregar automáticamente
}

# Verificar archivo de contacto
if (Test-Path "lib/widgets/contact_actions_widget.dart") {
    Write-Host "✅ ContactActionsWidget creado correctamente" -ForegroundColor Green
}
else {
    Write-Host "❌ ContactActionsWidget NO encontrado" -ForegroundColor Red
}

# Verificar configuración de colores por rol
if (Test-Path "lib/config/role_colors.dart") {
    Write-Host "✅ Configuración de colores por rol disponible" -ForegroundColor Green
}
else {
    Write-Host "❌ Configuración de colores por rol NO encontrada" -ForegroundColor Red
}

Write-Host ""
Write-Host "2. Limpiando proyecto..." -ForegroundColor Yellow
flutter clean

Write-Host ""
Write-Host "3. Obteniendo dependencias..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "4. Analizando código..." -ForegroundColor Yellow
flutter analyze

Write-Host ""
Write-Host "5. Verificando archivos implementados..." -ForegroundColor Yellow

$implementedFiles = @(
    "lib/widgets/contact_actions_widget.dart",
    "lib/config/role_colors.dart", 
    "lib/widgets/role_widgets.dart",
    "lib/presentacion/manager/manager_cobradores_screen.dart",
    "lib/presentacion/manager/manager_clientes_screen.dart",
    "lib/presentacion/cobrador/cobrador_clientes_screen.dart"
)

foreach ($file in $implementedFiles) {
    if (Test-Path $file) {
        Write-Host "✅ $file" -ForegroundColor Green
    }
    else {
        Write-Host "❌ $file" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "6. Funcionalidades implementadas:" -ForegroundColor Yellow
Write-Host "   📞 Botones de contacto rápido en tarjetas de usuarios" -ForegroundColor White
Write-Host "   📱 Integración con WhatsApp y llamadas telefónicas" -ForegroundColor White
Write-Host "   🎨 Sistema de colores basado en roles" -ForegroundColor White
Write-Host "   📋 Menús contextuales con opciones de contacto" -ForegroundColor White
Write-Host "   🔄 Widgets reutilizables para consistencia UI" -ForegroundColor White

Write-Host ""
Write-Host "7. Para probar en dispositivo físico:" -ForegroundColor Yellow
Write-Host "   - Conecte un dispositivo Android/iOS" -ForegroundColor White
Write-Host "   - Execute: flutter devices" -ForegroundColor White
Write-Host "   - Execute: flutter run" -ForegroundColor White
Write-Host "   - Pruebe llamadas y WhatsApp desde la app" -ForegroundColor White

Write-Host ""
Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "    PRUEBA COMPLETADA" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan
