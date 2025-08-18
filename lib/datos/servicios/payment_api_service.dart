import 'base_api_service.dart';
import 'package:dio/dio.dart';
import '../modelos/api_exception.dart';

/// Servicio API para gestión de pagos
class PaymentApiService extends BaseApiService {
  static final PaymentApiService _instance = PaymentApiService._internal();
  factory PaymentApiService() => _instance;
  PaymentApiService._internal();

  // ========================================
  // MÉTODOS DE PAGOS
  // ========================================

  /// Obtiene todos los pagos
  Future<Map<String, dynamic>> getPayments({
    int? creditId,
    int? clientId,
    int? cobradorId,
    String? status,
    String? paymentType,
    String? search,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo pagos...');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (creditId != null) queryParams['credit_id'] = creditId;
      if (clientId != null) queryParams['client_id'] = clientId;
      if (cobradorId != null) queryParams['cobrador_id'] = cobradorId;
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (paymentType != null && paymentType.isNotEmpty) {
        queryParams['payment_type'] = paymentType;
      }
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await get('/payments', queryParameters: queryParams);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pagos obtenidos exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener pagos: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener pagos: $e');
      throw Exception('Error al obtener pagos: $e');
    }
  }

  /// Crea un nuevo pago
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      print('💰 Creando nuevo pago...');
      print('📋 Datos a enviar: $paymentData');

      final response = await post('/payments', data: paymentData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pago creado exitosamente');
        return data;
      } else {
        throw ApiException(
          message: 'Error al crear pago',
          statusCode: response.statusCode,
          errorData: response.data,
        );
      }
    } on DioException catch (e) {
      // Propagar información del backend para que UI la muestre
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error al crear pago';
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) message = data['message'].toString();
        else if (data['error'] != null) message = data['error'].toString();
      }
      print('❌ Error al crear pago: $message');
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      print('❌ Error al crear pago: $e');
      throw ApiException(message: 'Error al crear pago: $e', originalError: e);
    }
  }

  /// Obtiene un pago específico
  Future<Map<String, dynamic>> getPayment(int paymentId) async {
    try {
      print('🔍 Obteniendo pago: $paymentId');

      final response = await get('/payments/$paymentId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pago obtenido exitosamente');
        return data;
      } else {
        throw Exception('Error al obtener pago: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener pago: $e');
      throw Exception('Error al obtener pago: $e');
    }
  }

  /// Actualiza un pago
  Future<Map<String, dynamic>> updatePayment(
    int paymentId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      print('✏️ Actualizando pago: $paymentId');
      print('📋 Datos a actualizar: $paymentData');

      final response = await put('/payments/$paymentId', data: paymentData);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pago actualizado exitosamente');
        return data;
      } else {
        throw Exception('Error al actualizar pago: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al actualizar pago: $e');
      throw Exception('Error al actualizar pago: $e');
    }
  }

  /// Elimina un pago
  Future<Map<String, dynamic>> deletePayment(int paymentId) async {
    try {
      print('🗑️ Eliminando pago: $paymentId');

      final response = await delete('/payments/$paymentId');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pago eliminado exitosamente');
        return data;
      } else {
        throw Exception('Error al eliminar pago: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al eliminar pago: $e');
      throw Exception('Error al eliminar pago: $e');
    }
  }

  /// Obtiene pagos de un crédito específico
  Future<Map<String, dynamic>> getCreditPayments(
    int creditId, {
    String? status,
    String? paymentType,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo pagos del crédito: $creditId');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (paymentType != null && paymentType.isNotEmpty) {
        queryParams['payment_type'] = paymentType;
      }

      final response = await get(
        '/credits/$creditId/payments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pagos del crédito obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener pagos del crédito: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener pagos del crédito: $e');
      throw Exception('Error al obtener pagos del crédito: $e');
    }
  }

  /// Obtiene pagos de un cliente específico
  Future<Map<String, dynamic>> getClientPayments(
    int clientId, {
    String? status,
    String? paymentType,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo pagos del cliente: $clientId');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (paymentType != null && paymentType.isNotEmpty) {
        queryParams['payment_type'] = paymentType;
      }

      final response = await get(
        '/clients/$clientId/payments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pagos del cliente obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener pagos del cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener pagos del cliente: $e');
      throw Exception('Error al obtener pagos del cliente: $e');
    }
  }

  /// Obtiene pagos de un cobrador específico
  Future<Map<String, dynamic>> getCobradorPayments(
    int cobradorId, {
    String? status,
    String? paymentType,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      print('📋 Obteniendo pagos del cobrador: $cobradorId');

      final queryParams = <String, dynamic>{'page': page, 'per_page': perPage};

      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (paymentType != null && paymentType.isNotEmpty) {
        queryParams['payment_type'] = paymentType;
      }

      final response = await get(
        '/cobradores/$cobradorId/payments',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pagos del cobrador obtenidos exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener pagos del cobrador: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener pagos del cobrador: $e');
      throw Exception('Error al obtener pagos del cobrador: $e');
    }
  }

  /// Procesa un pago (confirma, rechaza, etc.)
  Future<Map<String, dynamic>> processPayment(
    int paymentId,
    String action, {
    String? notes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      print('⚙️ Procesando pago: $paymentId con acción: $action');

      final data = <String, dynamic>{'action': action};
      if (notes != null && notes.isNotEmpty) data['notes'] = notes;
      if (additionalData != null) data.addAll(additionalData);

      final response = await post('/payments/$paymentId/process', data: data);

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        print('✅ Pago procesado exitosamente');
        return responseData;
      } else {
        throw Exception('Error al procesar pago: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al procesar pago: $e');
      throw Exception('Error al procesar pago: $e');
    }
  }

  /// Obtiene estadísticas de pagos
  Future<Map<String, dynamic>> getPaymentStats({
    int? cobradorId,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      print('📊 Obteniendo estadísticas de pagos...');

      final queryParams = <String, dynamic>{};
      if (cobradorId != null) queryParams['cobrador_id'] = cobradorId;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;

      final response = await get(
        '/payments/stats',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Estadísticas de pagos obtenidas exitosamente');
        return data;
      } else {
        throw Exception(
          'Error al obtener estadísticas de pagos: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas de pagos: $e');
      throw Exception('Error al obtener estadísticas de pagos: $e');
    }
  }

  /// Crea un pago para un crédito específico
  Future<Map<String, dynamic>> createPaymentForCredit(
    int creditId,
    Map<String, dynamic> paymentData,
  ) async {
    try {
      print('💰 Creando pago para crédito: $creditId');
      print('📋 Datos a enviar: $paymentData');

      final response = await post(
        // '/credits/$creditId/payments',
        '/payments',
        data: paymentData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Pago para crédito creado exitosamente');
        return data;
      } else {
        throw ApiException(
          message: 'Error al crear pago para crédito',
          statusCode: response.statusCode,
          errorData: response.data,
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error al crear pago para crédito';
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) message = data['message'].toString();
        else if (data['error'] != null) message = data['error'].toString();
      }
      print('❌ Error al crear pago para crédito: $message');
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      print('❌ Error al crear pago para crédito: $e');
      throw ApiException(
        message: 'Error al crear pago para crédito: $e',
        originalError: e,
      );
    }
  }

  /// Simula un pago para un crédito específico
  Future<Map<String, dynamic>> simulatePayment(
    int creditId,
    double amount,
  ) async {
    try {
      print('🧮 Simulando pago para crédito: $creditId, monto: $amount');

      final response = await post(
        '/credits/$creditId/simulate-payment',
        data: {'amount': amount},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Simulación de pago completada');
        return data;
      } else {
        throw ApiException(
          message: 'Error al simular pago',
          statusCode: response.statusCode,
          errorData: response.data,
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error al simular pago';
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) message = data['message'].toString();
        else if (data['error'] != null) message = data['error'].toString();
      }
      print('❌ Error al simular pago: $message');
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      print('❌ Error al simular pago: $e');
      throw ApiException(message: 'Error al simular pago: $e', originalError: e);
    }
  }
}
