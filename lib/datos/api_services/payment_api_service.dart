import 'base_api_service.dart';
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
    // La conversión de DioException a ApiException se maneja automáticamente en BaseApiService
    print('💰 Creando pago para crédito: $creditId');
    print('📋 Datos a enviar: $paymentData');

    final response = await post(
      '/payments',
      data: paymentData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        print('✅ Pago para crédito creado exitosamente');
        print('📥 Response Data: $raw');
        return raw;
      } else {
        // Respuesta inesperada del backend
        print('❌ Formato de respuesta inesperado: ${raw.runtimeType}');
        throw ApiException(
          message: 'Formato de respuesta inesperado al crear pago para crédito',
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
  }
}
