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
      if (notes != null && notes.isNotEmpty) paymentData['notes'] = notes;
      if (clientId != null) paymentData['client_id'] = clientId;

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
        // ignore: avoid_print
        print('✅ Pago procesado exitosamente (PagoProvider)');
        return result;
      } else {
        throw Exception(response['message'] ?? 'Error al procesar pago');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error al procesar pago (PagoProvider): $e');
      String errorMessage = 'Error al procesar pago';
      Map<String, dynamic> validation = const {};
      if (e is ApiException) {
        errorMessage = e.message;
        validation = e.validationErrors;
      } else {
        final errorText = e.toString();
        if (errorText.contains('422')) {
          errorMessage = 'Datos de pago inválidos';
        } else if (errorText.contains('404')) {
          errorMessage = 'Crédito no encontrado';
        }
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
        validationErrors: validation,
      );
      return null;
    }
  }

  /// Simula un pago sin efectuarlo
  Future<PaymentAnalysis?> simulatePaymentForCredit({
    required int creditId,
    required double amount,
  }) async {
    try {
      // ignore: avoid_print
      print('🔄 Simulando pago (PagoProvider) para crédito: $creditId');
      final response = await _paymentApiService.simulatePayment(creditId, amount);
      if (response['success'] == true) {
        final analysisData = response['data'];
        // ignore: avoid_print
        print('✅ Simulación de pago completada (PagoProvider)');
        return PaymentAnalysis.fromJson(analysisData);
      } else {
        throw Exception(response['message'] ?? 'Error al simular pago');
      }
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error al simular pago (PagoProvider): $e');
      state = state.copyWith(errorMessage: 'Error al simular pago: $e');
      return null;
    }
  }

  void _notifyPaymentUpdate(
    Map<String, dynamic> paymentResult,
    Credito credit,
  ) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        wsNotifier.notifyPaymentMade({
          'payment': {
            'id': paymentResult['payment']?['id'],
            'amount': paymentResult['payment']?['amount'],
            'notes': paymentResult['payment']?['notes'],
            'credit_id': credit.id,
            'cobrador_id': authState.usuario!.id,
            'client_id': credit.clientId,
            'client_name': credit.client?.nombre ?? 'Cliente',
          },
          'credit': {
            'id': credit.id,
            'client_name': credit.client?.nombre ?? 'Cliente',
            'balance': credit.balance,
          },
          'action': 'payment_made',
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
