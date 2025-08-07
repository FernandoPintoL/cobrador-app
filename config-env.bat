@echo off
title Configurador de Entorno - Cobrador App

echo.
echo 🔧 Configurador de Entorno - Cobrador App
echo =======================================

rem Archivos de configuración
set ENV_FILE=.env
set ENV_DEV_FILE=.env.development
set ENV_PROD_FILE=.env.production

rem Crear archivos de configuración si no existen
if not exist "%ENV_DEV_FILE%" (
    echo 📝 Creando %ENV_DEV_FILE%...
    (
        echo # Configuración de Desarrollo
        echo GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
        echo APP_NAME=Cobrador Dev
        echo APP_VERSION=1.0.0-dev
        echo BASE_URL=http://192.168.5.44:8000/api
        echo WEBSOCKET_URL=ws://192.168.5.44:3001
    ) > "%ENV_DEV_FILE%"
)

if not exist "%ENV_PROD_FILE%" (
    echo 📝 Creando %ENV_PROD_FILE%...
    (
        echo # Configuración de Producción
        echo GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
        echo APP_NAME=Cobrador
        echo APP_VERSION=1.0.0
        echo BASE_URL=https://cobrador-web-production.up.railway.app/api
        echo WEBSOCKET_URL=wss://websocket-server-cobrador-production.up.railway.app
    ) > "%ENV_PROD_FILE%"
)

rem Mostrar configuración actual
echo.
echo 📋 Configuración actual:
if exist "%ENV_FILE%" (
    for /f "tokens=2 delims==" %%i in ('findstr "^BASE_URL=" "%ENV_FILE%"') do echo   BASE_URL: %%i
    for /f "tokens=2 delims==" %%i in ('findstr "^WEBSOCKET_URL=" "%ENV_FILE%"') do echo   WEBSOCKET_URL: %%i
)

echo.
echo ¿Qué configuración quieres usar?
echo 1^) Desarrollo ^(local^)
echo 2^) Producción ^(Railway^)
echo 3^) Mostrar configuraciones disponibles
echo 4^) Crear configuración personalizada
echo 0^) Cancelar

set /p choice="Selecciona una opción (0-4): "

if "%choice%"=="1" (
    echo.
    echo 🔄 Configurando para DESARROLLO...
    copy "%ENV_DEV_FILE%" "%ENV_FILE%" >nul
    echo ✅ Configurado para desarrollo
    echo   🌐 API: http://192.168.5.44:8000/api
    echo   🔌 WebSocket: ws://192.168.5.44:3001
) else if "%choice%"=="2" (
    echo.
    echo 🔄 Configurando para PRODUCCIÓN...
    copy "%ENV_PROD_FILE%" "%ENV_FILE%" >nul
    echo ✅ Configurado para producción
    echo   🌐 API: https://cobrador-web-production.up.railway.app/api
    echo   🔌 WebSocket: wss://websocket-server-cobrador-production.up.railway.app
) else if "%choice%"=="3" (
    echo.
    echo 📋 Configuraciones disponibles:
    echo.
    echo DESARROLLO:
    type "%ENV_DEV_FILE%"
    echo.
    echo PRODUCCIÓN:
    type "%ENV_PROD_FILE%"
) else if "%choice%"=="4" (
    echo.
    echo 📝 Configuración personalizada
    set /p base_url="BASE_URL: "
    set /p websocket_url="WEBSOCKET_URL: "
    
    (
        echo GOOGLE_MAPS_API_KEY=AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
        echo APP_NAME=Cobrador Custom
        echo APP_VERSION=1.0.0-custom
        echo BASE_URL=%base_url%
        echo WEBSOCKET_URL=%websocket_url%
    ) > "%ENV_FILE%"
    echo ✅ Configuración personalizada aplicada
) else if "%choice%"=="0" (
    echo ❌ Operación cancelada
    goto end
) else (
    echo ❌ Opción inválida
    goto end
)

echo.
echo 🔧 Configuración final:
type "%ENV_FILE%"

echo.
echo 🚀 ¡Listo! Puedes ejecutar 'flutter run' ahora

:end
pause
