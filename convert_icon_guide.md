# Guía para Convertir .jpg a Icono de Notificación

## Pasos para convertir tu .jpg a icono de notificación:

### 1. Convertir .jpg a .png con transparencia
- Usar herramientas como GIMP, Photoshop, o herramientas online
- Asegurar que el fondo sea transparente
- Tamaño recomendado: 24x24dp (puede escalarse automáticamente)

### 2. Generar diferentes densidades (opcional pero recomendado)
Crear archivos PNG en estas carpetas:
- `android/app/src/main/res/drawable-mdpi/ic_notification.png` (24x24px)
- `android/app/src/main/res/drawable-hdpi/ic_notification.png` (36x36px)  
- `android/app/src/main/res/drawable-xhdpi/ic_notification.png` (48x48px)
- `android/app/src/main/res/drawable-xxhdpi/ic_notification.png` (72x72px)
- `android/app/src/main/res/drawable-xxxhdpi/ic_notification.png` (96x96px)

### 3. Herramientas recomendadas:
- Android Asset Studio: https://romannurik.github.io/AndroidAssetStudio/
- GIMP (gratuito)
- Canva (online)

### 4. Consideraciones de diseño:
- Usar colores simples (blanco/gris)
- Evitar detalles pequeños
- El sistema puede aplicar tinte automáticamente
