import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/api_services/map_api_service.dart';
import '../../datos/modelos/map/location_cluster.dart';

// Servicio API
final mapApiProvider = Provider<MapApiService>((ref) => MapApiService());

// ===== Parámetros tipados para families =====
class MapClientsQuery {
  final String? status; // 'overdue' | 'pending' | 'paid'
  final int? cobradorId; // solo admin/manager
  const MapClientsQuery({this.status, this.cobradorId});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapClientsQuery &&
        other.status == status &&
        other.cobradorId == cobradorId;
  }

  @override
  int get hashCode => Object.hash(status, cobradorId);
}

class AreaBounds {
  final double north, south, east, west;
  const AreaBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AreaBounds &&
        other.north == north &&
        other.south == south &&
        other.east == east &&
        other.west == west;
  }

  @override
  int get hashCode => Object.hash(north, south, east, west);
}

// ===== Providers =====

/// Coordenadas ligeras para marcadores del mapa
final clientCoordinatesProvider = FutureProvider.family<Map<String, dynamic>, int?>(
  (ref, cobradorId) async {
    final api = ref.read(mapApiProvider);
    return await api.getCoordinates(cobradorId: cobradorId);
  },
);

/// Lista detallada de clientes (créditos, pagos, balances)
final mapClientsProvider = FutureProvider.family<List<dynamic>, MapClientsQuery>((ref, params) async {
  final api = ref.read(mapApiProvider);
  final resp = await api.getClients(status: params.status, cobradorId: params.cobradorId);
  // El backend devuelve { success, data: [ ... ] }
  if (resp['success'] == true) {
    final data = resp['data'];
    if (data is List) {
      return List<dynamic>.from(data);
    }
  }
  // Si la forma es distinta, intentar compatibilizar
  if (resp['data'] is Map && resp['data']['clients'] is List) {
    return List<dynamic>.from(resp['data']['clients']);
  }
  return [];
});

/// Resumen de estadísticas para cabecera
final mapStatsProvider = FutureProvider.family<Map<String, dynamic>, int?>((ref, cobradorId) async {
  final api = ref.read(mapApiProvider);
  final resp = await api.getStats(cobradorId: cobradorId);
  return Map<String, dynamic>.from(resp['data'] ?? resp);
});

/// Clientes por área visible (bounds)
final clientsByAreaProvider = FutureProvider.family<List<dynamic>, AreaBounds>((ref, bounds) async {
  final api = ref.read(mapApiProvider);
  final resp = await api.getClientsByArea(
    north: bounds.north,
    south: bounds.south,
    east: bounds.east,
    west: bounds.west,
  );
  if (resp['success'] == true && resp['data'] is List) {
    return List<dynamic>.from(resp['data']);
  }
  return [];
});

/// Rutas de cobradores (para overlays opcionales)
final cobradorRoutesProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(mapApiProvider);
  return await api.getCobradorRoutes();
});

// ===== NUEVO: Provider unificado de clusters =====

/// Parámetros para la búsqueda de clusters
class MapClusterQuery {
  final String? search; // Buscar por nombre, teléfono, CI, categoría
  final String? status; // 'overdue' | 'pending' | 'paid'
  final int? cobradorId; // filtro por cobrador (admin/manager)

  const MapClusterQuery({
    this.search,
    this.status,
    this.cobradorId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapClusterQuery &&
        other.search == search &&
        other.status == status &&
        other.cobradorId == cobradorId;
  }

  @override
  int get hashCode => Object.hash(search, status, cobradorId);
}

/// Provider unificado que retorna lista de clusters de ubicaciones
/// Reemplaza a los 3 providers anteriores (coordinates, clients, stats)
final mapLocationClustersProvider =
    FutureProvider.family<List<LocationCluster>, MapClusterQuery>(
  (ref, params) async {
    final api = ref.read(mapApiProvider);
    final resp = await api.getLocationClusters(
      search: params.search,
      status: params.status,
      cobradorId: params.cobradorId,
    );

    if (resp['success'] == true && resp['data'] is List) {
      final data = resp['data'] as List;
      return data
          .map((item) => LocationCluster.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return [];
  },
);
