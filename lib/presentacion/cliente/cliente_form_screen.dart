import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  final Usuario? cliente;
  final VoidCallback? onClienteCreated;

  const ClienteFormScreen({super.key, this.cliente, this.onClienteCreated});

  @override
  ConsumerState<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends ConsumerState<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  // bool _showPassword = false;
  bool _isEditing = false;
  bool _obteniendoUbicacion = false;

  // Variables para ubicación
  double? _latitud;
  double? _longitud;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.cliente != null;

    if (_isEditing) {
      _nombreController.text = widget.cliente!.nombre;
      _emailController.text = widget.cliente!.email;
      _telefonoController.text = widget.cliente!.telefono;
      _direccionController.text = widget.cliente!.direccion;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el estado solo cuando cambian los valores específicos
    ref.listen<ClientState>(clientProvider, (previous, next) {
      // Solo procesar errores nuevos o diferentes
      if (next.error != null && next.error != previous?.error) {
        if (mounted) {
          setState(() => _isLoading = false);

          print('🚨 Mostrando error: ${next.error}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.error!),
              backgroundColor: Colors.red,
              duration: const Duration(
                seconds: 6,
              ), // Más tiempo para leer el error
              action: SnackBarAction(
                label: 'Cerrar',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );

          // Limpiar el error después de mostrarlo
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(clientProvider.notifier).limpiarMensajes();
            }
          });
        }
      }

      // Solo procesar mensajes de éxito nuevos o diferentes
      if (next.successMessage != null &&
          next.successMessage != previous?.successMessage) {
        if (mounted) {
          setState(() => _isLoading = false);

          print('✅ Mostrando éxito: ${next.successMessage}');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next.successMessage!),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Limpiar el mensaje y cerrar pantalla
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(clientProvider.notifier).limpiarMensajes();

              if (widget.onClienteCreated != null) {
                widget.onClienteCreated!();
              }
              Navigator.pop(context);
            }
          });
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Cliente' : 'Nuevo Cliente'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Información básica
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.person, color: const Color(0xFF667eea)),
                          const SizedBox(width: 8),
                          const Text(
                            'Información Básica',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Nombre
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre completo *',
                          hintText: 'Ingrese el nombre del cliente',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'El nombre es requerido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      /* TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'ejemplo@email.com (opcional)',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          // Email es opcional, pero si se ingresa debe ser válido
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
                      const SizedBox(height: 16), */

                      // Teléfono
                      TextFormField(
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          hintText: '+1234567890',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Dirección con botón de ubicación
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _direccionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Dirección',
                              hintText: 'Ingrese la dirección del cliente',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _obteniendoUbicacion
                                      ? null
                                      : _obtenerUbicacionActual,
                                  icon: _obteniendoUbicacion
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.my_location),
                                  label: Text(
                                    _obteniendoUbicacion
                                        ? 'Obteniendo...'
                                        : 'Ubicación Actual',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF667eea),
                                    side: const BorderSide(
                                      color: Color(0xFF667eea),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _abrirMapa,
                                  icon: const Icon(Icons.map),
                                  label: const Text('Seleccionar en Mapa'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF667eea),
                                    side: const BorderSide(
                                      color: Color(0xFF667eea),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_latitud != null && _longitud != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green[600],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'Coordenadas: ${_latitud!.toStringAsFixed(6)}, ${_longitud!.toStringAsFixed(6)}',
                                      style: TextStyle(
                                        color: Colors.green[700],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _latitud = null;
                                        _longitud = null;
                                      });
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.green[600],
                                      size: 16,
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contraseña (opcional - solo para nuevos clientes)
              /* if (!_isEditing)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange[600]),
                            const SizedBox(width: 8),
                            const Text(
                              'Contraseña (Opcional)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Los clientes no necesitan ingresar al sistema. Este campo es opcional.',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          decoration: InputDecoration(
                            labelText: 'Contraseña (opcional)',
                            hintText: 'Dejar vacío - no es necesario',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (!_isEditing) const SizedBox(height: 16), */

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _cancelar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _guardarCliente,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(_isEditing ? 'Actualizar' : 'Crear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _guardarCliente() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Evitar múltiples clicks mientras está cargando
    if (_isLoading) {
      print('⚠️ Ya se está procesando una solicitud...');
      return;
    }

    setState(() => _isLoading = true);
    print('🔄 Iniciando proceso de guardado...');

    // Limpiar mensajes previos antes de iniciar
    ref.read(clientProvider.notifier).limpiarMensajes();

    final authState = ref.read(authProvider);
    final cobradorId = authState.isCobrador
        ? authState.usuario?.id.toString()
        : null;

    bool resultado = false;

    try {
      if (_isEditing) {
        // Actualizar cliente existente
        resultado = await ref
            .read(clientProvider.notifier)
            .actualizarCliente(
              id: widget.cliente!.id.toString(),
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim(),
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              cobradorId: cobradorId,
            );
      } else {
        // Crear nuevo cliente
        resultado = await ref
            .read(clientProvider.notifier)
            .crearCliente(
              nombre: _nombreController.text.trim(),
              email: _emailController.text.trim().isEmpty
                  ? null
                  : _emailController.text.trim(),
              password: _passwordController.text.isNotEmpty
                  ? _passwordController.text
                  : null,
              telefono: _telefonoController.text.trim(),
              direccion: _direccionController.text.trim(),
              cobradorId: cobradorId,
            );
      }

      print('📋 Resultado del guardado: $resultado');

      // Si el resultado fue exitoso pero no hay mensaje de éxito,
      // el listener se encargará de manejar la respuesta
      if (!resultado) {
        // Solo cambiar el estado si falló localmente
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error en _guardarCliente: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelar() {
    Navigator.pop(context);
  }

  // Métodos para manejo de ubicación
  Future<void> _obtenerUbicacionActual() async {
    setState(() {
      _obteniendoUbicacion = true;
    });

    try {
      // Verificar permisos de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
      });

      // Intentar obtener dirección legible
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String direccion = '';

          if (place.street != null && place.street!.isNotEmpty) {
            direccion += place.street!;
          }
          if (place.subThoroughfare != null &&
              place.subThoroughfare!.isNotEmpty) {
            direccion += ' ${place.subThoroughfare!}';
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            direccion += ', ${place.locality!}';
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            direccion += ', ${place.administrativeArea!}';
          }

          if (direccion.isNotEmpty) {
            _direccionController.text = direccion;
          }
        }
      } catch (e) {
        print('Error obteniendo dirección: $e');
        // No es crítico si no se puede obtener la dirección
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación obtenida exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error obteniendo ubicación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _obteniendoUbicacion = false;
      });
    }
  }

  void _abrirMapa() {
    // Por ahora mostrar un diálogo informativo
    // En una implementación futura se puede abrir un mapa interactivo
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selección en Mapa'),
        content: const Text(
          'Esta funcionalidad estará disponible próximamente.\n\n'
          'Por ahora, puedes usar el botón "Ubicación Actual" para obtener '
          'automáticamente las coordenadas y dirección.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
