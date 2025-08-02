import 'package:flutter/material.dart';

class ClientesScreen extends StatelessWidget {
  const ClientesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar agregar cliente
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Función en desarrollo')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de búsqueda
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 16),

            // Filtros
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: const Text('Todos'),
                    selected: true,
                    onSelected: (bool selected) {
                      // TODO: Implementar filtro
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Con Créditos'),
                    selected: false,
                    onSelected: (bool selected) {
                      // TODO: Implementar filtro
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Pendientes'),
                    selected: false,
                    onSelected: (bool selected) {
                      // TODO: Implementar filtro
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lista de clientes
            Expanded(
              child: ListView.builder(
                itemCount: 0, // TODO: Implementar lista real
                itemBuilder: (context, index) {
                  return const Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(0xFF667eea),
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text('Cliente Ejemplo'),
                      subtitle: Text('Dirección del cliente'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  );
                },
              ),
            ),

            // Mensaje cuando no hay clientes
            if (true) // TODO: Cambiar por condición real
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay clientes registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Agrega tu primer cliente para comenzar',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implementar agregar cliente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función en desarrollo')),
          );
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
