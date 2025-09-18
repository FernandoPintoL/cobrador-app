import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/api_exception.dart';
import '../../datos/servicios/credit_api_service.dart';
import '../../datos/modelos/credit_full_details.dart';
import '../../datos/modelos/credito.dart';
import 'auth_provider.dart';
import 'websocket_provider.dart';
import 'pago_provider.dart';
import '../utils/schedule_utils.dart';

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
  final bool isLoadingMore;
  final String? errorMessage;
  final String? successMessage;
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final Map<String, dynamic> validationErrors;

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
    this.isLoadingMore = false,
    this.errorMessage,
    this.successMessage,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.validationErrors = const {},
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
    bool? isLoadingMore,
    String? errorMessage,
    String? successMessage,
    int? currentPage,
    int? totalPages,
    int? totalItems,
    Map<String, dynamic>? validationErrors,
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
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage,
      successMessage: successMessage,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }
}

// Notifier para gestionar créditos
class CreditNotifier extends StateNotifier<CreditState> {
  final CreditApiService _creditApiService;
  final Ref _ref;

  CreditNotifier(this._creditApiService, this._ref) : super(CreditState());

  Map<String, dynamic>? _lastQuery;

  // ========================================
  // MÉTODOS PRINCIPALES
  // ========================================

  /// Obtiene todos los créditos
  Future<void> loadCredits({
    int? clientId,
    int? cobradorId,
    String? status,
    String? search,
    List<String>? frequencies,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    DateTime? endDateFrom,
    DateTime? endDateTo,
    double? amountMin,
    double? amountMax,
    double? totalAmountMin,
    double? totalAmountMax,
    double? balanceMin,
    double? balanceMax,
    bool? isOverdue, // Filtro para cuotas atrasadas
    double? overdueAmountMin, // Monto mínimo atrasado
    double? overdueAmountMax, // Monto máximo atrasado
    int page = 1,
    int? perPage,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos...');

      // Guardar últimos parámetros de consulta
      _lastQuery = {
        'clientId': clientId,
        'cobradorId': cobradorId,
        'status': status,
        'search': search,
        'frequencies': frequencies,
        'startDateFrom': startDateFrom,
        'startDateTo': startDateTo,
        'endDateFrom': endDateFrom,
        'endDateTo': endDateTo,
        'amountMin': amountMin,
        'amountMax': amountMax,
        'totalAmountMin': totalAmountMin,
        'totalAmountMax': totalAmountMax,
        'balanceMin': balanceMin,
        'balanceMax': balanceMax,
        'isOverdue': isOverdue,
        'overdueAmountMin': overdueAmountMin,
        'overdueAmountMax': overdueAmountMax,
        'perPage': perPage ?? 15,
      };

      final response = await _creditApiService.getCredits(
        clientId: clientId,
        cobradorId: cobradorId,
        status: status,
        search: search,
        frequency: (frequencies == null || frequencies.isEmpty)
            ? null
            : frequencies.join(','),
        startDateFrom: startDateFrom?.toIso8601String().split('T')[0],
        startDateTo: startDateTo?.toIso8601String().split('T')[0],
        endDateFrom: endDateFrom?.toIso8601String().split('T')[0],
        endDateTo: endDateTo?.toIso8601String().split('T')[0],
        amountMin: amountMin,
        amountMax: amountMax,
        totalAmountMin: totalAmountMin,
        totalAmountMax: totalAmountMax,
        balanceMin: balanceMin,
        balanceMax: balanceMax,
        isOverdue: isOverdue,
        overdueAmountMin: overdueAmountMin,
        overdueAmountMax: overdueAmountMax,
        page: page,
        perPage: perPage ?? 15,
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
          isLoadingMore: false,
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
        isLoadingMore: false,
        errorMessage: 'Error al cargar créditos: $e',
      );
    }
  }

  bool get hasMore => state.currentPage < state.totalPages;

  Future<void> loadMoreCredits() async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!hasMore) return;

    final query = _lastQuery ?? {};
    final int nextPage = (state.currentPage) + 1;
    final int perPage = (query['perPage'] as int?) ?? 15;

    try {
      state = state.copyWith(isLoadingMore: true, errorMessage: null);

      final response = await _creditApiService.getCredits(
        clientId: query['clientId'] as int?,
        cobradorId: query['cobradorId'] as int?,
        status: query['status'] as String?,
        search: query['search'] as String?,
        frequency:
            (query['frequencies'] == null ||
                (query['frequencies'] as List).isEmpty)
            ? null
            : (query['frequencies'] as List).join(','),
        startDateFrom: (query['startDateFrom'] as DateTime?)
            ?.toIso8601String()
            .split('T')[0],
        startDateTo: (query['startDateTo'] as DateTime?)
            ?.toIso8601String()
            .split('T')[0],
        endDateFrom: (query['endDateFrom'] as DateTime?)
            ?.toIso8601String()
            .split('T')[0],
        endDateTo: (query['endDateTo'] as DateTime?)?.toIso8601String().split(
          'T',
        )[0],
        amountMin: query['amountMin'] as double?,
        amountMax: query['amountMax'] as double?,
        totalAmountMin: query['totalAmountMin'] as double?,
        totalAmountMax: query['totalAmountMax'] as double?,
        balanceMin: query['balanceMin'] as double?,
        balanceMax: query['balanceMax'] as double?,
        page: nextPage,
        perPage: perPage,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final creditsData = data['data'] as List? ?? [];
        final newCredits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        // Evitar duplicados por id
        final existing = {for (var c in state.credits) c.id: c};
        for (final c in newCredits) {
          existing[c.id] = c;
        }
        final merged = existing.values.toList();

        state = state.copyWith(
          credits: merged,
          isLoadingMore: false,
          currentPage: data['current_page'] ?? nextPage,
          totalPages: data['last_page'] ?? state.totalPages,
          totalItems: data['total'] ?? state.totalItems,
        );
      } else {
        throw Exception(response['message'] ?? 'Error al cargar más créditos');
      }
    } catch (e) {
      print('❌ Error al cargar más créditos: $e');
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Error al cargar más créditos: $e',
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
    double? installmentAmount,
    int? totalInstallments,
    double? latitude,
    double? longitude,
    DateTime? scheduledDeliveryDate,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🔄 Iniciando proceso de creación de crédito...');

      // Ajustar regla de negocio: créditos diarios usan la duración manual (Lun–Sáb)
      DateTime normalizedEndDate = endDate;
      if (frequency == 'daily') {
        final count = totalInstallments ?? 24;
        normalizedEndDate = ScheduleUtils.computeDailyEndDate(startDate, count);
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

      // Agregar campos opcionales
      if (scheduledDeliveryDate != null) {
        creditData['scheduled_delivery_date'] = scheduledDeliveryDate
            .toIso8601String();
      }
      if (interestRate != null && interestRate > 0) {
        creditData['interest_rate'] = interestRate;
      }
      if (totalAmount != null) {
        creditData['total_amount'] = totalAmount;
      }
      if (installmentAmount != null) {
        creditData['installment_amount'] = installmentAmount;
      }
      if (totalInstallments != null) {
        creditData['total_installments'] = totalInstallments;
      }
      if (latitude != null) {
        creditData['latitude'] = latitude;
      }
      if (longitude != null) {
        creditData['longitude'] = longitude;
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

        // Notificar vía WebSocket
        _notifyCreditCreated(nuevoCredito);

        print('✅ Crédito creado exitosamente');
        return true;
      } else {
        throw Exception(response['message'] ?? 'Error al crear crédito');
      }
    } on ApiException catch (e) {
      print('❌ ApiException al crear crédito: ${e.message}');

      String errorMessage = e.message;
      Map<String, dynamic> validationErrors = {};
      if (e.hasValidationErrors) {
        validationErrors = e.validationErrors;
        if (validationErrors.isNotEmpty) {
          final firstKey = validationErrors.keys.first;
          final firstList = validationErrors[firstKey];
          if (firstList is List && firstList.isNotEmpty) {
            errorMessage = firstList.first.toString();
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
        validationErrors: validationErrors,
      );
      return false;
    } catch (e) {
      print('❌ Error al crear crédito: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear crédito: $e',
      );
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
    int? totalInstallments,
    double? latitude,
    double? longitude,
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
      if (startDate != null) {
        creditData['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        var normalizedEnd = endDate;
        // Si es diario, ajustar fecha fin
        final existing = state.credits.firstWhere(
          (c) => c.id == creditId,
          orElse: () => throw Exception('Crédito no encontrado'),
        );
        final freq = frequency ?? existing.frequency;
        final start = startDate ?? existing.startDate;
        if (freq == 'daily') {
          final count =
              totalInstallments ??
              _inferInstallmentsFromAmounts(totalAmount, installmentAmount) ??
              24;
          normalizedEnd = ScheduleUtils.computeDailyEndDate(start, count);
        }
        creditData['end_date'] = normalizedEnd.toIso8601String().split('T')[0];
      }
      if (totalAmount != null) creditData['total_amount'] = totalAmount;
      if (installmentAmount != null)
        creditData['installment_amount'] = installmentAmount;
      if (totalInstallments != null)
        creditData['total_installments'] = totalInstallments;
      if (latitude != null) creditData['latitude'] = latitude;
      if (longitude != null) creditData['longitude'] = longitude;

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

  /// Anula un crédito cambiando su estado a 'cancelled'
  Future<bool> cancelCredit(int creditId) async {
    try {
      print('🚫 Anulando crédito: $creditId');

      // Obtener el crédito actual para preservar todos sus datos
      final currentCredit = state.credits.firstWhere(
        (c) => c.id == creditId,
        orElse: () =>
            throw Exception('Crédito no encontrado en el estado local'),
      );

      // Usar el método updateCredit existente para cambiar solo el estado
      final success = await updateCredit(
        creditId: creditId,
        clientId: currentCredit.clientId,
        amount: currentCredit.amount,
        balance: currentCredit.balance,
        interestRate: currentCredit.interestRate,
        frequency: currentCredit.frequency,
        status: 'cancelled', // Estado de anulado
        startDate: currentCredit.startDate,
        endDate: currentCredit.endDate,
        totalAmount: currentCredit.totalAmount,
        installmentAmount: currentCredit.installmentAmount,
        totalInstallments: currentCredit.totalInstallments,
      );

      if (success) {
        print('✅ Crédito anulado exitosamente');
        state = state.copyWith(successMessage: 'Crédito anulado exitosamente');
      }

      return success;
    } catch (e) {
      print('❌ Error al anular crédito: $e');

      String errorMessage = 'Error al anular crédito';
      if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para anular este crédito';
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

  /// Procesa un pago para un crédito (delegado al PagoProvider) - CON UBICACIÓN GPS
  Future<Map<String, dynamic>?> processPayment({
    required int creditId,
    required double amount,
    String paymentType = 'cash',
    String? notes,
    double? latitude,
    double? longitude,
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

    // Delegar al PagoProvider incluyendo la ubicación GPS
    final pagoNotifier = _ref.read(pagoProvider.notifier);
    final result = await pagoNotifier.processPaymentForCredit(
      creditId: creditId,
      amount: amount,
      paymentType: paymentType,
      notes: notes,
      latitude: latitude,
      longitude: longitude,
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

  /// Obtiene créditos de un cliente específico
  Future<void> loadClientCredits(
    int clientId, {
    String? status,
    List<String>? frequencies,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    DateTime? endDateFrom,
    DateTime? endDateTo,
    double? amountMin,
    double? amountMax,
    double? balanceMin,
    double? balanceMax,
    int page = 1,
    int perPage = 50,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos del cliente: $clientId');

      final response = await _creditApiService.getClientCredits(
        clientId,
        status: status,
        frequency: (frequencies == null || frequencies.isEmpty)
            ? null
            : frequencies.join(','),
        startDateFrom: startDateFrom?.toIso8601String().split('T')[0],
        startDateTo: startDateTo?.toIso8601String().split('T')[0],
        endDateFrom: endDateFrom?.toIso8601String().split('T')[0],
        endDateTo: endDateTo?.toIso8601String().split('T')[0],
        amountMin: amountMin,
        amountMax: amountMax,
        balanceMin: balanceMin,
        balanceMax: balanceMax,
        page: page,
        perPage: perPage,
      );

      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> creditsData;
        int currentPageVal = 1;
        int totalPagesVal = 1;
        int totalItemsVal = 0;

        if (data is Map<String, dynamic> && data['data'] is List) {
          creditsData = data['data'] as List<dynamic>;
          currentPageVal = data['current_page'] ?? 1;
          totalPagesVal = data['last_page'] ?? 1;
          totalItemsVal = data['total'] ?? (creditsData.length);
        } else if (data is List) {
          creditsData = data;
          totalItemsVal = data.length;
        } else {
          creditsData = const [];
        }

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          credits: credits,
          isLoading: false,
          currentPage: currentPageVal,
          totalPages: totalPagesVal,
          totalItems: totalItemsVal,
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

  /// Obtiene créditos por cobrador (para admin/manager)
  Future<void> loadCobradorCredits(
    int cobradorId, {
    String? status,
    String? search,
    List<String>? frequencies,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    DateTime? endDateFrom,
    DateTime? endDateTo,
    double? amountMin,
    double? amountMax,
    double? balanceMin,
    double? balanceMax,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando créditos del cobrador: $cobradorId');

      final response = await _creditApiService.getCobradorCredits(
        cobradorId,
        status: status,
        search: search,
        frequency: (frequencies == null || frequencies.isEmpty)
            ? null
            : frequencies.join(','),
        startDateFrom: startDateFrom?.toIso8601String().split('T')[0],
        startDateTo: startDateTo?.toIso8601String().split('T')[0],
        endDateFrom: endDateFrom?.toIso8601String().split('T')[0],
        endDateTo: endDateTo?.toIso8601String().split('T')[0],
        amountMin: amountMin,
        amountMax: amountMax,
        balanceMin: balanceMin,
        balanceMax: balanceMax,
        page: page,
        perPage: perPage,
      );

      if (response['success'] == true) {
        final data = response['data'];
        final creditsData = (data is Map<String, dynamic>)
            ? (data['data'] as List? ?? [])
            : (data as List? ?? []);

        final credits = creditsData
            .map(
              (creditJson) =>
                  Credito.fromJson(creditJson as Map<String, dynamic>),
            )
            .toList();

        state = state.copyWith(
          credits: credits,
          isLoading: false,
          currentPage: (data is Map<String, dynamic>)
              ? (data['current_page'] ?? 1)
              : 1,
          totalPages: (data is Map<String, dynamic>)
              ? (data['last_page'] ?? 1)
              : 1,
          totalItems: (data is Map<String, dynamic>)
              ? (data['total'] ?? credits.length)
              : credits.length,
        );
        print('✅ Créditos del cobrador cargados (${credits.length})');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar créditos del cobrador',
        );
      }
    } catch (e) {
      print('❌ Error al cargar créditos del cobrador: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar créditos del cobrador: $e',
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

  /// Obtiene un crédito por ID desde el backend (sin alterar el estado global)
  Future<Credito?> fetchCreditById(int creditId) async {
    try {
      print('🔍 [CreditNotifier] Fetching credit by ID: $creditId');

      Map<String, dynamic> response;
      try {
        response = await _creditApiService.getCreditDetails(creditId);
      } catch (_) {
        response = await _creditApiService.getCredit(creditId);
      }

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        Map<String, dynamic>? creditJson;

        if (data is Map<String, dynamic>) {
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

      print(
        '⚠️ [CreditNotifier] No se pudo parsear el crédito con ID $creditId',
      );
      return null;
    } catch (e) {
      print('❌ [CreditNotifier] Error al obtener crédito $creditId: $e');
      return null;
    }
  }

  /// Obtiene el cronograma de pagos de un crédito
  Future<List<PaymentSchedule>?> getPaymentSchedule(int creditId) async {
    try {
      print(
        '🔄 Obteniendo cronograma de pagos desde backend para crédito: $creditId',
      );
      final response = await _creditApiService.getCreditPaymentSchedule(
        creditId,
      );
      if (response['success'] == true) {
        final data = response['data'];
        List<dynamic> scheduleData = [];

        if (data is List) {
          scheduleData = data;
        } else if (data is Map<String, dynamic>) {
          final inner = data['schedule'];
          if (inner is List) {
            scheduleData = inner;
          } else if (inner is Map<String, dynamic>) {
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
      print(
        '🔁 Generando cronograma de pagos localmente para crédito: $creditId',
      );
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

  /// Obtiene detalles extendidos de un crédito: credit + summary + schedule + history
  Future<CreditFullDetails?> getCreditFullDetails(int creditId) async {
    try {
      final response = await _creditApiService.getCreditDetails(creditId);
      if (response['success'] == true) {
        final details = CreditFullDetails.fromApi(response);
        return details;
      } else {
        throw Exception(response['message'] ?? 'Error al obtener detalles');
      }
    } catch (e) {
      print('❌ Error al obtener detalles del crédito: $e');
      state = state.copyWith(errorMessage: 'Error al obtener detalles: $e');
      return null;
    }
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

        if (data is List) {
          creditsData = data;
        } else if (data is Map<String, dynamic>) {
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

        if (data is List) {
          creditsData = data;
        } else if (data is Map<String, dynamic>) {
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

        if (data is List) {
          creditsData = data;
        } else if (data is Map<String, dynamic>) {
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
    bool immediate = false,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
        validationErrors: {},
      );
      print('✅ Aprobando crédito para entrega: $creditId');

      final response = await _creditApiService.approveCreditForDelivery(
        creditId: creditId.toString(),
        scheduledDeliveryDate: scheduledDeliveryDate,
        notes: notes,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        _updateCreditInAllLists(creditoActualizado);
        _notifyCreditApproved(creditoActualizado, immediate: immediate);

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

      Map<String, dynamic> validationErrors = {};
      if (e.hasValidationErrors) {
        validationErrors = e.validationErrors;
        print('❌ Errores de validación: $validationErrors');
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        validationErrors: validationErrors,
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

        _updateCreditInAllLists(creditoActualizado);
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
      print('⏰ Reprogramando fecha de entrega del crédito: $creditId');

      final response = await _creditApiService.rescheduleCreditDelivery(
        creditId,
        newScheduledDate: newScheduledDate,
        reason: reason,
      );

      // La API puede devolver en diferentes formatos; intentamos cubrir ambos
      final dynamic data = response['data'] ?? response;
      final dynamic creditJson = (data is Map<String, dynamic>)
          ? (data['credit'] ?? data)
          : null;

      if (creditJson is Map<String, dynamic>) {
        final creditoActualizado = Credito.fromJson(creditJson);
        _updateCreditInAllLists(creditoActualizado);
      }

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Fecha de entrega reprogramada exitosamente',
      );
      print('✅ Fecha de entrega reprogramada');
      return true;
    } catch (e) {
      print('❌ Error al reprogramar fecha de entrega: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al reprogramar fecha de entrega: $e',
      );
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

        _updateCreditInAllLists(creditoActualizado);
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

  // ========================================
  // MÉTODOS DE UTILIDAD
  // ========================================

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
  // MÉTODOS PRIVADOS
  // ========================================

  /// Intenta inferir el número de cuotas a partir de totalAmount e installmentAmount
  int? _inferInstallmentsFromAmounts(
    double? totalAmount,
    double? installmentAmount,
  ) {
    if (totalAmount == null ||
        installmentAmount == null ||
        installmentAmount <= 0)
      return null;
    final est = (totalAmount / installmentAmount).round();
    if (est <= 0) return null;
    return est;
  }

  /// Genera un cronograma de pagos local basado en los datos del crédito
  List<PaymentSchedule> _generatePaymentSchedule(Credito credit) {
    final schedule = <PaymentSchedule>[];

    // Calcular información base
    final totalDays = credit.endDate.difference(credit.startDate).inDays;
    final interestRate = credit.interestRate ?? 20.0;

    int installments;
    int daysBetweenPayments;

    // Determinar número de cuotas y frecuencia basado en el tipo
    switch (credit.frequency) {
      case 'daily':
        final inferred = _inferInstallmentsFromAmounts(
          credit.totalAmount,
          credit.installmentAmount,
        );
        installments = inferred ?? 24;
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
        installments = 24;
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
      if (credit.frequency == 'daily' &&
          currentDue.weekday == DateTime.sunday) {
        continue; // Saltar domingos
      }
      final dueDate = currentDue;
      created++;

      // Verificar si ya fue pagado comparando con pagos existentes
      final existingPayment =
          credit.payments?.where((p) {
            final paymentDate = p.paymentDate;
            final daysDiff = (paymentDate.difference(dueDate).inDays).abs();
            return daysDiff <= (daysBetweenPayments ~/ 2);
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

  /// Actualiza un crédito en todas las listas donde pueda estar presente
  void _updateCreditInAllLists(Credito creditoActualizado) {
    final creditosActualizados = state.credits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    final attentionUpdated = state.attentionCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    final pendingUpdated = state.pendingApprovalCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    final waitingUpdated = state.waitingDeliveryCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    final readyUpdated = state.readyForDeliveryCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    final overdueUpdated = state.overdueDeliveryCredits.map((credito) {
      return credito.id == creditoActualizado.id ? creditoActualizado : credito;
    }).toList();

    state = state.copyWith(
      credits: creditosActualizados,
      attentionCredits: attentionUpdated,
      pendingApprovalCredits: pendingUpdated,
      waitingDeliveryCredits: waitingUpdated,
      readyForDeliveryCredits: readyUpdated,
      overdueDeliveryCredits: overdueUpdated,
    );
  }

  /// Notifica la creación de un crédito vía WebSocket
  void _notifyCreditCreated(Credito credito) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        // Notificar al manager (targetUserId) que el cobrador solicitó crédito
        final managerId = authState.usuario!.assignedManagerId?.toString();
        wsNotifier.notifyCreditLifecycle(
          action: 'created',
          creditId: credito.id!,
          targetUserId: managerId,
          credit: {
            'id': credito.id,
            'client_id': credito.clientId,
            'client_name': credito.client?.nombre,
            'amount': credito.amount,
          },
          userType: 'cobrador',
          message: 'Nuevo crédito solicitado',
        );
        print('🔔 WS: evento credit_lifecycle(created) emitido');
      }
    } catch (e) {
      print('⚠️ Error enviando notificación WebSocket: $e');
    }
  }

  /// Notifica la aprobación de un crédito vía WebSocket
  void _notifyCreditApproved(Credito credito, {bool immediate = false}) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        // Notificar al creador del crédito (puede ser manager o cobrador), sin importar su rol
        final String? creatorIdStr = (() {
          final int? creatorId =
              credito.createdBy ??
              (credito.creator?.id is int ? credito.creator?.id as int? : null);
          return creatorId != null ? creatorId.toString() : null;
        })();

        wsNotifier.notifyCreditLifecycle(
          action: 'approved',
          creditId: credito.id!,
          targetUserId: creatorIdStr,
          credit: {
            'id': credito.id,
            'client_id': credito.clientId,
            'client_name': credito.client?.nombre,
            'amount': credito.amount,
            'entrega_inmediata': immediate,
          },
          userType: 'manager',
          message: 'Crédito aprobado',
        );
        print('🔔 WS: evento credit_lifecycle(approved) emitido');
      }
    } catch (e) {
      print('⚠️ Error enviando notificación WebSocket: $e');
    }
  }

  /// Notifica el rechazo de un crédito vía WebSocket
  void _notifyCreditRejected(Credito credito, String reason) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        // Notificar al cobrador que el manager rechazó el crédito
        wsNotifier.notifyCreditLifecycle(
          action: 'rejected',
          creditId: credito.id!,
          targetUserId: credito.cobrador?.id.toString(),
          credit: {
            'id': credito.id,
            'client_id': credito.clientId,
            'client_name': credito.client?.nombre,
            'amount': credito.amount,
            'reason': reason,
          },
          userType: 'manager',
          message: 'Crédito rechazado: $reason',
        );
        print('🔔 WS: evento credit_lifecycle(rejected) emitido');
      }
    } catch (e) {
      print('⚠️ Error enviando notificación WebSocket: $e');
    }
  }

  /// Orquesta aprobación y entrega inmediata del crédito
  Future<bool> approveAndDeliverCredit({
    required int creditId,
    required DateTime scheduledDeliveryDate,
    String? approvalNotes,
    String? deliveryNotes,
  }) async {
    // Primero aprobar para entrega
    final approved = await approveCreditForDelivery(
      creditId: creditId,
      scheduledDeliveryDate: scheduledDeliveryDate,
      notes: approvalNotes,
      immediate: true,
    );
    if (!approved) return false;

    // Luego entregar al cliente
    final delivered = await deliverCreditToClient(
      creditId: creditId,
      notes: deliveryNotes,
    );
    return delivered;
  }

  /// Notifica la entrega de un crédito vía WebSocket
  void _notifyCreditDelivered(Credito credito, {String? notes}) {
    try {
      final authState = _ref.read(authProvider);
      final wsNotifier = _ref.read(webSocketProvider.notifier);

      if (authState.usuario != null) {
        // Notificar al manager que se realizó la entrega del crédito
        final authUser = authState.usuario!;
        final managerId = authUser.assignedManagerId?.toString();
        wsNotifier.notifyCreditLifecycle(
          action: 'delivered',
          creditId: credito.id!,
          targetUserId: managerId,
          credit: {
            'id': credito.id,
            'client_id': credito.clientId,
            'client_name': credito.client?.nombre,
            'amount': credito.amount,
            if (notes != null) 'notes': notes,
          },
          userType: 'cobrador',
          message: 'Crédito entregado',
        );
        print('🔔 WS: evento credit_lifecycle(delivered) emitido');
      }
    } catch (e) {
      print('⚠️ Error enviando notificación WebSocket: $e');
    }
  }
}

// Provider para gestionar créditos
final creditProvider = StateNotifierProvider<CreditNotifier, CreditState>((
  ref,
) {
  final creditApiService = CreditApiService();
  return CreditNotifier(creditApiService, ref);
});
