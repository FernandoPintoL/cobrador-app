import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../ui/utilidades/image_utils.dart';
import '../../ui/utilidades/phone_utils.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/api_services/user_api_service.dart';
import '../../datos/api_services/api_service.dart';
import '../../negocio/providers/manager_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../cliente/location_picker_screen.dart';
import '../pantallas/change_password_screen.dart';
import '../widgets/validation_error_widgets.dart';
import '../widgets/camera/in_app_camera_screen.dart';
import '../widgets/camera/camera_with_document_detection_screen.dart';
import '../widgets/camera/camera_with_face_detection_screen.dart';

class CobradorFormScreen extends ConsumerStatefulWidget {
  final Usuario? cobrador; // null para crear, con datos para editar
  final VoidCallback? onCobradorSaved;

  const CobradorFormScreen({super.key, this.cobrador, this.onCobradorSaved});

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

  // Variables para errores de campo específicos
  String? _nombreError;
  String? _emailError;
  String? _passwordError;
  String? _ciError;
  String? _telefonoError;
  String? _direccionError;

  // Variables para ubicación GPS
  double? _latitud;
  double? _longitud;
  bool _ubicacionObtenida = false;

  // Imágenes requeridas de CI y opcional foto de perfil
  File? _idFront;
  File? _idBack;
  File? _profileImage;
  final _picker = ImagePicker();

  // Estados de carga para procesamiento de imágenes
  bool _isProcessingIdFront = false;
  bool _isProcessingIdBack = false;
  bool _isProcessingProfile = false;

  // URLs existentes (modo edición)
  String? _idFrontUrl;
  String? _idBackUrl;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.cobrador != null;

    if (_isEditMode) {
      // Usar ApiService para construir correctamente la URL de la imagen de perfil
      final apiService = ApiService();

      // Si hay una imagen de perfil, construir la URL correcta
      if (widget.cobrador!.profileImage.isNotEmpty) {
        _profileImageUrl = apiService.getProfileImageUrl(
          widget.cobrador!.profileImage,
        );
        debugPrint('🖼️ URL de perfil construida: $_profileImageUrl');
      } else {
        _profileImageUrl = null;
        debugPrint('⚠️ No hay imagen de perfil para el cobrador');
      }

      debugPrint(
        'Cargando fotos existentes para el cobrador: ${widget.cobrador!.nombre}',
      );
      _cargarFotosExistentes(widget.cobrador!.id);

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

    // Intento automático de obtener ubicación actual al abrir (solo en creación)
    if (!_isEditMode) {
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

  void _limpiarErroresCampos() {
    setState(() {
      _nombreError = null;
      _emailError = null;
      _passwordError = null;
      _ciError = null;
      _telefonoError = null;
      _direccionError = null;
    });
  }

  void _procesarErroresCampos(Map<String, dynamic>? errorsMap) {
    if (errorsMap == null || errorsMap.isEmpty) return;

    setState(() {
      // Limpiar errores previos
      _nombreError = null;
      _emailError = null;
      _passwordError = null;
      _ciError = null;
      _telefonoError = null;
      _direccionError = null;

      // Procesar errores del backend
      // El formato es: { "field": ["error message 1", "error message 2"] }
      errorsMap.forEach((field, messages) {
        if (messages is List && messages.isNotEmpty) {
          final errorMessage = messages.first.toString();
          final fieldLower = field.toLowerCase();

          // Mapear campos del backend a variables de error
          if (fieldLower == 'name' || fieldLower == 'nombre') {
            _nombreError = errorMessage;
          } else if (fieldLower == 'email' || fieldLower == 'correo') {
            _emailError = errorMessage;
          } else if (fieldLower == 'password' || fieldLower == 'contraseña') {
            _passwordError = errorMessage;
          } else if (fieldLower == 'phone' || fieldLower == 'telefono' || fieldLower == 'teléfono') {
            _telefonoError = errorMessage;
          } else if (fieldLower == 'address' || fieldLower == 'direccion' || fieldLower == 'dirección') {
            _direccionError = errorMessage;
          } else if (fieldLower == 'ci' || fieldLower == 'cedula' || fieldLower == 'cédula') {
            _ciError = errorMessage;
          }
        }
      });
    });
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
                decoration: InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(
                    Icons.person,
                    color: _nombreError != null ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _nombreError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _nombreError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r"[A-Za-zÁÉÍÓÚáéíóúÑñÜü\s']"),
                  ),
                ],
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
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  prefixIcon: Icon(
                    Icons.email,
                    color: _emailError != null ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _emailError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _emailError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
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
              if (!_isEditMode)
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: _isEditMode
                        ? 'Nueva Contraseña (opcional)'
                        : 'Contraseña',
                    prefixIcon: Icon(
                      Icons.lock,
                      color: _passwordError != null ? Colors.red : null,
                    ),
                    border: const OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _passwordError != null
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _passwordError != null
                            ? Colors.red
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    errorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    helperText: _isEditMode
                        ? 'Deja vacío si no deseas cambiar la contraseña'
                        : 'Mínimo 8 caracteres',
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
                      if (value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                    } else {
                      // En modo edición, la contraseña es opcional pero debe ser válida si se proporciona
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 8) {
                        return 'La contraseña debe tener al menos 8 caracteres';
                      }
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),

              // CI obligatorio
              TextFormField(
                controller: _ciController,
                decoration: InputDecoration(
                  labelText: 'CI (Cédula de identidad) *',
                  prefixIcon: Icon(
                    Icons.badge,
                    color: _ciError != null ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _ciError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _ciError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor ingresa el CI';
                  }
                  if (value.trim().length < 5) {
                    return 'El CI debe tener al menos 5 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // telefono
              TextFormField(
                controller: _telefonoController,
                decoration: InputDecoration(
                  labelText: 'Teléfono',
                  prefixIcon: Icon(
                    Icons.phone,
                    color: _telefonoError != null ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _telefonoError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _telefonoError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneUtils.inputFormatter()],
                validator: (value) =>
                    PhoneUtils.validatePhone(value, required: true),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _direccionController,
                decoration: InputDecoration(
                  labelText: 'Dirección',
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: _direccionError != null ? Colors.red : null,
                  ),
                  border: const OutlineInputBorder(),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _direccionError != null ? Colors.red : Colors.grey,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: _direccionError != null
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  errorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botón para obtener ubicación actual automática
                      IconButton(
                        icon: Icon(
                          _ubicacionObtenida
                              ? Icons.gps_fixed
                              : Icons.gps_not_fixed,
                          color: _ubicacionObtenida ? Colors.green : null,
                        ),
                        onPressed: _obtenerUbicacionActual,
                        tooltip: 'Obtener ubicación actual',
                      ),
                      // Botón para abrir mapa y seleccionar manualmente
                      IconButton(
                        icon: const Icon(
                          Icons.map,
                          color: Colors.blue,
                        ),
                        onPressed: _abrirMapaParaSeleccionar,
                        tooltip: 'Seleccionar en mapa',
                      ),
                    ],
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
              const SizedBox(height: 16),

              // Carga de imágenes de CI y perfil
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Documentos de Identidad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isEditMode
                            ? 'Puedes actualizar las fotos del CI si es necesario'
                            : 'Puedes subir las fotos del CI ahora o después (opcional)',
                        style: TextStyle(color: Colors.grey[700], fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildImagePicker(
                            label: 'CI Anverso',
                            file: _idFront,
                            existingUrl: _idFrontUrl,
                            onTap: () => _pickImage('id_front'),
                            isProcessing: _isProcessingIdFront,
                          ),
                          const SizedBox(width: 12),
                          _buildImagePicker(
                            label: 'CI Reverso',
                            file: _idBack,
                            existingUrl: _idBackUrl,
                            onTap: () => _pickImage('id_back'),
                            isProcessing: _isProcessingIdBack,
                          ),
                          const SizedBox(width: 12),
                          _buildImagePicker(
                            label: 'Perfil (opcional)',
                            file: _profileImage,
                            existingUrl: _profileImageUrl,
                            onTap: () => _pickImage('profile'),
                            isProcessing: _isProcessingProfile,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Las imágenes deben pesar menos de 1MB. Se comprimen automáticamente.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

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

              // Botón adicional para cambiar contraseña en modo edición
              if (_isEditMode) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _mostrarDialogoContrasena,
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Cambiar Contraseña'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ],

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

      String direccionObtenida = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          direccionObtenida = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _ubicacionObtenida = true;
        if (direccionObtenida.isNotEmpty) {
          _direccionController.text = direccionObtenida;
        }
      });
    } catch (_) {
      // silencioso
    }
  }

  Future<void> _obtenerUbicacionActual() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _mostrarError('Los servicios de ubicación están desactivados');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _mostrarError('Permisos de ubicación denegados');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _mostrarError('Permisos de ubicación denegados permanentemente');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      String direccionObtenida = '';
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          direccionObtenida = [
            place.street,
            place.locality,
            place.administrativeArea,
            place.country,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _ubicacionObtenida = true;
        if (direccionObtenida.isNotEmpty) {
          _direccionController.text = direccionObtenida;
        }
      });

      _mostrarExito('Ubicación actual obtenida correctamente');
    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    }
  }

  Future<void> _abrirMapaParaSeleccionar() async {
    try {
      // Navegar a la pantalla de selección de ubicación
      // Si hay ubicación guardada (modo edición), mostrarla en el mapa
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            allowSelection: true, // Permitir selección manual
            customTitle: 'Seleccionar ubicación del cobrador',
            initialLatitude: _latitud, // Pasar ubicación guardada si existe
            initialLongitude: _longitud, // Pasar ubicación guardada si existe
          ),
        ),
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

        _mostrarExito('Ubicación seleccionada correctamente');
      }
    } catch (e) {
      _mostrarError('Error al obtener ubicación: $e');
    }
  }

  Future<void> _guardarCobrador() async {
    if (!_formKey.currentState!.validate()) return;

    // Limpiar errores anteriores
    _limpiarErroresCampos();

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
        // Verificar si hay fotos nuevas para actualizar
        bool hayFotosNuevas =
            _idFront != null || _idBack != null || _profileImage != null;

        bool success;
        if (hayFotosNuevas) {
          // Usar el método que actualiza con fotos
          success = await ref
              .read(userManagementProvider.notifier)
              .actualizarUsuarioConFotos(
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
                idFront: _idFront,
                idBack: _idBack,
                profileImage: _profileImage,
              );
        } else {
          // Usar el método normal sin fotos
          success = await ref
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
        }

        if (success) {
          _mostrarExito(
            hayFotosNuevas
                ? 'Cobrador y documentos actualizados exitosamente'
                : 'Cobrador actualizado exitosamente',
          );
          // Recargar datos del manager
          await ref
              .read(managerProvider.notifier)
              .cargarCobradoresAsignados(managerId);
          widget.onCobradorSaved?.call();
          Navigator.pop(context);
        } else {
          final state = ref.read(userManagementProvider);
          if (state.fieldErrors != null && state.fieldErrors!.isNotEmpty) {
            _procesarErroresCampos(state.fieldErrors!);
            ValidationErrorDialog.show(
              context,
              title: 'Error de validación',
              message: 'Por favor corrija los siguientes errores:',
              fieldErrors: state.fieldErrors!,
            );
          } else {
            ValidationErrorSnackBar.show(
              context,
              message: state.error ?? 'Error al actualizar cobrador',
            );
          }
        }
      } else {
        // Crear nuevo cobrador (fotos opcionales)
        final success = await ref
            .read(userManagementProvider.notifier)
            .crearUsuarioConFotos(
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              ci: _ciController.text.trim(),
              password: _passwordController.text,
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              roles: ['cobrador'],
              latitud: _latitud,
              longitud: _longitud,
              idFront: _idFront, // Ahora opcional
              idBack: _idBack,   // Ahora opcional
              profileImage: _profileImage,
            );

        if (success) {
          _mostrarExito('Cobrador creado exitosamente');
          // Recargar datos del manager
          await ref
              .read(managerProvider.notifier)
              .cargarCobradoresAsignados(managerId);
          widget.onCobradorSaved?.call();
          Navigator.pop(context);
        } else {
          final state = ref.read(userManagementProvider);
          if (state.fieldErrors != null && state.fieldErrors!.isNotEmpty) {
            _procesarErroresCampos(state.fieldErrors!);
            ValidationErrorDialog.show(
              context,
              title: 'Error de validación',
              message: 'Por favor corrija los siguientes errores:',
              fieldErrors: state.fieldErrors!,
            );
          } else {
            ValidationErrorSnackBar.show(
              context,
              message: state.error ?? 'Error al crear cobrador',
            );
          }
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
          style: TextStyle(color: Colors.white),
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
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? file,
    String? existingUrl,
    required VoidCallback onTap,
    bool isProcessing = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: isProcessing ? null : onTap,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Builder(
                builder: (_) {
                  if (file != null) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        file,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  } else if (existingUrl != null && existingUrl.isNotEmpty) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        existingUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    );
                  }
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
              // Overlay de carga durante procesamiento
              if (isProcessing)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Procesando...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
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

  Future<void> _cargarFotosExistentes(BigInt userId) async {
    try {
      final photos = await UserApiService().listUserPhotos(userId);
      debugPrint('Fotos existentes cargadas: $photos');
      for (final p in photos) {
        final type = p['type']?.toString();
        final url =
            p['url']?.toString() ??
            p['full_url']?.toString() ??
            p['path_url']?.toString();
        if (type == 'id_front' && url != null) {
          _idFrontUrl = url;
          debugPrint('Foto CI Anverso URL: ' + _idFrontUrl.toString());
        } else if (type == 'id_back' && url != null) {
          _idBackUrl = url;
          debugPrint('Foto CI Reverso URL: ' + _idBackUrl.toString());
        }
      }
      if (mounted) setState(() {});
    } catch (e) {
      // Silencioso
    }
  }

  Future<void> _pickImage(String type) async {
    try {
      final source = await _selectImageSource();
      if (source == null) return;

      File? file;

      // Usar cámara in-app con detección automática según el tipo
      if (source == ImageSource.camera) {
        if (!mounted) return;

        // Para CI (anverso y reverso) usar detección de documentos
        if (type == 'id_front' || type == 'id_back') {
          file = await Navigator.of(context).push<File>(
            MaterialPageRoute(
              builder: (context) => CameraWithDocumentDetectionScreen(
                autoCapture: true,
              ),
            ),
          );
        } else {
          // Para foto de perfil usar detección de rostros
          file = await Navigator.of(context).push<File>(
            MaterialPageRoute(
              builder: (context) => CameraWithFaceDetectionScreen(
                autoCapture: true,
              ),
            ),
          );
        }
      } else {
        // Para galería, usar el picker normal
        final XFile? picked = await _picker.pickImage(
          source: source,
          imageQuality: 100,
        );
        if (picked != null) {
          file = File(picked.path);
        }
      }

      if (file == null) return;

      // Activar indicador de carga según el tipo de imagen
      setState(() {
        if (type == 'id_front') {
          _isProcessingIdFront = true;
        } else if (type == 'id_back') {
          _isProcessingIdBack = true;
        } else {
          _isProcessingProfile = true;
        }
      });

      // Comprimir imagen
      file = await ImageUtils.compressToUnder(file, maxBytes: 1024 * 1024);

      setState(() {
        // Guardar archivo e desactivar indicador
        if (type == 'id_front') {
          _idFront = file;
          _isProcessingIdFront = false;
        } else if (type == 'id_back') {
          _idBack = file;
          _isProcessingIdBack = false;
        } else {
          _profileImage = file;
          _isProcessingProfile = false;
        }
      });
    } catch (e) {
      // Desactivar indicadores en caso de error
      setState(() {
        _isProcessingIdFront = false;
        _isProcessingIdBack = false;
        _isProcessingProfile = false;
      });

      _mostrarError('No se pudo seleccionar la imagen: $e');
    }
  }

  Future<void> _mostrarDialogoContrasena() async {
    if (widget.cobrador == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangePasswordScreen(
          targetUser: widget.cobrador!,
          onPasswordChanged: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contraseña cambiada exitosamente')),
            );
          },
        ),
      ),
    );
  }
}
