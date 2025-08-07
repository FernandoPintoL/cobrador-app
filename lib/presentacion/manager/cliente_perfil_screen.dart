import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';
import 'cliente_creditos_screen.dart';
import 'cliente_ubicacion_screen.dart';

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
                    CircleAvatar(
                      backgroundColor: RoleColors.clientePrimary,
                      radius: 40,
                      backgroundImage: cliente.profileImage.isNotEmpty
                          ? NetworkImage(cliente.profileImage)
                          : null,
                      child: cliente.profileImage.isEmpty
                          ? Text(
                              cliente.nombre.isNotEmpty
                                  ? cliente.nombre[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
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
                    if (cliente.telefono.isNotEmpty)
                      _buildInfoRow('Teléfono', cliente.telefono),
                    if (cliente.direccion.isNotEmpty)
                      _buildInfoRow('Dirección', cliente.direccion),
                  ],
                ),
              ),
            ),

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
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClienteUbicacionScreen(cliente: cliente),
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
