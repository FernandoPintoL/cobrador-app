import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../datos/modelos/usuario.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../config/role_colors.dart';
import 'location_picker_screen.dart';

class ClienteFormScreen extends ConsumerStatefulWidget {
  final Usuario? cliente; // null para crear, con datos para editar
  final VoidCallback? onClienteSaved;
  final VoidCallback? onClienteCreated;
  final String? initialName;

  const ClienteFormScreen({
    super.key,
    this.cliente,
    this.onClienteSaved,
    this.onClienteCreated,
    this.initialName
  });

  @override
  ConsumerState<ClienteFormScreen> createState() =>
      _ManagerClienteFormScreenState();
}

class _ManagerClienteFormScreenState
    extends ConsumerState<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _contrasenaController = TextEditingController();
  final _ciController = TextEditingController();

  bool _esEdicion = false;
  bool _isLoading = false;

  // Variables para ubicación GPS
  double? _latitud;
  double? _longitud;
  bool _ubicacionObtenida = false;
  String _tipoUbicacion = ''; // 'actual' o 'mapa'

  @override
  void initState() {
    super.initState();
    _esEdicion = widget.cliente != null;

    if (_esEdicion) {
      _nombreController.text = widget.cliente!.nombre;
      _emailController.text = widget.cliente!.email;
      _telefonoController.text = widget.cliente!.telefono;
      _direccionController.text = widget.cliente!.direccion;
      _ciController.text = widget.cliente!.ci;

      // Cargar ubicación si existe
      if (widget.cliente!.latitud != null && widget.cliente!.longitud != null) {
        _latitud = widget.cliente!.latitud;
        _longitud = widget.cliente!.longitud;
        _ubicacionObtenida = true;
        _tipoUbicacion = 'existente';
      }
    } else if (widget.initialName != null && widget.initialName!.trim().isNotEmpty) {
      _nombreController.text = widget.initialName!.trim();
    }
  }

  String _getTipoUbicacionTexto() {
    switch (_tipoUbicacion) {
      case 'actual':
        return 'Ubicación actual obtenida';
      case 'mapa':
        return 'Ubicación seleccionada en mapa';
      case 'existente':
        return 'Ubicación existente';
      default:
        return 'Ubicación GPS obtenida';
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _contrasenaController.dispose();
    _ciController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Cliente' : 'Creares Cliente'),
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
                            // CI obligatorio
                            TextFormField(
                              controller: _ciController,
                              decoration: const InputDecoration(
                                labelText: 'CI (Cédula de identidad) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'El CI es obligatorio';
                                }
                                if (value.trim().length < 5) {
                                  return 'El CI debe tener al menos 5 caracteres';
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
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Botón para obtener ubicación actual
                                    IconButton(
                                      icon: Icon(
                                        Icons.my_location,
                                        size: 20,
                                        color: _ubicacionObtenida
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                      onPressed: _obtenerUbicacionActual,
                                      tooltip: 'Obtener mi ubicación actual',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                    // Botón para seleccionar en mapa
                                    IconButton(
                                      icon: Icon(
                                        Icons.map,
                                        size: 20,
                                        color: _ubicacionObtenida
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      onPressed: _obtenerUbicacionGPS,
                                      tooltip: 'Seleccionar en mapa',
                                      constraints: const BoxConstraints(
                                        minWidth: 32,
                                        minHeight: 32,
                                      ),
                                      padding: const EdgeInsets.all(4),
                                    ),
                                  ],
                                ),
                                helperText: _ubicacionObtenida
                                    ? '${_getTipoUbicacionTexto()} ✓'
                                    : 'Usa el botón de ubicación actual o selecciona en el mapa',
                              ),
                              maxLines: 2,
                            ),
                            if (_ubicacionObtenida) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _tipoUbicacion == 'actual'
                                          ? Icons.my_location
                                          : _tipoUbicacion == 'mapa'
                                          ? Icons.map
                                          : Icons.location_on,
                                      color: Colors.green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Lat: ${_latitud?.toStringAsFixed(4)}, Lng: ${_longitud?.toStringAsFixed(4)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.green,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _latitud = null;
                                          _longitud = null;
                                          _ubicacionObtenida = false;
                                          _tipoUbicacion = '';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.clear,
                                          size: 12,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
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

  Future<void> _obtenerUbicacionActual() async {
    try {
      // Verificar permisos de ubicación
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Los servicios de ubicación están deshabilitados'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permisos de ubicación denegados'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permisos de ubicación denegados permanentemente. Ve a configuración para habilitarlos.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Obteniendo ubicación actual...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // Cerrar diálogo de carga
      if (mounted) Navigator.of(context).pop();

      // Intentar obtener dirección de las coordenadas
      String direccionObtenida = '';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks.first;
          direccionObtenida =
              [
                    place.street,
                    place.locality,
                    place.administrativeArea,
                    place.country,
                  ]
                  .where((element) => element != null && element.isNotEmpty)
                  .join(', ');
        }
      } catch (e) {
        print('Error al obtener dirección: $e');
      }

      setState(() {
        _latitud = position.latitude;
        _longitud = position.longitude;
        _ubicacionObtenida = true;
        _tipoUbicacion = 'actual';

        // Si se obtuvo una dirección, la usamos; si no, mantenemos la actual
        if (direccionObtenida.isNotEmpty) {
          _direccionController.text = direccionObtenida;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ubicación actual obtenida correctamente\n'
            'Lat: ${position.latitude.toStringAsFixed(4)}\n'
            'Lng: ${position.longitude.toStringAsFixed(4)}',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación actual: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
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
          _tipoUbicacion = 'mapa';

          // Si viene una dirección, la usamos
          if (result['direccion'] != null &&
              result['direccion'].toString().isNotEmpty) {
            _direccionController.text = result['direccion'] as String;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ubicación seleccionada en mapa correctamente'),
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
              ci: _ciController.text.trim(),
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
              ci: _ciController.text.trim(),
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
