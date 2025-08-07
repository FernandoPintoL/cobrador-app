@echo off
echo ================================================
echo      VERIFICACION DE CERTIFICADO ANDROID
echo ================================================
echo.

echo Obteniendo huella digital SHA-1 del certificado de debug...
echo.

REM Verificar si keytool está disponible
keytool -version >nul 2>&1
if errorlevel 1 (
    echo ERROR: keytool no encontrado en PATH
    echo Asegurate de tener Java JDK instalado y configurado
    echo.
    pause
    exit /b 1
)

echo Buscando keystore de debug de Android...
echo.

REM Rutas comunes del keystore de debug
set KEYSTORE_PATH=%USERPROFILE%\.android\debug.keystore
if exist "%KEYSTORE_PATH%" (
    echo Keystore encontrado en: %KEYSTORE_PATH%
    echo.
    echo Obteniendo huella digital SHA-1...
    echo.
    keytool -list -v -keystore "%KEYSTORE_PATH%" -alias androiddebugkey -storepass android -keypass android | findstr "SHA1:"
    echo.
    echo ================================================
    echo INFORMACION PARA GOOGLE CLOUD CONSOLE:
    echo ================================================
    echo Package Name: com.fpl.cobrador.cobrador_app
    echo SHA-1 Certificate Fingerprint: [Ver arriba]
    echo API Key Actual: AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU
    echo.
    echo INSTRUCCIONES:
    echo 1. Copia la huella SHA-1 de arriba
    echo 2. Ve a Google Cloud Console
    echo 3. APIs ^& Services ^> Credentials
    echo 4. Edita tu API Key
    echo 5. Application restrictions ^> Android apps
    echo 6. Agrega tu aplicacion con el Package Name y SHA-1
    echo.
) else (
    echo ERROR: No se encontro el keystore de debug de Android
    echo Ubicacion esperada: %KEYSTORE_PATH%
    echo.
    echo Intenta ejecutar una compilacion de Flutter primero:
    echo flutter run
    echo.
)

echo.
pause
