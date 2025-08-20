import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../datos/modelos/usuario.dart';
import 'location_picker_screen.dart';

class ClienteUbicacionScreen extends StatelessWidget {
  final Usuario cliente;

  const ClienteUbicacionScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context) {
    // Si el cliente no tiene coordenadas, mostramos un mensaje amigable
    if (cliente.latitud == null || cliente.longitud == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Ubicación de ${cliente.nombre}')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Este cliente no tiene ubicación GPS registrada',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    // Crear un marcador para el cliente
    final marker = Marker(
      markerId: MarkerId('cliente_${cliente.id}'),
      position: LatLng(cliente.latitud!, cliente.longitud!),
      infoWindow: InfoWindow(
        title: cliente.nombre,
        snippet: (cliente.direccion.isNotEmpty)
            ? cliente.direccion
            : 'Cliente',
      ),
    );

    return LocationPickerScreen(
      allowSelection: false,
      extraMarkers: {marker},
      customTitle: 'Ubicación de ${cliente.nombre}',
    );
  }
}
