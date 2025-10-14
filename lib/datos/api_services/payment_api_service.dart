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
        // El objeto `response` es una instancia de `Response` de Dio.
        // Los datos devueltos por el backend están en `response.data`.
        final raw = response.data;
        if (raw is Map<String, dynamic>) {
          print('✅ Pago para crédito creado exitosamente');
          print('📥 Response Data: $raw');
          return raw;
        } else {
          // Respuesta inesperada del backend
          print('❌ Formato de respuesta inesperado: ${raw.runtimeType}');
          throw ApiException(
            message:
                'Formato de respuesta inesperado al crear pago para crédito',
            statusCode: response.statusCode,
            errorData: raw,
          );
        }
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
        if (data['message'] != null)
          message = data['message'].toString();
        else if (data['error'] != null)
          message = data['error'].toString();
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
}
