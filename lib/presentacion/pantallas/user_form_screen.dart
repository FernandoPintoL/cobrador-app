import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../datos/modelos/usuario.dart';
import '../widgets/validation_error_widgets.dart';
import 'location_picker_screen.dart';

class UserFormScreen extends ConsumerStatefulWidget {
  final String userType;
  final Usuario? usuario;
  final VoidCallback onUserCreated;

  const UserFormScreen({
    super.key,
    required this.userType,
    this.usuario,
    required this.onUserCreated,
  });

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isGettingLocation = false;

  // Variables de ubicación
  double? _latitud;
  double? _longitud;
  String _ubicacionTexto = '';

  // Variables para asignación de cobrador
  Usuario? _cobradorSeleccionado;
  bool _cargandoCobradores = false;

  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nombreController.text = widget.usuario!.nombre;
      _emailController.text = widget.usuario!.email;
      _telefonoController.text = widget.usuario!.telefono;
      _direccionController.text = widget.usuario!.direccion;
      _latitud = widget.usuario!.latitud;
      _longitud = widget.usuario!.longitud;
      _actualizarTextoUbicacion();
    }

    // Cargar cobradores si estamos creando un cliente
    if (widget.userType == 'client' && widget.usuario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarCobradores();
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  void _actualizarTextoUbicacion() {
    if (_latitud != null && _longitud != null) {
      setState(() {
        _ubicacionTexto =
            '${_latitud!.toStringAsFixed(6)}, ${_longitud!.toStringAsFixed(6)}';
      });
    } else {
      setState(() {
        _ubicacionTexto = 'No seleccionada';
      });
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarError('Permisos de ubicación denegados');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _mostrarError(
          'Los permisos de ubicación están permanentemente denegados',
        );
        return;
      }

      // Obtener ubicación actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
      });

      // Obtener dirección
      await _obtenerDireccionDesdeCoordenadas();

      _mostrarExito('Ubicación obtenida exitosamente');
    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _obtenerDireccionDesdeCoordenadas() async {
    if (_latitud == null || _longitud == null) return;

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _latitud!,
        _longitud!,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String direccion = [
          place.street,
          place.subLocality,
          place.locality,
          place.administrativeArea,
        ].where((e) => e != null && e.isNotEmpty).join(', ');

        if (direccion.isNotEmpty) {
          setState(() {
            _direccionController.text = direccion;
          });
        }
      }
    } catch (e) {
      print('Error al obtener dirección: $e');
    }
  }

  Future<void> _seleccionarUbicacionEnMapa() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LocationPickerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _latitud = result['latitud'];
        _longitud = result['longitud'];
        if (result['direccion'] != null) {
          _direccionController.text = result['direccion'];
        }
      });
      _actualizarTextoUbicacion();
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.green),
    );
  }

  Future<void> _cargarCobradores() async {
    setState(() {
      _cargandoCobradores = true;
    });

    try {
      await ref.read(cobradorAssignmentProvider.notifier).cargarCobradores();
    } catch (e) {
      print('Error al cargar cobradores: $e');
    } finally {
      setState(() {
        _cargandoCobradores = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.usuario != null;
    final title = isEditing ? 'Editar Usuario' : 'Crear Usuario';
    String userTypeName;

    switch (widget.userType) {
      case 'client':
        userTypeName = 'Cliente';
        break;
      case 'cobrador':
        userTypeName = 'Cobrador';
        break;
      case 'manager':
        userTypeName = 'Manager';
        break;
      default:
        userTypeName = 'Usuario';
    }

    return Scaffold(
      appBar: AppBar(title: Text('$title - $userTypeName')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nombre
            TextFormField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre completo *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es requerido';
                }
                if (value.trim().length < 2) {
                  return 'El nombre debe tener al menos 2 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email *',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El email es requerido';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Ingrese un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Selección de cobrador (solo para clientes nuevos)
            if (widget.userType == 'client' && widget.usuario == null) ...[
              Consumer(
                builder: (context, ref, child) {
                  final cobradorState = ref.watch(cobradorAssignmentProvider);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Asignar a Cobrador (Opcional)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: DropdownButtonFormField<Usuario>(
                          value: _cobradorSeleccionado,
                          hint: _cargandoCobradores
                              ? const Text('Cargando cobradores...')
                              : const Text('Seleccionar cobrador'),
                          items: cobradorState.cobradores.map((cobrador) {
                            return DropdownMenuItem<Usuario>(
                              value: cobrador,
                              child: Text(cobrador.nombre),
                            );
                          }).toList(),
                          onChanged: _cargandoCobradores
                              ? null
                              : (Usuario? cobrador) {
                                  setState(() {
                                    _cobradorSeleccionado = cobrador;
                                  });
                                },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.person_add),
                          ),
                          validator: (value) {
                            // No es requerido, puede ser null
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Si no seleccionas un cobrador, el cliente quedará sin asignar.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
            ],

            // Contraseña (opcional)
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña (opcional)',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                border: const OutlineInputBorder(),
                helperText: isEditing
                    ? 'Dejar vacío para mantener la contraseña actual'
                    : 'Opcional - el usuario podrá establecer su contraseña más tarde',
              ),
              validator: (value) {
                // Solo validar si se proporciona una contraseña
                if (value != null && value.isNotEmpty) {
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _telefonoController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (value.length < 7) {
                    return 'El teléfono debe tener al menos 7 dígitos';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Ubicación
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Text(
                          'Ubicación',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (_latitud != null && _longitud != null)
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ubicacionTexto,
                      style: TextStyle(
                        color: _latitud != null ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGettingLocation
                                ? null
                                : _obtenerUbicacionActual,
                            icon: _isGettingLocation
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.my_location),
                            label: Text(
                              _isGettingLocation
                                  ? 'Obteniendo...'
                                  : 'Ubicación Actual',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _seleccionarUbicacionEnMapa,
                            icon: const Icon(Icons.map),
                            label: const Text('Seleccionar en Mapa'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dirección
            TextFormField(
              controller: _direccionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Dirección',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
                helperText:
                    'Se puede llenar automáticamente desde la ubicación',
              ),
            ),
            const SizedBox(height: 24),

            // Botón de guardar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _guardarUsuario,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Actualizar' : 'Crear'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _guardarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      bool success;

      if (widget.usuario != null) {
        // Actualizar usuario existente
        success = await ref
            .read(userManagementProvider.notifier)
            .actualizarUsuario(
              id: widget.usuario!.id,
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              roles: [widget.userType],
              password: _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
            );
      } else {
        // Crear nuevo usuario
        success = await ref
            .read(userManagementProvider.notifier)
            .crearUsuario(
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
              roles: [widget.userType],
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              latitud: _latitud,
              longitud: _longitud,
            );

        // Si es un cliente y se seleccionó un cobrador, asignarlo
        if (success &&
            widget.userType == 'client' &&
            _cobradorSeleccionado != null) {
          try {
            // Obtener el ID del cliente recién creado
            final userState = ref.read(userManagementProvider);
            final clienteCreado = userState.usuarios.firstWhere(
              (user) => user.email == _emailController.text.trim(),
              orElse: () => Usuario(
                id: BigInt.zero,
                nombre: '',
                email: '',
                profileImage: '',
                telefono: '',
                direccion: '',
                fechaCreacion: DateTime.now(),
                fechaActualizacion: DateTime.now(),
                roles: [],
              ),
            );

            if (clienteCreado.id != BigInt.zero) {
              await ref
                  .read(cobradorAssignmentProvider.notifier)
                  .asignarClienteACobrador(
                    cobradorId: _cobradorSeleccionado!.id,
                    clienteId: clienteCreado.id,
                  );
            }
          } catch (e) {
            print('Error al asignar cliente a cobrador: $e');
            // No fallar la creación si la asignación falla
          }
        }
      }

      if (success) {
        widget.onUserCreated();
        if (mounted) Navigator.pop(context);
      } else {
        final state = ref.read(userManagementProvider);

        // Usar el nuevo sistema de manejo de errores
        if (state.fieldErrors != null &&
            state.fieldErrors!.isNotEmpty &&
            mounted) {
          // Si hay errores específicos de campos, mostrar en un diálogo
          ValidationErrorDialog.show(
            context,
            title: 'Error de validación',
            message: 'Por favor, corrija los siguientes errores:',
            fieldErrors: state.fieldErrors!,
          );
        } else if (mounted) {
          // Error genérico en snackbar
          ValidationErrorSnackBar.show(
            context,
            message: state.error ?? 'Error al guardar usuario',
          );
        }
      }
    } catch (e) {
      // Manejar errores de excepción
      if (mounted) {
        ValidationErrorSnackBar.show(
          context,
          message: 'Error inesperado: ${e.toString()}',
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
