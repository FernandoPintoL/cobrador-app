import 'package:geolocator/geolocator.dart';
import '../../datos/modelos/map/client_to_visit.dart';

/// Servicio para optimizar rutas de visita a clientes
/// Usa el algoritmo "Nearest Neighbor" (vecino más cercano)
class RouteOptimizationService {
  /// Optimiza la ruta de visita usando algoritmo Nearest Neighbor
  /// Empieza desde la ubicación actual y visita el cliente más cercano sucesivamente
  /// Prioriza clientes urgentes (priority = 1) antes que la distancia
  static List<ClientToVisit> optimizeRoute({
    required List<ClientToVisit> clients,
    required double startLat,
    required double startLng,
    bool prioritizeUrgent = true,
  }) {
    if (clients.isEmpty) return [];
    if (clients.length == 1) return clients;

    final optimized = <ClientToVisit>[];
    final remaining = List<ClientToVisit>.from(clients);

    // Ubicación actual (inicio)
    double currentLat = startLat;
    double currentLng = startLng;

    // Mientras queden clientes por visitar
    while (remaining.isNotEmpty) {
      ClientToVisit? nextClient;
      double minDistance = double.infinity;

      // Si priorizamos urgentes, primero buscar si hay algún urgente
      if (prioritizeUrgent) {
        final urgentClients = remaining.where((c) => c.priority == 1).toList();

        if (urgentClients.isNotEmpty) {
          // Entre los urgentes, elegir el más cercano
          for (final client in urgentClients) {
            final distance = Geolocator.distanceBetween(
              currentLat,
              currentLng,
              client.latitude,
              client.longitude,
            );

            if (distance < minDistance) {
              minDistance = distance;
              nextClient = client;
            }
          }
        }
      }

      // Si no hay urgentes (o no priorizamos), buscar el más cercano de todos
      if (nextClient == null) {
        for (final client in remaining) {
          final distance = Geolocator.distanceBetween(
            currentLat,
            currentLng,
            client.latitude,
            client.longitude,
          );

          // Factor de prioridad: urgentes valen como si estuvieran más cerca
          final adjustedDistance = prioritizeUrgent
              ? distance * _getPriorityFactor(client.priority)
              : distance;

          if (adjustedDistance < minDistance) {
            minDistance = adjustedDistance;
            nextClient = client;
          }
        }
      }

      if (nextClient != null) {
        optimized.add(nextClient);
        remaining.remove(nextClient);
        currentLat = nextClient.latitude;
        currentLng = nextClient.longitude;
      } else {
        // No debería pasar, pero por seguridad
        break;
      }
    }

    return optimized;
  }

  /// Factor de ajuste según prioridad
  /// Urgentes (1) se consideran como si estuvieran a 1/3 de la distancia real
  /// Hoy (2) se consideran a 2/3 de la distancia
  /// Próximos (3) distancia normal
  static double _getPriorityFactor(int priority) {
    switch (priority) {
      case 1:
        return 0.33; // Urgentes pesan 3x más
      case 2:
        return 0.66; // Hoy pesan 1.5x más
      case 3:
      default:
        return 1.0; // Normal
    }
  }

  /// Calcula la distancia total de una ruta
  static double calculateTotalDistance({
    required List<ClientToVisit> route,
    required double startLat,
    required double startLng,
  }) {
    if (route.isEmpty) return 0.0;

    double totalDistance = 0.0;
    double currentLat = startLat;
    double currentLng = startLng;

    for (final client in route) {
      totalDistance += Geolocator.distanceBetween(
        currentLat,
        currentLng,
        client.latitude,
        client.longitude,
      );
      currentLat = client.latitude;
      currentLng = client.longitude;
    }

    return totalDistance;
  }

  /// Formatea la distancia en km o m
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()}m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)}km';
    }
  }

  /// Calcula tiempo estimado en minutos (asumiendo velocidad promedio en ciudad)
  /// Velocidad promedio: 20 km/h en ciudad con tráfico
  static int calculateEstimatedTime(double meters) {
    const averageSpeedKmH = 20.0; // km/h
    final km = meters / 1000;
    final hours = km / averageSpeedKmH;
    final minutes = (hours * 60).round();
    return minutes;
  }

  /// Formatea tiempo estimado
  static String formatTime(int minutes) {
    if (minutes < 60) {
      return '${minutes}min';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      return mins > 0 ? '${hours}h ${mins}min' : '${hours}h';
    }
  }
}
