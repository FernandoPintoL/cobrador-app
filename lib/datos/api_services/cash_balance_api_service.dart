import 'base_api_service.dart';
import 'package:dio/dio.dart';
import '../modelos/api_exception.dart';

/// Servicio API para gestión de cash balances / cajas
class CashBalanceApiService extends BaseApiService {
  static final CashBalanceApiService _instance =
      CashBalanceApiService._internal();
  factory CashBalanceApiService() => _instance;
  CashBalanceApiService._internal();

  /// Abre una caja (idempotente). Devuelve la respuesta del backend (Map)
  Future<Map<String, dynamic>> openCashBalance({
    int? cobradorId,
    String? date,
    double? initialAmount,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (cobradorId != null) payload['cobrador_id'] = cobradorId;
      if (date != null) payload['date'] = date;
      if (initialAmount != null) payload['initial_amount'] = initialAmount;

      final response = await post('/cash-balances/open', data: payload);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          return raw;
        } else {
          throw ApiException(
            message: 'Formato de respuesta inesperado al abrir caja',
            statusCode: response.statusCode,
            errorData: raw,
          );
        }
      } else {
        throw ApiException(
          message: 'Error al abrir caja',
          statusCode: response.statusCode,
          errorData: response.data,
        );
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error al abrir caja';
      if (data is Map<String, dynamic>) {
        if (data['message'] != null) message = data['message'].toString();
      }
      // Log removed to satisfy analyzer (avoid_print)
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(message: 'Error al abrir caja: $e', originalError: e);
    }
  }

  /// Lista cajas con filtros y paginación.
  Future<Map<String, dynamic>> listCashBalances({
    int? cobradorId,
    String? dateFrom,
    String? dateTo,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final query = <String, dynamic>{'page': page, 'per_page': perPage};
      if (cobradorId != null) query['cobrador_id'] = cobradorId;
      if (dateFrom != null) query['date_from'] = dateFrom;
      if (dateTo != null) query['date_to'] = dateTo;
      if (status != null) query['status'] = status;

      final response = await get('/cash-balances', queryParameters: query);
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado en lista de cajas',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error listando cajas',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error listando cajas';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(message: 'Error listando cajas: $e', originalError: e);
    }
  }

  /// Obtener detalle extendido de una caja
  Future<Map<String, dynamic>> getCashBalanceDetailed(int id) async {
    try {
      final response = await get('/cash-balances/$id/detailed');
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado en detalle de caja',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error obteniendo detalle de caja',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error obteniendo detalle de caja';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Error obteniendo detalle de caja: $e',
        originalError: e,
      );
    }
  }

  /// Crear una caja manualmente (POST /cash-balances)
  Future<Map<String, dynamic>> createCashBalance(
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await post('/cash-balances', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado al crear caja',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error creando caja',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error creando caja';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(message: 'Error creando caja: $e', originalError: e);
    }
  }

  /// Actualizar/editar una caja (PUT /cash-balances/{id})
  Future<Map<String, dynamic>> updateCashBalance(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await put('/cash-balances/$id', data: payload);
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado al actualizar caja',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error actualizando caja',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error actualizando caja';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Error actualizando caja: $e',
        originalError: e,
      );
    }
  }

  /// Auto-calculate (POST /cash-balances/auto)
  Future<Map<String, dynamic>> autoCalculate({
    required int cobradorId,
    required String date,
    double? initialAmount,
    double? finalAmount,
  }) async {
    try {
      final payload = <String, dynamic>{
        'cobrador_id': cobradorId,
        'date': date,
      };
      if (initialAmount != null) payload['initial_amount'] = initialAmount;
      if (finalAmount != null) payload['final_amount'] = finalAmount;
      final response = await post(
        '/cash-balances/auto',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado en auto-calculate',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error en auto-calculate',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error en auto-calculate';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Error en auto-calculate: $e',
        originalError: e,
      );
    }
  }

  /// Obtener cajas pendientes de cierre
  Future<Map<String, dynamic>> getPendingClosures({int? cobradorId}) async {
    try {
      final query = <String, dynamic>{};
      if (cobradorId != null) query['cobrador_id'] = cobradorId;

      final response = await get(
        '/cash-balances/pending-closures',
        queryParameters: query.isEmpty ? null : query,
      );
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado en cajas pendientes',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error obteniendo cajas pendientes',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error obteniendo cajas pendientes';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Error obteniendo cajas pendientes: $e',
        originalError: e,
      );
    }
  }

  /// Cerrar caja usando el endpoint correcto POST /cash-balances/{id}/close
  Future<Map<String, dynamic>> closeCashBalance(
    int id, {
    double? finalAmount,
    String? notes,
    String status = 'closed', // Añadimos el parámetro status con valor por defecto 'closed'
  }) async {
    try {
      final payload = <String, dynamic>{
        'status': status, // Incluimos siempre el status en el payload
      };
      if (finalAmount != null) payload['final_amount'] = finalAmount;
      if (notes != null) payload['notes'] = notes;

      // Usar POST /cash-balances/{id}/close según documentación
      final response = await post('/cash-balances/$id/close', data: payload);
      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado al cerrar caja',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }
      throw ApiException(
        message: 'Error cerrando caja',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error cerrando caja';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(message: 'Error cerrando caja: $e', originalError: e);
    }
  }

  /// Obtener el estado actual de la caja (GET /cash-balances/current-status)
  /// Retorna información sobre si la caja de hoy está abierta, si hay cajas pendientes, etc.
  Future<Map<String, dynamic>> getCurrentStatus({int? cobradorId}) async {
    try {
      final query = <String, dynamic>{};
      if (cobradorId != null) query['cobrador_id'] = cobradorId;

      final response = await get(
        '/cash-balances/current-status',
        queryParameters: query.isEmpty ? null : query,
      );

      if (response.statusCode == 200) {
        final raw = response.data;
        if (raw is Map<String, dynamic>) return raw;
        throw ApiException(
          message: 'Formato inesperado en estado actual de caja',
          statusCode: response.statusCode,
          errorData: raw,
        );
      }

      throw ApiException(
        message: 'Error obteniendo estado actual de caja',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      String message = 'Error obteniendo estado actual de caja';
      if (data is Map<String, dynamic> && data['message'] != null)
        message = data['message'].toString();
      throw ApiException(
        message: message,
        statusCode: status,
        errorData: data,
        originalError: e,
      );
    } catch (e) {
      throw ApiException(
        message: 'Error obteniendo estado actual de caja: $e',
        originalError: e,
      );
    }
  }
}
