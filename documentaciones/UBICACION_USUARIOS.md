# Funcionalidad de Ubicación para Usuarios

## 🎯 Objetivo

Implementar la funcionalidad para obtener y gestionar la ubicación de los usuarios al crear o actualizar clientes y cobradores. Esto permite:

1. **Obtener ubicación actual** usando GPS del dispositivo
2. **Seleccionar ubicación en mapa** para mayor precisión
3. **Obtener dirección automáticamente** desde coordenadas
4. **Guardar coordenadas** en la base de datos

## 🔧 Funcionalidades Implementadas

### 1. **Obtención de Ubicación Actual**

```dart
Future<void> _obtenerUbicacionActual() async {
  // Verificar permisos
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  
  // Obtener ubicación
  Position position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );
  
  // Obtener dirección
  await _obtenerDireccionDesdeCoordenadas();
}
```

### 2. **Selección en Mapa**

```dart
Future<void> _seleccionarUbicacionEnMapa() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const LocationPickerScreen(),
    ),
  );
  
  if (result != null && result is Map<String, dynamic>) {
    setState(() {
      _latitud = result['latitud'];
      _longitud = result['longitud'];
      if (result['direccion'] != null) {
        _direccionController.text = result['direccion'];
      }
    });
  }
}
```

### 3. **Geocodificación Inversa**

```dart
Future<void> _obtenerDireccionDesdeCoordenadas() async {
  List<Placemark> placemarks = await placemarkFromCoordinates(
    _latitud!,
    _longitud!,
  );
  
  if (placemarks.isNotEmpty) {
    Placemark place = placemarks[0];
    String direccion = [
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    
    _direccionController.text = direccion;
  }
}
```

## 📱 Interfaz de Usuario

### **Formulario de Usuario**

- ✅ **Card de ubicación**: Muestra estado y coordenadas
- ✅ **Botón "Ubicación Actual"**: Obtiene GPS del dispositivo
- ✅ **Botón "Seleccionar en Mapa"**: Abre mapa interactivo
- ✅ **Indicador visual**: Check verde cuando hay ubicación
- ✅ **Texto informativo**: Muestra coordenadas o "No seleccionada"

### **Pantalla de Mapa**

- ✅ **Google Maps**: Mapa interactivo completo
- ✅ **Marcador de ubicación**: Pin rojo en ubicación seleccionada
- ✅ **Información detallada**: Latitud, longitud y dirección
- ✅ **Botón "Mi Ubicación"**: Centra mapa en ubicación actual
- ✅ **Botón "Confirmar"**: Guarda ubicación seleccionada

## 🔄 Flujo de Funcionamiento

### **Opción 1: Ubicación Actual**
```
1. Usuario toca "Ubicación Actual"
2. Sistema solicita permisos de ubicación
3. GPS obtiene coordenadas precisas
4. Geocodificación obtiene dirección
5. Se llena automáticamente el campo dirección
6. Se muestra coordenadas en el card
```

### **Opción 2: Selección en Mapa**
```
1. Usuario toca "Seleccionar en Mapa"
2. Se abre pantalla con Google Maps
3. Usuario toca donde quiere ubicar
4. Sistema obtiene coordenadas del tap
5. Geocodificación obtiene dirección
6. Usuario confirma ubicación
7. Se regresa al formulario con datos
```

## 📊 Estructura de Datos

### **En el Formulario**
```dart
// Variables de estado
double? _latitud;
double? _longitud;
String _ubicacionTexto = '';
bool _isGettingLocation = false;
```

### **En la API**
```json
{
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "location": {
    "type": "Point",
    "coordinates": [-77.0428, -12.0464]
  },
  "address": "Av. Arequipa 123, Lima, Lima"
}
```

### **En la Base de Datos**
```sql
-- Estructura esperada en la tabla usuarios
CREATE TABLE usuarios (
  id BIGINT PRIMARY KEY,
  name VARCHAR(255),
  email VARCHAR(255),
  location POINT,  -- Tipo espacial para coordenadas
  address TEXT
);
```

## 🛠️ Configuración Técnica

### **Dependencias Requeridas**
```yaml
dependencies:
  geolocator: ^10.1.0      # GPS y permisos
  geocoding: ^2.1.1        # Geocodificación
  google_maps_flutter: ^2.5.3  # Mapas
```

### **Permisos Android**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### **API Key de Google Maps**
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="TU_API_KEY_AQUI" />
```

## 🎯 Casos de Uso

### **Caso 1: Crear Cliente con Ubicación**
```
1. Admin llena formulario de cliente
2. Toca "Ubicación Actual"
3. Sistema obtiene GPS automáticamente
4. Se llena dirección automáticamente
5. Admin confirma y guarda
6. Cliente queda registrado con ubicación
```

### **Caso 2: Seleccionar Ubicación Específica**
```
1. Admin necesita ubicar cliente en dirección específica
2. Toca "Seleccionar en Mapa"
3. Busca la dirección en el mapa
4. Toca exactamente donde está
5. Confirma la ubicación
6. Se guarda con coordenadas precisas
```

### **Caso 3: Actualizar Ubicación**
```
1. Admin edita cliente existente
2. Ve ubicación actual en el card
3. Puede cambiar usando cualquiera de las opciones
4. Guarda cambios
5. Ubicación se actualiza en la base de datos
```

## 🚨 Manejo de Errores

### **Permisos Denegados**
- ✅ **Solicitud automática**: Sistema pide permisos
- ✅ **Mensaje informativo**: Explica por qué se necesitan
- ✅ **Fallback**: Permite continuar sin ubicación

### **GPS No Disponible**
- ✅ **Detección de estado**: Verifica si GPS está activo
- ✅ **Mensaje de error**: Informa al usuario
- ✅ **Opción alternativa**: Sugiere usar mapa

### **Sin Conexión**
- ✅ **Geocodificación offline**: Usa coordenadas sin dirección
- ✅ **Guardado local**: Guarda para sincronizar después
- ✅ **Mensaje informativo**: Avisa sobre estado offline

## 📈 Beneficios

- ✅ **Precisión**: Coordenadas exactas para cada cliente
- ✅ **Automatización**: Dirección se llena automáticamente
- ✅ **Flexibilidad**: Múltiples formas de obtener ubicación
- ✅ **UX mejorada**: Interfaz intuitiva y visual
- ✅ **Datos completos**: Información geográfica completa

## 🧪 Casos de Prueba

1. ✅ **Permisos concedidos**: Obtiene ubicación correctamente
2. ✅ **Permisos denegados**: Maneja error apropiadamente
3. ✅ **GPS desactivado**: Detecta y informa
4. ✅ **Sin conexión**: Funciona con coordenadas locales
5. ✅ **Selección en mapa**: Guarda ubicación seleccionada
6. ✅ **Geocodificación**: Obtiene dirección desde coordenadas
7. ✅ **Actualización**: Modifica ubicación existente

## 🔮 Mejoras Futuras

- [ ] **Búsqueda de direcciones**: Buscar por nombre de calle
- [ ] **Favoritos**: Guardar ubicaciones frecuentes
- [ ] **Historial**: Últimas ubicaciones utilizadas
- [ ] **Validación**: Verificar que ubicación está en zona válida
- [ ] **Sincronización**: Sincronizar cuando hay conexión
- [ ] **Rutas**: Calcular rutas entre ubicaciones
- [ ] **Clusters**: Agrupar clientes por zona geográfica

## 🎯 Resultado Final

- ✅ **Ubicación automática**: GPS obtiene coordenadas precisas
- ✅ **Selección manual**: Mapa permite ubicación específica
- ✅ **Dirección automática**: Geocodificación inversa
- ✅ **Interfaz intuitiva**: Botones claros y feedback visual
- ✅ **Datos completos**: Coordenadas + dirección guardadas
- ✅ **Manejo de errores**: Permisos y estados offline 