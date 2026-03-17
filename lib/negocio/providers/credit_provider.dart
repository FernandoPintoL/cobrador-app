import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/api_exception.dart';
import '../../datos/api_services/credit_api_service.dart';
import '../../datos/api_services/cash_balance_api_service.dart';
import '../../datos/modelos/credit_full_details.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/modelos/cash_balance_status.dart';
import 'auth_provider.dart';
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
  final Map<String, int> tabCounts;

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
    this.tabCounts = const {
      'active': 0,
      'pending_approval': 0,
      'waiting_delivery': 0,
    },
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
    Map<String, int>? tabCounts,
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
      tabCounts: tabCounts ?? this.tabCounts,
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
    double? totalPaidMin,
    double? totalPaidMax,
    bool? isOverdue, // Filtro para cuotas atrasadas
    double? overdueAmountMin, // Monto mínimo atrasado
    double? overdueAmountMax, // Monto máximo atrasado
    int page = 1,
    int? perPage,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      print(
        '🔄 Cargando créditos con filtros: status=$status, clientId=$clientId, cobradorId=$cobradorId, search=$search',
      );

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
        'totalPaidMin': totalPaidMin,
        'totalPaidMax': totalPaidMax,
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
        totalPaidMin: totalPaidMin,
        totalPaidMax: totalPaidMax,
        isOverdue: isOverdue,
        overdueAmountMin: overdueAmountMin,
        overdueAmountMax: overdueAmountMax,
        page: page,
        perPage: perPage ?? 15,
      );

      if (response['success'] == true) {
        final data = response['data'];
        // Verificar la estructura completa de la respuesta
        print('🔄 Estructura de datos recibida:');
        print('  - success: ${response['success']}');
        print('  - data keys: ${data.keys.toList()}');
        print(
          '  - pagination: current=${data['current_page']}, last=${data['last_page']}, total=${data['total']}',
        );

        final creditsData = data['data'] as List? ?? [];

        print('📊 API retornó ${creditsData.length} créditos en formato JSON');

        if (creditsData.isEmpty) {
          print('⚠️ La lista de créditos está vacía en la respuesta del API');
          // Revisar si hay un mensaje explicando por qué está vacía
          if (response.containsKey('message')) {
            print('ℹ️ Mensaje del servidor: ${response['message']}');
          }
        } else {
          print('🔍 Primer crédito en respuesta: ${creditsData.first}');
          // Verificar campos clave en el primer crédito
          if (creditsData.first is Map) {
            final firstCreditMap = creditsData.first as Map;
            print(
              '🔍 Campos del primer crédito: ${firstCreditMap.keys.toList()}',
            );
            print(
              '🔍 ID: ${firstCreditMap['id']}, Estado: ${firstCreditMap['status']}',
            );

            // Verificar cliente
            if (firstCreditMap.containsKey('client')) {
              print('🔍 Cliente: ${firstCreditMap['client']}');
            } else {
              print('⚠️ El crédito no tiene cliente asociado');
            }
          }
        }

        final credits = creditsData
            .map((creditJson) {
              try {
                final credito = Credito.fromJson(
                  creditJson as Map<String, dynamic>,
                );
                print(
                  '✅ Convertido crédito ID=${credito.id}, Estado=${credito.status}, ClienteID=${credito.clientId}',
                );
                return credito;
              } catch (e) {
                print('❌ Error al convertir crédito: $e');
                print('❌ JSON problemático: $creditJson');
                return null;
              }
            })
            .whereType<Credito>() // Filtrar nulos
            .toList();

        // Si se cargó waiting_delivery, actualizar también las listas filtradas
        List<Credito>? readyForDelivery;
        List<Credito>? overdueDelivery;
        if (status == 'waiting_delivery') {
          print('🔍 Analizando ${credits.length} créditos waiting_delivery:');
          for (var c in credits) {
            print('  - Crédito ID ${c.id}: scheduledDate=${c.scheduledDeliveryDate}, isReady=${c.isReadyForDelivery}, isOverdue=${c.isOverdueForDelivery}');
          }

          // NOTA: readyForDelivery ahora incluye TODOS los créditos waiting_delivery
          // para mostrarlos en el tab "Para Entregar" sin filtrar por fecha
          readyForDelivery = credits; // Todos los waiting_delivery
          overdueDelivery = credits
              .where((c) => c.isOverdueForDelivery)
              .toList();
          print('🔍 Filtrado waiting_delivery:');
          print('  - Para entregar (todos): ${readyForDelivery.length}');
          print('  - Atrasados: ${overdueDelivery.length}');
        }

        state = state.copyWith(
          credits: credits,
          isLoading: false,
          isLoadingMore: false,
          currentPage: data['current_page'] ?? 1,
          totalPages: data['last_page'] ?? 1,
          totalItems: data['total'] ?? 0,
          readyForDeliveryCredits: readyForDelivery,
          overdueDeliveryCredits: overdueDelivery,
          waitingDeliveryCredits: status == 'waiting_delivery' ? credits : null,
        );

        print('✅ ${credits.length} créditos cargados exitosamente');
        print('📑 Estados de créditos: ${_countCreditsByStatus(credits)}');

        // Verificar si cada tipo de lista recibe sus créditos correspondientes
        final pendingApproval = credits
            .where((c) => c.status == 'pending_approval')
            .toList();
        // final attentionList = credits
        //     .where((c) => c.status == 'atencion')
        //     .toList();
        final waitingDelivery = credits
            .where((c) => c.status == 'waiting_delivery')
            .toList();
        print('📋 Resumen de listas específicas:');
        print('  - Pendientes de aprobación: ${pendingApproval.length}');
        // print('  - Atención: ${attentionList.length}');
        print('  - Esperando entrega: ${waitingDelivery.length}');
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
        totalPaidMin: query['totalPaidMin'] as double?,
        totalPaidMax: query['totalPaidMax'] as double?,
        isOverdue: query['isOverdue'] as bool?,
        overdueAmountMin: query['overdueAmountMin'] as double?,
        overdueAmountMax: query['overdueAmountMax'] as double?,
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

  /// Verifica el estado de la caja antes de crear un crédito
  /// Retorna el estado de la caja o null si hay un error
  Future<CashBalanceStatus?> checkCashBalanceStatus() async {
    try {
      final authState = _ref.read(authProvider);
      final isCobrador = authState.usuario?.esCobrador() ?? false;

      if (!isCobrador) {
        // Si no es cobrador, no necesita verificación de caja
        return null;
      }

      final cobradorId = authState.usuario!.id.toInt();
      print('🔍 Verificando estado de caja para cobrador=$cobradorId');

      final cashApi = CashBalanceApiService();
      final response = await cashApi.getCurrentStatus(cobradorId: cobradorId);

      if (response['success'] == true) {
        final data = response['data'];
        final status = CashBalanceStatus.fromJson(data as Map<String, dynamic>);
        print('✅ Estado de caja obtenido: $status');
        return status;
      } else {
        final msg =
            response['message']?.toString() ??
            'Error al obtener estado de caja';
        print('❌ Error al obtener estado de caja: $msg');
        state = state.copyWith(errorMessage: msg);
        return null;
      }
    } catch (e) {
      print('❌ Error al verificar estado de caja: $e');
      state = state.copyWith(
        errorMessage: 'Error al verificar estado de caja: $e',
      );
      return null;
    }
  }

  /// Crea un nuevo crédito
  Future<bool> createCredit({
    required int clientId,
    int? cobradorId,
    required double amount,
    required double balance,
    required String frequency,
    required DateTime startDate,
    required DateTime endDate,
    double? interestRate,
    int? interestRateId,
    double? totalAmount,
    double? installmentAmount,
    int? totalInstallments,
    double? latitude,
    double? longitude,
    DateTime? scheduledDeliveryDate,
    // ✅ NUEVO: Parámetros para crédito antiguo
    bool? isLegacyCredit,
    int? paidInstallmentsCount,
    // ✅ NUEVO: Parámetros para modo personalizado
    String? description,
    double? downPayment,
    bool? isCustomCredit,
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
      if (cobradorId != null) {
        creditData['cobrador_id'] = cobradorId;
      }
      if (scheduledDeliveryDate != null) {
        creditData['scheduled_delivery_date'] = scheduledDeliveryDate
            .toIso8601String();
      }
      // Prioridad: interest_rate_id > interest_rate manual
      if (interestRateId != null) {
        creditData['interest_rate_id'] = interestRateId;
      } else if (interestRate != null && interestRate > 0) {
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
      // ✅ NUEVO: Agregar parámetros para crédito antiguo
      if (isLegacyCredit != null && isLegacyCredit) {
        creditData['is_legacy_credit'] = true;
      }
      // Enviar paid_installments_count siempre que exista (legacy manual o custom calculado)
      if (paidInstallmentsCount != null && paidInstallmentsCount > 0) {
        creditData['paid_installments_count'] = paidInstallmentsCount;
      }

      // ✅ NUEVO: Agregar parámetros para modo personalizado
      if (isCustomCredit != null && isCustomCredit) {
        creditData['is_custom_credit'] = true;
        if (description != null && description.isNotEmpty) {
          creditData['description'] = description;
        }
        if (downPayment != null && downPayment > 0) {
          creditData['down_payment'] = downPayment;
        }
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

    // Si hay información del crédito retornada, actualizar la lista local.
    // `result` puede ser la respuesta completa ({success,data,message}) o
    // directamente el `data` (Map). Normalizamos a `resultData`.
    Map<String, dynamic>? resultData;
    if (result != null) {
      if (result['success'] != null) {
        // Es la respuesta completa
        final dynamic d = result['data'];
        if (d is Map<String, dynamic>) resultData = d;
        // si `data` es List o null, dejamos resultData en null
      } else if (result is Map<String, dynamic>) {
        // Podría ser que el caller devolvió directamente el data
        resultData = result;
      }
    }

    if (resultData != null && resultData['credit'] != null) {
      final creditoActualizado = Credito.fromJson(resultData['credit']);
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

  /// Establece directamente las estadísticas sin hacer petición
  /// Útil para usar datos que ya vienen del login
  void setStats(CreditStats stats) {
    print('✅ Estableciendo estadísticas directamente (desde login)');
    state = state.copyWith(stats: stats, isLoading: false);
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
      print('❌ Error al cargar estadísticas del cobrador: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar estadísticas: $e',
      );
    }
  }

  /// Carga estadísticas del manager actual o de un manager específico
  /// Incluye métricas consolidadas de:
  /// - Clientes directos del manager
  /// - Clientes de cobradores bajo su supervisión
  Future<void> loadManagerStats({int? managerId}) async {
    try {
      final authState = _ref.read(authProvider);
      if (authState.usuario == null) return;

      // Usar el ID proporcionado o el del usuario autenticado
      final targetManagerId = managerId ?? authState.usuario!.id.toInt();

      state = state.copyWith(isLoading: true, errorMessage: null);
      print('🔄 Cargando estadísticas del manager: $targetManagerId');

      final response = await _creditApiService.getManagerStats(targetManagerId);

      if (response['success'] == true) {
        final stats = CreditStats.fromJson(response['data']);

        state = state.copyWith(stats: stats, isLoading: false);

        print('✅ Estadísticas del manager cargadas exitosamente');
      } else {
        throw Exception(
          response['message'] ?? 'Error al cargar estadísticas del manager',
        );
      }
    } catch (e) {
      print('❌ Error al cargar estadísticas del manager: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar estadísticas del manager: $e',
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

        // ⭐ El backend SIEMPRE retorna el cronograma ahora (fuente única de verdad)
        // No es necesario generarlo localmente

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
    DateTime? scheduledDeliveryDate,
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

      // Si es entrega inmediata, NO enviar fecha (el backend usa "now")
      // Si NO es inmediata, la fecha es requerida
      final response = await _creditApiService.approveCreditForDelivery(
        creditId: creditId.toString(),
        scheduledDeliveryDate: immediate ? null : scheduledDeliveryDate,
        notes: notes,
        immediateDelivery: immediate,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        _updateCreditInAllLists(creditoActualizado);

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

      String displayMessage = e.message;
      Map<String, dynamic> validationErrors = {};

      if (e.hasValidationErrors) {
        validationErrors = e.validationErrors;
        print('❌ Errores de validación: $validationErrors');

        // Si hay errores de validación, intentar extraer el primer mensaje
        // ya que el mensaje principal ya debería contener el error más relevante
        if (displayMessage.contains('Error al aprobar crédito para entrega') &&
            validationErrors.isNotEmpty) {
          final firstKey = validationErrors.keys.first;
          final firstList = validationErrors[firstKey];
          if (firstList is List && firstList.isNotEmpty) {
            displayMessage = firstList.first.toString();
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: displayMessage,
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
    bool firstPaymentToday = false,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🚚 Entregando crédito al cliente: $creditId');

      // Asegurar que la caja esté abierta para el cobrador en la fecha actual
      try {
        final authState = _ref.read(authProvider);
        final isCobrador = authState.usuario?.esCobrador() ?? false;
        if (isCobrador) {
          final cobradorId = authState.usuario!.id.toInt();
          final today = DateTime.now().toIso8601String().split('T')[0];
          print(
            '🔍 Verificando/abriendo caja para cobrador=$cobradorId en fecha=$today',
          );
          final cashApi = CashBalanceApiService();
          final openResp = await cashApi.openCashBalance(
            cobradorId: cobradorId,
            date: today,
          );
          if (openResp['success'] == false) {
            final msg =
                openResp['message']?.toString() ?? 'No se pudo abrir la caja';
            state = state.copyWith(isLoading: false, errorMessage: msg);
            return false;
          }
        }
      } catch (e) {
        // Si falla la verificación de caja, detener y mostrar mensaje claro
        final msg =
            'No se pudo preparar la caja para la entrega: ${e.toString()}';
        print('❌ $msg');
        state = state.copyWith(isLoading: false, errorMessage: msg);
        return false;
      }

      final response = await _creditApiService.deliverCreditToClient(
        creditId,
        notes: notes,
        firstPaymentToday: firstPaymentToday,
      );

      if (response['success'] == true) {
        // Algunos endpoints envían el crédito en data.credit, otros en data
        final dynamic data = response['data'];
        final dynamic creditJson = (data is Map<String, dynamic>)
            ? (data['credit'] ?? data)
            : null;
        final creditoActualizado = creditJson is Map<String, dynamic>
            ? Credito.fromJson(creditJson)
            : Credito.fromJson(response['data']['credit']);

        _updateCreditInAllLists(creditoActualizado);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Crédito entregado al cliente exitosamente',
        );

        print('✅ Crédito entregado al cliente exitosamente');
        return true;
      } else {
        final msg =
            response['message']?.toString() ?? 'Error al entregar crédito';
        throw ApiException(message: msg, errorData: response);
      }
    } catch (e) {
      print('❌ Error al entregar crédito: $e');

      String errorMessage = 'Error al entregar crédito';
      final esApi = e is ApiException;
      final rawMsg = esApi ? e.message : e.toString();
      if (rawMsg != null && rawMsg.toLowerCase().contains('permiso')) {
        errorMessage = 'No tienes permisos para entregar este crédito';
      } else if (rawMsg != null && rawMsg.contains('404')) {
        errorMessage = 'Crédito no encontrado';
      } else if (rawMsg != null &&
          (rawMsg.toLowerCase().contains('caja') ||
              rawMsg.toLowerCase().contains('cash'))) {
        // Mensajes relevantes a caja/efectivo insuficiente
        errorMessage = rawMsg;
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

  /// Cuenta los créditos agrupados por estado
  String _countCreditsByStatus(List<Credito> credits) {
    final counts = <String, int>{};
    for (final c in credits) {
      final status = c.status;
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}: ${e.value}').join(', ');
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

  /// Orquesta aprobación y entrega inmediata del crédito
  /// Usa el parámetro immediate_delivery=true del API para hacer ambas acciones en una sola llamada
  Future<bool> approveAndDeliverCredit({
    required int creditId,
    DateTime? scheduledDeliveryDate,
    String? approvalNotes,
    String? deliveryNotes,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        errorMessage: null,
        successMessage: null,
      );
      print('🚀 Aprobando y entregando crédito inmediatamente: $creditId');

      // Combinar notas si existen ambas
      String? combinedNotes;
      if (approvalNotes != null && deliveryNotes != null) {
        combinedNotes = 'Aprobación: $approvalNotes\nEntrega: $deliveryNotes';
      } else {
        combinedNotes = approvalNotes ?? deliveryNotes;
      }

      // Una sola llamada con immediate_delivery=true
      // El backend se encarga de aprobar Y entregar el crédito
      // NO enviamos scheduled_delivery_date para entrega inmediata
      final response = await _creditApiService.approveCreditForDelivery(
        creditId: creditId.toString(),
        scheduledDeliveryDate: null, // null para entrega inmediata
        notes: combinedNotes,
        immediateDelivery: true,
      );

      if (response['success'] == true) {
        final creditoActualizado = Credito.fromJson(response['data']['credit']);

        _updateCreditInAllLists(creditoActualizado);

        state = state.copyWith(
          isLoading: false,
          successMessage: 'Crédito aprobado y entregado exitosamente',
        );

        print(
          '✅ Crédito aprobado y entregado exitosamente en una sola operación',
        );
        return true;
      } else {
        throw Exception(
          response['message'] ?? 'Error al aprobar y entregar crédito',
        );
      }
    } on ApiException catch (e) {
      print('❌ ApiException al aprobar y entregar: ${e.message}');

      String displayMessage = e.message;
      Map<String, dynamic> validationErrors = {};

      if (e.hasValidationErrors) {
        validationErrors = e.validationErrors;
        print('❌ Errores de validación: $validationErrors');

        // Si el mensaje es genérico y hay errores de validación, usar el primer error
        if (displayMessage.contains('Error al aprobar') &&
            validationErrors.isNotEmpty) {
          final firstKey = validationErrors.keys.first;
          final firstList = validationErrors[firstKey];
          if (firstList is List && firstList.isNotEmpty) {
            displayMessage = firstList.first.toString();
          }
        }
      }

      state = state.copyWith(
        isLoading: false,
        errorMessage: displayMessage,
        validationErrors: validationErrors,
      );
      return false;
    } catch (e) {
      print('❌ Error al aprobar y entregar crédito: $e');

      String errorMessage = 'Error al aprobar y entregar crédito';
      if (e.toString().contains('403')) {
        errorMessage = 'No tienes permisos para realizar esta acción';
      } else if (e.toString().contains('404')) {
        errorMessage = 'Crédito no encontrado';
      } else if (e.toString().toLowerCase().contains('caja')) {
        errorMessage = e.toString();
      } else if (e is ApiException) {
        errorMessage = e.message;
      }

      state = state.copyWith(isLoading: false, errorMessage: errorMessage);
      return false;
    }
  }

  /// Carga los contadores de tabs con una sola request al endpoint /credits/counts.
  /// Úsalo en la carga inicial de la pantalla y después de mutaciones.
  Future<void> loadTabCounts({String? search, int? cobradorId}) async {
    try {
      final response = await _creditApiService.getTabCounts(
        search: search,
        cobradorId: cobradorId,
      );
      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        state = state.copyWith(
          tabCounts: {
            'active': (data['active'] as num? ?? 0).toInt(),
            'pending_approval':
                (data['pending_approval'] as num? ?? 0).toInt(),
            'waiting_delivery':
                (data['waiting_delivery'] as num? ?? 0).toInt(),
          },
        );
      }
    } catch (e) {
      print('❌ Error al cargar contadores de tabs: $e');
    }
  }

  /// Carga los créditos de todos los estados en paralelo para poblar los badges de los tabs
  Future<void> loadAllTabCounts({
    int? clientId,
    int? cobradorId,
    String? search,
  }) async {
    try {
      print('🔄 Cargando contadores de todos los tabs en paralelo...');

      // Hacer requests en paralelo para cada estado
      final futures = await Future.wait([
        _creditApiService.getCredits(
          clientId: clientId,
          cobradorId: cobradorId,
          status: 'active',
          search: search,
          page: 1,
          perPage: 100, // Cargar suficientes para contar
        ),
        _creditApiService.getCredits(
          clientId: clientId,
          cobradorId: cobradorId,
          status: 'pending_approval',
          search: search,
          page: 1,
          perPage: 100,
        ),
        _creditApiService.getCredits(
          clientId: clientId,
          cobradorId: cobradorId,
          status: 'waiting_delivery',
          search: search,
          page: 1,
          perPage: 100,
        ),
      ]);

      // Procesar respuestas
      final activeCredits = _parseCreditsFromResponse(futures[0]);
      final pendingCredits = _parseCreditsFromResponse(futures[1]);
      final waitingCredits = _parseCreditsFromResponse(futures[2]);

      // Actualizar state con las listas específicas
      // NOTA: readyForDeliveryCredits ahora incluye TODOS los créditos waiting_delivery
      // para mostrarlos en el tab "Para Entregar" sin filtrar por fecha
      state = state.copyWith(
        pendingApprovalCredits: pendingCredits,
        waitingDeliveryCredits: waitingCredits,
        readyForDeliveryCredits: waitingCredits, // Todos los waiting_delivery
        overdueDeliveryCredits: waitingCredits
            .where((c) => c.isOverdueForDelivery)
            .toList(),
      );

      print('✅ Contadores cargados:');
      print('  - Activos: ${activeCredits.length}');
      print('  - Pendientes: ${pendingCredits.length}');
      print('  - En Espera: ${waitingCredits.length}');
      print('  - Para Entregar: ${waitingCredits.length}');
    } catch (e) {
      print('❌ Error al cargar contadores de tabs: $e');
    }
  }

  /// Helper para parsear créditos de una respuesta del API
  List<Credito> _parseCreditsFromResponse(Map<String, dynamic> response) {
    if (response['success'] != true) return [];

    final data = response['data'];
    final creditsData = data['data'] as List? ?? [];

    return creditsData
        .map((json) {
          try {
            return Credito.fromJson(json as Map<String, dynamic>);
          } catch (e) {
            print('❌ Error al parsear crédito: $e');
            return null;
          }
        })
        .whereType<Credito>()
        .toList();
  }
}

// Provider para gestionar créditos
final creditProvider = StateNotifierProvider<CreditNotifier, CreditState>((
  ref,
) {
  final creditApiService = CreditApiService();
  return CreditNotifier(creditApiService, ref);
});
