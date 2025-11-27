import 'package:geo_toolkit/geo_toolkit.dart';
import 'package:cobrador_app/datos/modelos/usuario.dart';

/// Adapter que permite usar la entidad Usuario del dominio con geo_toolkit.
///
/// Este adapter implementa IGeoEntity para que los clientes puedan
/// ser usados con los servicios de clustering, geofencing, etc.
///
/// Ejemplo de uso:
/// ```dart
/// final clients = await UserApiService().getClients();
/// final clientLocations = clients.map((c) => ClientLocationAdapter(c)).toList();
///
/// final clusteringService = ClusteringService<ClientLocationAdapter>(
///   strategy: ProximityClusteringStrategy(),
/// );
///
/// final clusters = clusteringService.cluster(
///   entities: clientLocations,
///   config: {'precision': 6, 'minClusterSize': 2},
/// );
///
/// // Usar en el mapa
/// for (final cluster in clusters) {
///   if (cluster.isMultiple) {
///     _addClusterMarker(cluster);
///   } else {
///     _addSingleMarker(cluster.entities.first);
///   }
/// }
/// ```
class ClientLocationAdapter implements IGeoEntity {
  final Usuario client;

  ClientLocationAdapter(this.client);

  @override
  String get entityId => client.id.toString();

  @override
  GeoPoint get location => GeoPoint(
        client.latitud ?? 0.0,
        client.longitud ?? 0.0,
      );

  @override
  Map<String, dynamic> get clusterData => {
        'id': client.id.toString(),
        'nombre': client.nombre,
        'client_category': client.clientCategory,
        'telefono': client.telefono,
        'direccion': client.direccion,
        'email': client.email,
        'ci': client.ci,
        'assigned_cobrador_id': client.assignedCobradorId?.toString(),
        'assigned_manager_id': client.assignedManagerId?.toString(),
        'roles': client.roles,
        'is_vip': client.isVipClient,
        'is_bad_client': client.isBadClient,
      };

  @override
  DateTime? get locationUpdatedAt => client.fechaActualizacion;

  @override
  double? get locationAccuracy => null; // No disponible en el modelo actual

  /// Obtiene el cliente original
  Usuario get originalClient => client;

  /// Verifica si la ubicación es válida
  bool get hasValidLocation =>
      client.latitud != null &&
      client.longitud != null &&
      location.isValid;

  /// Verifica si es un cliente (tiene rol 'cliente')
  bool get isClient => client.esCliente();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientLocationAdapter &&
          runtimeType == other.runtimeType &&
          client.id == other.client.id;

  @override
  int get hashCode => client.id.hashCode;

  @override
  String toString() =>
      'ClientLocationAdapter(id: ${client.id}, nombre: ${client.nombre}, location: $location)';
}

/// Extension para facilitar la conversión de listas de Usuarios
extension UsuarioListToLocationAdapter on List<Usuario> {
  /// Convierte lista de Usuarios a lista de ClientLocationAdapter
  List<ClientLocationAdapter> toLocationAdapters() {
    return map((usuario) => ClientLocationAdapter(usuario)).toList();
  }

  /// Convierte solo usuarios con ubicación válida
  List<ClientLocationAdapter> toValidLocationAdapters() {
    return map((usuario) => ClientLocationAdapter(usuario))
        .where((adapter) => adapter.hasValidLocation)
        .toList();
  }

  /// Filtra solo los clientes (con rol 'cliente')
  List<ClientLocationAdapter> toClientLocationAdapters() {
    return map((usuario) => ClientLocationAdapter(usuario))
        .where((adapter) => adapter.hasValidLocation && adapter.isClient)
        .toList();
  }
}

/// Configuración de clustering específica para clientes
class ClientClusteringConfig {
  /// Precisión según nivel de zoom del mapa
  static int precisionForZoom(double zoom) {
    if (zoom >= 18) return 7; // ~1 metro (muy cerca)
    if (zoom >= 16) return 6; // ~10 metros (cerca)
    if (zoom >= 14) return 5; // ~100 metros (media)
    if (zoom >= 12) return 4; // ~1 km (lejos)
    return 3; // ~10 km (muy lejos)
  }

  /// Distancia máxima según categoría de cliente
  static double? maxDistanceForCategory(String? category) {
    switch (category?.toUpperCase()) {
      case 'A': // VIP
        return 50; // 50 metros (no agrupar mucho)
      case 'B': // Normal
        return 100; // 100 metros
      case 'C': // Bajo
        return 200; // 200 metros
      default:
        return null; // Usar precision por defecto
    }
  }

  /// Configuración recomendada para vista de cobrador
  static Map<String, dynamic> configForCobradorView({
    required double currentZoom,
    String? filterByCategory,
  }) {
    return {
      'precision': precisionForZoom(currentZoom),
      'minClusterSize': 2, // Mínimo 2 clientes para formar cluster
      if (filterByCategory != null)
        'maxDistanceMeters': maxDistanceForCategory(filterByCategory),
    };
  }

  /// Configuración recomendada para vista de manager
  static Map<String, dynamic> configForManagerView({
    required double currentZoom,
  }) {
    return {
      'precision': precisionForZoom(currentZoom),
      'minClusterSize': 5, // Clusters más grandes para vista general
    };
  }
}
