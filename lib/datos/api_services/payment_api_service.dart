import 'package:flutter/foundation.dart';
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
    debugPrint('💰 Creando pago para crédito: $creditId');
    debugPrint('📋 Datos a enviar: $paymentData');

    final response = await post(
      '/payments',
      data: paymentData,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final raw = response.data;
      if (raw is Map<String, dynamic>) {
        debugPrint('✅ Pago para crédito creado exitosamente');
        debugPrint('📥 Response Data: $raw');
        return raw;
      } else {
        // Respuesta inesperada del backend
        debugPrint('❌ Formato de respuesta inesperado: ${raw.runtimeType}');
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

  /// Obtiene la URL del recibo de un pago para impresión térmica
  /// [format] puede ser 'html' o 'pdf'
  String getReceiptUrl(int paymentId, {String format = 'html'}) {
    return '${BaseApiService.baseUrl}/payments/$paymentId/receipt?format=$format';
  }

  /// Descarga el recibo de un pago en formato HTML
  Future<String> getReceiptHtml(int paymentId) async {
    debugPrint('🧾 Obteniendo recibo HTML para pago: $paymentId');

    final response = await get(
      '/payments/$paymentId/receipt?format=html',
    );

    if (response.statusCode == 200) {
      debugPrint('✅ Recibo HTML obtenido exitosamente');
      return response.data.toString();
    } else {
      throw ApiException(
        message: 'Error al obtener recibo',
        statusCode: response.statusCode,
        errorData: response.data,
      );
    }
  }

  /// Obtiene la URL pública del recibo para compartir con clientes
  /// Esta URL no requiere autenticación
  Future<String?> getPublicReceiptUrl(int paymentId) async {
    debugPrint('🔗 Obteniendo URL pública para pago: $paymentId');

    final response = await get(
      '/payments/$paymentId/receipt-url',
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        final receiptUrl = data['data']['receipt_url'] as String?;
        debugPrint('✅ URL pública obtenida: $receiptUrl');
        return receiptUrl;
      }
    }
    return null;
  }
}
