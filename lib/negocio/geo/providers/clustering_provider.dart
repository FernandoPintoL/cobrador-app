import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geo_toolkit/geo_toolkit.dart';
import 'package:cobrador_app/negocio/geo/adapters/client_location_adapter.dart';

/// Provider del servicio de clustering genérico.
///
/// Este servicio puede usarse en toda la app para agrupar clientes
/// geográficamente según diferentes estrategias.
final clusteringServiceProvider = Provider<ClusteringService<ClientLocationAdapter>>((ref) {
  return ClusteringService<ClientLocationAdapter>(
    strategy: ProximityClusteringStrategy<ClientLocationAdapter>(),
    defaultConfig: {
      'precision': 6, // ~10 metros por defecto
      'minClusterSize': 2, // Mínimo 2 clientes
    },
  );
});

/// Provider de clusters de clientes.
///
/// Toma la lista de clientes y genera clusters automáticamente.
///
/// Uso en UI:
/// ```dart
/// final clustersAsync = ref.watch(clientClustersProvider);
///
/// clustersAsync.when(
///   data: (clusters) => _buildMap(clusters),
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => ErrorWidget(err),
/// );
/// ```
final clientClustersProvider = FutureProvider<List<GeoCluster<ClientLocationAdapter>>>((ref) async {
  // Obtener clientes desde el provider existente
  // NOTA: Ajustar según tu provider real de clientes
  // final usuarios = ref.watch(usuariosProvider); // Ejemplo

  // Por ahora retornamos lista vacía - integrar con tu provider real
  // Cuando integres, usa: final clientLocations = usuarios.toClientLocationAdapters();
  final clientLocations = <ClientLocationAdapter>[];

  // Obtener servicio de clustering
  final clusteringService = ref.watch(clusteringServiceProvider);

  // Generar clusters
  return clusteringService.cluster(
    entities: clientLocations,
    config: {'precision': 6},
  );
});

/// Provider de clusters con zoom dinámico.
///
/// Recalcula clusters cuando cambia el nivel de zoom del mapa.
final clientClustersWithZoomProvider = FutureProvider.family<
    List<GeoCluster<ClientLocationAdapter>>,
    double
>((ref, currentZoom) async {
  // Obtener clientes desde tu provider
  // final usuarios = ref.watch(usuariosProvider); // Ejemplo
  // final clientLocations = usuarios.toClientLocationAdapters();
  final clientLocations = <ClientLocationAdapter>[];

  // Obtener servicio
  final clusteringService = ref.watch(clusteringServiceProvider);

  // Configuración según zoom
  final config = ClientClusteringConfig.configForCobradorView(
    currentZoom: currentZoom,
  );

  // Generar clusters
  return clusteringService.cluster(
    entities: clientLocations,
    config: config,
  );
});

/// Provider de separación de clusters (múltiples vs individuales).
///
/// Útil para renderizar de forma diferente en el mapa.
final clusterSeparationProvider = FutureProvider<ClusterSeparation<ClientLocationAdapter>>((ref) async {
  final clusters = await ref.watch(clientClustersProvider.future);
  final clusteringService = ref.watch(clusteringServiceProvider);

  return clusteringService.separateMultipleAndSingle(clusters);
});

/// Provider de agregados por cluster.
///
/// Calcula estadísticas útiles para cada cluster.
final clusterAggregatesProvider = FutureProvider<List<ClusterAggregate<ClientLocationAdapter>>>((ref) async {
  final clusters = await ref.watch(clientClustersProvider.future);
  final clusteringService = ref.watch(clusteringServiceProvider);

  return clusteringService.aggregateClusterData(
    clusters,
    (entities) {
      // Calcular agregados relevantes para clientes
      int vipCount = 0;
      int normalCount = 0;
      int badCount = 0;

      for (final entity in entities) {
        final data = entity.clusterData;

        if (data['is_vip'] == true) {
          vipCount++;
        } else if (data['is_bad_client'] == true) {
          badCount++;
        } else {
          normalCount++;
        }
      }

      return {
        'vip_count': vipCount,
        'normal_count': normalCount,
        'bad_count': badCount,
        'total_clients': entities.length,
        'has_vip': vipCount > 0,
        'has_bad': badCount > 0,
      };
    },
  );
});

/// StateProvider para el zoom actual del mapa.
///
/// Usado para recalcular clusters dinámicamente.
final mapZoomProvider = StateProvider<double>((ref) => 14.0);

/// Provider combinado que usa el zoom actual.
final dynamicClustersProvider = FutureProvider<List<GeoCluster<ClientLocationAdapter>>>((ref) async {
  final currentZoom = ref.watch(mapZoomProvider);
  return ref.watch(clientClustersWithZoomProvider(currentZoom).future);
});

/// Ejemplo de uso en MapScreen:
///
/// ```dart
/// class MapScreen extends ConsumerStatefulWidget {
///   @override
///   ConsumerState<MapScreen> createState() => _MapScreenState();
/// }
///
/// class _MapScreenState extends ConsumerState<MapScreen> {
///   GoogleMapController? _mapController;
///
///   @override
///   Widget build(BuildContext context) {
///     final clustersAsync = ref.watch(dynamicClustersProvider);
///
///     return clustersAsync.when(
///       data: (clusters) => GoogleMap(
///         onMapCreated: (controller) {
///           _mapController = controller;
///         },
///         onCameraMove: (position) {
///           // Actualizar zoom
///           ref.read(mapZoomProvider.notifier).state = position.zoom;
///         },
///         markers: _buildMarkers(clusters),
///       ),
///       loading: () => Center(child: CircularProgressIndicator()),
///       error: (err, stack) => ErrorScreen(error: err),
///     );
///   }
///
///   Set<Marker> _buildMarkers(List<GeoCluster<ClientLocationAdapter>> clusters) {
///     final markers = <Marker>{};
///
///     for (final cluster in clusters) {
///       if (cluster.isMultiple) {
///         // Marker de cluster
///         markers.add(Marker(
///           markerId: MarkerId(cluster.clusterId),
///           position: LatLng(
///             cluster.center.latitude,
///             cluster.center.longitude,
///           ),
///           icon: _createClusterIcon(cluster.size),
///           onTap: () => _showClusterDetails(cluster),
///         ));
///       } else {
///         // Marker individual
///         final client = cluster.entities.first;
///         markers.add(Marker(
///           markerId: MarkerId(client.entityId),
///           position: LatLng(
///             client.location.latitude,
///             client.location.longitude,
///           ),
///           icon: _createClientIcon(client),
///           onTap: () => _showClientDetails(client),
///         ));
///       }
///     }
///
///     return markers;
///   }
///
///   BitmapDescriptor _createClusterIcon(int size) {
///     // Implementar custom icon según tamaño
///     return BitmapDescriptor.defaultMarkerWithHue(
///       size > 10 ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange,
///     );
///   }
///
///   BitmapDescriptor _createClientIcon(ClientLocationAdapter client) {
///     // Implementar custom icon según estado
///     final status = client.clusterData['payment_status'];
///     return BitmapDescriptor.defaultMarkerWithHue(
///       status == 'moroso'
///           ? BitmapDescriptor.hueRed
///           : BitmapDescriptor.hueGreen,
///     );
///   }
///
///   void _showClusterDetails(GeoCluster<ClientLocationAdapter> cluster) {
///     showModalBottomSheet(
///       context: context,
///       builder: (ctx) => ClusterDetailsSheet(cluster: cluster),
///     );
///   }
///
///   void _showClientDetails(ClientLocationAdapter client) {
///     showModalBottomSheet(
///       context: context,
///       builder: (ctx) => ClientDetailsSheet(client: client.originalClient),
///     );
///   }
/// }
/// ```
