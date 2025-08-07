import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import '../pantallas/location_picker_screen.dart';

class ManagerClienteFormScreen extends ConsumerStatefulWidget {
  final Usuario? cliente; // null para crear, con datos para editar
  final VoidCallback? onClienteSaved;

  const ManagerClienteFormScreen({
    super.key,
    this.cliente,
    this.onClienteSaved,
  });

  @override
  ConsumerState<ManagerClienteFormScreen> createState() =>
      _ManagerClienteFormScreenState();
}

class _ManagerClienteFormScreenState
    extends ConsumerState<ManagerClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _esEdicion = false;
  bool _isLoading = false;

  // Variables para ubicación GPS
  double? _latitud;
  double? _longitud;
  bool _ubicacionObtenida = false;

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.cliente != null;

    if (_esEdicion) {
      _nombreController.text = widget.cliente!.nombre;
      _emailController.text = widget.cliente!.email;
      _telefonoController.text = widget.cliente!.telefono;
      _direccionController.text = widget.cliente!.direccion;

      // Cargar ubicación si existe
      if (widget.cliente!.latitud != null && widget.cliente!.longitud != null) {
        _latitud = widget.cliente!.latitud;
        _longitud = widget.cliente!.longitud;
        _ubicacionObtenida = true;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cliente' : 'Crear Cliente'),
        backgroundColor: RoleColors.managerPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_esEdicion)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmarEliminarCliente,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Información Personal',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _nombreController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre Completo *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El nombre es obligatorio';
                                }
                                if (value.trim().length < 2) {
                                  return 'El nombre debe tener al menos 2 caracteres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email (opcional)',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                // Email es opcional, solo validar formato si se proporciona
                                if (value != null && value.trim().isNotEmpty) {
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Ingrese un email válido';
                                  }
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _telefonoController,
                              decoration: const InputDecoration(
                                labelText: 'Teléfono *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.phone),
                              ),
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El teléfono es obligatorio';
                                }
                                if (value.trim().length < 8) {
                                  return 'El teléfono debe tener al menos 8 dígitos';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _direccionController,
                              decoration: InputDecoration(
                                labelText: 'Dirección',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.location_on),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _ubicacionObtenida
                                        ? Icons.gps_fixed
                                        : Icons.gps_not_fixed,
                                    color: _ubicacionObtenida
                                        ? Colors.green
                                        : null,
                                  ),
                                  onPressed: _obtenerUbicacionGPS,
                                  tooltip: 'Obtener ubicación GPS',
                                ),
                                helperText: _ubicacionObtenida
                                    ? 'Ubicación GPS obtenida ✓'
                                    : 'Presiona el botón GPS para obtener ubicación automáticamente',
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    /* const SizedBox(height: 16),
                    if (!_esEdicion) // Solo mostrar contraseña para nuevos clientes
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Credenciales de Acceso (Opcional)',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Solo necesario si el cliente tendrá acceso al sistema',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contrasenaController,
                                decoration: const InputDecoration(
                                  labelText: 'Contraseña (opcional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.lock),
                                  helperText:
                                      'Dejar vacío si el cliente no necesita acceso al sistema',
                                ),
                                obscureText: true,
                                validator: (value) {
                                  // Contraseña es opcional para clientes
                                  if (value != null && value.isNotEmpty) {
                                    if (value.length < 6) {
                                      return 'Si establece contraseña, debe tener al menos 6 caracteres';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ), */
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _guardarCliente,
                            child: Text(
                              _esEdicion ? 'Actualizar' : 'Crear Cliente',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _obtenerUbicacionGPS() async {
    try {
      // Navegar a la pantalla de selección de ubicación
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
      );

      if (result != null) {
        setState(() {
          _latitud = result['latitud'] as double?;
          _longitud = result['longitud'] as double?;
          _ubicacionObtenida = true;

          // Si viene una dirección, la usamos
          if (result['direccion'] != null &&
              result['direccion'].toString().isNotEmpty) {
            _direccionController.text = result['direccion'] as String;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación GPS obtenida correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.usuario == null) {
        throw Exception('Usuario no autenticado');
      }

      if (_esEdicion) {
        await ref
            .read(userManagementProvider.notifier)
            .actualizarUsuario(
              id: widget.cliente!.id,
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              latitud: _latitud,
              longitud: _longitud,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente actualizado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await ref
            .read(userManagementProvider.notifier)
            .crearUsuario(
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              roles: ['client'],
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              password: _contrasenaController.text.isNotEmpty
                  ? _contrasenaController.text
                  : null,
              latitud: _latitud,
              longitud: _longitud,
            );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cliente creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (widget.onClienteSaved != null) {
        widget.onClienteSaved!();
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al ${_esEdicion ? 'actualizar' : 'crear'} cliente: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _confirmarEliminarCliente() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente a ${widget.cliente!.nombre}?\n\n'
          'Esta acción no se puede deshacer y el cliente será eliminado del sistema.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _eliminarCliente();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _eliminarCliente() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(userManagementProvider.notifier)
          .eliminarUsuario(widget.cliente!.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cliente ${widget.cliente!.nombre} eliminado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );

        if (widget.onClienteSaved != null) {
          widget.onClienteSaved!();
        }

        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
