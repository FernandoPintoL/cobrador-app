import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';

class ClienteDetalleScreen extends ConsumerWidget {
  final Usuario cliente;

  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${cliente.nombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editarCliente(context),
          ),
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () => _llamarCliente(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente
            _buildClienteInfoCard(context),
            const SizedBox(height: 24),

            // Mapa con ubicación
            _buildMapaCard(context),
            const SizedBox(height: 24),

            // Préstamos activos
            _buildPrestamosCard(context),
            const SizedBox(height: 24),

            // Historial de cobros
            _buildHistorialCobrosCard(context),
            const SizedBox(height: 24),

            // Acciones rápidas
            _buildAccionesRapidasCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildClienteInfoCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    cliente.nombre.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cliente.nombre,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cliente.email,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        cliente.telefono,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (cliente.direccion.isNotEmpty) ...[
              const Text(
                'Dirección:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                cliente.direccion,
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMapaCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Ubicación del Cliente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: cliente.latitud != null && cliente.longitud != null
                ? _buildMapaWidget()
                : _buildSinUbicacionWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapaWidget() {
    // TODO: Implementar mapa real con Google Maps o similar
    return Container(
      decoration: BoxDecoration(
        color: Colors.blue[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.map, size: 48, color: Colors.blue),
            const SizedBox(height: 8),
            const Text(
              'Mapa de Ubicación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lat: ${cliente.latitud}, Lon: ${cliente.longitud}',
              style: const TextStyle(fontSize: 12, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSinUbicacionWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey),
            SizedBox(height: 8),
            Text(
              'Sin ubicación registrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'El cliente no tiene ubicación GPS',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrestamosCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Préstamos Activos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _verTodosPrestamos(context),
                  child: const Text('Ver todos'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPrestamoItem(
              'Préstamo #001',
              '\$5,000',
              '15/12/2024',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildPrestamoItem(
              'Préstamo #002',
              '\$3,500',
              '20/01/2025',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrestamoItem(
    String numero,
    String monto,
    String fecha,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  numero,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Vence: $fecha',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            monto,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorialCobrosCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Historial de Cobros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _verHistorialCompleto(context),
                  child: const Text('Ver todo'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildCobroItem(
              '\$500',
              '15/01/2025',
              'Pago parcial',
              Colors.green,
            ),
            const SizedBox(height: 8),
            _buildCobroItem(
              '\$1,000',
              '10/01/2025',
              'Pago completo',
              Colors.blue,
            ),
            const SizedBox(height: 8),
            _buildCobroItem(
              '\$750',
              '05/01/2025',
              'Pago parcial',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCobroItem(String monto, String fecha, String tipo, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.payment, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tipo, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  fecha,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Text(
            monto,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesRapidasCard(BuildContext context) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Acciones Rápidas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildAccionButton(
                    context,
                    'Registrar Cobro',
                    Icons.payment,
                    Colors.green,
                    () => _registrarCobro(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAccionButton(
                    context,
                    'Llamar',
                    Icons.phone,
                    Colors.blue,
                    () => _llamarCliente(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildAccionButton(
                    context,
                    'Enviar SMS',
                    Icons.sms,
                    Colors.orange,
                    () => _enviarSMS(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildAccionButton(
                    context,
                    'Navegar',
                    Icons.directions,
                    Colors.purple,
                    () => _navegarACliente(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccionButton(
    BuildContext context,
    String texto,
    IconData icono,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icono, size: 20),
      label: Text(texto),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _editarCliente(BuildContext context) {
    // TODO: Implementar edición de cliente
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Editar cliente - En desarrollo')),
    );
  }

  void _llamarCliente(BuildContext context) {
    // TODO: Implementar llamada al cliente
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Llamando a ${cliente.nombre}')));
  }

  void _verTodosPrestamos(BuildContext context) {
    // TODO: Implementar vista de todos los préstamos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ver todos los préstamos - En desarrollo')),
    );
  }

  void _verHistorialCompleto(BuildContext context) {
    // TODO: Implementar vista de historial completo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ver historial completo - En desarrollo')),
    );
  }

  void _registrarCobro(BuildContext context) {
    // TODO: Implementar registro de cobro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registrar cobro - En desarrollo')),
    );
  }

  void _enviarSMS(BuildContext context) {
    // TODO: Implementar envío de SMS
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Enviar SMS - En desarrollo')));
  }

  void _navegarACliente(BuildContext context) {
    // TODO: Implementar navegación al cliente
    if (cliente.latitud != null && cliente.longitud != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Abriendo navegación...')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El cliente no tiene ubicación registrada'),
        ),
      );
    }
  }
}
