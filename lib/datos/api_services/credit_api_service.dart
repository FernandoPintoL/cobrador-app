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
    String? frequency, // CSV: daily,weekly,biweekly,monthly
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    double? amountMin,
    double? amountMax,
    double? totalAmountMin,
    double? totalAmountMax,
    double? balanceMin,
    double? balanceMax,
    double? totalPaidMin,
    double? totalPaidMax,
    bool? isOverdue, // Filtro para cuotas atrasadas
    double? overdueAmountMin, // Monto mínimo atrasado
    double? overdueAmountMax, // Monto máximo atrasado
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      if (clientId != null) queryParams['client_id'] = clientId;
      if (cobradorId != null) queryParams['cobrador_id'] = cobradorId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (frequency != null && frequency.isNotEmpty)
        queryParams['frequency'] = frequency;
      if (startDateFrom != null && startDateFrom.isNotEmpty)
        queryParams['start_date_from'] = startDateFrom;
      if (startDateTo != null && startDateTo.isNotEmpty)
        queryParams['start_date_to'] = startDateTo;
      if (endDateFrom != null && endDateFrom.isNotEmpty)
        queryParams['end_date_from'] = endDateFrom;
      if (endDateTo != null && endDateTo.isNotEmpty)
        queryParams['end_date_to'] = endDateTo;
      if (amountMin != null) queryParams['amount_min'] = amountMin;
      if (amountMax != null) queryParams['amount_max'] = amountMax;
      if (totalAmountMin != null)
        queryParams['total_amount_min'] = totalAmountMin;
      if (totalAmountMax != null)
        queryParams['total_amount_max'] = totalAmountMax;
      if (balanceMin != null) queryParams['balance_min'] = balanceMin;
      if (balanceMax != null) queryParams['balance_max'] = balanceMax;
      if (totalPaidMin != null) queryParams['total_paid_min'] = totalPaidMin;
      if (totalPaidMax != null) queryParams['total_paid_max'] = totalPaidMax;
      if (isOverdue != null) queryParams['is_overdue'] = isOverdue;
      if (overdueAmountMin != null)
        queryParams['overdue_amount_min'] = overdueAmountMin;
      if (overdueAmountMax != null)
        queryParams['overdue_amount_max'] = overdueAmountMax;

      final response = await get('/credits', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
  Future<Map<String, dynamic>> createCredit(
    Map<String, dynamic> creditData,
  ) async {
    try {
      final response = await post('/credits', data: creditData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
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
      final response = await get('/credits/$creditId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
      final response = await put('/credits/$creditId', data: creditData);
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
      final response = await delete('/credits/$creditId');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
    String? frequency, // CSV
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    double? amountMin,
    double? amountMax,
    double? balanceMin,
    double? balanceMax,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (frequency != null && frequency.isNotEmpty)
        queryParams['frequency'] = frequency;
      if (startDateFrom != null && startDateFrom.isNotEmpty)
        queryParams['start_date_from'] = startDateFrom;
      if (startDateTo != null && startDateTo.isNotEmpty)
        queryParams['start_date_to'] = startDateTo;
      if (endDateFrom != null && endDateFrom.isNotEmpty)
        queryParams['end_date_from'] = endDateFrom;
      if (endDateTo != null && endDateTo.isNotEmpty)
        queryParams['end_date_to'] = endDateTo;
      if (amountMin != null) queryParams['amount_min'] = amountMin;
      if (amountMax != null) queryParams['amount_max'] = amountMax;
      if (balanceMin != null) queryParams['balance_min'] = balanceMin;
      if (balanceMax != null) queryParams['balance_max'] = balanceMax;

      final response = await get(
        '/credits/client/$clientId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
    String? frequency, // CSV
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    double? amountMin,
    double? amountMax,
    double? balanceMin,
    double? balanceMax,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (frequency != null && frequency.isNotEmpty)
        queryParams['frequency'] = frequency;
      if (startDateFrom != null && startDateFrom.isNotEmpty)
        queryParams['start_date_from'] = startDateFrom;
      if (startDateTo != null && startDateTo.isNotEmpty)
        queryParams['start_date_to'] = startDateTo;
      if (endDateFrom != null && endDateFrom.isNotEmpty)
        queryParams['end_date_from'] = endDateFrom;
      if (endDateTo != null && endDateTo.isNotEmpty)
        queryParams['end_date_to'] = endDateTo;
      if (amountMin != null) queryParams['amount_min'] = amountMin;
      if (amountMax != null) queryParams['amount_max'] = amountMax;
      if (balanceMin != null) queryParams['balance_min'] = balanceMin;
      if (balanceMax != null) queryParams['balance_max'] = balanceMax;
      final response = await get(
        '/credits/cobrador/$cobradorId',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
      final response = await get('/credits/cobrador/$cobradorId/stats');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          'Error al obtener estadísticas: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas del cobrador: $e');
      throw Exception('Error al obtener estadísticas del cobrador: $e');
    }
  }

  /// Obtiene estadísticas de créditos de un manager
  /// Incluye métricas consolidadas de todos los clientes bajo su supervisión
  /// (clientes directos + clientes de sus cobradores)
  Future<Map<String, dynamic>> getManagerStats(int managerId) async {
    try {
      final response = await get('/credits/manager/$managerId/stats');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          'Error al obtener estadísticas del manager: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas del manager: $e');
      throw Exception('Error al obtener estadísticas del manager: $e');
    }
  }

  /// Obtiene créditos que requieren atención
  Future<Map<String, dynamic>> getCreditsRequiringAttention({
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      final response = await get(
        '/credits-requiring-attention',
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener créditos que requieren atención: ${response.statusCode}',
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
      final response = await get('/credits/$creditId/payment-schedule');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener cronograma de pagos: ${response.statusCode}',
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
      final response = await get('/credits/$creditId/details');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener detalles del crédito: ${response.statusCode}',
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
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      final response = await get(
        '/credits/waiting-list/pending-approval',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener créditos pendientes de aprobación: ${response.statusCode}',
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
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      final response = await get(
        '/credits/waiting-list/waiting-delivery',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener créditos en lista de espera: ${response.statusCode}',
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
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      final response = await get(
        '/credits/waiting-list/ready-today',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};
      final response = await get(
        '/credits/waiting-list/overdue-delivery',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener créditos con entrega atrasada: ${response.statusCode}',
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
      final response = await get('/credits/waiting-list/summary');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
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
    DateTime? scheduledDeliveryDate,
    String? notes,
    bool? immediateDelivery,
  }) async {
    try {
      final data = <String, dynamic>{};

      // Solo incluir scheduled_delivery_date si se proporciona
      // Si immediate_delivery es true, la fecha es opcional (el backend usa "now")
      if (scheduledDeliveryDate != null) {
        data['scheduled_delivery_date'] = scheduledDeliveryDate.toIso8601String();
      }

      if (notes != null && notes.isNotEmpty) {
        data['notes'] = notes;
      }

      if (immediateDelivery != null) {
        data['immediate_delivery'] = immediateDelivery;
      }

      final response = await post(
        '/credits/$creditId/waiting-list/approve',
        data: data,
      );

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return responseData;
      } else {
        throw Exception(
          'Error al aprobar crédito para entrega: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      final errorMessage = handleDioError(e);
      print('❌ Error al aprobar crédito para entrega: $errorMessage');

      // Lanzamos una excepción con el mensaje específico del backend
      throw ApiException(
        message: errorMessage,
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
      final data = {'reason': reason};
      final response = await post(
        '/credits/$creditId/waiting-list/reject',
        data: data,
      );
      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
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
  ///
  /// [firstPaymentToday] indica si el primer pago es el mismo día de entrega (true)
  /// o si el cronograma inicia al día siguiente (false, por defecto)
  Future<Map<String, dynamic>> deliverCreditToClient(
    int creditId, {
    String? notes,
    bool firstPaymentToday = false,
  }) async {
    try {
      print('🚚 Entregando crédito al cliente: $creditId');
      print('📅 Primer pago hoy: $firstPaymentToday');

      final data = <String, dynamic>{
        'first_payment_today': firstPaymentToday,
      };

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

        // El backend ahora incluye payment_schedule en la respuesta
        if (responseData['data'] != null &&
            responseData['data']['payment_schedule'] != null) {
          print('📊 Cronograma de pagos recibido del backend (${responseData['data']['payment_schedule'].length} cuotas)');
        }

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
        return responseData;
      } else {
        throw Exception(
          '❌ Error al reprogramar fecha de entrega: ${response.statusCode}',
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
      final response = await get('/credits/$creditId/waiting-list/status');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data;
      } else {
        throw Exception(
          '❌ Error al obtener estado de entrega: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estado de entrega: $e');
      throw Exception('Error al obtener estado de entrega: $e');
    }
  }

  /// Obtener configuración del formulario de créditos según settings del tenant
  Future<Map<String, dynamic>> getFormConfig() async {
    try {
      final response = await get('/credits/form-config');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Respuesta inválida del servidor');
        }
      } else {
        throw Exception(
          '❌ Error al obtener configuración del formulario: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener configuración del formulario: $e');
      // Retornar valores por defecto en caso de error
      return {
        'interest': {'can_edit': false, 'default': 20.0},
        'payment_frequency': {'can_edit': false, 'default': 'diario'},
      };
    }
  }

  /// Obtiene las frecuencias de pago configuradas para el tenant actual
  ///
  /// Endpoint: GET /api/loan-frequencies
  ///
  /// Retorna la configuración de frecuencias que incluye:
  /// - code: Código de la frecuencia (daily, weekly, biweekly, monthly)
  /// - name: Nombre legible (Diario, Semanal, Quincenal, Mensual)
  /// - is_fixed_duration: Si tiene duración fija (true para diaria)
  /// - fixed_installments: Cuotas fijas (24 para diaria)
  /// - fixed_duration_days: Días fijos (28 para diaria)
  /// - default_installments: Cuotas sugeridas por defecto
  /// - min_installments: Mínimo de cuotas permitidas
  /// - max_installments: Máximo de cuotas permitidas
  /// - period_days: Días por período (1, 7, 15, 30)
  /// - interest_rate: Tasa de interés específica (si varía por frecuencia)
  /// - is_editable: Si el usuario puede editar el número de cuotas
  /// - suggested_installments: Número de cuotas sugerido
  Future<List<Map<String, dynamic>>> getLoanFrequencies() async {
    try {
      final response = await get('/loan-frequencies');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        if (data['success'] == true && data['data'] != null) {
          final frequencies = data['data'] as List<dynamic>;
          return frequencies
              .map((freq) => Map<String, dynamic>.from(freq as Map))
              .toList();
        } else {
          throw Exception('Respuesta inválida del servidor');
        }
      } else {
        throw Exception(
          '❌ Error al obtener frecuencias de pago: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener frecuencias de pago: $e');
      // Retornar valores por defecto en caso de error
      return [
        {
          'code': 'daily',
          'name': 'Diario',
          'period_days': 1,
          'is_fixed_duration': true,
          'fixed_installments': 24,
          'fixed_duration_days': 28,
          'is_editable': false,
          'suggested_installments': 24,
          'interest_rate': '20.00',
        },
        {
          'code': 'weekly',
          'name': 'Semanal',
          'period_days': 7,
          'is_fixed_duration': false,
          'default_installments': 12,
          'min_installments': 4,
          'max_installments': 24,
          'is_editable': true,
          'suggested_installments': 12,
          'interest_rate': '15.00',
        },
        {
          'code': 'biweekly',
          'name': 'Quincenal',
          'period_days': 15,
          'is_fixed_duration': false,
          'default_installments': 6,
          'min_installments': 2,
          'max_installments': 12,
          'is_editable': true,
          'suggested_installments': 6,
          'interest_rate': '12.00',
        },
        {
          'code': 'monthly',
          'name': 'Mensual',
          'period_days': 30,
          'is_fixed_duration': false,
          'default_installments': 3,
          'min_installments': 1,
          'max_installments': 6,
          'is_editable': true,
          'suggested_installments': 3,
          'interest_rate': '10.00',
        },
      ];
    }
  }
}
