import 'package:flutter/material.dart';
import '../../../datos/modelos/usuario.dart';

/// Widget que muestra la información del cliente de forma visual y destacada
class ClientInfoWidget extends StatelessWidget {
  final Usuario client;

  const ClientInfoWidget({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto de perfil del cliente
            _buildProfileImage(),
            const SizedBox(width: 16),

            // Información del cliente
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y categoría
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          client.nombre,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (client.clientCategory != null)
                        _buildCategoryChip(client.clientCategory!),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // CI
                  _buildInfoRow(
                    Icons.badge,
                    'CI',
                    client.ci ?? 'N/A',
                  ),
                  const SizedBox(height: 4),

                  // Teléfono
                  if (client.telefono != null)
                    _buildInfoRow(
                      Icons.phone,
                      'Tel',
                      client.telefono!,
                    ),

                  // Dirección (opcional, compacta)
                  if (client.direccion != null && client.direccion!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            client.direccion!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: ClipOval(
        child: client.profileImage != null && client.profileImage!.isNotEmpty
            ? Image.network(
                client.profileImage!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.blue[100],
      child: Icon(
        Icons.person,
        size: 40,
        color: Colors.blue[700],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color categoryColor;
    switch (category.toUpperCase()) {
      case 'A':
        categoryColor = Colors.green;
        break;
      case 'B':
        categoryColor = Colors.blue;
        break;
      case 'C':
        categoryColor = Colors.orange;
        break;
      case 'D':
        categoryColor = Colors.red;
        break;
      default:
        categoryColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: categoryColor),
      ),
      child: Text(
        'Categoría $category',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: categoryColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
