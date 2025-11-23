import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/api_services/payment_api_service.dart';
import '../../datos/api_services/credit_api_service.dart';
import '../../datos/api_services/cash_balance_api_service.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/modelos/api_exception.dart';
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
  final CashBalanceApiService _cashBalanceApiService;
  final Ref _ref;

  PagoNotifier(
    this._paymentApiService,
    this._creditApiService,
    this._cashBalanceApiService,
    this._ref,
  ) : super(const PagoState());

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
      try {
        final detailsResp = await _creditApiService.getCreditDetails(creditId);
        if (detailsResp['success'] == true) {
          final credito = Credito.fromJson(detailsResp['data']);
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

      // NOTA: Ya NO enviamos installment_number al backend
      // El backend automáticamente encuentra la primera cuota incompleta y distribuye
      // el pago secuencialmente, completando cuotas parciales antes de avanzar.
      // Esto evita el problema de saltar cuotas incompletas.

      final paymentData = <String, dynamic>{
        'credit_id': creditId,
        'amount': amount,
        'payment_method': method,
        'payment_date': paymentDate,
        // 'installment_number': NO SE ENVÍA - el backend lo calcula automáticamente
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

      // Asegurar que exista una caja abierta para el cobrador y la fecha del pago
      try {
        final authState = _ref.read(authProvider);
        final isCobrador = authState.usuario?.esCobrador() ?? false;
        if (isCobrador) {
          final cobradorId = authState.usuario!.id;
          print(
            '🔍 Usuario es cobrador (id=$cobradorId). Intentando abrir/asegurar caja para $paymentDate',
          );
          try {
            final openResp = await _cashBalanceApiService.openCashBalance(
              cobradorId: cobradorId.toInt(),
              date: paymentDate,
            );
            print('🔓 openCashBalance response: $openResp');

            if (openResp['success'] == false) {
              final msg = openResp['message'] ?? 'No se pudo abrir la caja';
              state = state.copyWith(isLoading: false, errorMessage: msg);
              return {'success': false, 'message': msg};
            }

            // Verificar si la caja abierta tiene cajas pendientes (advertencia)
            final data = openResp['data'];
            if (data != null && data['has_pending_previous_boxes'] == true) {
              final pendingBoxes = data['pending_boxes_info'];
              print('⚠️ Caja abierta con cajas pendientes: $pendingBoxes');
              // Nota: Continuamos con el pago pero podrías mostrar una advertencia en la UI
            }
          } catch (e) {
            print('❌ Error abriendo caja: $e');
            state = state.copyWith(
              isLoading: false,
              errorMessage: 'No se pudo abrir la caja: ${e.toString()}',
            );
            return {
              'success': false,
              'message': 'No se pudo abrir la caja: ${e.toString()}',
            };
          }
        }
      } catch (e) {
        print('⚠️ Error verificando rol antes de abrir caja: $e');
        // No bloquear el pago si la verificación falla inesperadamente
      }

      final response = await _paymentApiService.createPaymentForCredit(
        creditId,
        paymentData,
      );

      if (response['success'] == true) {
        // `data` puede venir como Map o List (p. ej. [] cuando no hay payload)
        final dynamic rawData = response['data'];
        Map<String, dynamic> result;
        if (rawData is Map<String, dynamic>) {
          result = rawData;
        } else if (rawData is List) {
          // Si viene una lista vacía, no hay detalle del pago en `data`.
          // Intentar extraer información de otros campos de la respuesta.
          if (rawData.isEmpty) {
            print(
              '⚠️ `data` es una lista vacía. Buscando información alternativa en la respuesta',
            );
            // Si la respuesta incluye el objeto de pago en la raíz, usarla.
            final fallback = response['payment'] ?? response['data'];
            if (fallback is Map<String, dynamic>) {
              result = fallback;
            } else {
              // No hay datos detallados; usar map vacío para no romper el flujo.
              result = <String, dynamic>{};
            }
          } else if (rawData.first is Map<String, dynamic>) {
            // Si la lista contiene objetos, tomar el primero como resultado.
            result = Map<String, dynamic>.from(rawData.first as Map);
          } else {
            result = <String, dynamic>{};
          }
        } else {
          // Tipo inesperado, crear map vacío para continuar de forma segura
          print(
            '⚠️ Tipo inesperado en response["data"]: ${rawData.runtimeType}',
          );
          result = <String, dynamic>{};
        }

        // Intentar enviar notificación por WebSocket (no bloqueante)
        try {
          final creditJson = result['credit'] ?? response['credit'];
          if (creditJson != null && creditJson is Map<String, dynamic>) {
            final credit = Credito.fromJson(creditJson);
            _notifyPaymentUpdate(result, credit);
          } else if (creditJson != null) {
            // Si creditJson no es Map, intentar construir desde dynamic
            try {
              final creditMap = Map<String, dynamic>.from(creditJson);
              final credit = Credito.fromJson(creditMap);
              _notifyPaymentUpdate(result, credit);
            } catch (_) {
              print(
                '⚠️ creditJson no pudo convertirse a Map: ${creditJson.runtimeType}',
              );
            }
          }
        } catch (e) {
          print('⚠️ Error enviando notificación WebSocket: $e');
        }

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Pago procesado exitosamente',
        );

        // Devolver la respuesta completa del backend para que los callers
        // puedan acceder a `success`, `message` y `data`.
        return response;
      } else {
        final errorMessage =
            response['message'] ?? 'Error desconocido al procesar el pago';
        state = state.copyWith(isLoading: false, errorMessage: errorMessage);
        return response;
      }
    } on ApiException catch (e) {
      // ignore: avoid_print
      print('❌ Error procesando pago (ApiException): ${e.message}');

      // El mensaje ya viene procesado desde BaseApiService, solo lo usamos
      state = state.copyWith(isLoading: false, errorMessage: e.message);

      return null;
    } catch (e) {
      // ignore: avoid_print
      print('❌ Error procesando pago: $e');

      // Error inesperado no relacionado con el API
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error inesperado al procesar el pago',
      );

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
        // Estructura plana requerida por notifyPaymentMade
        final paymentId =
            paymentResult['payment']?['id']?.toString() ??
            paymentResult['id']?.toString();
        final montoDyn =
            paymentResult['payment']?['amount'] ?? paymentResult['amount'];
        final double amount = montoDyn is num
            ? montoDyn.toDouble()
            : double.tryParse(montoDyn?.toString() ?? '') ?? 0.0;
        final cobradorId = authState.usuario!.id.toString();
        final clientId = credit.clientId.toString();
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
  final cashBalanceApiService = CashBalanceApiService();
  return PagoNotifier(
    paymentApiService,
    creditApiService,
    cashBalanceApiService,
    ref,
  );
});
