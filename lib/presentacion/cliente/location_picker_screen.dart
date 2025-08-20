import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  final bool allowSelection; // Permite seleccionar ubicación tocando el mapa
  final Set<Marker>? extraMarkers; // Marcadores extra (por ejemplo, clientes registrados)
  final String? customTitle; // Título personalizado opcional

  const LocationPickerScreen({
    super.key,
    this.allowSelection = true,
    this.extraMarkers,
    this.customTitle,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  String _direccion = '';
  bool _isLoading = true;
  bool _isGettingAddress = false;
  bool _mapError = false;
  String _mapErrorMessage = '';

  // Ubicación por defecto (puedes cambiar esto)
  static const LatLng _defaultLocation = LatLng(
    -12.0464,
    -77.0428,
  ); // Lima, Perú

  @override
  void initState() {
    super.initState();
    if (widget.allowSelection) {
      _verificarConectividadYPermisos();
    } else {
      // En modo solo visualización, no solicitar permisos ni ubicar automáticamente
      // Mostrar directamente el mapa con marcadores extra (si existen)
      _isLoading = false;
    }
  }

  Future<void> _verificarConectividadYPermisos() async {
    try {
      print('🔍 Iniciando diagnóstico de ubicación y mapa...');

      // Verificar permisos primero
      LocationPermission permission = await Geolocator.checkPermission();
      print('📍 Permisos de ubicación: $permission');

      if (permission == LocationPermission.denied) {
        print('🔑 Solicitando permisos de ubicación...');
        permission = await Geolocator.requestPermission();
        print('📍 Permisos después de solicitar: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Mostrar mensaje informativo
        _mostrarMensaje(
          'Permisos de ubicación requeridos',
          'Para obtener tu ubicación actual, necesitamos permisos de ubicación.',
          Colors.orange,
        );
        print('❌ Permisos de ubicación denegados');
      } else {
        print('✅ Permisos de ubicación concedidos');
      }

      // Verificar conectividad
      print('🌐 Verificando conectividad...');

      // Intentar obtener ubicación
      await _obtenerUbicacionActual();

      print('✅ Inicialización completada');
    } catch (e) {
      print('❌ Error al inicializar ubicación: $e');
      _mostrarMensaje(
        'Error de inicialización',
        'No se pudo obtener la ubicación. Puedes seleccionar manualmente en el mapa. Error: $e',
        Colors.red,
      );
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      print('📍 Intentando obtener ubicación actual...');

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print('❌ Sin permisos, usando ubicación por defecto');
        // Si no hay permisos, usar ubicación por defecto
        setState(() {
          _selectedLocation = _defaultLocation;
          _isLoading = false;
        });
        return;
      }

      print('🔍 Obteniendo posición GPS...');
      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      print('✅ Posición obtenida: ${position.latitude}, ${position.longitude}');

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Mover mapa a la ubicación actual
      print('🗺️ Moviendo mapa a ubicación actual...');
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );

      // Obtener dirección
      await _obtenerDireccionDesdeCoordenadas();
    } catch (e) {
      print('❌ Error al obtener ubicación: $e');
      // En caso de error, usar ubicación por defecto
      setState(() {
        _selectedLocation = _defaultLocation;
        _isLoading = false;
      });

      _mostrarMensaje(
        'Ubicación por defecto',
        'No se pudo obtener tu ubicación actual. Usando ubicación por defecto. Error: $e',
        Colors.orange,
      );
    }
  }

  Future<void> _obtenerDireccionDesdeCoordenadas() async {
    if (_selectedLocation == null) return;

    setState(() {
      _isGettingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _selectedLocation!.latitude,
        _selectedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String direccion = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        setState(() {
          _direccion = direccion;
        });
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
    } finally {
      setState(() {
        _isGettingAddress = false;
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    print('✅ Google Maps cargado correctamente');
    print('🔑 API Key configurada en AndroidManifest.xml');
    _mapController = controller;
    setState(() {
      _mapError = false;
      _mapErrorMessage = '';
    });

    // Mover mapa a la ubicación seleccionada si existe
    if (_selectedLocation != null) {
      print('📍 Moviendo cámara a ubicación seleccionada');
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );
    }
  }

  void _onMapError(String error) {
    print('❌ Error del mapa: $error');
    setState(() {
      _mapError = true;
      _mapErrorMessage = error;
    });
  }

  void _onMapTap(LatLng location) {
    if (!widget.allowSelection) return; // En modo solo vista, ignorar taps
    setState(() {
      _selectedLocation = location;
    });
    _obtenerDireccionDesdeCoordenadas();
  }

  void _confirmarUbicacion() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitud': _selectedLocation!.latitude,
        'longitud': _selectedLocation!.longitude,
        'direccion': _direccion,
      });
    }
  }

  void _mostrarMensaje(String titulo, String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(mensaje),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool soloVista = !widget.allowSelection;
    final String appBarTitle = widget.customTitle ?? (
      soloVista
          ? (widget.extraMarkers != null && widget.extraMarkers!.isNotEmpty
              ? 'Mapa de Clientes'
              : 'Mapa')
          : 'Seleccionar Ubicación'
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        actions: [
          if (!soloVista && _selectedLocation != null)
            TextButton(
              onPressed: _confirmarUbicacion,
              child: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Información de ubicación
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.grey[100],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'Ubicación Seleccionada:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedLocation != null) ...[
                        Text(
                          'Latitud: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Longitud: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if (_direccion.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Dirección: $_direccion',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (_isGettingAddress) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text('Obteniendo dirección...'),
                            ],
                          ),
                        ],
                      ] else ...[
                        if (widget.allowSelection)
                          const Text(
                            'Toca en el mapa para seleccionar una ubicación',
                            style: TextStyle(fontSize: 14),
                          )
                        else
                          const Text(
                            'Visualización de ubicaciones en el mapa',
                            style: TextStyle(fontSize: 14),
                          ),
                      ],
                    ],
                  ),
                ),
                // Mapa
                Expanded(
                  child: Stack(
                    children: [
                      // Widget principal del mapa con manejo de errores
                      Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: GoogleMap(
                          onMapCreated: _onMapCreated,
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation ?? (
                              (widget.extraMarkers != null && widget.extraMarkers!.isNotEmpty)
                                  ? widget.extraMarkers!.first.position
                                  : _defaultLocation
                            ),
                            zoom: 15,
                          ),
                          onTap: _onMapTap,
                          markers: {
                            if (_selectedLocation != null)
                              Marker(
                                markerId: const MarkerId('selected_location'),
                                position: _selectedLocation!,
                                infoWindow: InfoWindow(
                                  title: 'Ubicación Seleccionada',
                                  snippet: widget.allowSelection
                                      ? 'Toca para cambiar'
                                      : null,
                                ),
                              ),
                            ...?widget.extraMarkers,
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                          // Agregar callbacks para manejo de errores
                          onCameraMove: (CameraPosition position) {
                            print('📍 Cámara moviéndose a: ${position.target}');
                          },
                          onCameraIdle: () {
                            print('📍 Cámara detuvo movimiento');
                          },
                        ),
                      ),

                      // Widget de diagnóstico (solo en debug)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '🔍 Diagnóstico:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'API Key: ✅ Configurada',
                                style: TextStyle(
                                  color: Colors.green[300],
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Ubicación: ${_selectedLocation != null ? "✅ Obtenida" : "⏳ Cargando"}',
                                style: TextStyle(
                                  color: _selectedLocation != null
                                      ? Colors.green[300]
                                      : Colors.orange[300],
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Mapa: ${_mapController != null ? "✅ Activo" : "⏳ Cargando"}',
                                style: TextStyle(
                                  color: _mapController != null
                                      ? Colors.green[300]
                                      : Colors.orange[300],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error, color: Colors.red),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Error del Mapa',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _mapErrorMessage.isNotEmpty
                                      ? _mapErrorMessage
                                      : 'No se pudo cargar el mapa. Verifica tu conexión a internet.',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _mapError = false;
                                            _mapErrorMessage = '';
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                        ),
                                        child: const Text('Reintentar'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Botones de acción
                if (!soloVista)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _obtenerUbicacionActual,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Mi Ubicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedLocation != null
                                ? _confirmarUbicacion
                                : null,
                            icon: const Icon(Icons.check),
                            label: const Text('Confirmar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
