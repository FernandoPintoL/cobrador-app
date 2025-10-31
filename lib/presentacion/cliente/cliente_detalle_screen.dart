import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/client_provider.dart';
import 'cliente_form_screen.dart';
import 'cliente_asignacion_screen.dart';

class ClienteDetalleScreen extends ConsumerStatefulWidget {
  final Usuario cliente;

  const ClienteDetalleScreen({super.key, required this.cliente});

  @override
  ConsumerState<ClienteDetalleScreen> createState() =>
      _ClienteDetalleScreenState();
}

class _ClienteDetalleScreenState extends ConsumerState<ClienteDetalleScreen> {
  Usuario? _cobradorAsignado;
  bool _cargandoCobrador = true;

  @override
  void initState() {
    super.initState();
    _cargarCobradorAsignado();
  }

  Future<void> _cargarCobradorAsignado() async {
    try {
      _cobradorAsignado = await ref
          .read(clientProvider.notifier)
          .obtenerCobradorDeCliente(widget.cliente.id.toString());
    } catch (e) {
      print('Error al cargar cobrador asignado: $e');
    } finally {
      setState(() {
        _cargandoCobrador = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${widget.cliente.nombre}'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        actions: [
          if (authState.isManager || authState.isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editarCliente(context);
                    break;
                  case 'delete':
                    _confirmarEliminacion(context, ref);
                    break;
                  case 'assign':
                    _asignarACobrador(context);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'assign',
                  child: Row(
                    children: [
                      Icon(Icons.person_add, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Asignar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con información principal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF667eea),
                      child: Text(
                        widget.cliente.nombre.isNotEmpty
                            ? widget.cliente.nombre[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.cliente.nombre,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.cliente.email,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Cliente',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Información de contacto
            _buildSection(
              context,
              'Información de Contacto',
              Icons.contact_phone,
              [
                if (widget.cliente.telefono.isNotEmpty)
                  _buildInfoRow('📞 Teléfono', widget.cliente.telefono),
                _buildInfoRow('📧 Email', widget.cliente.email),
                if (widget.cliente.direccion.isNotEmpty)
                  _buildInfoRow('📍 Dirección', widget.cliente.direccion),
              ],
            ),
            const SizedBox(height: 24),

            // Información de ubicación
            if (widget.cliente.latitud != null &&
                widget.cliente.longitud != null)
              _buildSection(context, 'Ubicación', Icons.location_on, [
                _buildInfoRow('Latitud', widget.cliente.latitud.toString()),
                _buildInfoRow('Longitud', widget.cliente.longitud.toString()),
              ]),
            if (widget.cliente.latitud != null &&
                widget.cliente.longitud != null)
              const SizedBox(height: 24),

            // Información del sistema
            _buildSection(context, 'Información del Sistema', Icons.info, [
              _buildInfoRow('ID', widget.cliente.id.toString()),
              _buildInfoRow(
                'Fecha de registro',
                _formatDate(widget.cliente.fechaCreacion),
              ),
              _buildInfoRow(
                'Última actualización',
                _formatDate(widget.cliente.fechaActualizacion),
              ),
            ]),
            const SizedBox(height: 24),

            // Información del cobrador asignado
            if (!_cargandoCobrador) ...[
              _buildSection(
                context,
                'Cobrador Asignado',
                Icons.person,
                _cobradorAsignado != null
                    ? [
                        _buildInfoRow('Nombre', _cobradorAsignado!.nombre),
                        _buildInfoRow('Email', _cobradorAsignado!.email),
                        if (_cobradorAsignado!.telefono.isNotEmpty)
                          _buildInfoRow(
                            'Teléfono',
                            _cobradorAsignado!.telefono,
                          ),
                      ]
                    : [_buildInfoRow('Estado', 'Sin asignar')],
              ),
              const SizedBox(height: 24),
            ],

            // Acciones rápidas
            _buildSection(
              context,
              'Acciones Rápidas',
              Icons.flash_on,
              [],
              showContent: false,
            ),
            const SizedBox(height: 16),

            // Botones de acción
            Column(
              children: [
                _buildActionButton(
                  context,
                  'Ver Créditos',
                  Icons.account_balance_wallet,
                  Colors.green,
                  () => _verCreditos(context),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  'Ver Historial de Pagos',
                  Icons.history,
                  Colors.orange,
                  () => _verHistorialPagos(context),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  'Registrar Cobro',
                  Icons.payment,
                  Colors.purple,
                  () => _registrarCobro(context),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  context,
                  'Ver en Mapa',
                  Icons.map,
                  Colors.blue,
                  () => _verEnMapa(context),
                ),
                if (authState.isManager || authState.isAdmin) ...[
                  const SizedBox(height: 12),
                  _buildActionButton(
                    context,
                    _cobradorAsignado != null
                        ? 'Reasignar Cobrador'
                        : 'Asignar a Cobrador',
                    Icons.person_add,
                    Colors.teal,
                    () => _asignarACobrador(context),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children, {
    bool showContent = true,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF667eea)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            if (showContent) ...[const SizedBox(height: 16), ...children],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _editarCliente(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteFormScreen(
          cliente: widget.cliente
          /*onClienteCreated: () {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cliente actualizado exitosamente')),
            );
          },*/
        ),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${widget.cliente.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Cerrar diálogo

              final authState = ref.read(authProvider);
              final cobradorId = authState.isCobrador
                  ? authState.usuario?.id.toString()
                  : null;

              final success = await ref
                  .read(clientProvider.notifier)
                  .eliminarCliente(
                    id: widget.cliente.id.toString(),
                    cobradorId: cobradorId,
                  );

              if (success && context.mounted) {
                Navigator.pop(context); // Volver a la lista
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cliente eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _asignarACobrador(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteAsignacionScreen(cliente: widget.cliente),
      ),
    ).then((result) {
      if (result == true) {
        _cargarCobradorAsignado();
      }
    });
  }

  void _verCreditos(BuildContext context) {
    // TODO: Implementar vista de créditos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vista de créditos - En desarrollo')),
    );
  }

  void _verHistorialPagos(BuildContext context) {
    // TODO: Implementar vista de historial de pagos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historial de pagos - En desarrollo')),
    );
  }

  void _registrarCobro(BuildContext context) {
    // TODO: Implementar registro de cobro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro de cobro - En desarrollo')),
    );
  }

  void _verEnMapa(BuildContext context) {
    // TODO: Implementar vista en mapa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vista en mapa - En desarrollo')),
    );
  }
}
