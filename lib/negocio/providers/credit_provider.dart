import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/api_exception.dart';
import '../../datos/servicios/credit_api_service.dart';
import '../../datos/servicios/payment_api_service.dart';
import '../../datos/servicios/websocket_service.dart';
import '../../datos/modelos/credito.dart';
import 'auth_provider.dart';
import 'websocket_provider.dart';
import 'pago_provider.dart';

// Estado del provider de créditos
class CreditState {
  final List<Credito> credits;
  final List<Credito> attentionCredits;
  final List<Credito> pendingApprovalCredits;
  final List<Credito> waitingDeliveryCredits;
  final List<Credito> readyForDeliveryCredits;
  final List<Credito> overdueDeliveryCredits;
  final CreditStats? stats;
  final WaitingListSummary? waitingListSummary;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final Map<String, dynamic> validationErrors; // Errores de validación

  CreditState({
    this.credits = const [],
    this.attentionCredits = const [],
    this.pendingApprovalCredits = const [],
    this.waitingDeliveryCredits = const [],
    this.readyForDeliveryCredits = const [],
    this.overdueDeliveryCredits = const [],
    this.stats,
    this.waitingListSummary,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.validationErrors = const {}, // Inicializar como vacío
  });

  CreditState copyWith({
    List<Credito>? credits,
    List<Credito>? attentionCredits,
    List<Credito>? pendingApprovalCredits,
    List<Credito>? waitingDeliveryCredits,
    List<Credito>? readyForDeliveryCredits,
    List<Credito>? overdueDeliveryCredits,
    CreditStats? stats,
    WaitingListSummary? waitingListSummary,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    Map<String, dynamic>? validationErrors, // Agregar parámetros de copia
  }) {
    return CreditState(
      credits: credits ?? this.credits,
      attentionCredits: attentionCredits ?? this.attentionCredits,
      pendingApprovalCredits:
          pendingApprovalCredits ?? this.pendingApprovalCredits,
      waitingDeliveryCredits:
          waitingDeliveryCredits ?? this.waitingDeliveryCredits,
      readyForDeliveryCredits:
          readyForDeliveryCredits ?? this.readyForDeliveryCredits,
      overdueDeliveryCredits:
          overdueDeliveryCredits ?? this.overdueDeliveryCredits,
      stats: stats ?? this.stats,
      waitingListSummary: waitingListSummary ?? this.waitingListSummary,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      validationErrors: validationErrors ?? this.validationErrors, // Copiar errores de validación
    );
  }
}

// Notifier para gestionar créditos
class CreditNotifier extends StateNotifier<CreditState> {
  final CreditApiService _creditApiService;
  final PaymentApiService _paymentApiService;
  final Ref _ref;

  CreditNotifier(this._creditApiService, this._paymentApiService, this._ref)
    : super(CreditState());

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

      final response = await _creditApiService.getCredits(
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
    double? totalAmount,
    double? installmentAmount}) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🔄 Iniciando proceso de creación de crédito...');

      // Asegurar regla de negocio: créditos diarios duran exactamente 24 días de pago (Lun-Sáb)
      DateTime normalizedEndDate = endDate;
      if (frequency == 'daily') {
        normalizedEndDate = _computeDailyEndDateFromStart(startDate);
      }

      final creditData = <String, dynamic>{
        'client_id': clientId,
        'amount': amount,
        'balance': balance,
        'frequency': frequency,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': normalizedEndDate.toIso8601String().split('T')[0],
        'status': 'pending_approval', // Estado inicial para lista de espera
      };

      if (interestRate != null && interestRate > 0) {
        creditData['interest_rate'] = interestRate;
      }

      if (totalAmount != null) {
        creditData['total_amount'] = totalAmount;
      }

      if (installmentAmount != null) {
        creditData['installment_amount'] = installmentAmount;
      }

      print('🚀 Enviando datos al servidor: $creditData');

      final response = await _creditApiService.createCredit(creditData);

      if (response['success'] == true) {
        final nuevoCredito = Credito.fromJson(response['data']);

        // Agregar el nuevo crédito a la lista
        final creditosActualizados = [nuevoCredito, ...state.credits];

        state = state.copyWith(
          credits: creditosActualizados,
          isLoading: false,
          successMessage: 'Crédito creado exitosamente',
        );

        // 🔔 NOTIFICAR AL MANAGER VÍA WEBSOCKET
        _notifyCreditCreated(nuevoCredito);

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
    double? totalAmount,
    double? installmentAmount,
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
      if (endDate != null) {
        var normalizedEnd = endDate;
        // Si es o seguirá siendo diario, forzar fin en 24 días de pago (Lun–Sáb) desde startDate disponible
        final freq = frequency ?? state.credits.firstWhere((c) => c.id == creditId, orElse: () => throw Exception('Crédito no encontrado')).frequency;
        final start = startDate ?? state.credits.firstWhere((c) => c.id == creditId, orElse: () => throw Exception('Crédito no encontrado')).startDate;
        if (freq == 'daily') {
          normalizedEnd = _computeDailyEndDateFromStart(start);
        }
        creditData['end_date'] = normalizedEnd.toIso8601String().split('T')[0];
      }
      if (totalAmount != null) creditData['total_amount'] = totalAmount;
      if (installmentAmount != null)
        creditData['installment_amount'] = installmentAmount;

      final response = await _creditApiService.updateCredit(
        creditId,
        creditData,
      );

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

      final response = await _creditApiService.deleteCredit(creditId);

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

      final response = await _creditApiService.getClientCredits(clientId);

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

      final response = await _creditApiService.getCobradorStats(
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

      final response = await _creditApiService.getCreditsRequiringAttention();

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

  /// Procesa un pago para un crédito (delegado al PagoProvider)
  Future<Map<String, dynamic>?> processPayment({
    required int creditId,
    required double amount,
    String paymentType = 'cash',
    String? notes,
  }) async {
    // Validar estado del crédito localmente
    final current = state.credits.firstWhere(
      (c) => c.id == creditId,
      orElse: () => Credito(
        id: creditId,
        clientId: 0,
        amount: 0,
        balance: 0,
        frequency: 'monthly',
        status: 'active',
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    if (current.status != 'active') {
      state = state.copyWith(
        errorMessage: 'Solo se pueden registrar pagos para créditos activos',
        successMessage: null,
      );
      return null;
    }

    // Delegar al PagoProvider
    final pagoNotifier = _ref.read(pagoProvider.notifier);
    final result = await pagoNotifier.processPaymentForCredit(
      creditId: creditId,
      amount: amount,
      paymentType: paymentType,
      notes: notes,
    );

    // Si hay información del crédito retornada, actualizar la lista local
    if (result != null && result['credit'] != null) {
      final creditoActualizado = Credito.fromJson(result['credit']);
      final creditosActualizados = state.credits.map((credito) {
        return credito.id == creditId ? creditoActualizado : credito;
      }).toList();
      state = state.copyWith(
        credits: creditosActualizados,
        isLoading: false,
        successMessage: 'Pago procesado exitosamente',
      );
    }

    return result;
  }

  /// Notifica la actualización de pago a través de WebSocket
  void _notifyPaymentUpdate(Map<String, dynamic> paymentResult, Credito credit) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        // Enviar notificación de pago realizado
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

        print('🔔 Notificación WebSocket enviada para pago');
      }
    } catch (e) {
      print('⚠️ Error enviando notificación WebSocket: $e');
      // No fallar el proceso de pago por error en notificación
    }
  }

  /// Simula un pago sin guardarlo (delegado al PagoProvider)
  Future<PaymentAnalysis?> simulatePayment({required int creditId, required double amount}) async {
    final result = await _ref
        .read(pagoProvider.notifier)
        .simulatePaymentForCredit(creditId: creditId, amount: amount);
    return result;
  }

  /// Obtiene un crédito por ID desde el backend (sin alterar el estado global)
  Future<Credito?> fetchCreditById(int creditId) async {
    try {
      print('🔍 [CreditNotifier] Fetching credit by ID: $creditId');
      // Intentar obtener detalles extendidos primero
      Map<String, dynamic> response;
      try {
        response = await _creditApiService.getCreditDetails(creditId);
      } catch (_) {
        // Si falla, intentar el endpoint básico
        response = await _creditApiService.getCredit(creditId);
      }

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        Map<String, dynamic>? creditJson;
        if (data is Map<String, dynamic>) {
          // Algunos backends envuelven en { credit: {...} } o directamente {...}
          if (data['credit'] is Map<String, dynamic>) {
            creditJson = Map<String, dynamic>.from(data['credit']);
          } else if (data['data'] is Map<String, dynamic>) {
            creditJson = Map<String, dynamic>.from(data['data']);
          } else {
            creditJson = Map<String, dynamic>.from(data);
          }
        }
        if (creditJson != null) {
          final credit = Credito.fromJson(creditJson);
          print('✅ [CreditNotifier] Crédito obtenido: ${credit.id}');
          return credit;
        }
      }

      // En algunos casos, el backend puede devolver el crédito en la raíz
      if (response is Map<String, dynamic>) {
        // Intentar encontrar un mapa que parezca un crédito
        final maybeCredit = response['credit'] ?? response['data'];
        if (maybeCredit is Map<String, dynamic>) {
          return Credito.fromJson(maybeCredit);
        }
      }

      print('⚠️ [CreditNotifier] No se pudo parsear el crédito con ID $creditId');
      return null;
    } catch (e) {
      print('❌ [CreditNotifier] Error al obtener crédito $creditId: $e');
      return null;
    }
  }

  /// Obtiene el cronograma de pagos de un crédito
  Future<List<PaymentSchedule>?> getPaymentSchedule(int creditId) async {
    // Primero intentar obtener del backend para reflejar pagos recientes
    try {
      print('🔄 Obteniendo cronograma de pagos desde backend para crédito: $creditId');
      final response = await _creditApiService.getCreditPaymentSchedule(creditId);
      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> scheduleData = [];

        // El backend puede devolver directamente una lista o un objeto con 'schedule'
        if (data is List) {
          scheduleData = data;
        } else if (data is Map<String, dynamic>) {
          final inner = data['schedule'];
          if (inner is List) {
            scheduleData = inner;
          } else if (inner is Map<String, dynamic>) {
            // En caso de un formato aún más anidado, intentar extraer 'data'
            final nested = inner['data'];
            if (nested is List) scheduleData = nested;
          }
        }

        final schedule = scheduleData
            .whereType<Map<String, dynamic>>()
            .map((item) => PaymentSchedule.fromJson(item))
            .toList();
        print('✅ Cronograma de ${schedule.length} cuotas obtenido del backend');
        return schedule;
      }
    } catch (apiError) {
      print('⚠️ No se pudo obtener cronograma desde backend: $apiError');
    }

    // Si backend falla, generar cronograma localmente
    try {
      print('🔁 Generando cronograma de pagos localmente para crédito: $creditId');
      // Buscar el crédito en el estado actual
      final credit = state.credits.firstWhere(
        (c) => c.id == creditId,
        orElse: () => throw Exception('Crédito no encontrado'),
      );
      final schedule = _generatePaymentSchedule(credit);
      print('✅ Cronograma de ${schedule.length} cuotas generado localmente');
      return schedule;
    } catch (e) {
      print('❌ Error al generar cronograma local: $e');
      state = state.copyWith(errorMessage: 'Error al obtener cronograma: $e');
      return null;
    }
  }

  /// Calcula la fecha de vencimiento final para créditos diarios (24 días de pago Lun–Sáb)
  DateTime _computeDailyEndDateFromStart(DateTime start) {
    int payments = 0;
    DateTime current = start;
    while (payments < 24) {
      current = current.add(const Duration(days: 1));
      if (current.weekday != DateTime.sunday) {
        payments++;
      }
    }
    return current;
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
        // 24 cuotas, pagos de lunes a sábado. Primer pago al día siguiente de la entrega.
        installments = 24;
        daysBetweenPayments = 1; // iteramos por días, pero saltaremos domingos abajo
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

    // Usar installmentAmount si está disponible, o calcular
    final installmentAmount =
        credit.installmentAmount ??
        (credit.amount * (1 + interestRate / 100)) / installments;

    // Generar cronograma
    DateTime currentDue = credit.startDate;
    int created = 0;
    while (created < installments) {
      currentDue = currentDue.add(Duration(days: daysBetweenPayments));
      if (credit.frequency == 'daily' && currentDue.weekday == DateTime.sunday) {
        // Saltar domingos
        continue;
      }
      final dueDate = currentDue;
      created++;

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
          installmentNumber: created,
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

      final response = await _creditApiService.getCreditDetails(creditId);

      if (response['success'] == true) {
        final data = response['data'];
        // Algunas APIs devuelven { data: { credit: { ... } } }
        final creditJson = (data is Map<String, dynamic> && data['credit'] != null)
            ? data['credit'] as Map<String, dynamic>
            : data as Map<String, dynamic>;
        var credito = Credito.fromJson(creditJson);

        // Merge de ubicación del cliente si viene separada en data.location_cliente
        if (data is Map<String, dynamic>) {
          final loc = data['location_cliente'];
          if (loc is Map<String, dynamic>) {
            final latStr = loc['latitude']?.toString();
            final lngStr = loc['longitude']?.toString();
            final lat = latStr != null ? double.tryParse(latStr) : null;
            final lng = lngStr != null ? double.tryParse(lngStr) : null;
            if (lat != null && lng != null && credito.client != null) {
              final updatedClient = credito.client!.copyWith(latitud: lat, longitud: lng);
              credito = credito.copyWith(client: updatedClient);
              print('📍 Ubicación del cliente fusionada desde location_cliente -> ($lat, $lng)');
            }
          }
        }

        print('✅ Detalles del crédito obtenidos');
        return credito;
      } else {
        throw Exception(response['message'] ?? 'Error al obtener detalles');
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

  // ========================================
  // MÉTODOS DE LISTA DE ESPERA
  // ========================================

  /// Carga créditos pendientes de aprobación
  Future<void> loadPendingApprovalCredits({int page = 1}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos pendientes de aprobación...');

      final response = await _creditApiService.getPendingApprovalCredits(
        page: page,
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> creditsData = [];

        // Manejar respuesta paginada o directa
        if (data is List) {
          // Respuesta directa como array
          creditsData = data;
        } else if (data is Map<String, dynamic>) {
          // Respuesta paginada
          creditsData = data['data'] as List? ?? [];
        }

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          pendingApprovalCredits: credits,
          isLoading: false,
        );

        print('✅ ${credits.length} créditos pendientes de aprobación cargados');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar créditos pendientes',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos pendientes de aprobación: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos pendientes: $e',
      );
    }
  }

  /// Carga créditos en lista de espera para entrega
  Future<void> loadWaitingDeliveryCredits({int page = 1}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos en lista de espera...');

      final response = await _creditApiService.getWaitingDeliveryCredits(
        page: page,
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> creditsData = [];

        // Manejar respuesta paginada o directa
        if (data is List) {
          // Respuesta directa como array
          creditsData = data;
        } else if (data is Map<String, dynamic>) {
          // Respuesta paginada
          creditsData = data['data'] as List? ?? [];
        }

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          waitingDeliveryCredits: credits,
          isLoading: false,
        );

        print('✅ ${credits.length} créditos en lista de espera cargados');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar créditos en espera',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos en lista de espera: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos en lista de espera: $e',
      );
    }
  }

  /// Carga créditos listos para entrega hoy
  Future<void> loadReadyForDeliveryCredits({int page = 1}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos listos para entrega hoy...');

      final response = await _creditApiService.getReadyForDeliveryToday(
        page: page,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final creditsData = data is List ? data : (data['data'] as List? ?? []);

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          readyForDeliveryCredits: credits,
          isLoading: false,
        );

        print('✅ ${credits.length} créditos listos para entrega hoy cargados');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar créditos listos',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos listos para entrega: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos listos para entrega: $e',
      );
    }
  }

  /// Carga créditos con entrega atrasada
  Future<void> loadOverdueDeliveryCredits({int page = 1}) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos con entrega atrasada...');

      final response = await _creditApiService.getOverdueDeliveryCredits(
        page: page,
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> creditsData = [];

        // Manejar respuesta paginada o directa
        if (data is List) {
          // Respuesta directa como array
          creditsData = data;
        } else if (data is Map<String, dynamic>) {
          // Respuesta paginada
          creditsData = data['data'] as List? ?? [];
        }

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          overdueDeliveryCredits: credits,
          isLoading: false,
        );

        print('✅ ${credits.length} créditos con entrega atrasada cargados');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar créditos atrasados',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos con entrega atrasada: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos con entrega atrasada: $e',
      );
    }
  }

  /// Carga resumen de lista de espera
  Future<void> loadWaitingListSummary() async {
    try {
      print('🔄 Cargando resumen de lista de espera...');

      final response = await _creditApiService.getWaitingListSummary();

      if (response['success'] == true) {
        final summaryData = response['data'];
        final summary = WaitingListSummary.fromJson(summaryData);

        state = state.copyWith(waitingListSummary: summary);

        print('✅ Resumen de lista de espera cargado');
      } else {
        throw Exception(response['message'] ?? 'Error al cargar resumen');
      }
    } catch (e) {
      print('❌ Error al cargar resumen de lista de espera: $e');
      state = state.copyWith(
        errorMessage: 'Error al cargar resumen de lista de espera: $e',
      );
    }
  }

  /// Aprueba un crédito para entrega
  Future<bool> approveCreditForDelivery({
    required int creditId,
    required DateTime scheduledDeliveryDate,
    String? notes,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
        validationErrors: {}, // Limpiar errores de validación anteriores
      );
      print('✅ Aprobando crédito para entrega: $creditId');

      final response = await _creditApiService.approveCreditForDelivery(
        creditId: creditId.toString(),
        scheduledDeliveryDate: scheduledDeliveryDate,
        notes: notes,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        // Actualizar el crédito en todas las listas
        _updateCreditInAllLists(creditoActualizado);

        // 🔔 Notificar por WebSocket la aprobación para entrega
        _notifyCreditApproved(creditoActualizado);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Crédito aprobado para entrega exitosamente',
        );

        return true;
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No se pudo aprobar el crédito',
      );
      return false;
    } on ApiException catch (e) {
      print('❌ ApiException: ${e.message}');

      // Capturar errores de validación específicamente
      Map<String, dynamic> validationErrors = {};
      if (e.hasValidationErrors) {
        validationErrors = e.validationErrors;
        print('❌ Errores de validación: $validationErrors');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        validationErrors: validationErrors, // Almacenar errores de validación
      );
      return false;
    } catch (e) {
      print('❌ Error general al aprobar crédito: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al aprobar crédito para entrega: $e',
      );
      return false;
    }
  }

  /// Rechaza un crédito
  Future<bool> rejectCredit({
    required int creditId,
    required String reason,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('❌ Rechazando crédito: $creditId');

      final response = await _creditApiService.rejectCredit(
        creditId,
        reason: reason,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        // Actualizar el crédito en todas las listas
        _updateCreditInAllLists(creditoActualizado);

        // 🔔 Notificar por WebSocket el rechazo del crédito
        _notifyCreditRejected(creditoActualizado, reason);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Crédito rechazado exitosamente',
        );

        print('✅ Crédito rechazado exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al rechazar crédito');
      }
    } catch (e) {
      print('❌ Error al rechazar crédito: $e');

      String errorMessage = 'Error al rechazar crédito';
      if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para rechazar créditos';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Entrega un crédito al cliente
  Future<bool> deliverCreditToClient({
    required int creditId,
    String? notes,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🚚 Entregando crédito al cliente: $creditId');

      final response = await _creditApiService.deliverCreditToClient(
        creditId,
        notes: notes,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        // Actualizar el crédito en todas las listas
        _updateCreditInAllLists(creditoActualizado);

        // 🔔 Notificar por WebSocket la entrega del crédito
        _notifyCreditDelivered(creditoActualizado, notes: notes);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Crédito entregado al cliente exitosamente',
        );

        print('✅ Crédito entregado al cliente exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al entregar crédito');
      }
    } catch (e) {
      print('❌ Error al entregar crédito: $e');

      String errorMessage = 'Error al entregar crédito';
      if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para entregar este crédito';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Aprueba y entrega el crédito inmediatamente (flujo combinado)
  Future<bool> approveAndDeliverCredit({
    required int creditId,
    required DateTime scheduledDeliveryDate,
    String? approvalNotes,
    String? deliveryNotes,
  }) async {
    try {
      // Limpiar mensajes previos
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
        validationErrors: {},
      );

      // 1) Aprobar para entrega
      final approved = await approveCreditForDelivery(
        creditId: creditId,
        scheduledDeliveryDate: scheduledDeliveryDate,
        notes: approvalNotes,
      );

      if (!approved) {
        // approveCreditForDelivery ya gestionó errores/validaciones
        return false;
      }

      // 2) Entregar inmediatamente
      final delivered = await deliverCreditToClient(
        creditId: creditId,
        notes: deliveryNotes ?? 'Entrega inmediata tras aprobación',
      );

      if (!delivered) {
        // deliverCreditToClient ya gestionó errores
        return false;
      }

      // Asegurar mensaje de éxito coherente para el flujo combinado
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Crédito aprobado y entregado exitosamente',
      );
      return true;
    } on ApiException catch (e) {
      Map<String, dynamic> validationErrors = {};
      if (e.hasValidationErrors) {
        validationErrors = e.validationErrors;
      }
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        validationErrors: validationErrors,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al aprobar y entregar crédito: $e',
      );
      return false;
    }
  }

  /// Reprograma la fecha de entrega de un crédito
  Future<bool> rescheduleCreditDelivery({
    required int creditId,
    required DateTime newScheduledDate,
    String? reason,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('📅 Reprogramando entrega del crédito: $creditId');

      final response = await _creditApiService.rescheduleCreditDelivery(
        creditId,
        newScheduledDate: newScheduledDate,
        reason: reason,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        // Actualizar el crédito en todas las listas
        _updateCreditInAllLists(creditoActualizado);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Fecha de entrega reprogramada exitosamente',
        );

        print('✅ Fecha de entrega reprogramada exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al reprogramar entrega');
      }
    } catch (e) {
      print('❌ Error al reprogramar fecha de entrega: $e');

      String errorMessage = 'Error al reprogramar fecha de entrega';
      if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para reprogramar entregas';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Obtiene el estado de entrega de un crédito
  Future<DeliveryStatus?> getCreditDeliveryStatus(int creditId) async {
    try {
      print('📋 Obteniendo estado de entrega del crédito: $creditId');

      final response = await _creditApiService.getCreditDeliveryStatus(
        creditId,
      );

      if (response['success'] == true) {
        final statusData = response['data'];
        final deliveryStatus = DeliveryStatus.fromJson(statusData);

        print('✅ Estado de entrega obtenido');
        return deliveryStatus;
      } else {
        throw Exception(
          response['message'] ?? 'Error al obtener estado de entrega',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estado de entrega: $e');
      state = state.copyWith(
        errorMessage: 'Error al obtener estado de entrega: $e',
      );
      return null;
    }
  }

  /// Actualiza un crédito en todas las listas del estado
  void _updateCreditInAllLists(Credito creditoActualizado) {
    // Actualizar en la lista principal de créditos
    final creditosActualizados = state.credits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    // Actualizar en créditos pendientes de aprobación
    final pendingActualizados = state.pendingApprovalCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    // Actualizar en créditos en lista de espera
    final waitingActualizados = state.waitingDeliveryCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    // Actualizar en créditos listos para entrega
    final readyActualizados = state.readyForDeliveryCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    // Actualizar en créditos con entrega atrasada
    final overdueActualizados = state.overdueDeliveryCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    state = state.copyWith(
      credits: creditosActualizados,
      pendingApprovalCredits: pendingActualizados,
      waitingDeliveryCredits: waitingActualizados,
      readyForDeliveryCredits: readyActualizados,
      overdueDeliveryCredits: overdueActualizados,
    );
  }

  /// Carga todos los datos relacionados con lista de espera
  Future<void> loadAllWaitingListData() async {
    await Future.wait([
      loadPendingApprovalCredits(),
      loadWaitingDeliveryCredits(),
      loadReadyForDeliveryCredits(),
      loadOverdueDeliveryCredits(),
      loadWaitingListSummary(),
    ]);
  }

  /// Notifica la creación de un crédito a través de WebSocket
  void _notifyCreditCreated(Credito credit) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        final cobrador = authState.usuario!;

        // Obtener información del cliente
        final clientName = credit.client?.nombre ?? 'Cliente';

        // Preparar datos del crédito para la notificación
        final creditData = {
          'id': credit.id,
          'amount': credit.amount,
          'balance': credit.balance,
          'frequency': credit.frequency,
          'status': credit.status,
          'client_id': credit.clientId,
          'client_name': clientName,
          'start_date': credit.startDate.toIso8601String(),
          'end_date': credit.endDate.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
        };

        // Usar el WebSocketService directamente para enviar el evento de ciclo de vida
        final wsServiceInstance = WebSocketService();
        wsServiceInstance.sendCreditLifecycle(
          action: 'created',
          creditId: credit.id.toString(),
          credit: creditData,
          message: 'El cobrador ${cobrador.nombre} ha creado un crédito de ${credit.amount} Bs para $clientName que requiere aprobación',
        );

        // También enviar notificación usando el método existente del websocket_provider
        /*wsNotifier.notifyCreditCreated({
          'creditId': credit.id.toString(),
          'title': 'Nuevo Crédito Creado',
          'message': 'El cobrador ${cobrador.nombre} ha creado un crédito de ${credit.amount} Bs para $clientName',
          'credit': creditData,
          'cobrador': {
            'id': cobrador.id,
            'name': cobrador.nombre,
            'email': cobrador.email,
          },
          'action': 'created',
          'timestamp': DateTime.now().toIso8601String(),
        });*/

        print('🔔 Notificación WebSocket enviada para nuevo crédito ID: ${credit.id}');
        print('   - Cobrador: ${cobrador.nombre}');
        print('   - Cliente: $clientName');
        print('   - Monto: ${credit.amount} Bs');
      } else {
        print('⚠️ No se puede enviar notificación: usuario no autenticado');
      }
    } catch (e) {
      print('⚠️ Error enviando notificación WebSocket para crédito: $e');
      // No fallar el proceso de creación por error en notificación
    }
  }

  /// Notifica aprobación de crédito (manager -> cobrador)
  void _notifyCreditApproved(Credito credit) {
    try {
      final authState = _ref.read(authProvider);
      if (authState.usuario == null) return;
      final actor = authState.usuario!;

      final clientName = credit.client?.nombre ?? 'Cliente';
      final targetCobradorId = credit.cobrador?.id?.toString();

      final creditData = {
        'id': credit.id,
        'amount': credit.amount,
        'balance': credit.balance,
        'status': credit.status,
        'client_id': credit.clientId,
        'client_name': clientName,
        'scheduled_delivery_date': credit.scheduledDeliveryDate?.toIso8601String(),
      }..removeWhere((k, v) => v == null);

      final ws = WebSocketService();
      ws.sendCreditLifecycle(
        action: 'approved',
        creditId: credit.id.toString(),
        targetUserId: targetCobradorId, // avisar al cobrador si lo conocemos
        userType: 'cobrador',
        credit: creditData,
        message: 'Tu crédito #${credit.id} por ${credit.amount} Bs ha sido aprobado por ${actor.nombre}',
      );
    } catch (e) {
      print('⚠️ Error enviando notificación de aprobación: $e');
    }
  }

  /// Notifica rechazo de crédito (manager -> cobrador)
  void _notifyCreditRejected(Credito credit, String reason) {
    try {
      final authState = _ref.read(authProvider);
      if (authState.usuario == null) return;
      final actor = authState.usuario!;

      final clientName = credit.client?.nombre ?? 'Cliente';
      final targetCobradorId = credit.cobrador?.id?.toString();

      final creditData = {
        'id': credit.id,
        'amount': credit.amount,
        'balance': credit.balance,
        'status': credit.status,
        'client_id': credit.clientId,
        'client_name': clientName,
        'rejection_reason': reason,
      }..removeWhere((k, v) => v == null);

      final ws = WebSocketService();
      ws.sendCreditLifecycle(
        action: 'rejected',
        creditId: credit.id.toString(),
        targetUserId: targetCobradorId,
        userType: 'cobrador',
        credit: creditData,
        message: 'Tu crédito #${credit.id} por ${credit.amount} Bs fue rechazado por ${actor.nombre}. Motivo: $reason',
      );
    } catch (e) {
      print('⚠️ Error enviando notificación de rechazo: $e');
    }
  }

  /// Notifica entrega de crédito (cobrador -> managers)
  void _notifyCreditDelivered(Credito credit, {String? notes}) {
    try {
      final authState = _ref.read(authProvider);
      if (authState.usuario == null) return;
      final actor = authState.usuario!;

      final clientName = credit.client?.nombre ?? 'Cliente';

      final creditData = {
        'id': credit.id,
        'amount': credit.amount,
        'balance': credit.balance,
        'status': credit.status,
        'client_id': credit.clientId,
        'client_name': clientName,
        if (notes != null && notes.isNotEmpty) 'delivery_notes': notes,
      }..removeWhere((k, v) => v == null);

      final ws = WebSocketService();
      ws.sendCreditLifecycle(
        action: 'delivered',
        creditId: credit.id.toString(),
        credit: creditData,
        message: 'El cobrador ${actor.nombre} entregó el crédito #${credit.id} de ${credit.amount} Bs al cliente $clientName',
      );
    } catch (e) {
      print('⚠️ Error enviando notificación de entrega: $e');
    }
  }
}

// Provider para el notifier de créditos
final creditProvider = StateNotifierProvider<CreditNotifier, CreditState>((
  ref,
) {
  final creditApiService = CreditApiService();
  final paymentApiService = PaymentApiService();
  return CreditNotifier(creditApiService, paymentApiService, ref);
});
