import 'base_api_service.dart';

/// Servicio API para gestión de la relación Manager → Cobrador
class ManagerApiService extends BaseApiService {
  static final ManagerApiService _instance = ManagerApiService._internal();
  factory ManagerApiService() => _instance;
  ManagerApiService._internal();

  // ===== GESTIÓN DE COBRADORES ASIGNADOS A MANAGERS =====

  /// Obtiene todos los cobradores asignados a un manager específico
  Future<Map<String, dynamic>> getCobradoresByManager(
    String managerId, {
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      print('📋 Obteniendo cobradores del manager: $managerId');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await get(
        '/users/$managerId/cobradores',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cobradores del manager obtenidos exitosamente');
        return data;
      } else if (response.statusCode == 400) {
        // Manejo específico para error 400
        final data = response.data as Map<String, dynamic>?;
        final message = data?['message'] ?? 'Error 400: Solicitud inválida';

        print('❌ Error 400: $message');

        // Si el error es porque el usuario no es un manager, dar mensaje más claro
        if (message.contains('no es un cobrador') ||
            message.contains('no válido')) {
          return {
            'success': false,
            'message':
                'El usuario con ID $managerId no tiene rol de manager o no existe',
            'data': {'current_page': 1, 'data': [], 'total': 0},
          };
        }

        return {
          'success': false,
          'message': message,
          'data': {'current_page': 1, 'data': [], 'total': 0},
        };
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      print('❌ Excepción al obtener cobradores del manager: $e');

      // Si es un DioException con status 400, manejar específicamente
      if (e.toString().contains('400') &&
          e.toString().contains('bad response')) {
        return {
          'success': false,
          'message': 'El usuario no tiene permisos de manager o no existe',
          'data': {'current_page': 1, 'data': [], 'total': 0},
        };
      }

      return _handleException(e, 'obtener cobradores del manager');
    }
  }

  /// Asigna múltiples cobradores a un manager
  Future<Map<String, dynamic>> assignCobradoresToManager(
    String managerId,
    List<String> cobradorIds,
  ) async {
    try {
      print('👥 Asignando cobradores al manager: $managerId');
      print('   Cobradores: $cobradorIds');

      final response = await post(
        '/users/$managerId/assign-cobradores',
        data: {'cobrador_ids': cobradorIds},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cobradores asignados exitosamente al manager');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'asignar cobradores al manager');
    }
  }

  /// Remueve la asignación de un cobrador específico de un manager
  Future<Map<String, dynamic>> removeCobradorFromManager(
    String managerId,
    String cobradorId,
  ) async {
    try {
      print('❌ Removiendo cobrador $cobradorId del manager: $managerId');

      final response = await delete('/users/$managerId/cobradores/$cobradorId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cobrador removido exitosamente del manager');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'remover cobrador del manager');
    }
  }

  /// Obtiene el manager asignado a un cobrador específico
  Future<Map<String, dynamic>> getManagerByCobrador(String cobradorId) async {
    try {
      print('👤 Obteniendo manager del cobrador: $cobradorId');

      final response = await get('/users/$cobradorId/manager');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Manager del cobrador obtenido exitosamente');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener manager del cobrador');
    }
  }

  // ===== MÉTODOS AUXILIARES PARA JERARQUÍA COMPLETA =====

  /// Obtiene todos los clientes de un manager específico usando el endpoint recomendado
  /// GET /api/users/{managerId}/manager-clients
  Future<Map<String, dynamic>> getClientesByManager(
    String managerId, {
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      print('📋 Obteniendo TODOS los clientes del manager: $managerId');
      print('   Incluye clientes directos y clientes de cobradores');

      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await get(
        '/users/$managerId/manager-clients',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes del manager obtenidos exitosamente');
        print('   Total encontrado: ${data['data']?['total'] ?? 'N/A'}');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener clientes del manager');
    }
  }

  /// Obtiene solo los clientes directos de un manager (sin incluir los de cobradores)
  /// GET /api/users/{managerId}/clients-direct
  Future<Map<String, dynamic>> getClientesDirectosDelManager(
    String managerId, {
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      print('📋 Obteniendo clientes DIRECTOS del manager: $managerId');

      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
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
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener clientes directos del manager');
    }
  }

  /// Obtiene los clientes de un cobrador específico
  /// GET /api/users/{cobradorId}/clients
  Future<Map<String, dynamic>> getClientesDelCobrador(
    String cobradorId, {
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    try {
      print('📋 Obteniendo clientes del cobrador: $cobradorId');

      final queryParams = <String, dynamic>{
        'page': page,
        'per_page': perPage,
      };

      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await get(
        '/users/$cobradorId/clients',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Clientes del cobrador obtenidos exitosamente');
        print('   Total encontrado: ${data['data']?['total'] ?? 'N/A'}');
        return data;
      } else {
        return _handleErrorResponse(response);
      }
    } catch (e) {
      return _handleException(e, 'obtener clientes del cobrador');
    }
  }

  /// Obtiene estadísticas completas de un manager
  Future<Map<String, dynamic>> getManagerStats(String managerId) async {
    try {
      print('📊 Obteniendo estadísticas del manager: $managerId');

      // Obtener cobradores del manager
      final cobradoresResponse = await getCobradoresByManager(
        managerId,
        perPage: 100,
      );

      if (cobradoresResponse['success'] != true) {
        return cobradoresResponse;
      }

      final cobradoresData = cobradoresResponse['data']?['data'] as List? ?? [];
      final totalCobradores = cobradoresData.length;

      // Obtener clientes del manager
      final clientesResponse = await getClientesByManager(managerId);
      final clientesData = clientesResponse['data']?['data'] as List? ?? [];
      final totalClientes = clientesData.length;

      // TODO: Agregar estadísticas de créditos y pagos cuando estén disponibles

      return {
        'success': true,
        'message': 'Estadísticas del manager obtenidas exitosamente',
        'data': {
          'total_cobradores': totalCobradores,
          'total_clientes': totalClientes,
          'cobradores_activos': totalCobradores, // Por ahora todos son activos
          'total_creditos': 0, // TODO: Implementar
          'total_pagos': 0, // TODO: Implementar
          'cobros_mes': 0, // TODO: Implementar
        },
      };
    } catch (e) {
      return _handleException(e, 'obtener estadísticas del manager');
    }
  }

  // ===== MÉTODOS DE MANEJO DE ERRORES =====

  Map<String, dynamic> _handleErrorResponse(dynamic response) {
    final data = response.data as Map<String, dynamic>?;
    return {
      'success': false,
      'message': data?['message'] ?? 'Error en la operación',
      'errors': data?['errors'],
    };
  }

  Map<String, dynamic> _handleException(Object e, String operation) {
    print('❌ Error al $operation: $e');
    return {
      'success': false,
      'message': 'Error de conexión al $operation',
      'error': e.toString(),
    };
  }
}
