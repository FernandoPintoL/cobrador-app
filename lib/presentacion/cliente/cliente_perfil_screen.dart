import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../datos/modelos/usuario.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../ui/widgets/response_viewer_dialog.dart';
import '../widgets/profile_image_widget.dart';
import 'cliente_creditos_screen.dart';
import 'location_picker_screen.dart';
import '../../datos/servicios/base_api_service.dart';
import '../../datos/servicios/user_api_service.dart';

class ClientePerfilScreen extends ConsumerWidget {
  final Usuario cliente;

  const ClientePerfilScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: RoleAppBar(
        title: 'Perfil de ${cliente.nombre}',
        role: 'manager',
        actions: [
          /*IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Ver categorías',
            onPressed: () async {
              final resp = await ref.read(userManagementProvider.notifier).fetchClientCategories();
              ResponseViewerDialog.show(context, Map<String, dynamic>.from(resp), title: 'Categorías disponibles');
            },
          ),*/
          if (cliente.telefono.isNotEmpty)
            ContactActionsWidget.buildContactButton(
              context: context,
              userName: cliente.nombre,
              phoneNumber: cliente.telefono,
              userRole: 'cliente',
              customMessage: ContactActionsWidget.getDefaultMessage(
                'cliente',
                cliente.nombre,
              ),
              color: RoleColors.clientePrimary,
              tooltip: 'Contactar cliente',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header con información básica
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Usar widget que resuelve correctamente la URL de imagen de perfil
                    ProfileImageWidget(
                      profileImage: cliente.profileImage,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      cliente.nombre,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: RoleColors.clientePrimary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Cliente',
                            style: TextStyle(
                              color: RoleColors.clientePrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${cliente.clientCategory ?? 'B'} - ${cliente.clientCategoryName}',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Información personal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Información Personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('ID', cliente.id.toString()),
                    _buildInfoRow('Nombre', cliente.nombre),
                    _buildInfoRow('Email', cliente.email),
                    _buildInfoRow('Roles', cliente.roles.join(', ')),
                    _buildInfoRow('Categoría', cliente.clientCategoryName),
                    if (cliente.telefono.isNotEmpty)
                      _buildInfoRow('Teléfono', cliente.telefono),
                    if (cliente.direccion.isNotEmpty)
                      _buildInfoRow('Dirección', cliente.direccion),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Fotos de CI registradas
            _ClientIdPhotosSection(cliente: cliente),

            const SizedBox(height: 16),

            // Acciones rápidas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flash_on, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'Acciones Disponibles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActionTile(
                      'Ver Créditos',
                      'Revisar historial de créditos del cliente',
                      Icons.account_balance_wallet,
                      Colors.green,
                      () => _navigateToCredits(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      'Ver en Mapa',
                      'Mostrar ubicación del cliente en el mapa',
                      Icons.map,
                      Colors.blue,
                      () => _showOnMap(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      'Contactar Cliente',
                      'Llamar o enviar WhatsApp al cliente',
                      Icons.phone,
                      Colors.orange,
                      () => _contactClient(context),
                    ),
                    const SizedBox(height: 8),
                    _buildActionTile(
                      'Cambiar Categoría',
                      'Actualizar categoría del cliente (A/B/C)',
                      Icons.category,
                      Colors.purple,
                      () => _changeCategory(context, ref),
                    ),
                    const SizedBox(height: 8),
                    /*_buildActionTile(
                      'Ver Estadísticas de Categorías',
                      'Mostrar conteos por categoría del sistema',
                      Icons.bar_chart,
                      Colors.teal,
                      () => _showCategoryStats(context, ref),
                    ),*/
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _changeCategory(BuildContext context, WidgetRef ref) async {
    final current = (cliente.clientCategory ?? 'B').toUpperCase();
    String selected = current;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar categoría'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              value: 'A',
              groupValue: selected,
              title: const Text('A - Cliente VIP'),
              onChanged: (v) => {selected = v!, Navigator.of(context).pop()},
            ),
            RadioListTile<String>(
              value: 'B',
              groupValue: selected,
              title: const Text('B - Cliente Normal'),
              onChanged: (v) => {selected = v!, Navigator.of(context).pop()},
            ),
            RadioListTile<String>(
              value: 'C',
              groupValue: selected,
              title: const Text('C - Mal Cliente'),
              onChanged: (v) => {selected = v!, Navigator.of(context).pop()},
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        ],
      ),
    );

    if (selected != current) {
      final resp = await ref.read(userManagementProvider.notifier).updateClientCategoryApi(
            clientId: cliente.id,
            category: selected,
          );
      // Mostrar respuesta del endpoint
      ResponseViewerDialog.show(context, Map<String, dynamic>.from(resp), title: 'Respuesta: actualizar categoría');
    }
  }

  Future<void> _showCategoryStats(BuildContext context, WidgetRef ref) async {
    final resp = await ref.read(userManagementProvider.notifier).fetchCategoryStatistics();
  ResponseViewerDialog.show(context, Map<String, dynamic>.from(resp), title: 'Estadísticas de categorías');
  }

  void _navigateToCredits(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteCreditosScreen(cliente: cliente),
      ),
    );
  }

  void _showOnMap(BuildContext context) {
    if (cliente.latitud != null && cliente.longitud != null) {
      // Crear marcador para la ubicación del cliente
      final clienteMarker = Marker(
        markerId: MarkerId('cliente_${cliente.id}'),
        position: LatLng(cliente.latitud!, cliente.longitud!),
        infoWindow: InfoWindow(
          title: cliente.nombre,
          snippet: 'Cliente ${cliente.clientCategory ?? 'B'} - ${cliente.telefono}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            allowSelection: false, // Modo solo visualización
            extraMarkers: {clienteMarker},
            customTitle: 'Ubicación de ${cliente.nombre}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene ubicación GPS registrada'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _contactClient(BuildContext context) {
    if (cliente.telefono.isNotEmpty) {
      ContactActionsWidget.showContactDialog(
        context: context,
        userName: cliente.nombre,
        phoneNumber: cliente.telefono,
        userRole: 'cliente',
        customMessage: ContactActionsWidget.getDefaultMessage(
          'cliente',
          cliente.nombre,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene teléfono registrado'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

class _ClientIdPhotosSection extends StatelessWidget {
  final Usuario cliente;
  const _ClientIdPhotosSection({required this.cliente});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UserApiService().listUserPhotos(cliente.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Cargando fotos de CI...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se pudieron cargar las fotos de CI: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final photos = (snapshot.data ?? []);
        // Filtrar fotos relacionadas al CI (id card)
        List<Map<String, dynamic>> ciPhotos = photos.where((p) {
          final type = (p['type'] ?? p['category'] ?? p['tag'] ?? '').toString().toLowerCase();
          return type.contains('id') || type.contains('ci') || type.contains('carnet');
        }).map((e) => Map<String, dynamic>.from(e)).toList();

        // Si la API no envía tipos y hay fotos, mostrarlas todas como respaldo
        if (ciPhotos.isEmpty && photos.isNotEmpty) {
          ciPhotos = photos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        if (ciPhotos.isEmpty) {
          // Si no hay fotos de CI ni fotos en general, no mostrar nada
          return const SizedBox.shrink();
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.badge, color: Colors.teal),
                    SizedBox(width: 8),
                    Text(
                      'Fotos de CI',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: ciPhotos.length,
                  itemBuilder: (context, index) {
                    final item = ciPhotos[index];
                    final url = _resolvePhotoUrl(item);
                    final label = (item['type'] ?? '').toString().toLowerCase();
                    final pretty = label.contains('front') || label.contains('anverso')
                        ? 'Anverso'
                        : (label.contains('back') || label.contains('reverso'))
                            ? 'Reverso'
                            : 'Documento';

                    return _IdPhotoTile(url: url, label: pretty);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _resolvePhotoUrl(Map<String, dynamic> item) {
    final dynamic directUrl = item['url'] ?? item['image_url'];
    if (directUrl is String && directUrl.startsWith('http')) {
      return directUrl;
    }
    final String? path = (item['path'] ?? item['file_path'] ?? item['image'])?.toString();
    if (path == null || path.isEmpty) return UserApiService().getProfileImageUrl('');

    // Construir URL similar a getProfileImageUrl
    final serverUrl = BaseApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      // Si ya empieza con '/', asumir que es ruta absoluta del servidor
      return '$serverUrl$path';
    }
    // Asegurar prefijo storage
    final full = path.startsWith('storage/') ? path : 'storage/$path';
    return '$serverUrl/$full';
  }
}

class _IdPhotoTile extends StatelessWidget {
  final String url;
  final String label;
  const _IdPhotoTile({required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openViewer(context, url, label),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.zoom_in, size: 14, color: Colors.white70),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(imageUrl: url, fit: BoxFit.contain),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
