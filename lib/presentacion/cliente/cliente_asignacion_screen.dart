import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../negocio/providers/client_provider.dart';

class ClienteAsignacionScreen extends ConsumerStatefulWidget {
  final Usuario cliente;

  const ClienteAsignacionScreen({super.key, required this.cliente});

  @override
  ConsumerState<ClienteAsignacionScreen> createState() =>
      _ClienteAsignacionScreenState();
}

class _ClienteAsignacionScreenState
    extends ConsumerState<ClienteAsignacionScreen> {
  Usuario? _cobradorSeleccionado;
  Usuario? _cobradorActual;
  bool _cargandoCobradorActual = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  Future<void> _cargarDatos() async {
    // Cargar cobradores disponibles
    await ref.read(cobradorAssignmentProvider.notifier).cargarCobradores();

    // Obtener cobrador actual del cliente
    _cobradorActual = await ref
        .read(clientProvider.notifier)
        .obtenerCobradorDeCliente(widget.cliente.id.toString());

    setState(() {
      _cargandoCobradorActual = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final assignmentState = ref.watch(cobradorAssignmentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asignar Cliente'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: _cargandoCobradorActual
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información del cliente
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cliente a Asignar:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: const Color(0xFF667eea),
                                child: Text(
                                  widget.cliente.nombre.isNotEmpty
                                      ? widget.cliente.nombre[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.cliente.nombre,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      widget.cliente.email,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    if (widget.cliente.telefono.isNotEmpty)
                                      Text(
                                        widget.cliente.telefono,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Cobrador actual
                  if (_cobradorActual != null) ...[
                    Card(
                      color: Colors.orange[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cobrador Actual:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.orange,
                                  child: Text(
                                    _cobradorActual!.nombre.isNotEmpty
                                        ? _cobradorActual!.nombre[0]
                                              .toUpperCase()
                                        : 'C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _cobradorActual!.nombre,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        _cobradorActual!.email,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => _removerAsignacion(),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Remover'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Selección de nuevo cobrador
                  const Text(
                    'Asignar a Cobrador:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  if (assignmentState.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (assignmentState.error != null)
                    Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          assignmentState.error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    )
                  else if (assignmentState.cobradores.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No hay cobradores disponibles'),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: assignmentState.cobradores.length,
                        itemBuilder: (context, index) {
                          final cobrador = assignmentState.cobradores[index];
                          final isSelected =
                              _cobradorSeleccionado?.id == cobrador.id;
                          final isCurrentCobrador =
                              _cobradorActual?.id == cobrador.id;

                          return Card(
                            color: isSelected
                                ? const Color(0xFF667eea).withOpacity(0.1)
                                : isCurrentCobrador
                                ? Colors.grey[100]
                                : null,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCurrentCobrador
                                    ? Colors.grey
                                    : const Color(0xFF667eea),
                                child: Text(
                                  cobrador.nombre.isNotEmpty
                                      ? cobrador.nombre[0].toUpperCase()
                                      : 'C',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                cobrador.nombre,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cobrador.email),
                                  if (cobrador.telefono.isNotEmpty)
                                    Text(cobrador.telefono),
                                  if (isCurrentCobrador)
                                    const Text(
                                      'Cobrador actual',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF667eea),
                                    )
                                  : null,
                              onTap: isCurrentCobrador
                                  ? null
                                  : () {
                                      setState(() {
                                        _cobradorSeleccionado = cobrador;
                                      });
                                    },
                            ),
                          );
                        },
                      ),
                    ),

                  // Botones de acción
                  if (_cobradorSeleccionado != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: assignmentState.isLoading
                            ? null
                            : () => _asignarCliente(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: assignmentState.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'Asignar Cliente',
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Future<void> _asignarCliente() async {
    if (_cobradorSeleccionado == null) return;

    final success = await ref
        .read(clientProvider.notifier)
        .asignarClienteACobrador(
          cobradorId: _cobradorSeleccionado!.id.toString(),
          clientIds: [widget.cliente.id.toString()],
        );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente asignado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ref.read(clientProvider).error ?? 'Error al asignar cliente',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removerAsignacion() async {
    if (_cobradorActual == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Remoción'),
        content: Text(
          '¿Estás seguro de que quieres remover a ${widget.cliente.nombre} del cobrador ${_cobradorActual!.nombre}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(clientProvider.notifier)
          .removerClienteDeCobrador(
            cobradorId: _cobradorActual!.id.toString(),
            clientId: widget.cliente.id.toString(),
          );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente removido exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ref.read(clientProvider).error ?? 'Error al remover cliente',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
