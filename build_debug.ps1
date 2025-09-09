param(
    [switch]$Clean,
    [switch]$VerboseLogs
)

$ErrorActionPreference = 'Stop'

function Write-Info($msg) { Write-Host "[build_debug] $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "[build_debug] $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Warning "[build_debug] $msg" }
function Write-Err($msg)  { Write-Error "[build_debug] $msg" }

try {
    Write-Info "Proyecto: $PSScriptRoot"
    Set-Location $PSScriptRoot

    if ($Clean) {
        Write-Info "Limpiando proyecto (flutter clean)..."
        flutter clean
    }

    Write-Info "Resolviendo dependencias (flutter pub get)..."
    flutter pub get

    $args = @('build','apk','--debug')
    if ($VerboseLogs) { $args += '--verbose' }

    Write-Info "Compilando APK debug (flutter $($args -join ' '))..."
    flutter $args

    $apkPath = Join-Path $PSScriptRoot 'build\app\outputs\flutter-apk\app-debug.apk'
    if (Test-Path $apkPath) {
        Write-Ok "APK generado correctamente: $apkPath"
        Write-Host "\nCómo instalar en un dispositivo:" -ForegroundColor Yellow
        Write-Host "  1) Copia el APK al teléfono y ábrelo, o" -ForegroundColor Yellow
        Write-Host "  2) Con ADB: adb install -r `"$apkPath`"" -ForegroundColor Yellow
        exit 0
    } else {
        Write-Err "No se encontró el APK en la ruta esperada: $apkPath"
        Write-Host "Revisa la salida de Flutter para detalles." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Err $_.Exception.Message
    exit 1
}