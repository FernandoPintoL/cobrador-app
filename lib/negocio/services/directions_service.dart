import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

/// Servicio para obtener direcciones usando Google Directions API
class DirectionsService {
  // La API key se obtendrá del archivo de configuración
  static const String _apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyBp4Zd4RFDIbIeUgR_3C2eGAZ6iNbLTpEU',
  );

  /// Obtiene la ruta entre múltiples puntos (waypoints)
  /// Retorna lista de coordenadas para dibujar polyline
  static Future<DirectionsResult?> getDirections({
    required LatLng origin,
    required LatLng destination,
    List<LatLng>? waypoints,
  }) async {
    try {
      // Construir URL con waypoints
      final waypointsParam = waypoints != null && waypoints.isNotEmpty
          ? '&waypoints=${waypoints.map((w) => '${w.latitude},${w.longitude}').join('|')}'
          : '';

      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '$waypointsParam'
        '&key=$_apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylinePoints = PolylinePoints();
          final points = polylinePoints.decodePolyline(
            route['overview_polyline']['points'] as String,
          );

          final coordinates = points
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          // Extraer información de la ruta
          final leg = route['legs'][0];
          final distanceMeters = leg['distance']['value'] as int;
          final durationSeconds = leg['duration']['value'] as int;

          return DirectionsResult(
            polylineCoordinates: coordinates,
            totalDistanceMeters: distanceMeters,
            totalDurationSeconds: durationSeconds,
            bounds: _getBounds(coordinates),
          );
        } else {
          print('❌ Directions API error: ${data['status']}');
          return null;
        }
      } else {
        print('❌ HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo direcciones: $e');
      return null;
    }
  }

  /// Obtiene la ruta optimizada pasando por todos los puntos
  static Future<DirectionsResult?> getOptimizedRoute({
    required LatLng origin,
    required List<LatLng> waypoints,
  }) async {
    if (waypoints.isEmpty) return null;

    // El último waypoint es el destino
    final destination = waypoints.last;
    final intermediateWaypoints =
        waypoints.length > 1 ? waypoints.sublist(0, waypoints.length - 1) : null;

    return getDirections(
      origin: origin,
      destination: destination,
      waypoints: intermediateWaypoints,
    );
  }

  /// Calcula los bounds (límites) de un conjunto de coordenadas
  static LatLngBounds _getBounds(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      return LatLngBounds(
        southwest: const LatLng(0, 0),
        northeast: const LatLng(0, 0),
      );
    }

    double minLat = coordinates.first.latitude;
    double maxLat = coordinates.first.latitude;
    double minLng = coordinates.first.longitude;
    double maxLng = coordinates.first.longitude;

    for (final coord in coordinates) {
      if (coord.latitude < minLat) minLat = coord.latitude;
      if (coord.latitude > maxLat) maxLat = coord.latitude;
      if (coord.longitude < minLng) minLng = coord.longitude;
      if (coord.longitude > maxLng) maxLng = coord.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}

/// Resultado de una consulta a Directions API
class DirectionsResult {
  final List<LatLng> polylineCoordinates;
  final int totalDistanceMeters;
  final int totalDurationSeconds;
  final LatLngBounds bounds;

  DirectionsResult({
    required this.polylineCoordinates,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.bounds,
  });

  String get formattedDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters}m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  String get formattedDuration {
    final minutes = totalDurationSeconds ~/ 60;
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
    }
  }
}
