import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import '../../negocio/domain_services/allowed_apps_helper.dart';
import '../../ui/utilidades/image_utils.dart';
import '../../ui/utilidades/phone_utils.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../datos/modelos/usuario.dart';
import '../widgets/validation_error_widgets.dart';
import '../cliente/location_picker_screen.dart';

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
  final _ciController = TextEditingController();

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

  // Categoría de cliente (A, B, C) - solo aplicable para userType == 'client'
  String _clientCategory = 'B';

  // Imágenes requeridas de CI y opcional foto de perfil
  File? _idFront;
  File? _idBack;
  File? _profileImage;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.usuario != null) {
      _nombreController.text = widget.usuario!.nombre;
      _emailController.text = widget.usuario!.email;
      _telefonoController.text = widget.usuario!.telefono;
      _direccionController.text = widget.usuario!.direccion;
      _ciController.text = widget.usuario!.ci;
      _latitud = widget.usuario!.latitud;
      _longitud = widget.usuario!.longitud;
      _actualizarTextoUbicacion();

      // Inicializar categoría si es cliente existente
      if (widget.userType == 'client') {
        _clientCategory = (widget.usuario!.clientCategory ?? 'B').toUpperCase();
        if (!['A', 'B', 'C'].contains(_clientCategory)) {
          _clientCategory = 'B';
        }
      }
    } else {
      // Valor por defecto para nuevos clientes
      if (widget.userType == 'client') {
        _clientCategory = 'B';
      }
    }

    // Cargar cobradores si estamos creando un cliente
    if (widget.userType == 'client' && widget.usuario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _cargarCobradores();
      });
    }

    // Intento automático de obtener ubicación actual al abrir (solo en creación)
    if (widget.usuario == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoObtenerUbicacionActual();
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
    _ciController.dispose();
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

  Future<void> _autoObtenerUbicacionActual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final direccion = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
          if (direccion.isNotEmpty) {
            _direccionController.text = direccion;
          }
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _actualizarTextoUbicacion();
      });
    } catch (_) {
      // silencioso
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s']"),
                ),
              ],
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

            // CI
            TextFormField(
              controller: _ciController,
              keyboardType: TextInputType.text,
              decoration: const InputDecoration(
                labelText: 'CI (Cédula de identidad) *',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[A-Za-z0-9]'),
                ),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El CI es requerido';
                }
                if (value.trim().length < 5) {
                  return 'El CI debe tener al menos 5 caracteres';
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

            // Categoría de Cliente (solo para clientes)
            if (widget.userType == 'client') ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categoría de Cliente',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _clientCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                      helperText:
                          'A = Cliente VIP, B = Cliente Normal, C = Mal Cliente',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'A', child: Text('A - Cliente VIP')),
                      DropdownMenuItem(value: 'B', child: Text('B - Cliente Normal')),
                      DropdownMenuItem(value: 'C', child: Text('C - Mal Cliente')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _clientCategory = v);
                    },
                  ),
                ],
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
              inputFormatters: [PhoneUtils.inputFormatter()],
              validator: (value) => PhoneUtils.validatePhone(value, required: false),
            ),
            const SizedBox(height: 16),

            // Documentos de Identidad (requerido para clientes/cobradores en creación)
            if (widget.usuario == null && (widget.userType == 'client' || widget.userType == 'cobrador'))
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documentos de Identidad',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Anverso y Reverso del CI son obligatorios. La foto de perfil es opcional.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildImagePicker(
                            label: 'CI Anverso*',
                            file: _idFront,
                            onTap: () => _pickImage('id_front'),
                          ),
                          const SizedBox(width: 12),
                          _buildImagePicker(
                            label: 'CI Reverso*',
                            file: _idBack,
                            onTap: () => _pickImage('id_back'),
                          ),
                          const SizedBox(width: 12),
                          _buildImagePicker(
                            label: 'Perfil (opcional)',
                            file: _profileImage,
                            onTap: () => _pickImage('profile'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Las imágenes se comprimen automáticamente para pesar menos de 1MB.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
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

    // Validar fotos requeridas si es creación de cliente o cobrador
    if (widget.usuario == null && (widget.userType == 'client' || widget.userType == 'cobrador')) {
      if (_idFront == null || _idBack == null) {
        ValidationErrorSnackBar.show(
          context,
          message: 'Debes subir las fotos del CI (anverso y reverso)'.toString(),
        );
        return;
      }
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
              ci: _ciController.text.trim(),
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              roles: [widget.userType],
              clientCategory:
                  widget.userType == 'client' ? _clientCategory : null,
              password: _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
            );
      } else {
        // Crear nuevo usuario
        final roles = [widget.userType];
        if (widget.userType == 'client' || widget.userType == 'cobrador') {
          success = await ref
              .read(userManagementProvider.notifier)
              .crearUsuarioConFotos(
                nombre: _nombreController.text.trim(),
                email: _emailController.text.trim(),
                ci: _ciController.text.trim(),
                password: _passwordController.text.isNotEmpty
                    ? _passwordController.text
                    : null,
                roles: roles,
                telefono: _telefonoController.text.trim(),
                direccion: _direccionController.text.trim(),
                latitud: _latitud,
                longitud: _longitud,
                clientCategory:
                    widget.userType == 'client' ? _clientCategory : null,
                idFront: _idFront!,
                idBack: _idBack!,
                profileImage: _profileImage,
              );
        } else {
          success = await ref
              .read(userManagementProvider.notifier)
              .crearUsuario(
                nombre: _nombreController.text.trim(),
                email: _emailController.text.trim(),
                ci: _ciController.text.trim(),
                password: _passwordController.text.isNotEmpty
                    ? _passwordController.text
                    : null,
                roles: roles,
                telefono: _telefonoController.text.trim(),
                direccion: _direccionController.text.trim(),
                latitud: _latitud,
                longitud: _longitud,
                clientCategory:
                    widget.userType == 'client' ? _clientCategory : null,
              );
        }

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
                ci: '',
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

  Widget _buildImagePicker({required String label, required File? file, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_a_photo, size: 20, color: Colors.grey),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
        ),
      ),
    );
  }

  Future<ImageSource?> _selectImageSource() async {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Cámara'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(String type) async {
    try {
      final source = await _selectImageSource();
      if (source == null) return;

      final XFile? picked = await AllowedAppsHelper.openCameraSecurely(
              source: source,
              imageQuality: 100,
            );
      if (picked == null) return;
      File file = File(picked.path);
      file = await ImageUtils.compressToUnder(file, maxBytes: 1024 * 1024);

      setState(() {
        if (type == 'id_front') {
          _idFront = file;
        } else if (type == 'id_back') {
          _idBack = file;
        } else {
          _profileImage = file;
        }
      });
    } catch (e) {
      if (mounted) {
        ValidationErrorSnackBar.show(
          context,
          message: 'No se pudo seleccionar la imagen: $e',
        );
      }
    }
  }
}
