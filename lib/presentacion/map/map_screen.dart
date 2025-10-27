import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../datos/modelos/map/location_cluster.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/map_provider.dart' as mp_provider;
import 'utils/client_data_extractor.dart';
import 'utils/cluster_icon_generator.dart';
import 'widgets/client_details_sheet.dart';
import 'widgets/cluster_people_list.dart';
import 'widgets/map_filters_bar.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Controladores y estado del mapa
  GoogleMapController? _mapController;
  LatLng? _myLocation;
  MapType _mapType = MapType.normal;

  // Filtros
  int? _selectedCobradorId;
  String? _statusFilter;
  String? _searchQuery;

  // Ubicación inicial (Lima)
  static const LatLng _initialCenter = LatLng(-12.0464, -77.0428);
  static const CameraPosition _initialCamera = CameraPosition(
    target: _initialCenter,
    zoom: 11.5,
  );

  // Cache de iconos
  final Map<String, BitmapDescriptor> _markerIconCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initLocation();
      _loadCobradores();
    });
  }

  /// Carga los cobradores asignados si el usuario es manager
  void _loadCobradores() {
    final auth = ref.read(authProvider);
    final role = _getUserRole(auth.usuario?.roles ?? []);
    if (role == 'manager') {
      final managerId = auth.usuario!.id.toString();
      ref.read(managerProvider.notifier).cargarCobradoresAsignados(managerId);
    }
  }

  /// Inicializa la ubicación del usuario
  Future<void> _initLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final latLng = LatLng(pos.latitude, pos.longitude);

      if (!mounted) return;
      setState(() => _myLocation = latLng);

      if (_mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(latLng, 15),
        );
      }
    } catch (_) {
      // Ignorar silenciosamente
    }
  }

  /// Obtiene el rol del usuario
  String _getUserRole(List<String> roles) {
    final lowered = roles.map((e) => e.toLowerCase()).toList();
    if (lowered.contains('admin')) return 'admin';
    if (lowered.contains('manager')) return 'manager';
    if (lowered.contains('cobrador')) return 'cobrador';
    return lowered.isNotEmpty ? lowered.first : '';
  }

  /// Construye los marcadores desde los clusters
  /// UN MARCADOR POR CLUSTER (casa), no por persona
  Future<Set<Marker>> _buildMarkers(List<LocationCluster> clusters) async {
    final markers = <Marker>{};

    for (final cluster in clusters) {
      final lat = cluster.location.latitude;
      final lng = cluster.location.longitude;
      final peopleCount = cluster.people.length;
      final clusterStatus = cluster.clusterStatus;

      // Color basado en el estado del cluster
      final color = _getColorForClusterStatus(clusterStatus);

      // Determinar icono basado en número de personas
      BitmapDescriptor icon;
      if (peopleCount == 1) {
        // UN CLIENTE: mostrar sus datos personales
        final person = cluster.people.first;
        final paidToday = ClientDataExtractor.extractPaidToday(person);
        final pagoLabel = ClientDataExtractor.labelForPaidToday(paidToday);
        final personColor = ClientDataExtractor.colorForPaidToday(paidToday);

        // Información de próximo pago
        final nextInfo = ClientDataExtractor.extractNextPaymentInfo(person);
        final amount = nextInfo['amount'] as double?;
        final installment = nextInfo['installment'] as int?;

        String? secondLine;
        if (installment != null && amount != null) {
          secondLine =
              'Cuota #$installment · ${ClientDataExtractor.formatSoles(amount)}';
        } else if (installment != null) {
          secondLine = 'Cuota #$installment';
        } else if (amount != null) {
          secondLine = ClientDataExtractor.formatSoles(amount);
        }

        if (secondLine != null) {
          final cacheKey = '$paidToday|$secondLine';
          if (_markerIconCache.containsKey(cacheKey)) {
            icon = _markerIconCache[cacheKey]!;
          } else {
            icon = await ClusterIconGenerator.generateMarkerIcon(
              pagoLabel,
              personColor,
              line2: secondLine,
            );
            _markerIconCache[cacheKey] = icon;
          }
        } else {
          icon = await ClusterIconGenerator.generateMarkerIcon(
            pagoLabel,
            personColor,
          );
        }
      } else {
        // MÚLTIPLES CLIENTES: mostrar contador
        icon = await ClusterIconGenerator.generateClusterIcon(
          peopleCount,
          clusterStatus,
          color,
        );
      }

      markers.add(
        Marker(
          markerId: MarkerId('cluster_${cluster.clusterId}'),
          position: LatLng(lat, lng),
          icon: icon,
          infoWindow: InfoWindow(
            title: peopleCount == 1
                ? cluster.people.first.name
                : '$peopleCount personas',
            snippet: cluster.location.address,
            onTap: () => _showClusterModal(context, cluster),
          ),
          onTap: () => _showClusterModal(context, cluster),
        ),
      );
    }

    return markers;
  }

  /// Obtiene el color para el estado del cluster
  Color _getColorForClusterStatus(String status) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return Colors.red.shade400;
      case 'pending':
        return Colors.amber.shade700;
      case 'paid':
        return Colors.green.shade600;
      default:
        return Colors.blue.shade400;
    }
  }

  /// Muestra el modal apropiado según el número de personas
  /// Si hay 1 persona: muestra detalles directamente
  /// Si hay múltiples: muestra listado para seleccionar
  void _showClusterModal(BuildContext context, LocationCluster cluster) {
    if (cluster.people.length == 1) {
      // Caso: 1 persona → mostrar detalles directamente
      _showClientDetailsSheet(context, cluster.people.first);
    } else {
      // Caso: múltiples personas → mostrar listado
      _showClusterPeopleListSheet(context, cluster);
    }
  }

  /// Muestra el modal con listado de personas en el cluster
  void _showClusterPeopleListSheet(
    BuildContext context,
    LocationCluster cluster,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClusterPeopleList(
              cluster: cluster,
              onPersonSelected: (person) {
                Navigator.pop(context); // Cerrar listado
                _showClientDetailsSheet(context, person);
              },
            ),
          ),
        );
      },
    );
  }

  /// Muestra el modal con detalles del cliente
  void _showClientDetailsSheet(BuildContext context, ClusterPerson person) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.7,
                minChildSize: 0.5,
                maxChildSize: 0.95,
                builder: (_, controller) => ClientDetailsSheet(
                  person: person,
                  scrollController: controller,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.usuario;
    final role = _getUserRole(user?.roles ?? []);
    final isAdminOrManager = role == 'admin' || role == 'manager';

    // Watchear el provider de clusters
    final clustersAsync = ref.watch(
      mp_provider.mapLocationClustersProvider(
        mp_provider.MapClusterQuery(
          search: _searchQuery,
          status: _statusFilter,
          cobradorId: _selectedCobradorId,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Clientes'),
        actions: [
          if (isAdminOrManager) _buildCobradorSelector(),
          IconButton(
            tooltip: _mapType == MapType.satellite ? 'Mapa estándar' : 'Vista satélite',
            icon: Icon(
              _mapType == MapType.satellite
                  ? Icons.map
                  : Icons.satellite_alt_outlined,
            ),
            onPressed: () => setState(() {
              _mapType = _mapType == MapType.satellite
                  ? MapType.normal
                  : MapType.satellite;
            }),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: clustersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => _buildErrorView(e, context),
        data: (clusters) => _buildMapView(clusters, context),
      ),
    );
  }

  Widget _buildMapView(List<LocationCluster> clusters, BuildContext context) {
    return Column(
      children: [
        // Búsqueda
        ClusterSearchBar(
          onSearch: (query) => setState(() => _searchQuery = query.isEmpty ? null : query),
        ),

        // Filtros de estado
        MapStatusFiltersBar(
          selectedStatus: _statusFilter,
          onStatusChanged: (status) => setState(() => _statusFilter = status),
        ),

        // Estadísticas (mostrar solo si hay un cluster seleccionado o el primero)
        if (clusters.isNotEmpty)
          ClusterStatsBar(cluster: clusters.first),

        // Mapa
        Expanded(
          child: Stack(
            children: [
              FutureBuilder<Set<Marker>>(
                future: _buildMarkers(clusters),
                builder: (context, snapshot) {
                  final markers = snapshot.data ?? {};
                  return GoogleMap(
                    mapType: _mapType,
                    initialCameraPosition: _initialCamera,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: false,
                    markers: markers,
                    onMapCreated: (controller) async {
                      _mapController = controller;
                      if (_myLocation != null) {
                        await controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_myLocation!, 15),
                        );
                      } else if (markers.isNotEmpty) {
                        final first = markers.first.position;
                        await controller.animateCamera(
                          CameraUpdate.newLatLngZoom(first, 13),
                        );
                      }
                    },
                  );
                },
              ),
              if (clusters.isEmpty)
                _buildEmptyView()
              else if (clusters.length == 1 && clusters.first.people.isEmpty)
                _buildEmptyView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          const Text(
            'No hay clientes para mostrar',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() {}),
            child: const Text('Refrescar'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(dynamic error, BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 8),
          Text(
            'Error al cargar datos:\n$error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() {}),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildCobradorSelector() {
    final managerState = ref.watch(managerProvider);
    final cobradores = managerState.cobradoresAsignados;

    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            hint: const Text('Filtrar por cobrador'),
            value: _selectedCobradorId,
            onChanged: (v) => setState(() => _selectedCobradorId = v),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todos')),
              ...cobradores.map(
                (u) => DropdownMenuItem<int?>(
                  value: u.id.toInt(),
                  child: Text(u.nombre ?? 'Usuario ${u.id}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    ClusterIconGenerator.clearCache();
    super.dispose();
  }
}
