import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/servicios/api_service.dart';
import '../../datos/modelos/credito.dart';
import 'auth_provider.dart';

// Estado del provider de créditos
class CreditState {
  final List<Credito> credits;
  final List<Credito> attentionCredits;
  final CreditStats? stats;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final int currentPage;
  final int totalPages;
  final int totalItems;

  CreditState({
    this.credits = const [],
    this.attentionCredits = const [],
    this.stats,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
  });

  CreditState copyWith({
    List<Credito>? credits,
    List<Credito>? attentionCredits,
    CreditStats? stats,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    int? currentPage,
    int? totalPages,
    int? totalItems,
  }) {
    return CreditState(
      credits: credits ?? this.credits,
      attentionCredits: attentionCredits ?? this.attentionCredits,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

// Notifier para gestionar créditos
class CreditNotifier extends StateNotifier<CreditState> {
  final ApiService _apiService;
  final Ref _ref;

  CreditNotifier(this._apiService, this._ref) : super(CreditState());

  // ========================================
  // MÉTODOS PÚBLICOS
  // ========================================

  /// Obtiene todos los créditos
  Future<void> loadCredits({
    int? clientId,
    int? cobradorId,
    String? status,
    String? search,
    int page = 1,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos...');

      final response = await _apiService.getCredits(
        clientId: clientId,
        cobradorId: cobradorId,
        status: status,
        search: search,
        page: page,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final creditsData = data['data'] as List? ?? [];

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          credits: credits,
          isLoading: false,
          currentPage: data['current_page'] ?? 1,
          totalPages: data['last_page'] ?? 1,
          totalItems: data['total'] ?? 0,
        );

        print('✅ ${credits.length} créditos cargados exitosamente');
      } else {
        throw Exception(response['message'] ?? 'Error al cargar créditos');
      }
    } catch (e) {
      print('❌ Error al cargar créditos: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos: $e',
      );
    }
  }

  /// Crea un nuevo crédito
  Future<bool> createCredit({
    required int clientId,
    required double amount,
    required double balance,
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
    double? interestRate,
    String? notes,
    double? paymentAmount,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🔄 Iniciando proceso de creación de crédito...');

      final creditData = <String, dynamic>{
        'client_id': clientId,
        'amount': amount,
        'balance': balance,
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'status': 'active',
      };

      if (interestRate != null && interestRate > 0) {
        creditData['interest_rate'] = interestRate;
      }

      if (notes != null && notes.isNotEmpty) {
        creditData['notes'] = notes;
      }

      if (paymentAmount != null) {
        creditData['payment_amount'] = paymentAmount;
      }

      print('🚀 Enviando datos al servidor: $creditData');

      final response = await _apiService.createCredit(creditData);

      if (response['success'] == true) {
        final nuevoCredito = Credito.fromJson(response['data']);

        // Agregar el nuevo crédito a la lista
        final creditosActualizados = [nuevoCredito, ...state.credits];

        state = state.copyWith(
          credits: creditosActualizados,
          isLoading: false,
          successMessage: 'Crédito creado exitosamente',
        );

        print('✅ Crédito creado exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al crear crédito');
      }
    } catch (e) {
      print('❌ Error al crear crédito: $e');

      String errorMessage = 'Error al crear crédito';
      if (e.toString().contains('422')) {
        errorMessage = 'Datos de entrada inválidos';
      } else if (e.toString().contains('403')) {
        errorMessage =
            'No tienes permisos para crear créditos para este cliente';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Actualiza un crédito existente
  Future<bool> updateCredit({
    required int creditId,
    int? clientId,
    double? amount,
    double? balance,
    double? interestRate,
    String? frequency,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? notes,
    double? paymentAmount,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🔄 Actualizando crédito: $creditId');

      final creditData = <String, dynamic>{};

      if (clientId != null) creditData['client_id'] = clientId;
      if (amount != null) creditData['amount'] = amount;
      if (balance != null) creditData['balance'] = balance;
      if (interestRate != null) creditData['interest_rate'] = interestRate;
      if (frequency != null) creditData['frequency'] = frequency;
      if (status != null) creditData['status'] = status;
      if (startDate != null)
        creditData['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null)
        creditData['end_date'] = endDate.toIso8601String().split('T')[0];
      if (notes != null) creditData['notes'] = notes;
      if (paymentAmount != null) creditData['payment_amount'] = paymentAmount;

      final response = await _apiService.updateCredit(creditId, creditData);

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']);

        // Actualizar el crédito en la lista
        final creditosActualizados = state.credits.map((credito) {
          return credito.id == creditId ? creditoActualizado : credito;
        }).toList();

        state = state.copyWith(
          credits: creditosActualizados,
          isLoading: false,
          successMessage: 'Crédito actualizado exitosamente',
        );

        print('✅ Crédito actualizado exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al actualizar crédito');
      }
    } catch (e) {
      print('❌ Error al actualizar crédito: $e');

      String errorMessage = 'Error al actualizar crédito';
      if (e.toString().contains('422')) {
        errorMessage = 'Datos de entrada inválidos';
      } else if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para actualizar este crédito';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Elimina un crédito
  Future<bool> deleteCredit(int creditId) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🗑️ Eliminando crédito: $creditId');

      final response = await _apiService.deleteCredit(creditId);

      if (response['success'] == true) {
        // Remover el crédito de la lista
        final creditosActualizados = state.credits
            .where((credito) => credito.id != creditId)
            .toList();

        state = state.copyWith(
          credits: creditosActualizados,
          isLoading: false,
          successMessage: 'Crédito eliminado exitosamente',
        );

        print('✅ Crédito eliminado exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al eliminar crédito');
      }
    } catch (e) {
      print('❌ Error al eliminar crédito: $e');

      String errorMessage = 'Error al eliminar crédito';
      if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para eliminar este crédito';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Obtiene créditos de un cliente específico
  Future<void> loadClientCredits(int clientId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos del cliente: $clientId');

      final response = await _apiService.getClientCredits(clientId);

      if (response['success'] == true) {
        final data = response['data'];
        final creditsData = data['data'] as List? ?? [];

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          credits: credits,
          isLoading: false,
          currentPage: data['current_page'] ?? 1,
          totalPages: data['last_page'] ?? 1,
          totalItems: data['total'] ?? 0,
        );

        print('✅ ${credits.length} créditos del cliente cargados exitosamente');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar créditos del cliente',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos del cliente: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos del cliente: $e',
      );
    }
  }

  /// Carga estadísticas del cobrador actual
  Future<void> loadCobradorStats() async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.usuario == null) return;

      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando estadísticas del cobrador...');

      final response = await _apiService.getCobradorStats(
        authState.usuario!.id.toInt(),
      );

      if (response['success'] == true) {
        final stats = CreditStats.fromJson(response['data']);

        state = state.copyWith(stats: stats, isLoading: false);

        print('✅ Estadísticas del cobrador cargadas exitosamente');
      } else {
        throw Exception(response['message'] ?? 'Error al cargar estadísticas');
      }
    } catch (e) {
      print('❌ Error al cargar estadísticas: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar estadísticas: $e',
      );
    }
  }

  /// Carga créditos que requieren atención
  Future<void> loadCreditsRequiringAttention() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos que requieren atención...');

      final response = await _apiService.getCreditsRequiringAttention();

      if (response['success'] == true) {
        final data = response['data'];
        final creditsData = data['data'] as List? ?? [];

        final attentionCredits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          attentionCredits: attentionCredits,
          isLoading: false,
        );

        print(
          '✅ ${attentionCredits.length} créditos que requieren atención cargados',
        );
      } else {
        throw Exception(
          response['message'] ??
              'Error al cargar créditos que requieren atención',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos que requieren atención: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos que requieren atención: $e',
      );
    }
  }

  /// Procesa un pago para un crédito
  Future<Map<String, dynamic>?> processPayment({
    required int creditId,
    required double amount,
    String paymentType = 'cash',
    String? notes,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🔄 Procesando pago para crédito: $creditId');

      final paymentData = <String, dynamic>{
        'amount': amount,
        'payment_type': paymentType,
      };

      if (notes != null && notes.isNotEmpty) {
        paymentData['notes'] = notes;
      }

      final response = await _apiService.post(
        '/credits/$creditId/payments',
        data: paymentData,
      );

      if (response.data['success'] == true) {
        final result = response.data['data'];

        // Actualizar el crédito en la lista si está disponible la información
        if (result['credit'] != null) {
          final creditoActualizado = Credito.fromJson(result['credit']);
          final creditosActualizados = state.credits.map((credito) {
            return credito.id == creditId ? creditoActualizado : credito;
          }).toList();

          state = state.copyWith(
            credits: creditosActualizados,
            isLoading: false,
            successMessage: 'Pago procesado exitosamente',
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            successMessage: 'Pago procesado exitosamente',
          );
        }

        print('✅ Pago procesado exitosamente');
        return result;
      } else {
        throw Exception(response.data['message'] ?? 'Error al procesar pago');
      }
    } catch (e) {
      print('❌ Error al procesar pago: $e');

      String errorMessage = 'Error al procesar pago';
      if (e.toString().contains('422')) {
        errorMessage = 'Datos de pago inválidos';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return null;
    }
  }

  /// Simula un pago sin guardarlo
  Future<PaymentAnalysis?> simulatePayment({
    required int creditId,
    required double amount,
  }) async {
    try {
      print('🔄 Simulando pago para crédito: $creditId');

      final response = await _apiService.post(
        '/credits/$creditId/simulate-payment',
        data: {'amount': amount},
      );

      if (response.data['success'] == true) {
        final analysisData = response.data['data'];
        print('✅ Simulación de pago completada');
        return PaymentAnalysis.fromJson(analysisData);
      } else {
        throw Exception(response.data['message'] ?? 'Error al simular pago');
      }
    } catch (e) {
      print('❌ Error al simular pago: $e');
      state = state.copyWith(errorMessage: 'Error al simular pago: $e');
      return null;
    }
  }

  /// Obtiene el cronograma de pagos de un crédito
  Future<List<PaymentSchedule>?> getPaymentSchedule(int creditId) async {
    try {
      print('🔄 Generando cronograma de pagos para crédito: $creditId');

      // Buscar el crédito en el estado actual
      final credit = state.credits.firstWhere(
        (c) => c.id == creditId,
        orElse: () => throw Exception('Crédito no encontrado'),
      );

      // Generar cronograma localmente basado en los datos del crédito
      final schedule = _generatePaymentSchedule(credit);

      print('✅ Cronograma de ${schedule.length} cuotas generado localmente');
      return schedule;
    } catch (e) {
      print('❌ Error al generar cronograma: $e');

      // Si no podemos generar localmente, intentar obtener del backend como fallback
      try {
        final response = await _apiService.get(
          '/credits/$creditId/payment-schedule',
        );

        if (response.data['success'] == true) {
          final scheduleData = response.data['data'] as List;
          final schedule = scheduleData
              .map((item) => PaymentSchedule.fromJson(item))
              .toList();

          print(
            '✅ Cronograma de ${schedule.length} cuotas obtenido del backend',
          );
          return schedule;
        }
      } catch (apiError) {
        print(
          '🧹 Backend no disponible, usando generación local como fallback',
        );
      }

      state = state.copyWith(errorMessage: 'Error al obtener cronograma: $e');
      return null;
    }
  }

  /// Genera un cronograma de pagos local basado en los datos del crédito
  List<PaymentSchedule> _generatePaymentSchedule(Credito credit) {
    final schedule = <PaymentSchedule>[];

    // Calcular información base
    final totalDays = credit.endDate.difference(credit.startDate).inDays;
    final interestRate = credit.interestRate ?? 20.0; // Usar 20% por defecto

    int installments;
    int daysBetweenPayments;

    // Determinar número de cuotas y frecuencia basado en el tipo
    switch (credit.frequency) {
      case 'daily':
        installments = totalDays;
        daysBetweenPayments = 1;
        break;
      case 'weekly':
        installments = (totalDays / 7).ceil();
        daysBetweenPayments = 7;
        break;
      case 'biweekly':
        installments = (totalDays / 14).ceil();
        daysBetweenPayments = 14;
        break;
      case 'monthly':
        installments = (totalDays / 30).ceil();
        daysBetweenPayments = 30;
        break;
      default:
        installments = 24; // Valor por defecto
        daysBetweenPayments = (totalDays / installments).round();
    }

    // Usar paymentAmount si está disponible, o calcular
    final installmentAmount =
        credit.paymentAmount ??
        (credit.amount * (1 + interestRate / 100)) / installments;

    // Generar cronograma
    for (int i = 0; i < installments; i++) {
      final dueDate = credit.startDate.add(
        Duration(days: daysBetweenPayments * (i + 1)),
      );

      // Verificar si ya fue pagado comparando con pagos existentes
      final existingPayment =
          credit.payments?.where((p) {
            final paymentDate = p.paymentDate;
            final daysDiff = (paymentDate.difference(dueDate).inDays).abs();
            return daysDiff <=
                (daysBetweenPayments ~/
                    2); // Tolerancia de la mitad del período
          }).isNotEmpty ??
          false;

      // Determinar estado
      String status;
      if (existingPayment) {
        status = 'paid';
      } else if (dueDate.isBefore(DateTime.now())) {
        status = 'overdue';
      } else {
        status = 'pending';
      }

      schedule.add(
        PaymentSchedule(
          installmentNumber: i + 1,
          dueDate: dueDate,
          amount: installmentAmount,
          status: status,
        ),
      );
    }

    return schedule;
  }

  /// Obtiene detalles completos de un crédito
  Future<Credito?> getCreditDetails(int creditId) async {
    try {
      print('🔄 Obteniendo detalles del crédito: $creditId');

      final response = await _apiService.get('/credits/$creditId/details');

      if (response.data['success'] == true) {
        final creditData = response.data['data'];
        final credito = Credito.fromJson(creditData);

        print('✅ Detalles del crédito obtenidos');
        return credito;
      } else {
        throw Exception(
          response.data['message'] ?? 'Error al obtener detalles',
        );
      }
    } catch (e) {
      print('❌ Error al obtener detalles del crédito: $e');
      state = state.copyWith(errorMessage: 'Error al obtener detalles: $e');
      return null;
    }
  }

  /// Limpia mensajes de error y éxito
  void clearMessages() {
    print('🧹 Limpiando mensajes de error y éxito...');
    state = state.copyWith(errorMessage: null, successMessage: null);
  }

  /// Limpia solo el mensaje de error
  void clearError() {
    print('🧹 Limpiando error...');
    state = state.copyWith(errorMessage: null);
  }

  /// Limpia solo el mensaje de éxito
  void clearSuccess() {
    print('🧹 Limpiando éxito...');
    state = state.copyWith(successMessage: null);
  }
}

// Provider para el notifier de créditos
final creditProvider = StateNotifierProvider<CreditNotifier, CreditState>((
  ref,
) {
  final apiService = ApiService();
  return CreditNotifier(apiService, ref);
});
