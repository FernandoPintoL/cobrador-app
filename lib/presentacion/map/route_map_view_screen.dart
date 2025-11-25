import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../datos/modelos/map/client_to_visit.dart';
import '../../negocio/services/directions_service.dart';
import '../../negocio/services/route_optimization_service.dart';

/// Pantalla que muestra el mapa con la ruta optimizada dibujada
class RouteMapViewScreen extends StatefulWidget {
  final List<ClientToVisit> clients;
  final Position currentPosition;
  final bool prioritizeUrgent;

  const RouteMapViewScreen({
    super.key,
    required this.clients,
    required this.currentPosition,
    this.prioritizeUrgent = true,
  });

  @override
  State<RouteMapViewScreen> createState() => _RouteMapViewScreenState();
}

class _RouteMapViewScreenState extends State<RouteMapViewScreen> {
  GoogleMapController? _mapController;
  DirectionsResult? _directionsResult;
  bool _isLoadingRoute = true;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      // Optimizar ruta
      final optimizedRoute = RouteOptimizationService.optimizeRoute(
        clients: widget.clients,
        startLat: widget.currentPosition.latitude,
        startLng: widget.currentPosition.longitude,
        prioritizeUrgent: widget.prioritizeUrgent,
      );

      if (optimizedRoute.isEmpty) {
        setState(() {
          _isLoadingRoute = false;
        });
        return;
      }

      // Crear waypoints para Google Directions API
      final origin = LatLng(
        widget.currentPosition.latitude,
        widget.currentPosition.longitude,
      );

      final waypoints = optimizedRoute
          .map((client) => LatLng(client.latitude, client.longitude))
          .toList();

      // Obtener direcciones de Google
      final directionsResult = await DirectionsService.getOptimizedRoute(
        origin: origin,
        waypoints: waypoints,
      );

      if (directionsResult != null) {
        // Crear marcadores
        final markers = <Marker>{};

        // Marcador de inicio (mi ubicación)
        markers.add(
          Marker(
            markerId: const MarkerId('origin'),
            position: origin,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: const InfoWindow(
              title: 'Tu ubicación',
              snippet: 'Punto de inicio',
            ),
          ),
        );

        // Marcadores de clientes
        for (var i = 0; i < optimizedRoute.length; i++) {
          final client = optimizedRoute[i];
          final markerColor = _getMarkerColor(client.priority);

          markers.add(
            Marker(
              markerId: MarkerId('client_${client.personId}'),
              position: LatLng(client.latitude, client.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
              infoWindow: InfoWindow(
                title: '${i + 1}. ${client.name}',
                snippet: client.address,
              ),
            ),
          );
        }

        // Crear polyline
        final polylines = <Polyline>{
          Polyline(
            polylineId: const PolylineId('route'),
            points: directionsResult.polylineCoordinates,
            color: Colors.blue,
            width: 5,
            geodesic: true,
          ),
        };

        setState(() {
          _directionsResult = directionsResult;
          _markers = markers;
          _polylines = polylines;
          _isLoadingRoute = false;
        });

        // Ajustar cámara para mostrar toda la ruta
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngBounds(
              directionsResult.bounds,
              80, // padding
            ),
          );
        }
      } else {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error cargando ruta: $e');
      setState(() {
        _isLoadingRoute = false;
      });
    }
  }

  double _getMarkerColor(int priority) {
    switch (priority) {
      case 1: // Urgente
        return BitmapDescriptor.hueRed;
      case 2: // Hoy
        return BitmapDescriptor.hueOrange;
      case 3: // Próximo
        return BitmapDescriptor.hueGreen;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ruta en Mapa'),
        backgroundColor: Colors.green,
        actions: [
          if (_directionsResult != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.route, size: 18),
                  label: Text(
                    '${_directionsResult!.formattedDistance} • ${_directionsResult!.formattedDuration}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                widget.currentPosition.latitude,
                widget.currentPosition.longitude,
              ),
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
              // Si ya tenemos la ruta, ajustar cámara
              if (_directionsResult != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(
                    _directionsResult!.bounds,
                    80,
                  ),
                );
              }
            },
          ),
          if (_isLoadingRoute)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Calculando ruta óptima...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _directionsResult != null
          ? FloatingActionButton.extended(
              onPressed: () {
                // Mostrar información detallada de la ruta
                _showRouteInfo();
              },
              icon: const Icon(Icons.info_outline),
              label: const Text('Info de Ruta'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  void _showRouteInfo() {
    if (_directionsResult == null) return;

    final optimizedRoute = RouteOptimizationService.optimizeRoute(
      clients: widget.clients,
      startLat: widget.currentPosition.latitude,
      startLng: widget.currentPosition.longitude,
      prioritizeUrgent: widget.prioritizeUrgent,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de la Ruta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.people, color: Colors.blue),
              title: const Text('Clientes a visitar'),
              trailing: Text(
                '${optimizedRoute.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.route, color: Colors.orange),
              title: const Text('Distancia total'),
              trailing: Text(
                _directionsResult!.formattedDistance,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.access_time, color: Colors.purple),
              title: const Text('Tiempo estimado'),
              trailing: Text(
                _directionsResult!.formattedDuration,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'La ruta está optimizada por proximidad${widget.prioritizeUrgent ? " y prioriza clientes urgentes" : ""}.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
