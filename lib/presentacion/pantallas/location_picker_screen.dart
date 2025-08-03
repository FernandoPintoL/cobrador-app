import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

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
    _verificarConectividadYPermisos();
  }

  Future<void> _verificarConectividadYPermisos() async {
    try {
      // Verificar permisos primero
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Mostrar mensaje informativo
        _mostrarMensaje(
          'Permisos de ubicación requeridos',
          'Para obtener tu ubicación actual, necesitamos permisos de ubicación.',
          Colors.orange,
        );
      }

      // Intentar obtener ubicación
      await _obtenerUbicacionActual();
    } catch (e) {
      print('Error al inicializar ubicación: $e');
      _mostrarMensaje(
        'Error de inicialización',
        'No se pudo obtener la ubicación. Puedes seleccionar manualmente en el mapa.',
        Colors.red,
      );
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        // Si no hay permisos, usar ubicación por defecto
        setState(() {
          _selectedLocation = _defaultLocation;
          _isLoading = false;
        });
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      // Mover mapa a la ubicación actual
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
      );

      // Obtener dirección
      await _obtenerDireccionDesdeCoordenadas();
    } catch (e) {
      // En caso de error, usar ubicación por defecto
      setState(() {
        _selectedLocation = _defaultLocation;
        _isLoading = false;
      });
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
    _mapController = controller;
    setState(() {
      _mapError = false;
      _mapErrorMessage = '';
    });
  }

  void _onMapTap(LatLng location) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Ubicación'),
        actions: [
          if (_selectedLocation != null)
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
                        const Text(
                          'Toca en el mapa para seleccionar una ubicación',
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
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation ?? _defaultLocation,
                          zoom: 15,
                        ),
                        onTap: _onMapTap,
                        markers: _selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected_location'),
                                  position: _selectedLocation!,
                                  infoWindow: const InfoWindow(
                                    title: 'Ubicación Seleccionada',
                                    snippet: 'Toca para cambiar',
                                  ),
                                ),
                              }
                            : {},
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: true,
                        mapToolbarEnabled: false,
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
