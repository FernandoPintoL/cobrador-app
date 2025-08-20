import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../cliente/location_picker_screen.dart';

class CobradorFormScreen extends ConsumerStatefulWidget {
  final Usuario? cobrador; // null para crear, con datos para editar
  final VoidCallback? onCobradorSaved;

  const CobradorFormScreen({
    super.key,
    this.cobrador,
    this.onCobradorSaved,
  });

  @override
  ConsumerState<CobradorFormScreen> createState() =>
      _ManagerCobradorFormScreenState();
}

class _ManagerCobradorFormScreenState
    extends ConsumerState<CobradorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _ciController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEditMode = false;

  // Variables para ubicación GPS
  double? _latitud;
  double? _longitud;
  bool _ubicacionObtenida = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.cobrador != null;

    if (_isEditMode) {
      _nombreController.text = widget.cobrador!.nombre;
      _emailController.text = widget.cobrador!.email;
      _telefonoController.text = widget.cobrador!.telefono;
      _direccionController.text = widget.cobrador!.direccion;
      _ciController.text = widget.cobrador!.ci;

      // Cargar ubicación si existe
      if (widget.cobrador!.latitud != null &&
          widget.cobrador!.longitud != null) {
        _latitud = widget.cobrador!.latitud;
        _longitud = widget.cobrador!.longitud;
        _ubicacionObtenida = true;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Editar Cobrador' : 'Crear Cobrador'),
        actions: [
          if (_isEditMode)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmarEliminarCobrador(),
              tooltip: 'Eliminar cobrador',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del formulario
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        _isEditMode ? Icons.edit : Icons.person_add,
                        size: 48,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditMode
                            ? 'Modificar información del cobrador'
                            : 'Crear nuevo cobrador en tu equipo',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campos del formulario
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre';
                  }
                  if (value.length < 3) {
                    return 'El nombre debe tener al menos 3 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el correo electrónico';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Por favor ingresa un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _isEditMode
                      ? 'Nueva Contraseña (opcional)'
                      : 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  helperText: _isEditMode
                      ? 'Deja vacío si no deseas cambiar la contraseña'
                      : 'Mínimo 6 caracteres',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
                validator: (value) {
                  if (!_isEditMode) {
                    // En modo creación, la contraseña es obligatoria
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa una contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                  } else {
                    // En modo edición, la contraseña es opcional pero debe ser válida si se proporciona
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefonoController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el teléfono';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: const Icon(Icons.location_on),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ubicacionObtenida
                          ? Icons.gps_fixed
                          : Icons.gps_not_fixed,
                      color: _ubicacionObtenida ? Colors.green : null,
                    ),
                    onPressed: _obtenerUbicacionGPS,
                    tooltip: 'Obtener ubicación GPS',
                  ),
                  helperText: _ubicacionObtenida
                      ? 'Ubicación GPS obtenida ✓'
                      : 'Presiona el botón GPS para obtener ubicación automáticamente',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa la dirección';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarCobrador,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_isEditMode ? 'Actualizar' : 'Crear Cobrador'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Mostrar errores de validación si los hay
              Consumer(
                builder: (context, ref, child) {
                  final userManagementState = ref.watch(userManagementProvider);
                  if (userManagementState.error != null) {
                    return Card(
                      color: Colors.red[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                userManagementState.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
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

        _mostrarExito('Ubicación GPS obtenida correctamente');
      }
    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    }
  }

  Future<void> _guardarCobrador() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authProvider);
      final managerId = authState.usuario?.id.toString();

      if (managerId == null) {
        _mostrarError('Error: No se pudo identificar el manager');
        return;
      }

      if (_isEditMode) {
        // Actualizar cobrador existente
        final success = await ref
            .read(userManagementProvider.notifier)
            .actualizarUsuario(
              id: widget.cobrador!.id,
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              ci: _ciController.text.trim(),
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              password: _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
              latitud: _latitud,
              longitud: _longitud,
            );

        if (success) {
          _mostrarExito('Cobrador actualizado exitosamente');
          // Recargar datos del manager
          await ref
              .read(managerProvider.notifier)
              .cargarCobradoresAsignados(managerId);
          widget.onCobradorSaved?.call();
          Navigator.pop(context);
        }
      } else {
        // Crear nuevo cobrador
        final success = await ref
            .read(userManagementProvider.notifier)
            .crearUsuario(
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              ci: _ciController.text.trim(),
              password: _passwordController.text,
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              roles: ['cobrador'],
              latitud: _latitud,
              longitud: _longitud,
            );

        if (success) {
          _mostrarExito('Cobrador creado exitosamente');
          // Asignar el cobrador al manager después de crearlo
          // TODO: Implementar asignación automática al manager

          // Recargar datos del manager
          await ref
              .read(managerProvider.notifier)
              .cargarCobradoresAsignados(managerId);
          widget.onCobradorSaved?.call();
          Navigator.pop(context);
        }
      }
    } catch (e) {
      _mostrarError('Error inesperado: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmarEliminarCobrador() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Cobrador'),
        content: Text(
          '¿Estás seguro de que deseas eliminar a ${widget.cobrador!.nombre}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _eliminarCobrador();
    }
  }

  Future<void> _eliminarCobrador() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final success = await ref
          .read(userManagementProvider.notifier)
          .eliminarUsuario(widget.cobrador!.id);

      if (success) {
        _mostrarExito('Cobrador eliminado exitosamente');

        // Recargar datos del manager
        final authState = ref.read(authProvider);
        final managerId = authState.usuario?.id.toString();
        if (managerId != null) {
          await ref
              .read(managerProvider.notifier)
              .cargarCobradoresAsignados(managerId);
        }

        widget.onCobradorSaved?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      _mostrarError('Error al eliminar: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }
}
