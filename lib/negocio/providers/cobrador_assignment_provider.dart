import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/api_services/client_api_service.dart';
import '../../datos/api_services/user_api_service.dart';

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
  final UserApiService _userApiService = UserApiService();
  final ClientApiService _clientApiService = ClientApiService();

  CobradorAssignmentNotifier() : super(CobradorAssignmentState());

  // Cargar todos los cobradores disponibles
  Future<void> cargarCobradores() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _userApiService.getUsers(role: 'cobrador');

      if (response['success'] == true) {
        List<dynamic> cobradoresData;

        if (response['data'] is List) {
          cobradoresData = response['data'] as List<dynamic>;
        } else if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
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
          error: response['message'] ?? 'Error al cargar cobradores',
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
      final response = await _clientApiService.getCobradorClients(
        cobradorId.toString(),
      );

      if (response['success'] == true) {
        List<dynamic> clientesData;

        if (response['data'] is List) {
          clientesData = response['data'] as List<dynamic>;
        } else if (response['data'] is Map) {
          final dataMap = response['data'] as Map<String, dynamic>;
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
          error: response['message'] ?? 'Error al cargar clientes asignados',
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
      final response = await _clientApiService.assignClientsToCollector(
        cobradorId.toString(),
        [clienteId.toString()],
      );

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Cliente asignado exitosamente',
        );
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

  // Remover cliente de un cobrador
  Future<bool> removerClienteDeCobrador({
    required BigInt cobradorId,
    required BigInt clienteId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _clientApiService.removeClientFromCollector(
        cobradorId.toString(),
        clienteId.toString(),
      );

      if (response['success'] == true) {
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
      state = state.copyWith(isLoading: false, error: 'Error de conexión: $e');
      return false;
    }
  }

  // Obtener cobrador asignado a un cliente
  Future<Usuario?> obtenerCobradorDeCliente(BigInt clienteId) async {
    try {
      final response = await _clientApiService.getClientCobrador(
        clienteId.toString(),
      );

      if (response['success'] == true && response['data'] != null) {
        return Usuario.fromJson(response['data']);
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
