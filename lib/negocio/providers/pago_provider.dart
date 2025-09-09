import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/servicios/payment_api_service.dart';
import '../../datos/modelos/api_exception.dart';
import '../../datos/servicios/credit_api_service.dart';
import '../../datos/servicios/websocket_service.dart';
import '../../datos/modelos/credito.dart';
import 'auth_provider.dart';
import 'websocket_provider.dart';

class PagoState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Map<String, dynamic> validationErrors;

  const PagoState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.validationErrors = const {},
  });

  PagoState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    Map<String, dynamic>? validationErrors,
  }) {
    return PagoState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

class PagoNotifier extends StateNotifier<PagoState> {
  final PaymentApiService _paymentApiService;
  final CreditApiService _creditApiService;
  final Ref _ref;

  PagoNotifier(this._paymentApiService, this._creditApiService, this._ref)
      : super(const PagoState());

  /// Procesa un pago para un crédito y devuelve el resultado del backend
  Future<Map<String, dynamic>?> processPaymentForCredit({
    required int creditId,
    required double amount,
    String paymentType = 'cash',
    String? notes,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Validaciones previas requeridas por backend
      if (amount <= 0.01) {
        state = state.copyWith(
          errorMessage: 'El monto debe ser mayor a 0.01',
          successMessage: null,
        );
        return null;
      }

      // Normalizar y validar método de pago permitido
      final allowed = {'cash', 'transfer', 'check', 'other'};
      String method = paymentType.toLowerCase();
      if (!allowed.contains(method)) {
        method = 'cash';
      }

      // Intentar obtener client_id si es posible (ayuda a algunos endpoints)
      int? clientId;
      Credito? creditoDetalles;
      try {
        final detailsResp = await _creditApiService.getCreditDetails(creditId);
        if (detailsResp['success'] == true) {
          final credito = Credito.fromJson(detailsResp['data']);
          creditoDetalles = credito;
          clientId = credito.clientId;
        }
      } catch (e) {
        // Continuar sin clientId si falla
        // ignore: avoid_print
        print('⚠️ No se pudo obtener client_id para el crédito $creditId: $e');
      }

      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
        validationErrors: {},
      );
      // ignore: avoid_print
      print('🔄 Procesando pago (PagoProvider) para crédito: $creditId');
      if (latitude != null && longitude != null) {
        print('📍 Ubicación del pago: $latitude, $longitude');
      }

      // Fecha en formato YYYY-MM-DD
      final String paymentDate = DateTime.now().toIso8601String().split('T')[0];

      // Calcular installment_number (número de la última cuota cubierta por este pago)
      int installmentNumber = 1;
      try {
        if (creditoDetalles != null) {
          final totalInstallments = creditoDetalles.totalInstallments;
          final paidInstallments = creditoDetalles.paidInstallments;
          final perInstallment = (creditoDetalles.installmentAmount ??
                  ((creditoDetalles.totalAmount ?? creditoDetalles.amount) /
                      (totalInstallments == 0 ? 1 : totalInstallments)));
          int installmentsCovered = 0;
          if (perInstallment > 0) {
            installmentsCovered = (amount / perInstallment).floor();
          }
          // Siempre al menos la próxima cuota (para pagos parciales)
          final last = paidInstallments + (installmentsCovered > 0 ? installmentsCovered : 1);
          installmentNumber = last > totalInstallments ? totalInstallments : (last <= 0 ? 1 : last);
        }
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ No se pudo calcular installment_number: $e');
        installmentNumber = 1;
      }

      final paymentData = <String, dynamic>{
        'credit_id': creditId,
        'amount': amount,
        'payment_method': method,
        'payment_date': paymentDate,
        'installment_number': installmentNumber,
      };

      // Agregar datos opcionales
      if (notes != null && notes.isNotEmpty) paymentData['notes'] = notes;
      if (clientId != null) paymentData['client_id'] = clientId;

      // Agregar ubicación si está disponible
      if (latitude != null && longitude != null) {
        paymentData['latitude'] = latitude;
        paymentData['longitude'] = longitude;
        print('✅ Ubicación agregada al pago: $latitude, $longitude');
      }

      final response = await _paymentApiService.createPaymentForCredit(
        creditId,
        paymentData,
      );

      if (response['success'] == true) {
        final result = response['data'] as Map<String, dynamic>;

        // Intentar enviar notificación por WebSocket (no bloqueante)
        try {
          final creditJson = result['credit'];
          if (creditJson != null) {
            final credit = Credito.fromJson(creditJson);
            _notifyPaymentUpdate(result, credit);
          }
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ Error enviando notificación WebSocket: $e');
        }

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Pago procesado exitosamente',
        );

        return result;
      } else {
        final errorMessage = response['message'] ?? 'Error desconocido al procesar el pago';
        state = state.copyWith(
          isLoading: false,
          errorMessage: errorMessage,
        );
        return response;
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error procesando pago: $e');

      String errorMessage = 'Error al procesar el pago';
      if (e.toString().contains('422')) {
        errorMessage = 'Datos del pago inválidos';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      } else if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para procesar este pago';
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
      );

      return null;
    }
  }

  void _notifyPaymentUpdate(Map<String, dynamic> paymentResult, Credito credit) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        // Estructura plana requerida por notifyPaymentMade
        final paymentId = paymentResult['payment']?['id']?.toString() ?? paymentResult['id']?.toString();
        final montoDyn = paymentResult['payment']?['amount'] ?? paymentResult['amount'];
        final double amount = montoDyn is num ? montoDyn.toDouble() : double.tryParse(montoDyn?.toString() ?? '') ?? 0.0;
        final cobradorId = authState.usuario!.id.toString();
        final clientId = (credit.clientId ?? paymentResult['client_id'])?.toString();
        // Manager asignado para notificar (cuando el pago es exitoso)
        final managerId = authState.usuario!.assignedManagerId?.toString();

        wsNotifier.notifyPaymentMade({
          'paymentId': paymentId,
          'amount': amount,
          'cobradorId': cobradorId,
          'clientId': clientId,
          'status': paymentResult['payment']?['status'] ?? 'completed',
          'notes': paymentResult['payment']?['notes'],
          // Destinatario preferente de la notificación (manager)
          if (managerId != null) 'targetUserId': managerId,
          'userType': 'cobrador',
          // Mantener datos adicionales para futuros usos/debug
          'payment': paymentResult['payment'] ?? paymentResult,
          'credit': {
            'id': credit.id,
            'client_name': credit.client?.nombre ?? 'Cliente',
            'balance': credit.balance,
          },
          'action': 'payment_made',
          'message': 'Pago registrado por el cobrador',
          'timestamp': DateTime.now().toIso8601String(),
        });
        // ignore: avoid_print
        print('🔔 Notificación WebSocket enviada para pago (PagoProvider)');
      }
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ Error enviando notificación WebSocket (PagoProvider): $e');
    }
  }
}

final pagoProvider = StateNotifierProvider<PagoNotifier, PagoState>((ref) {
  final paymentApiService = PaymentApiService();
  final creditApiService = CreditApiService();
  return PagoNotifier(paymentApiService, creditApiService, ref);
});
