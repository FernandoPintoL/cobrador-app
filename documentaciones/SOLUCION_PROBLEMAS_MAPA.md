# Solución de Problemas del Mapa

## 🚨 Problema Identificado

El mapa aparece con fondo gris/beige sin cargar correctamente. Esto puede deberse a varios factores:

## 🔍 **Causas Principales**

### 1. **API Key de Google Maps**
```
❌ Problema: API Key inválida, expirada o sin permisos
✅ Solución: Verificar configuración en AndroidManifest.xml
```

### 2. **Falta de Conexión a Internet**
```
❌ Problema: Google Maps requiere conexión para cargar tiles
✅ Solución: Verificar conectividad WiFi/móvil
```

### 3. **Permisos de Ubicación**
```
❌ Problema: Sin permisos, el mapa no puede centrarse
✅ Solución: Solicitar permisos antes de abrir mapa
```

### 4. **Configuración de Google Cloud**
```
❌ Problema: APIs no habilitadas en Google Cloud Console
✅ Solución: Habilitar Maps SDK for Android
```

## 🔧 **Soluciones Implementadas**

### 1. **Verificación de Conectividad y Permisos**

```dart
Future<void> _verificarConectividadYPermisos() async {
  try {
    // Verificar permisos primero
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _mostrarMensaje(
        'Permisos de ubicación requeridos',
        'Para obtener tu ubicación actual, necesitamos permisos de ubicación.',
        Colors.orange,
      );
    }

    // Intentar obtener ubicación
    await _obtenerUbicacionActual();
  } catch (e) {
    _mostrarMensaje(
      'Error de inicialización',
      'No se pudo obtener la ubicación. Puedes seleccionar manualmente en el mapa.',
      Colors.red,
    );
  }
}
```

### 2. **Manejo de Errores del Mapa**

```dart
void _onMapCreated(GoogleMapController controller) {
  _mapController = controller;
  setState(() {
    _mapError = false;
    _mapErrorMessage = '';
  });
}

void _onMapError(String error) {
  setState(() {
    _mapError = true;
    _mapErrorMessage = error;
  });
}
```

### 3. **Indicador Visual de Errores**

```dart
// Indicador de error del mapa
if (_mapError)
  Positioned(
    top: 16,
    left: 16,
    right: 16,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              const Text('Error del Mapa', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          Text(_mapErrorMessage.isNotEmpty ? _mapErrorMessage : 'No se pudo cargar el mapa. Verifica tu conexión a internet.'),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _mapError = false;
                _mapErrorMessage = '';
              });
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  ),
```

## 📋 **Pasos de Verificación**

### **Paso 1: Verificar API Key**
```xml
<!-- En android/app/src/main/AndroidManifest.xml -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />
```

### **Paso 2: Verificar Google Cloud Console**
1. Ir a [Google Cloud Console](https://console.cloud.google.com/)
2. Seleccionar tu proyecto
3. Ir a "APIs & Services" > "Library"
4. Buscar y habilitar:
   - Maps SDK for Android
   - Places API
   - Geocoding API

### **Paso 3: Verificar Permisos**
```xml
<!-- En AndroidManifest.xml -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### **Paso 4: Verificar Conexión**
- ✅ WiFi activo
- ✅ Datos móviles activos
- ✅ Sin restricciones de firewall

## 🎯 **Casos de Uso y Soluciones**

### **Caso 1: Mapa Gris sin Cargar**
```
Síntomas:
- Mapa aparece con fondo gris
- No se cargan las calles/edificios
- Botones de zoom no funcionan

Causa: API Key inválida o sin permisos
Solución: Verificar API Key en Google Cloud Console
```

### **Caso 2: Error de Red**
```
Síntomas:
- Mensaje "No se pudo cargar el mapa"
- Indicador de error aparece
- Botón "Reintentar" disponible

Causa: Sin conexión a internet
Solución: Verificar conectividad WiFi/móvil
```

### **Caso 3: Permisos Denegados**
```
Síntomas:
- Mapa carga pero no muestra ubicación actual
- Botón "Mi Ubicación" no funciona
- Mensaje sobre permisos

Causa: Permisos de ubicación denegados
Solución: Ir a Configuración > Apps > Permisos
```

### **Caso 4: API Key Expirada**
```
Síntomas:
- Mapa no carga completamente
- Error en consola sobre API Key
- Mensaje de error específico

Causa: API Key expirada o inválida
Solución: Generar nueva API Key en Google Cloud Console
```

## 🔧 **Configuración Técnica**

### **API Key Correcta**
```xml
<!-- Ejemplo de configuración correcta -->
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU" />
```

### **Permisos Completos**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### **Dependencias Correctas**
```yaml
dependencies:
  google_maps_flutter: ^2.5.3
  geolocator: ^10.1.0
  geocoding: ^2.1.1
```

## 🚨 **Mensajes de Error Comunes**

### **"API key not valid"**
- ✅ Verificar API Key en Google Cloud Console
- ✅ Habilitar Maps SDK for Android
- ✅ Verificar restricciones de API Key

### **"Network error"**
- ✅ Verificar conexión a internet
- ✅ Probar en diferentes redes
- ✅ Verificar firewall/antivirus

### **"Location permission denied"**
- ✅ Ir a Configuración > Apps > Permisos
- ✅ Habilitar ubicación para la app
- ✅ Verificar permisos en tiempo de ejecución

### **"Map not loading"**
- ✅ Verificar API Key
- ✅ Verificar conexión
- ✅ Reiniciar app
- ✅ Limpiar cache

## 📈 **Mejoras Implementadas**

- ✅ **Verificación automática**: Permisos y conectividad
- ✅ **Mensajes informativos**: Explican el problema
- ✅ **Botón reintentar**: Para recuperar de errores
- ✅ **Indicador visual**: Muestra estado del mapa
- ✅ **Fallback**: Funciona sin ubicación inicial

## 🎯 **Resultado Esperado**

Con las mejoras implementadas:

1. **Mensajes claros**: El usuario sabe qué está pasando
2. **Recuperación automática**: El sistema maneja errores
3. **Opciones alternativas**: Puede seleccionar manualmente
4. **Feedback visual**: Indicadores de estado
5. **Mejor UX**: Experiencia más fluida

## 🔮 **Próximos Pasos**

- [ ] **Cache offline**: Guardar mapas para uso sin conexión
- [ ] **Múltiples proveedores**: Alternativas a Google Maps
- [ ] **Validación automática**: Verificar configuración al iniciar
- [ ] **Tutorial integrado**: Guía para configurar API Key 