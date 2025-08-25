import 'package:dio/dio.dart';

import '../modelos/api_exception.dart';
import 'base_api_service.dart';

/// Servicio API para gestión de créditos
class CreditApiService extends BaseApiService {
  static final CreditApiService _instance = CreditApiService._internal();
  factory CreditApiService() => _instance;
  CreditApiService._internal();

  // ========================================
  // MÉTODOS DE CRÉDITOS
  // ========================================

  /// Obtiene todos los créditos (para cobradores, solo de sus clientes asignados)
  Future<Map<String, dynamic>> getCredits({
    int? clientId,
    int? cobradorId,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (clientId != null) queryParams['client_id'] = clientId;
      if (cobradorId != null) queryParams['cobrador_id'] = cobradorId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await get('/credits', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos obtenidos exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener créditos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener créditos: $e');
      throw Exception('Error al obtener créditos: $e');
    }
  }

  /// Crea un nuevo crédito
  Future<Map<String, dynamic>> createCredit(Map<String, dynamic> creditData) async {
    try {
      print('➕ Creando nuevo crédito...');
      print('📋 Datos a enviar: $creditData');

      final response = await post('/credits', data: creditData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Crédito creado exitosamente');
        return data;
      } else {
        throw ApiException(
          message: 'Error al crear crédito: ${response.statusCode}',
          statusCode: response.statusCode,
          errorData: response.data,
        );
      }
    } on DioException catch (e) {
      // Convertir el error de Dio en ApiException con mensaje amigable y errores de validación
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error al crear crédito';
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) {
          message = data['message'].toString();
        } else if (data['error'] != null) {
          message = data['error'].toString();
        }
      } else if (e.message != null) {
        message = e.message!;
      }

      print('❌ Error al crear crédito (ApiException): $message');
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      print('❌ Error al crear crédito: $e');
      throw ApiException(message: 'Error al crear crédito: $e');
    }
  }

  /// Obtiene un crédito específico
  Future<Map<String, dynamic>> getCredit(int creditId) async {
    try {
      print('🔍 Obteniendo crédito: $creditId');

      final response = await get('/credits/$creditId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Crédito obtenido exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener crédito: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener crédito: $e');
      throw Exception('Error al obtener crédito: $e');
    }
  }

  /// Actualiza un crédito
  Future<Map<String, dynamic>> updateCredit(
    int creditId,
    Map<String, dynamic> creditData,
  ) async {
    try {
      print('✏️ Actualizando crédito: $creditId');
      print('📋 Datos a actualizar: $creditData');

      final response = await put('/credits/$creditId', data: creditData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Crédito actualizado exitosamente');
        return data;
      } else {
        throw Exception('Error al actualizar crédito: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al actualizar crédito: $e');
      throw Exception('Error al actualizar crédito: $e');
    }
  }

  /// Elimina un crédito
  Future<Map<String, dynamic>> deleteCredit(int creditId) async {
    try {
      print('🗑️ Eliminando crédito: $creditId');

      final response = await delete('/credits/$creditId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Crédito eliminado exitosamente');
        return data;
      } else {
        throw Exception('Error al eliminar crédito: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al eliminar crédito: $e');
      throw Exception('Error al eliminar crédito: $e');
    }
  }

  /// Obtiene créditos de un cliente específico
  Future<Map<String, dynamic>> getClientCredits(
    int clientId, {
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos del cliente: $clientId');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await get(
        '/credits/client/$clientId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos del cliente obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos del cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos del cliente: $e');
      throw Exception('Error al obtener créditos del cliente: $e');
    }
  }

  /// Obtiene créditos de un cobrador específico (solo para admins/managers)
  Future<Map<String, dynamic>> getCobradorCredits(
    int cobradorId, {
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos del cobrador: $cobradorId');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await get(
        '/credits/cobrador/$cobradorId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos del cobrador obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos del cobrador: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos del cobrador: $e');
      throw Exception('Error al obtener créditos del cobrador: $e');
    }
  }

  /// Obtiene estadísticas de créditos de un cobrador
  Future<Map<String, dynamic>> getCobradorStats(int cobradorId) async {
    try {
      print('📊 Obteniendo estadísticas del cobrador: $cobradorId');

      final response = await get('/credits/cobrador/$cobradorId/stats');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Estadísticas del cobrador obtenidas exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener estadísticas: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Obtiene créditos que requieren atención
  Future<Map<String, dynamic>> getCreditsRequiringAttention({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('⚠️ Obteniendo créditos que requieren atención...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      final response = await get(
        '/credits-requiring-attention',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos que requieren atención obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos que requieren atención: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos que requieren atención: $e');
      throw Exception('Error al obtener créditos que requieren atención: $e');
    }
  }

  /// Obtiene el cronograma de pagos de un crédito
  Future<Map<String, dynamic>> getCreditPaymentSchedule(int creditId) async {
    try {
      print('📅 Obteniendo cronograma de pagos para crédito: $creditId');

      final response = await get('/credits/$creditId/payment-schedule');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Cronograma de pagos obtenido exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener cronograma de pagos: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener cronograma de pagos: $e');
      throw Exception('Error al obtener cronograma de pagos: $e');
    }
  }

  /// Obtiene detalles extendidos de un crédito
  Future<Map<String, dynamic>> getCreditDetails(int creditId) async {
    try {
      print('🔍 Obteniendo detalles del crédito: $creditId');

      final response = await get('/credits/$creditId/details');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Detalles del crédito obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener detalles del crédito: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener detalles del crédito: $e');
      throw Exception('Error al obtener detalles del crédito: $e');
    }
  }

  // ========================================
  // MÉTODOS DE LISTA DE ESPERA
  // ========================================

  /// Obtiene créditos pendientes de aprobación
  Future<Map<String, dynamic>> getPendingApprovalCredits({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos pendientes de aprobación...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      final response = await get(
        '/credits/waiting-list/pending-approval',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos pendientes de aprobación obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos pendientes de aprobación: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos pendientes de aprobación: $e');
      throw Exception('Error al obtener créditos pendientes de aprobación: $e');
    }
  }

  /// Obtiene créditos en lista de espera para entrega
  Future<Map<String, dynamic>> getWaitingDeliveryCredits({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos en lista de espera...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      final response = await get(
        '/credits/waiting-list/waiting-delivery',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos en lista de espera obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos en lista de espera: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos en lista de espera: $e');
      throw Exception('Error al obtener créditos en lista de espera: $e');
    }
  }

  /// Obtiene créditos listos para entrega hoy
  Future<Map<String, dynamic>> getReadyForDeliveryToday({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos listos para entrega hoy...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      final response = await get(
        '/credits/waiting-list/ready-today',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos listos para entrega hoy obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos listos para entrega: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos listos para entrega: $e');
      throw Exception('Error al obtener créditos listos para entrega: $e');
    }
  }

  /// Obtiene créditos con entrega atrasada
  Future<Map<String, dynamic>> getOverdueDeliveryCredits({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo créditos con entrega atrasada...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      final response = await get(
        '/credits/waiting-list/overdue-delivery',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Créditos con entrega atrasada obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener créditos con entrega atrasada: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener créditos con entrega atrasada: $e');
      throw Exception('Error al obtener créditos con entrega atrasada: $e');
    }
  }

  /// Obtiene resumen de lista de espera
  Future<Map<String, dynamic>> getWaitingListSummary() async {
    try {
      print('📊 Obteniendo resumen de lista de espera...');

      final response = await get('/credits/waiting-list/summary');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Resumen de lista de espera obtenido exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener resumen de lista de espera: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener resumen de lista de espera: $e');
      throw Exception('Error al obtener resumen de lista de espera: $e');
    }
  }

  /// Aprueba un crédito para entrega
  Future<Map<String, dynamic>> approveCreditForDelivery({
    required String creditId,
    required DateTime scheduledDeliveryDate,
    String? notes,
  }) async {
    try {
      print('✅ Aprobando crédito para entrega: $creditId');

      final data = {
        'scheduled_delivery_date': scheduledDeliveryDate.toIso8601String(),
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };

      final response = await post(
        '/credits/$creditId/waiting-list/approve',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        print('✅ Crédito aprobado para entrega exitosamente');
        return responseData;
      } else {
        throw Exception(
          'Error al aprobar crédito para entrega: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final errorMessage = handleDioError(e);
      print('❌ Error al aprobar crédito para entrega: $errorMessage');

      // Lanzamos una excepción con los detalles del error para poder mostrarlos en la UI
      throw ApiException(
        message: 'Error al aprobar crédito para entrega',
        statusCode: e.response?.statusCode,
        errorData: e.response?.data,
        originalError: e,
      );
    } catch (e) {
      print('❌ Error al aprobar crédito para entrega: $e');
      throw Exception('Error al aprobar crédito para entrega: $e');
    }
  }

  /// Rechaza un crédito
  Future<Map<String, dynamic>> rejectCredit(
    int creditId, {
    required String reason,
  }) async {
    try {
      print('❌ Rechazando crédito: $creditId');

      final data = {'reason': reason};

      final response = await post(
        '/credits/$creditId/waiting-list/reject',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        print('✅ Crédito rechazado exitosamente');
        return responseData;
      } else {
        throw Exception('Error al rechazar crédito: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al rechazar crédito: $e');
      throw Exception('Error al rechazar crédito: $e');
    }
  }

  /// Entrega un crédito al cliente
  Future<Map<String, dynamic>> deliverCreditToClient(
    int creditId, {
    String? notes,
  }) async {
    try {
      print('🚚 Entregando crédito al cliente: $creditId');

      final data = <String, dynamic>{};
      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      final response = await post(
        '/credits/$creditId/waiting-list/deliver',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        print('✅ Crédito entregado al cliente exitosamente');
        return responseData;
      } else {
        throw Exception(
          'Error al entregar crédito al cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al entregar crédito al cliente: $e');
      throw Exception('Error al entregar crédito al cliente: $e');
    }
  }

  /// Reprograma la fecha de entrega de un crédito
  Future<Map<String, dynamic>> rescheduleCreditDelivery(
    int creditId, {
    required DateTime newScheduledDate,
    String? reason,
  }) async {
    try {
      print('📅 Reprogramando entrega del crédito: $creditId');

      final data = {
        'scheduled_delivery_date': newScheduledDate.toIso8601String(),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      };

      final response = await post(
        '/credits/$creditId/waiting-list/reschedule',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        print('✅ Fecha de entrega reprogramada exitosamente');
        return responseData;
      } else {
        throw Exception(
          'Error al reprogramar fecha de entrega: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al reprogramar fecha de entrega: $e');
      throw Exception('Error al reprogramar fecha de entrega: $e');
    }
  }

  /// Obtiene el estado de entrega de un crédito
  Future<Map<String, dynamic>> getCreditDeliveryStatus(int creditId) async {
    try {
      print('📋 Obteniendo estado de entrega del crédito: $creditId');

      final response = await get('/credits/$creditId/waiting-list/status');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Estado de entrega obtenido exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener estado de entrega: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estado de entrega: $e');
      throw Exception('Error al obtener estado de entrega: $e');
    }
  }
}
