import 'package:flutter/material.dart';

class CobrosScreen extends StatelessWidget {
  const CobrosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cobros'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implementar nuevo cobro
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
            // Filtros de estado
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
                    label: const Text('Pendientes'),
                    selected: false,
                    onSelected: (bool selected) {
                      // TODO: Implementar filtro
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilterChip(
                    label: const Text('Completados'),
                    selected: false,
                    onSelected: (bool selected) {
                      // TODO: Implementar filtro
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Resumen de cobros
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Pendientes',
                        '0',
                        Colors.orange,
                        Icons.schedule,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Completados',
                        '0',
                        Colors.green,
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryItem(
                        'Total',
                        '\$0.00',
                        Colors.blue,
                        Icons.attach_money,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Lista de cobros
            Expanded(
              child: ListView.builder(
                itemCount: 0, // TODO: Implementar lista real
                itemBuilder: (context, index) {
                  return const Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.schedule, color: Colors.white),
                      ),
                      title: Text('Cobro Pendiente'),
                      subtitle: Text('Cliente: Juan Pérez\nMonto: \$100.00'),
                      trailing: Icon(Icons.arrow_forward_ios),
                    ),
                  );
                },
              ),
            ),

            // Mensaje cuando no hay cobros
            if (true) // TODO: Cambiar por condición real
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay cobros registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Registra tu primer cobro para comenzar',
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
          // TODO: Implementar nuevo cobro
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Función en desarrollo')),
          );
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryItem(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
