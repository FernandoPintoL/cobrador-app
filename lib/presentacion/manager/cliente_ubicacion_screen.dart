import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;
import '../../datos/modelos/usuario.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';

class ClienteUbicacionScreen extends StatefulWidget {
  final Usuario cliente;

  const ClienteUbicacionScreen({super.key, required this.cliente});

  @override
  State<ClienteUbicacionScreen> createState() => _ClienteUbicacionScreenState();
}

class _ClienteUbicacionScreenState extends State<ClienteUbicacionScreen> {
  GoogleMapController? _mapController;
  String _direccion = '';
  bool _isGettingAddress = false;
  LatLng? _clienteLocation;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    if (widget.cliente.latitud != null && widget.cliente.longitud != null) {
      _clienteLocation = LatLng(
        widget.cliente.latitud!,
        widget.cliente.longitud!,
      );
      _obtenerDireccionDesdeCoordenadas();
    }
  }

  Future<void> _obtenerDireccionDesdeCoordenadas() async {
    if (_clienteLocation == null) return;

    setState(() {
      _isGettingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _clienteLocation!.latitude,
        _clienteLocation!.longitude,
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
    _mapController = controller;
    if (_clienteLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_clienteLocation!, 16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_clienteLocation == null) {
      return Scaffold(
        appBar: RoleAppBar(
          title: 'Ubicación de ${widget.cliente.nombre}',
          role: 'manager',
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Este cliente no tiene ubicación GPS registrada',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: RoleAppBar(
        title: 'Ubicación de ${widget.cliente.nombre}',
        role: 'manager',
        actions: [
          if (widget.cliente.telefono.isNotEmpty)
            ContactActionsWidget.buildContactButton(
              context: context,
              userName: widget.cliente.nombre,
              phoneNumber: widget.cliente.telefono,
              userRole: 'cliente',
              customMessage: ContactActionsWidget.getDefaultMessage(
                'cliente',
                widget.cliente.nombre,
              ),
              color: RoleColors.clientePrimary,
              tooltip: 'Contactar cliente',
            ),
        ],
      ),
      body: Column(
        children: [
          // Header con información del cliente
          Container(
            padding: const EdgeInsets.all(16),
            color: RoleColors.clientePrimary.withOpacity(0.1),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: RoleColors.clientePrimary,
                  radius: 25,
                  backgroundImage: widget.cliente.profileImage.isNotEmpty
                      ? NetworkImage(widget.cliente.profileImage)
                      : null,
                  child: widget.cliente.profileImage.isEmpty
                      ? Text(
                          widget.cliente.nombre.isNotEmpty
                              ? widget.cliente.nombre[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.cliente.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.cliente.telefono.isNotEmpty)
                        Text(
                          widget.cliente.telefono,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.location_on,
                  color: RoleColors.clientePrimary,
                  size: 24,
                ),
              ],
            ),
          ),

          // Información de ubicación
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Ubicación del Cliente:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coordenadas: ${_clienteLocation!.latitude.toStringAsFixed(6)}, ${_clienteLocation!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (_direccion.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Dirección: $_direccion',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          if (_isGettingAddress) ...[
                            const SizedBox(height: 4),
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text('Obteniendo dirección...'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Mapa
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _clienteLocation!,
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: MarkerId('cliente_${widget.cliente.id}'),
                  position: _clienteLocation!,
                  infoWindow: InfoWindow(
                    title: widget.cliente.nombre,
                    snippet: widget.cliente.direccion.isNotEmpty
                        ? widget.cliente.direccion
                        : 'Cliente',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showClientActions,
        backgroundColor: RoleColors.clientePrimary,
        icon: const Icon(Icons.more_vert, color: Colors.white),
        label: const Text('Acciones', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showClientActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones para ${widget.cliente.nombre}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Contactar Cliente'),
              subtitle: widget.cliente.telefono.isNotEmpty
                  ? Text(widget.cliente.telefono)
                  : const Text('No tiene teléfono registrado'),
              onTap: () {
                Navigator.pop(context);
                if (widget.cliente.telefono.isNotEmpty) {
                  ContactActionsWidget.showContactDialog(
                    context: context,
                    userName: widget.cliente.nombre,
                    phoneNumber: widget.cliente.telefono,
                    userRole: 'cliente',
                    customMessage: ContactActionsWidget.getDefaultMessage(
                      'cliente',
                      widget.cliente.nombre,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Este cliente no tiene teléfono registrado',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.blue),
              title: const Text('Obtener Direcciones'),
              subtitle: const Text('Abrir en app de mapas externa'),
              onTap: () {
                Navigator.pop(context);
                _openExternalMaps();
              },
            ),
            /*ListTile(
              leading: const Icon(Icons.share, color: Colors.purple),
              title: const Text('Compartir Ubicación'),
              subtitle: const Text('Enviar coordenadas por WhatsApp/SMS'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
            ),*/
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openExternalMaps() async {
    if (_clienteLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene ubicación para navegar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final lat = _clienteLocation!.latitude;
    final lng = _clienteLocation!.longitude;
    final label = Uri.encodeComponent(
      _direccion.isNotEmpty
          ? _direccion
          : (widget.cliente.nombre.isNotEmpty
              ? widget.cliente.nombre
              : 'Destino'),
    );

    // URIs para diferentes servicios
    final Uri googleMapsApp = Platform.isIOS
        ? Uri.parse('comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=16')
        : Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    final Uri googleMapsWeb =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    final Uri wazeUri = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');

    // Apple Maps solo relevante en iOS
    final Uri appleMapsUri =
        Uri.parse('http://maps.apple.com/?ll=$lat,$lng&q=$label');

    Future<void> tryLaunch(Uri uri, {Uri? fallback}) async {
      try {
        final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (!launched && fallback != null) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
        }
      } catch (_) {
        if (fallback != null) {
          await launchUrl(fallback, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir la app de mapas'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    // Mostrar opciones de mapas al usuario
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const ListTile(
                title: Text('Abrir en mapas'),
                subtitle: Text('Selecciona la app para obtener direcciones'),
              ),
              if (Platform.isIOS || Platform.isAndroid)
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.red),
                  title: const Text('Google Maps'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    // En Android primero intentamos con geo:, en iOS con comgooglemaps:// y luego web
                    final Uri primary = Platform.isIOS ? googleMapsApp : googleMapsApp;
                    await tryLaunch(primary, fallback: googleMapsWeb);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.navigation, color: Colors.blue),
                title: const Text('Waze'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await tryLaunch(wazeUri, fallback: googleMapsWeb);
                },
              ),
              if (Platform.isIOS)
                ListTile(
                  leading: const Icon(Icons.directions, color: Colors.black87),
                  title: const Text('Apple Maps'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await tryLaunch(appleMapsUri);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.public, color: Colors.green),
                title: const Text('Abrir en navegador'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await tryLaunch(googleMapsWeb);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _shareLocation() {
    // TODO: Implementar compartir ubicación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Compartir ubicación - En desarrollo')),
    );
  }
}
