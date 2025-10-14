import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/api_services/client_api_service.dart';
import '../../datos/api_services/manager_api_service.dart';
import '../../datos/api_services/user_api_service.dart';

/// Estado para la gestión de managers y sus cobradores asignados
class ManagerState {
  final List<Usuario> cobradoresAsignados;
  final List<Usuario> clientesDelManager;
  final Map<String, dynamic>? estadisticas;
  final Usuario? managerActual;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  ManagerState({
    this.cobradoresAsignados = const [],
    this.clientesDelManager = const [],
    this.estadisticas,
    this.managerActual,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  ManagerState copyWith({
    List<Usuario>? cobradoresAsignados,
    List<Usuario>? clientesDelManager,
    Map<String, dynamic>? estadisticas,
    Usuario? managerActual,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return ManagerState(
      cobradoresAsignados: cobradoresAsignados ?? this.cobradoresAsignados,
      clientesDelManager: clientesDelManager ?? this.clientesDelManager,
      estadisticas: estadisticas ?? this.estadisticas,
      managerActual: managerActual ?? this.managerActual,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

/// Notifier para gestionar el estado de managers
class ManagerNotifier extends StateNotifier<ManagerState> {
  final ManagerApiService _managerApiService = ManagerApiService();
  final UserApiService _userApiService = UserApiService();
  final ClientApiService _clientApiService = ClientApiService();

  ManagerNotifier() : super(ManagerState());

  // ===== MÉTODOS PARA COBRADORES ASIGNADOS =====

  /// Carga los cobradores asignados a un manager específico
  Future<void> cargarCobradoresAsignados(
    String managerId, {
    String? search,
  }) async {
    // Evitar múltiples peticiones simultáneas
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _managerApiService.getCobradoresByManager(
        managerId,
        search: search,
        perPage: 100, // Cargar todos los cobradores
      );

      if (response['success'] == true) {
        List<dynamic> cobradoresData;

        if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['data'] is List) {
            cobradoresData = dataMap['data'] as List<dynamic>;
          } else {
            cobradoresData = [];
          }
        } else if (response['data'] is List) {
          cobradoresData = response['data'] as List<dynamic>;
        } else {
          cobradoresData = [];
        }

        final cobradores = cobradoresData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(
          cobradoresAsignados: cobradores,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al cargar cobradores asignados',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  /// Asigna múltiples cobradores a un manager
  Future<bool> asignarCobradoresAManager(
    String managerId,
    List<String> cobradorIds,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _managerApiService.assignCobradoresToManager(
        managerId,
        cobradorIds,
      );

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cobradores asignados exitosamente al manager',
        );

        // Recargar la lista de cobradores asignados
        await cargarCobradoresAsignados(managerId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al asignar cobradores',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  /// Remueve un cobrador específico de un manager
  Future<bool> removerCobradorDeManager(
    String managerId,
    String cobradorId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _managerApiService.removeCobradorFromManager(
        managerId,
        cobradorId,
      );

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cobrador removido exitosamente del manager',
        );

        // Recargar la lista de cobradores asignados
        await cargarCobradoresAsignados(managerId);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al remover cobrador',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // ===== MÉTODOS PARA OBTENER COBRADORES DISPONIBLES =====

  /// Obtiene lista de cobradores que no están asignados a ningún manager
  Future<List<Usuario>> obtenerCobradoresDisponibles() async {
    try {
      final response = await _userApiService.getUsers(
        role: 'cobrador',
        perPage: 100,
      );

      if (response['success'] == true) {
        List<dynamic> cobradoresData;

        if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
          if (dataMap['data'] is List) {
            cobradoresData = dataMap['data'] as List<dynamic>;
          } else {
            cobradoresData = [];
          }
        } else if (response['data'] is List) {
          cobradoresData = response['data'] as List<dynamic>;
        } else {
          cobradoresData = [];
        }

        final todosLosCobradores = cobradoresData
            .map((json) => Usuario.fromJson(json))
            .toList();

        // Filtrar solo los que no tienen manager asignado
        final cobradoresDisponibles = todosLosCobradores
            .where((cobrador) => cobrador.assignedManagerId == null)
            .toList();

        return cobradoresDisponibles;
      } else {
        print(
          'Error al obtener cobradores disponibles: ${response['message']}',
        );
        return [];
      }
    } catch (e) {
      print('Error de conexión al obtener cobradores disponibles: $e');
      return [];
    }
  }

  // ===== MÉTODOS PARA CLIENTES DEL MANAGER =====

  /// Carga todos los clientes de un manager (directos + de cobradores)
  /// Usa el endpoint recomendado: GET /api/users/{managerId}/manager-clients
  Future<void> cargarClientesDelManager(String managerId) async {
    // Evitar múltiples peticiones simultáneas
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _managerApiService.getClientesByManager(managerId);

      if (response['success'] == true) {
        final clientesData = response['data']?['data'] as List? ?? [];

        final clientes = clientesData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(clientesDelManager: clientes, isLoading: false);
        print('✅ Clientes del manager cargados: ${clientes.length} encontrados');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al cargar clientes del manager',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  /// Carga los clientes de un cobrador específico
  /// Usa el endpoint: GET /api/users/{cobradorId}/clients
  Future<void> cargarClientesDelCobrador(String cobradorId) async {
    // Evitar múltiples peticiones simultáneas
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _managerApiService.getClientesDelCobrador(cobradorId);

      if (response['success'] == true) {
        final clientesData = response['data']?['data'] as List? ?? [];

        final clientes = clientesData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(clientesDelManager: clientes, isLoading: false);
        print('✅ Clientes del cobrador cargados: ${clientes.length} encontrados');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al cargar clientes del cobrador',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  /// Carga solo los clientes directos de un manager (sin incluir los de cobradores)
  /// Usa el endpoint: GET /api/users/{managerId}/clients-direct
  Future<void> cargarClientesDirectosDelManager(String managerId) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _managerApiService.getClientesDirectosDelManager(managerId);

      if (response['success'] == true) {
        final clientesData = response['data']?['data'] as List? ?? [];

        final clientes = clientesData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(clientesDelManager: clientes, isLoading: false);
        print('✅ Clientes directos del manager cargados: ${clientes.length} encontrados');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al cargar clientes directos del manager',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  // ===== MÉTODOS PARA ESTADÍSTICAS =====

  /// Carga las estadísticas de un manager
  Future<void> cargarEstadisticasManager(String managerId) async {
    try {
      final response = await _managerApiService.getManagerStats(managerId);

      if (response['success'] == true) {
        state = state.copyWith(estadisticas: response['data']);
      } else {
        print(
          'Error al cargar estadísticas del manager: ${response['message']}',
        );
      }
    } catch (e) {
      print('Error de conexión al cargar estadísticas: $e');
    }
  }

  // ===== MÉTODOS PARA OBTENER MANAGER DE UN COBRADOR =====

  /// Obtiene el manager asignado a un cobrador específico
  Future<Usuario?> obtenerManagerDeCobrador(String cobradorId) async {
    try {
      final response = await _managerApiService.getManagerByCobrador(
        cobradorId,
      );

      if (response['success'] == true && response['data'] != null) {
        return Usuario.fromJson(response['data']);
      }
      return null;
    } catch (e) {
      print('Error al obtener manager del cobrador: $e');
      return null;
    }
  }

  /// Asigna un cliente específico a un cobrador
  Future<bool> asignarClienteACobrador(
    String clienteId,
    String cobradorId,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _clientApiService.assignClientsToCollector(
        cobradorId,
        [clienteId],
      );

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente asignado exitosamente',
        );

        // Recargar la lista de clientes
        final authState = state.managerActual;
        if (authState?.id != null) {
          await cargarClientesDelManager(authState!.id.toString());
        }

        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response['message'] ?? 'Error al asignar cliente',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // ===== MÉTODOS DE UTILIDAD =====

  /// Limpia mensajes de error y éxito
  void limpiarMensajes() {
    state = state.copyWith(error: null, successMessage: null);
  }

  /// Limpia todo el estado
  void limpiarEstado() {
    state = ManagerState();
  }

  /// Establece el manager actual
  void establecerManagerActual(Usuario manager) {
    state = state.copyWith(managerActual: manager);
  }
}

/// Provider para la gestión de managers
final managerProvider = StateNotifierProvider<ManagerNotifier, ManagerState>(
  (ref) => ManagerNotifier(),
);

/// Provider para obtener cobradores disponibles (sin manager asignado)
final cobradoresDisponiblesProvider = FutureProvider<List<Usuario>>((ref) {
  final managerNotifier = ref.read(managerProvider.notifier);
  return managerNotifier.obtenerCobradoresDisponibles();
});

/// Provider para obtener el manager de un cobrador específico
final managerDeCobradorProvider = FutureProvider.family<Usuario?, String>((
  ref,
  cobradorId,
) {
  final managerNotifier = ref.read(managerProvider.notifier);
  return managerNotifier.obtenerManagerDeCobrador(cobradorId);
});
