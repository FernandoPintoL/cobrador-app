# Script para verificar y corregir el archivo .env
# Uso: .\verificar_env.ps1

Write-Host "🔍 Verificando archivo .env..." -ForegroundColor Green

# Verificar si el archivo existe
if (Test-Path .env) {
    Write-Host "✅ Archivo .env encontrado" -ForegroundColor Green
    
    # Mostrar contenido
    Write-Host "📄 Contenido actual:" -ForegroundColor Yellow
    Get-Content .env
    
    # Verificar codificación
    Write-Host "`n🔍 Verificando codificación..." -ForegroundColor Yellow
    $content = Get-Content .env -Raw
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($content)
    
    Write-Host "Bytes del archivo:" -ForegroundColor Cyan
    $bytes | ForEach-Object { "{0:X2}" -f $_ } | Out-String
    
} else {
    Write-Host "❌ Archivo .env no encontrado" -ForegroundColor Red
    Write-Host "Creando archivo .env..." -ForegroundColor Yellow
    
    # Crear archivo .env
    @"
GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
APP_NAME=Cobrador
APP_VERSION=1.0.0
"@ | Out-File -FilePath .env -Encoding UTF8
    
    Write-Host "✅ Archivo .env creado" -ForegroundColor Green
}

Write-Host "`n🎯 Verificación completada" -ForegroundColor Green 