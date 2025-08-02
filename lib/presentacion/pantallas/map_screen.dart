import 'package:flutter/material.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              // TODO: Implementar centrar en mi ubicación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función en desarrollo')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implementar filtros del mapa
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función en desarrollo')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Placeholder del mapa
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[200],
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Mapa en desarrollo',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aquí se mostrarán las ubicaciones de los clientes',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Panel de información
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Resumen del Mapa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMapStat(
                            'Clientes',
                            '0',
                            Icons.people,
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildMapStat(
                            'Pendientes',
                            '0',
                            Icons.schedule,
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildMapStat(
                            'Completados',
                            '0',
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón flotante para agregar cliente
          Positioned(
            bottom: 100,
            right: 16,
            child: FloatingActionButton(
              onPressed: () {
                // TODO: Implementar agregar cliente desde mapa
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Función en desarrollo')),
                );
              },
              backgroundColor: const Color(0xFF667eea),
              child: const Icon(Icons.add_location, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapStat(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
