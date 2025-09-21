import 'package:dio/dio.dart';
import 'base_api_service.dart';

/// Servicio API para gestión de clientes y asignaciones
class ClientApiService extends BaseApiService {
  static final ClientApiService _instance = ClientApiService._internal();
  factory ClientApiService() => _instance;
  ClientApiService._internal();

  // ================== MÉTODOS PARA GESTIÓN DE CLIENTES ASIGNADOS ==================

  /// Obtiene clientes directos asignados a un manager específico
  Future<Map<String, dynamic>> getManagerDirectClients(
    String managerId, {
    String? search,
    int? perPage,
  }) async {
    try {
      print('📋 Obteniendo clientes directos del manager: $managerId');

      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage;
      }

      final response = await get(
        '/users/$managerId/clients-direct',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes directos del manager obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener clientes directos: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener clientes directos del manager: $e');
      throw Exception('Error al obtener clientes directos del manager: $e');
    }
  }

  /// Obtiene todos los clientes de un manager (directos + indirectos)
  Future<Map<String, dynamic>> getManagerAllClients(
    String managerId, {
    String? search,
    int? perPage,
  }) async {
    try {
      print(
        '📋 Obteniendo todos los clientes (directos+indirectos) del manager: $managerId',
      );

      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage;
      }

      final response = await get(
        '/users/$managerId/manager-clients',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes totales del manager obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener clientes del manager: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener clientes totales del manager: $e');
      throw Exception('Error al obtener clientes totales del manager: $e');
    }
  }

  /// Obtiene todos los clientes asignados a un cobrador específico
  Future<Map<String, dynamic>> getCobradorClients(
    String cobradorId, {
    String? search,
    int? perPage,
  }) async {
    try {
      print('📋 Obteniendo clientes del cobrador: $cobradorId');

      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      if (perPage != null) {
        queryParams['per_page'] = perPage;
      }

      final response = await get(
        '/users/$cobradorId/clients',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes del cobrador obtenidos exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener clientes del cobrador: $e');
      throw Exception('Error al obtener clientes del cobrador: $e');
    }
  }

  /// Asigna múltiples clientes a un cobrador
  Future<Map<String, dynamic>> assignClientsToCollector(
    String cobradorId,
    List<String> clientIds,
  ) async {
    try {
      print(
        '👥 Asignando ${clientIds.length} clientes al cobrador: $cobradorId',
      );

      final response = await post(
        '/users/$cobradorId/assign-clients',
        data: {'client_ids': clientIds.map((id) => int.parse(id)).toList()},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes asignados exitosamente');
        return data;
      } else {
        throw Exception('Error al asignar clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al asignar clientes al cobrador: $e');
      throw Exception('Error al asignar clientes al cobrador: $e');
    }
  }

  /// Remueve un cliente de un cobrador
  Future<Map<String, dynamic>> removeClientFromCollector(
    String cobradorId,
    String clientId,
  ) async {
    try {
      print('🗑️ Removiendo cliente $clientId del cobrador: $cobradorId');

      final response = await delete('/users/$cobradorId/clients/$clientId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente removido del cobrador exitosamente');
        return data;
      } else {
        throw Exception('Error al remover cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al remover cliente del cobrador: $e');
      throw Exception('Error al remover cliente del cobrador: $e');
    }
  }

  /// Obtiene el cobrador asignado a un cliente específico
  Future<Map<String, dynamic>> getClientCobrador(String clientId) async {
    try {
      print('👤 Obteniendo cobrador del cliente: $clientId');

      final response = await get('/users/$clientId/cobrador');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cobrador del cliente obtenido exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener cobrador: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener cobrador del cliente: $e');
      throw Exception('Error al obtener cobrador del cliente: $e');
    }
  }

  /// Crea un nuevo cliente (solo para cobradores y managers)
  Future<Map<String, dynamic>> createClient(
    Map<String, dynamic> clientData,
  ) async {
    try {
      print('➕ Creando nuevo cliente...');
      print('📋 Datos a enviar: $clientData');

      final response = await post('/users', data: clientData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente creado exitosamente');
        return data;
      } else {
        // Extraer mensaje de error del servidor si existe
        String errorMessage = 'Error del servidor';

        if (response.data != null && response.data is Map) {
          final errorData = response.data as Map<String, dynamic>;

          // Intentar extraer el mensaje principal
          errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Error ${response.statusCode}';

          // Si es error 422, intentar extraer errores específicos de validación
          if (response.statusCode == 422 && errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            List<String> errorDetails = [];

            errors.forEach((field, messages) {
              if (messages is List) {
                errorDetails.addAll(messages.map((msg) => '$field: $msg'));
              }
            });

            if (errorDetails.isNotEmpty) {
              errorMessage = errorDetails.join(', ');
            }
          }
        }

        print('❌ Error del servidor: $errorMessage (${response.statusCode})');
        print('❌ Error Response Status: ${response.statusCode}');
        print('❌ Error Response Data: ${response.data}');

        return {
          'success': false,
          'message': errorMessage,
          'status_code': response.statusCode,
          'details': response.data,
        };
      }
    } catch (e) {
      print('❌ Error al crear cliente: $e');

      // Extraer mensaje de error específico del servidor
      if (e is DioException) {
        throw Exception(handleDioError(e));
      }

      String errorMessage = 'Error de conexión';

      // Extraer información más específica del error de Dio
      if (e.toString().contains('422')) {
        errorMessage = 'Datos de entrada inválidos';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Solicitud incorrecta';
      } else if (e.toString().contains('401')) {
        errorMessage = 'No autorizado';
      } else if (e.toString().contains('403')) {
        errorMessage = 'Sin permisos';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Error interno del servidor';
      }

      return {'success': false, 'message': errorMessage, 'error': e.toString()};
    }
  }

  /// Actualiza un cliente existente
  Future<Map<String, dynamic>> updateClient(
    String clientId,
    Map<String, dynamic> clientData,
  ) async {
    try {
      print('📝 Actualizando cliente: $clientId');

      final response = await put('/users/$clientId', data: clientData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente actualizado exitosamente');
        return data;
      } else {
        throw Exception('Error al actualizar cliente: ${response.statusCode}');
      }
    } catch (e) {
      // Extraer mensaje de error específico del servidor
      if (e is DioException) {
        throw Exception(handleDioError(e));
      }
      print('❌ Error al actualizar cliente: $e');
      throw Exception('Error al actualizar cliente: $e');
    }
  }

  /// Elimina un cliente
  Future<Map<String, dynamic>> deleteClient(String clientId) async {
    try {
      print('🗑️ Eliminando cliente: $clientId');

      final response = await delete('/users/$clientId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente eliminado exitosamente');
        return data;
      } else {
        throw Exception('Error al eliminar cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al eliminar cliente: $e');
      throw Exception('Error al eliminar cliente: $e');
    }
  }

  /// Obtiene todos los clientes
  Future<Map<String, dynamic>> getClients({
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo clientes...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await get('/users', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes obtenidos exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener clientes: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener clientes: $e');
      throw Exception('Error al obtener clientes: $e');
    }
  }

  /// Obtiene un cliente específico
  Future<Map<String, dynamic>> getClient(String clientId) async {
    try {
      print('🔍 Obteniendo cliente: $clientId');

      final response = await get('/users/$clientId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente obtenido exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener cliente: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener cliente: $e');
      throw Exception('Error al obtener cliente: $e');
    }
  }

  /// Obtiene clientes que no están asignados a ningún cobrador
  Future<Map<String, dynamic>> getUnassignedClients({
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo clientes sin asignar...');

      final queryParams = <String, dynamic>{
        'role': 'client',
        'unassigned': true,
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await get('/users', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes sin asignar obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener clientes sin asignar: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener clientes sin asignar: $e');
      throw Exception('Error al obtener clientes sin asignar: $e');
    }
  }

  // ================== MÉTODOS PARA GESTIÓN DIRECTA MANAGER → CLIENTE ==================

  /// Asigna múltiples clientes directamente a un manager
  Future<Map<String, dynamic>> assignClientsDirectlyToManager(
    String managerId,
    List<String> clientIds,
  ) async {
    try {
      print(
        '📝 Asignando ${clientIds.length} clientes directamente al manager: $managerId',
      );

      final response = await post(
        '/users/$managerId/assign-clients-direct',
        data: {'client_ids': clientIds},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes asignados directamente al manager exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al asignar clientes directamente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al asignar clientes directamente al manager: $e');
      throw Exception('Error al asignar clientes directamente al manager: $e');
    }
  }

  /// Remueve un cliente específico de la asignación directa del manager
  Future<Map<String, dynamic>> removeClientFromManagerDirect(
    String managerId,
    String clientId,
  ) async {
    try {
      print('🗑️ Removiendo cliente $clientId del manager directo: $managerId');

      final response = await delete(
        '/users/$managerId/clients-direct/$clientId',
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cliente removido del manager directo exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al remover cliente directo: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al remover cliente del manager directo: $e');
      throw Exception('Error al remover cliente del manager directo: $e');
    }
  }

  /// Obtiene el manager directo asignado a un cliente específico
  Future<Map<String, dynamic>> getClientDirectManager(String clientId) async {
    try {
      print('👤 Obteniendo manager directo del cliente: $clientId');

      final response = await get('/users/$clientId/manager-direct');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Manager directo del cliente obtenido exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener manager directo: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener manager directo del cliente: $e');
      throw Exception('Error al obtener manager directo del cliente: $e');
    }
  }
}
