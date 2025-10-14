import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/api_services/client_api_service.dart';
import '../../datos/api_services/user_api_service.dart';

class ClientState {
  final List<Usuario> clientes;
  final List<Usuario> clientesSinAsignar;
  final List<Usuario> clientesDirectosManager; // Nueva propiedad
  final bool isLoading;
  final String? error;
  final String? successMessage;
  final String? currentFilter;

  ClientState({
    this.clientes = const [],
    this.clientesSinAsignar = const [],
    this.clientesDirectosManager = const [], // Inicialización
    this.isLoading = false,
    this.error,
    this.successMessage,
    this.currentFilter,
  });

  ClientState copyWith({
    List<Usuario>? clientes,
    List<Usuario>? clientesSinAsignar,
    List<Usuario>? clientesDirectosManager,
    bool? isLoading,
    String? error,
    String? successMessage,
    String? currentFilter,
  }) {
    return ClientState(
      clientes: clientes ?? this.clientes,
      clientesSinAsignar: clientesSinAsignar ?? this.clientesSinAsignar,
      clientesDirectosManager:
          clientesDirectosManager ?? this.clientesDirectosManager,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
      currentFilter: currentFilter ?? this.currentFilter,
    );
  }
}

class ClientNotifier extends StateNotifier<ClientState> {
  final UserApiService _userApiService = UserApiService();
  final ClientApiService _clientApiService = ClientApiService();

  ClientNotifier() : super(ClientState());

  // Cargar clientes según el rol del usuario
  Future<void> cargarClientes({
    String? search,
    String? filter,
    String? cobradorId, // Para cobradores: usar su ID para obtener clientes asignados
    String? managerId, // Para managers: su ID
    bool managerAllClients = true, // Si true: directos + indirectos; si false: solo directos
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      List<Usuario> clientes = [];

      if (cobradorId != null) {
        // Obtener clientes asignados a un cobrador específico
        final response = await _clientApiService.getCobradorClients(
          cobradorId,
          search: search,
          perPage: 50, // Ajustable según necesidades
        );

        if (response['success'] == true) {
          List<dynamic> clientesData = [];
          final data = response['data'];

          if (data is Map<String, dynamic>) {
            if (data['data'] is List) {
              clientesData = data['data'] as List<dynamic>;
            } else if (data['clients'] is List) {
              clientesData = data['clients'] as List<dynamic>;
            }
          } else if (data is List) {
            clientesData = data;
          }

          clientes = clientesData
              .map((json) => Usuario.fromJson(json))
              .toList();
        }
      } else if (managerId != null) {
        // Para manager: decidir si solo directos o todos (directos + indirectos)
        final response = managerAllClients
            ? await _clientApiService.getManagerAllClients(
                managerId,
                search: search,
                perPage: 50,
              )
            : await _clientApiService.getManagerDirectClients(
                managerId,
                search: search,
                perPage: 50,
              );

        if (response['success'] == true) {
          List<dynamic> clientesData = [];
          final data = response['data'];

          if (data is Map<String, dynamic>) {
            if (data['data'] is List) {
              clientesData = data['data'] as List<dynamic>;
            } else if (data['clients'] is List) {
              clientesData = data['clients'] as List<dynamic>;
            }
          } else if (data is List) {
            clientesData = data;
          }

          clientes = clientesData
              .map((json) => Usuario.fromJson(json))
              .toList();
        }
      } else {
        // Para admins u otros: obtener todos los clientes generales
        final response = await _userApiService.getUsers(
          search: search,
          filter: filter,
        );

        if (response['success'] == true) {
          List<dynamic> clientesData;

          if (response['data'] is List) {
            clientesData = response['data'] as List<dynamic>;
          } else if (response['data'] is Map) {
            final dataMap = response['data'] as Map<String, dynamic>;
            if (dataMap['users'] is List) {
              clientesData = dataMap['users'] as List<dynamic>;
            } else if (dataMap['data'] is List) {
              clientesData = dataMap['data'] as List<dynamic>;
            } else {
              clientesData = [];
            }
          } else {
            clientesData = [];
          }

          clientes = clientesData
              .map((json) => Usuario.fromJson(json))
              .toList();
        }
      }

      state = state.copyWith(
        clientes: clientes,
        isLoading: false,
        currentFilter: filter,
      );
    } catch (e) {
      print('❌ Error al cargar clientes: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Error al cargar clientes: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // Crear cliente
  Future<bool> crearCliente({required String nombre, String? email, String? password, String? telefono, String? direccion, String? cobradorId}) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final clientData = <String, dynamic>{
        'name': nombre,
        'role': 'client',
        'roles': ['client'], // Backend requiere el campo roles como array
      };

      // Email es requerido por el backend, si no se proporciona usar un email por defecto
      if (email != null && email.trim().isNotEmpty) {
        clientData['email'] = email.trim();
      } else {
        // Generar un email temporal único basado en el nombre y timestamp
        String nombreLimpio = nombre
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll(RegExp(r'[^a-z0-9]'), '');
        clientData['email'] =
            '${nombreLimpio}_${DateTime.now().millisecondsSinceEpoch}@temp.cliente.com';
        print('📧 Email temporal generado: ${clientData['email']}');
      }

      if (password != null && password.isNotEmpty) {
        clientData['password'] = password;
      }

      if (telefono != null && telefono.isNotEmpty) {
        clientData['phone'] = telefono;
      }

      if (direccion != null && direccion.isNotEmpty) {
        clientData['address'] = direccion;
      }

      print('🚀 Enviando datos al servidor: $clientData');

      final response = await _clientApiService.createClient(clientData);

      if (response['success'] == true) {
        final nuevoCliente = Usuario.fromJson(response['data']);

        // Si el cliente fue creado por un cobrador, asignarlo automáticamente
        if (cobradorId != null) {
          await _clientApiService.assignClientsToCollector(cobradorId, [
            nuevoCliente.id.toString(),
          ]);
        }

        // Recargar la lista de clientes
        await cargarClientes(cobradorId: cobradorId);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente creado exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al crear cliente',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al crear cliente: $e');

      // Mejorar el manejo de errores para mostrar información específica del backend
      String errorMessage = 'Error al crear cliente';

      if (e.toString().contains('422')) {
        errorMessage = 'Faltan campos requeridos o datos inválidos';

        // Intentar extraer más detalles del error si está disponible
        if (e.toString().contains('email')) {
          errorMessage = 'Error con el campo email';
        } else if (e.toString().contains('roles')) {
          errorMessage = 'Error en la configuración de roles';
        } else if (e.toString().contains('name')) {
          errorMessage = 'Error con el nombre del cliente';
        }
      } else if (e.toString().contains('400')) {
        errorMessage = 'Solicitud inválida. Verifique los datos.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Error del servidor. Intente más tarde.';
      } else if (e.toString().contains('Connection') ||
          e.toString().contains('Network')) {
        errorMessage = 'Error de conexión. Verifique su internet.';
      }

      print('🚨 Mostrando error al usuario: $errorMessage');

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  // Actualizar cliente
  Future<bool> actualizarCliente({
    required String id,
    required String nombre,
    required String email,
    String? telefono,
    String? direccion,
    String? cobradorId,
  }) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final clientData = <String, dynamic>{'name': nombre, 'email': email};

      if (telefono != null && telefono.isNotEmpty) {
        clientData['phone'] = telefono;
      }

      if (direccion != null && direccion.isNotEmpty) {
        clientData['address'] = direccion;
      }

      final response = await _clientApiService.updateClient(id, clientData);

      if (response['success'] == true) {
        // Recargar la lista de clientes
        await cargarClientes(cobradorId: cobradorId);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente actualizado exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al actualizar cliente',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al actualizar cliente: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Error al actualizar cliente: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  // Eliminar cliente
  Future<bool> eliminarCliente({required String id, String? cobradorId}) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final response = await _clientApiService.deleteClient(id);

      if (response['success'] == true) {
        // Recargar la lista de clientes
        await cargarClientes(cobradorId: cobradorId);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente eliminado exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al eliminar cliente',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al eliminar cliente: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Error al eliminar cliente: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  // Asignar cliente a cobrador (solo para managers/admins)
  Future<bool> asignarClienteACobrador({
    required String cobradorId,
    required List<String> clientIds,
  }) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final response = await _clientApiService.assignClientsToCollector(
        cobradorId,
        clientIds,
      );

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Clientes asignados exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al asignar clientes',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al asignar clientes: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Error al asignar clientes: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  // Remover cliente de cobrador
  Future<bool> removerClienteDeCobrador({
    required String cobradorId,
    required String clientId,
  }) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null, successMessage: null);

    try {
      final response = await _clientApiService.removeClientFromCollector(
        cobradorId,
        clientId,
      );

      if (response['success'] == true) {
        // Recargar la lista de clientes
        await cargarClientes(cobradorId: cobradorId);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente removido exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al remover cliente',
        );
        return false;
      }
    } catch (e) {
      print('❌ Error al remover cliente: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Error al remover cliente: ${e.toString().replaceAll('Exception: ', '')}',
      );
      return false;
    }
  }

  // Obtener cobrador asignado a un cliente (método auxiliar)
  Future<Usuario?> obtenerCobradorDeCliente(String clientId) async {
    try {
      // Esta funcionalidad necesitaría un endpoint específico en el backend
      // Por ahora retornamos null ya que no está definido en la documentación
      return null;
    } catch (e) {
      print('❌ Error al obtener cobrador del cliente: $e');
      return null;
    }
  }

  // Limpiar mensajes de error y éxito
  void limpiarMensajes() {
    print('🧹 Limpiando mensajes de error y éxito...');
    state = state.copyWith(error: null, successMessage: null);
  }

  // Limpiar solo errores
  void limpiarError() {
    print('🧹 Limpiando error...');
    state = state.copyWith(error: null);
  }

  // Limpiar solo mensaje de éxito
  void limpiarExito() {
    print('🧹 Limpiando mensaje de éxito...');
    state = state.copyWith(successMessage: null);
  }

  // Filtrar clientes por estado
  void filtrarPorEstado(String filtro) {
    state = state.copyWith(currentFilter: filtro);
  }

  // Cargar clientes sin asignar
  Future<void> cargarClientesSinAsignar({String? search}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _clientApiService.getUnassignedClients(
        search: search,
        perPage: 100, // Cargar más clientes para selección
      );

      if (response['success'] == true) {
        List<dynamic> clientesData = [];
        final data = response['data'];

        if (data is Map<String, dynamic>) {
          if (data['data'] is List) {
            clientesData = data['data'] as List<dynamic>;
          } else if (data['clients'] is List) {
            clientesData = data['clients'] as List<dynamic>;
          }
        } else if (data is List) {
          clientesData = data;
        }

        final clientesSinAsignar = clientesData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(
          clientesSinAsignar: clientesSinAsignar,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al cargar clientes sin asignar',
        );
      }
    } catch (e) {
      print('❌ Error al cargar clientes sin asignar: $e');
      state = state.copyWith(
        isLoading: false,
        error:
            'Error al cargar clientes sin asignar: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  // Método para asignar múltiples clientes (alias para compatibilidad)
  Future<bool> asignarClientesACobrador(
    String cobradorId,
    List<String> clientIds,
  ) {
    return asignarClienteACobrador(
      cobradorId: cobradorId,
      clientIds: clientIds,
    );
  }

  // ================== MÉTODOS PARA GESTIÓN DIRECTA MANAGER → CLIENTE ==================

  /// Cargar clientes asignados directamente a un manager
  Future<void> cargarClientesDirectosManager(
    String managerId, {
    String? search,
  }) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('📋 Cargando clientes directos del manager: $managerId');

      final response = await _clientApiService.getManagerDirectClients(
        managerId,
        search: search,
      );

      if (response['success'] == true) {
        // Los clientes están en response['data']['data'] por la paginación
        final Map<String, dynamic> dataResponse = response['data'] ?? {};
        final List<dynamic> clientesData = dataResponse['data'] ?? [];
        final List<Usuario> clientesDirectos = clientesData
            .map((clienteJson) => Usuario.fromJson(clienteJson))
            .toList();

        state = state.copyWith(
          clientesDirectosManager: clientesDirectos,
          isLoading: false,
          successMessage: 'Clientes directos cargados exitosamente',
        );

        print('✅ ${clientesDirectos.length} clientes directos cargados');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar clientes directos',
        );
      }
    } catch (e) {
      print('❌ Error al cargar clientes directos: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al cargar clientes directos: $e',
      );
    }
  }

  /// Asignar clientes directamente a un manager
  Future<bool> asignarClientesDirectamenteAManager(
    String managerId,
    List<String> clientIds,
  ) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      print(
        '📝 Asignando ${clientIds.length} clientes directamente al manager: $managerId',
      );

      final response = await _clientApiService.assignClientsDirectlyToManager(
        managerId,
        clientIds,
      );

      if (response['success'] == true) {
        // Recargar la lista de clientes directos
        await cargarClientesDirectosManager(managerId);

        // También recargar clientes sin asignar para actualizar la lista
        await cargarClientesSinAsignar();

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Clientes asignados directamente exitosamente',
        );

        print('✅ Clientes asignados directamente al manager exitosamente');
        return true;
      } else {
        throw Exception(
          response['message'] ?? 'Error al asignar clientes directamente',
        );
      }
    } catch (e) {
      print('❌ Error al asignar clientes directamente: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al asignar clientes directamente: $e',
      );
      return false;
    }
  }

  /// Remover un cliente específico de la asignación directa del manager
  Future<bool> removerClienteDirectoDelManager(
    String managerId,
    String clientId,
  ) async {
    if (state.isLoading) return false;

    state = state.copyWith(isLoading: true, error: null);

    try {
      print('🗑️ Removiendo cliente $clientId del manager directo: $managerId');

      final response = await _clientApiService.removeClientFromManagerDirect(
        managerId,
        clientId,
      );

      if (response['success'] == true) {
        // Recargar la lista de clientes directos
        await cargarClientesDirectosManager(managerId);

        // También recargar clientes sin asignar para actualizar la lista
        await cargarClientesSinAsignar();

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente removido exitosamente',
        );

        print('✅ Cliente removido del manager directo exitosamente');
        return true;
      } else {
        throw Exception(
          response['message'] ?? 'Error al remover cliente directo',
        );
      }
    } catch (e) {
      print('❌ Error al remover cliente directo: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Error al remover cliente directo: $e',
      );
      return false;
    }
  }

  /// Obtener el manager directo asignado a un cliente específico
  Future<Usuario?> obtenerManagerDirectoDelCliente(String clientId) async {
    try {
      print('👤 Obteniendo manager directo del cliente: $clientId');

      final response = await _clientApiService.getClientDirectManager(clientId);

      if (response['success'] == true && response['data'] != null) {
        final Usuario manager = Usuario.fromJson(response['data']);
        print('✅ Manager directo obtenido: ${manager.nombre}');
        return manager;
      } else {
        print('ℹ️ Cliente no tiene manager directo asignado');
        return null;
      }
    } catch (e) {
      print('❌ Error al obtener manager directo: $e');
      return null;
    }
  }
}

// Provider para el manejo de clientes
final clientProvider = StateNotifierProvider<ClientNotifier, ClientState>(
  (ref) => ClientNotifier(),
);
