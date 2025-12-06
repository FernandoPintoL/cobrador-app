import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationPickerScreen extends StatefulWidget {
  final bool allowSelection; // Permite seleccionar ubicación tocando el mapa
  final Set<Marker>? extraMarkers; // Marcadores extra (por ejemplo, clientes registrados)
  final String? customTitle; // Título personalizado opcional
  final double? initialLatitude; // Ubicación inicial para edición
  final double? initialLongitude; // Ubicación inicial para edición

  const LocationPickerScreen({
    super.key,
    this.allowSelection = true,
    this.extraMarkers,
    this.customTitle,
    this.initialLatitude,
    this.initialLongitude,
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
  MapType _mapType = MapType.normal;

  // Ubicación por defecto (puedes cambiar esto)
  static const LatLng _defaultLocation = LatLng(
    -12.0464,
    -77.0428,
  ); // Lima, Perú

  // Estilo de mapa para modo oscuro
  static const String _darkMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "elementType": "labels.icon",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#212121"
        }
      ]
    },
    {
      "featureType": "administrative",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "administrative.country",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9e9e9e"
        }
      ]
    },
    {
      "featureType": "administrative.land_parcel",
      "stylers": [
        {
          "visibility": "off"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#bdbdbd"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#181818"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#1b1b1b"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.fill",
      "stylers": [
        {
          "color": "#2c2c2c"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#8a8a8a"
        }
      ]
    },
    {
      "featureType": "road.arterial",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#373737"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#3c3c3c"
        }
      ]
    },
    {
      "featureType": "road.highway.controlled_access",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#4e4e4e"
        }
      ]
    },
    {
      "featureType": "road.local",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#616161"
        }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#000000"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#3d3d3d"
        }
      ]
    }
  ]
  ''';

  @override
  void initState() {
    super.initState();

    // Si hay ubicación inicial (modo edición), usarla
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation = LatLng(
        widget.initialLatitude!,
        widget.initialLongitude!,
      );
      _isLoading = false;
      // Obtener dirección de la ubicación guardada
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _obtenerDireccionDesdeCoordenadas();
      });
    } else if (widget.allowSelection) {
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

  bool _hayUbicacionRegistrada() {
    return widget.extraMarkers != null && widget.extraMarkers!.isNotEmpty;
  }

  LatLng? _obtenerDestinoNavegacion() {
    // Prioridad: ubicación seleccionada, si no existe y hay un único marcador extra, usarlo
    if (_selectedLocation != null) return _selectedLocation;
    if (widget.extraMarkers != null && widget.extraMarkers!.length == 1) {
      return widget.extraMarkers!.first.position;
    }
    return null;
  }

  Future<void> _abrirEnGoogleMaps(LatLng destino) async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${destino.latitude},${destino.longitude}&travelmode=driving');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _mostrarMensaje('No se pudo abrir', 'No se pudo abrir Google Maps.', Colors.red);
    }
  }

  Future<void> _abrirEnWaze(LatLng destino) async {
    final uri = Uri.parse('https://waze.com/ul?ll=${destino.latitude},${destino.longitude}&navigate=yes');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _mostrarMensaje('No se pudo abrir', 'No se pudo abrir Waze.', Colors.red);
    }
  }

  Future<void> _mostrarOpcionesNavegacion() async {
    final destino = _obtenerDestinoNavegacion();
    if (destino == null) {
      _mostrarMensaje(
        'Selecciona un destino',
        'Selecciona una ubicación en el mapa o asegúrate de tener un único marcador para navegar.',
        Colors.orange,
      );
      return;
    }

    // Mostrar opciones para abrir en apps externas
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final isDarkMode = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.map, color: Colors.redAccent),
                title: const Text('Abrir en Google Maps'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _abrirEnGoogleMaps(destino);
                },
              ),
              ListTile(
                leading: const Icon(Icons.navigation, color: Colors.blueAccent),
                title: const Text('Abrir en Waze'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _abrirEnWaze(destino);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

    // Detectar el tema actual para adaptar colores
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[300] : Colors.grey[600];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: isDarkMode ? Colors.grey[900] : null,
        foregroundColor: isDarkMode ? Colors.white : null,
        actions: [
          if (_hayUbicacionRegistrada())
            IconButton(
              tooltip: 'Cómo llegar',
              onPressed: _mostrarOpcionesNavegacion,
              icon: const Icon(Icons.directions),
            ),
          IconButton(
            tooltip: _mapType == MapType.satellite ? 'Mapa estándar' : 'Vista satélite',
            onPressed: () {
              setState(() {
                _mapType = _mapType == MapType.satellite ? MapType.normal : MapType.satellite;
              });
            },
            icon: Icon(_mapType == MapType.satellite ? Icons.map : Icons.satellite_alt_outlined),
          ),
          if (!soloVista && _selectedLocation != null)
            TextButton(
              onPressed: _confirmarUbicacion,
              child: Text(
                'Confirmar',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? Colors.blue[300] : Colors.blue,
              ),
            )
          : Column(
              children: [
                // Información de ubicación
                Container(
                  padding: const EdgeInsets.all(16),
                  color: backgroundColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: isDarkMode ? Colors.blue[300] : Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ubicación Seleccionada:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_selectedLocation != null) ...[
                        Text(
                          'Latitud: ${_selectedLocation!.latitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                        Text(
                          'Longitud: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                        if (_direccion.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Dirección: $_direccion',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                        if (_isGettingAddress) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Obteniendo dirección...',
                                style: TextStyle(color: subtitleColor),
                              ),
                            ],
                          ),
                        ],
                      ] else ...[
                        if (widget.allowSelection)
                          Text(
                            'Toca en el mapa para seleccionar una ubicación',
                            style: TextStyle(fontSize: 14, color: subtitleColor),
                          )
                        else
                          Text(
                            'Visualización de ubicaciones en el mapa',
                            style: TextStyle(fontSize: 14, color: subtitleColor),
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
                          mapType: _mapType,
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
                          // Configurar estilo del mapa según el tema
                          style: (_mapType == MapType.normal && isDarkMode) ? _darkMapStyle : null,
                          onCameraMove: (CameraPosition position) {
                            print('📍 Cámara moviéndose a: ${position.target}');
                          },
                          onCameraIdle: () {
                            print('📍 Cámara detuvo movimiento');
                          },
                        ),
                      ),

                      // Widget de diagnóstico (adaptado para modo oscuro)
                      /*Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800]?.withOpacity(0.9) : Colors.black87,
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
                      ),*/
                      // Indicador de error del mapa (adaptado para modo oscuro)
                      if (_mapError)
                        Positioned(
                          top: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.red[900]?.withOpacity(0.9) : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode ? Colors.red[300]! : Colors.red,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error,
                                      color: isDarkMode ? Colors.red[300] : Colors.red,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Error del Mapa',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.red[300] : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _mapErrorMessage.isNotEmpty
                                      ? _mapErrorMessage
                                      : 'No se pudo cargar el mapa. Verifica tu conexión a internet.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
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
                                          backgroundColor: isDarkMode ? Colors.red[600] : Colors.red,
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
                // Botones de acción (adaptados para modo oscuro)
                if (!soloVista)
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: backgroundColor,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _obtenerUbicacionActual,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Mi Ubicación'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDarkMode ? Colors.blue[600] : Colors.blue,
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
                              backgroundColor: isDarkMode ? Colors.green[600] : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
      floatingActionButton: _hayUbicacionRegistrada()
          ? FloatingActionButton.extended(
              onPressed: _mostrarOpcionesNavegacion,
              icon: const Icon(Icons.directions, color: Colors.white),
              label: const Text('Cómo llegar', style: TextStyle(color: Colors.white)),
              backgroundColor: isDarkMode ? Colors.blue : Colors.blue,
            )
          : null,
    );
  }
}
