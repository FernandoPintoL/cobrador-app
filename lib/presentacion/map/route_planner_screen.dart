import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../datos/modelos/map/client_to_visit.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/map_provider.dart';
import '../../negocio/services/route_optimization_service.dart';
import 'route_map_view_screen.dart';

/// Pantalla de planificación de rutas optimizadas
class RoutePlannerScreen extends ConsumerStatefulWidget {
  const RoutePlannerScreen({super.key});

  @override
  ConsumerState<RoutePlannerScreen> createState() => _RoutePlannerScreenState();
}

class _RoutePlannerScreenState extends ConsumerState<RoutePlannerScreen> {
  bool _isLoading = true;
  List<ClientToVisit> _clients = [];
  List<ClientToVisit> _optimizedRoute = [];
  Position? _currentPosition;
  String? _errorMessage;
  bool _prioritizeUrgent = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Obtener ubicación actual
      final position = await _getCurrentPosition();

      // Obtener clientes a visitar
      final authState = ref.read(authProvider);
      final userId = authState.usuario?.id;
      final cobradorId = userId != null ? userId.toInt() : null;

      final mapService = ref.read(mapApiProvider);
      final response = await mapService.getClientsToVisitToday(
        cobradorId: cobradorId,
      );

      // El backend devuelve {success: true, data: [], message: "..."}
      final clientsData = (response['data'] as List?) ?? [];
      final clients = clientsData
          .map((json) => ClientToVisit.fromJson(json as Map<String, dynamic>))
          .toList();

      // Optimizar ruta
      final optimized = RouteOptimizationService.optimizeRoute(
        clients: clients,
        startLat: position.latitude,
        startLng: position.longitude,
        prioritizeUrgent: _prioritizeUrgent,
      );

      setState(() {
        _currentPosition = position;
        _clients = clients;
        _optimizedRoute = optimized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar datos: $e';
        _isLoading = false;
      });
    }
  }

  Future<Position> _getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Los servicios de ubicación están desactivados');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Permisos de ubicación denegados');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permisos de ubicación denegados permanentemente');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _togglePrioritization() {
    setState(() {
      _prioritizeUrgent = !_prioritizeUrgent;
    });

    if (_currentPosition != null && _clients.isNotEmpty) {
      final optimized = RouteOptimizationService.optimizeRoute(
        clients: _clients,
        startLat: _currentPosition!.latitude,
        startLng: _currentPosition!.longitude,
        prioritizeUrgent: _prioritizeUrgent,
      );

      setState(() {
        _optimizedRoute = optimized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificar Ruta'),
        backgroundColor: Colors.green,
        actions: [
          if (!_isLoading && _clients.isNotEmpty)
            IconButton(
              icon: Icon(_prioritizeUrgent ? Icons.priority_high : Icons.sort),
              tooltip: _prioritizeUrgent
                  ? 'Priorizar urgentes: ON'
                  : 'Priorizar urgentes: OFF',
              onPressed: _togglePrioritization,
            ),
          if (!_isLoading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Recargar',
              onPressed: _loadData,
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: !_isLoading &&
              _optimizedRoute.isNotEmpty &&
              _currentPosition != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RouteMapViewScreen(
                      clients: _optimizedRoute,
                      currentPosition: _currentPosition!,
                      prioritizeUrgent: _prioritizeUrgent,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.map),
              label: const Text('Ver en Mapa'),
              backgroundColor: Colors.green,
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Cargando clientes y optimizando ruta...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: _loadData,
            ),
          ],
        ),
      );
    }

    if (_optimizedRoute.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            const Text(
              'No hay clientes para visitar hoy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '¡Buen trabajo! Todos los pagos están al día.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final totalDistance = RouteOptimizationService.calculateTotalDistance(
      route: _optimizedRoute,
      startLat: _currentPosition!.latitude,
      startLng: _currentPosition!.longitude,
    );
    final estimatedTime = RouteOptimizationService.calculateEstimatedTime(totalDistance);

    return Column(
      children: [
        // Resumen de ruta
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                icon: Icons.people,
                label: 'Clientes',
                value: '${_optimizedRoute.length}',
                color: Colors.blue,
              ),
              _buildStatCard(
                icon: Icons.route,
                label: 'Distancia',
                value: RouteOptimizationService.formatDistance(totalDistance),
                color: Colors.orange,
              ),
              _buildStatCard(
                icon: Icons.access_time,
                label: 'Tiempo est.',
                value: RouteOptimizationService.formatTime(estimatedTime),
                color: Colors.purple,
              ),
            ],
          ),
        ),

        // Lista de clientes ordenados
        Expanded(
          child: ListView.builder(
            itemCount: _optimizedRoute.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final client = _optimizedRoute[index];
              final distance = _calculateDistanceFromPrevious(index);

              return _buildClientCard(client, index + 1, distance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  double _calculateDistanceFromPrevious(int index) {
    if (index == 0) {
      // Distancia desde ubicación actual
      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _optimizedRoute[0].latitude,
        _optimizedRoute[0].longitude,
      );
    } else {
      // Distancia desde cliente anterior
      final prev = _optimizedRoute[index - 1];
      final curr = _optimizedRoute[index];
      return Geolocator.distanceBetween(
        prev.latitude,
        prev.longitude,
        curr.latitude,
        curr.longitude,
      );
    }
  }

  Widget _buildClientCard(ClientToVisit client, int orderNumber, double distance) {
    final priorityColor = _getPriorityColor(client.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Número de orden
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$orderNumber',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Información del cliente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y prioridad
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          client.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: priorityColor),
                        ),
                        child: Text(
                          client.priorityLabel,
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Dirección
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          client.address,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Distancia desde punto anterior
                  Row(
                    children: [
                      Icon(
                        orderNumber == 1 ? Icons.my_location : Icons.arrow_forward,
                        size: 14,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        orderNumber == 1
                            ? 'Desde tu ubicación: ${RouteOptimizationService.formatDistance(distance)}'
                            : 'Desde anterior: ${RouteOptimizationService.formatDistance(distance)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  // Información de pago
                  if (client.hasOverdue) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.warning, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Vencido: \$${client.overdueAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (client.nextPaymentDate != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Próximo pago: \$${client.nextPaymentAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Botón de navegación
            IconButton(
              icon: const Icon(Icons.navigation, color: Colors.green),
              onPressed: () => _openNavigation(client),
              tooltip: 'Navegar',
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openNavigation(ClientToVisit client) async {
    // Mostrar diálogo para elegir app de navegación
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navegar a cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pop(context);
                _launchNavigation(client, 'google');
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.purple),
              title: const Text('Waze'),
              onTap: () {
                Navigator.pop(context);
                _launchNavigation(client, 'waze');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchNavigation(ClientToVisit client, String app) async {
    final lat = client.latitude;
    final lng = client.longitude;

    String url;
    if (app == 'google') {
      url = 'google.navigation:q=$lat,$lng';
    } else {
      url = 'waze://?ll=$lat,$lng&navigate=yes';
    }

    try {
      final uri = Uri.parse(url);
      final canLaunch = await canLaunchUrl(uri);

      if (canLaunch) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No se pudo abrir ${app == "google" ? "Google Maps" : "Waze"}'),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir navegación: $e')),
        );
      }
    }
  }
}
