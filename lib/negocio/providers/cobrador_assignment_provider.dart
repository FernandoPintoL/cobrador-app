import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/servicios/api_service.dart';

class CobradorAssignmentState {
  final List<Usuario> cobradores;
  final List<Usuario> clientesAsignados;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  CobradorAssignmentState({
    this.cobradores = const [],
    this.clientesAsignados = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  CobradorAssignmentState copyWith({
    List<Usuario>? cobradores,
    List<Usuario>? clientesAsignados,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return CobradorAssignmentState(
      cobradores: cobradores ?? this.cobradores,
      clientesAsignados: clientesAsignados ?? this.clientesAsignados,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class CobradorAssignmentNotifier
    extends StateNotifier<CobradorAssignmentState> {
  final ApiService _apiService = ApiService();

  CobradorAssignmentNotifier() : super(CobradorAssignmentState());

  // Cargar todos los cobradores disponibles
  Future<void> cargarCobradores() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.get(
        '/users',
        queryParameters: {'role': 'cobrador'},
      );

      if (response.data['success'] == true) {
        List<dynamic> cobradoresData;

        if (response.data['data'] is List) {
          cobradoresData = response.data['data'] as List<dynamic>;
        } else if (response.data['data'] is Map) {
          final dataMap = response.data['data'] as Map<String, dynamic>;
          if (dataMap['users'] is List) {
            cobradoresData = dataMap['users'] as List<dynamic>;
          } else if (dataMap['data'] is List) {
            cobradoresData = dataMap['data'] as List<dynamic>;
          } else {
            cobradoresData = [];
          }
        } else {
          cobradoresData = [];
        }

        final cobradores = cobradoresData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(cobradores: cobradores, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al cargar cobradores',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  // Obtener clientes asignados a un cobrador
  Future<void> cargarClientesAsignados(BigInt cobradorId) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.get('/users/$cobradorId/clients');

      if (response.data['success'] == true) {
        List<dynamic> clientesData;

        if (response.data['data'] is List) {
          clientesData = response.data['data'] as List<dynamic>;
        } else if (response.data['data'] is Map) {
          final dataMap = response.data['data'] as Map<String, dynamic>;
          if (dataMap['clients'] is List) {
            clientesData = dataMap['clients'] as List<dynamic>;
          } else if (dataMap['data'] is List) {
            clientesData = dataMap['data'] as List<dynamic>;
          } else {
            clientesData = [];
          }
        } else {
          clientesData = [];
        }

        final clientes = clientesData
            .map((json) => Usuario.fromJson(json))
            .toList();

        state = state.copyWith(clientesAsignados: clientes, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error:
              response.data['message'] ?? 'Error al cargar clientes asignados',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
    }
  }

  // Asignar cliente a un cobrador
  Future<bool> asignarClienteACobrador({
    required BigInt cobradorId,
    required BigInt clienteId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.post(
        '/users/$cobradorId/assign-clients',
        data: {
          'client_ids': [clienteId.toString()],
        },
      );

      if (response.data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente asignado exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al asignar cliente',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // Remover cliente de un cobrador
  Future<bool> removerClienteDeCobrador({
    required BigInt cobradorId,
    required BigInt clienteId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.delete(
        '/users/$cobradorId/clients/$clienteId',
      );

      if (response.data['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente removido exitosamente',
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: response.data['message'] ?? 'Error al remover cliente',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // Obtener cobrador asignado a un cliente
  Future<Usuario?> obtenerCobradorDeCliente(BigInt clienteId) async {
    try {
      final response = await _apiService.get('/users/$clienteId/cobrador');

      if (response.data['success'] == true && response.data['data'] != null) {
        return Usuario.fromJson(response.data['data']);
      }
      return null;
    } catch (e) {
      print('Error al obtener cobrador del cliente: $e');
      return null;
    }
  }

  // Limpiar mensajes
  void limpiarMensajes() {
    state = state.copyWith(error: null, successMessage: null);
  }
}

final cobradorAssignmentProvider =
    StateNotifierProvider<CobradorAssignmentNotifier, CobradorAssignmentState>(
      (ref) => CobradorAssignmentNotifier(),
    );
