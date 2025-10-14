import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/api_services/cash_balance_api_service.dart';

class CashBalanceState {
  final bool isLoading;
  final String? errorMessage;
  final List<dynamic> items; // lista de cajas (raw)
  final Map<String, dynamic>? currentDetail;
  // Metadatos de paginación
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const CashBalanceState({
    this.isLoading = false,
    this.errorMessage,
    this.items = const [],
    this.currentDetail,
    this.currentPage = 1,
    this.perPage = 20,
    this.total = 0,
    this.lastPage = 1,
  });

  CashBalanceState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<dynamic>? items,
    Map<String, dynamic>? currentDetail,
    int? currentPage,
    int? perPage,
    int? total,
    int? lastPage,
  }) {
    return CashBalanceState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      items: items ?? this.items,
      currentDetail: currentDetail ?? this.currentDetail,
      currentPage: currentPage ?? this.currentPage,
      perPage: perPage ?? this.perPage,
      total: total ?? this.total,
      lastPage: lastPage ?? this.lastPage,
    );
  }
}

class CashBalanceNotifier extends StateNotifier<CashBalanceState> {
  final CashBalanceApiService _service;

  CashBalanceNotifier(this._service) : super(const CashBalanceState());

  Future<void> list({
    int? cobradorId,
    String? dateFrom,
    String? dateTo,
    String? status,
    int page = 1,
    int perPage = 20,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _service.listCashBalances(
        cobradorId: cobradorId,
        dateFrom: dateFrom,
        dateTo: dateTo,
        status: status,
        page: page,
        perPage: perPage,
      );

      List<dynamic> items = const [];
      int currentPage = page;
      int lastPage = 1;
      int total = 0;
      int perPageResp = perPage;

      final dynamic dataField = resp['data'];
      if (dataField is List) {
        items = dataField;
        currentPage = page;
        lastPage = 1;
        total = dataField.length;
        perPageResp = dataField.length;
      } else if (dataField is Map<String, dynamic>) {
        // Laravel paginator style { current_page, data: [], per_page, total, last_page? }
        final pgData = dataField['data'];
        if (pgData is List) items = pgData;
        currentPage = (dataField['current_page'] is int)
            ? dataField['current_page'] as int
            : int.tryParse(dataField['current_page']?.toString() ?? '') ?? page;
        lastPage = (dataField['last_page'] is int)
            ? dataField['last_page'] as int
            : int.tryParse(dataField['last_page']?.toString() ?? '') ?? currentPage;
        total = (dataField['total'] is int)
            ? dataField['total'] as int
            : int.tryParse(dataField['total']?.toString() ?? '') ?? items.length;
        perPageResp = (dataField['per_page'] is int)
            ? dataField['per_page'] as int
            : int.tryParse(dataField['per_page']?.toString() ?? '') ?? perPage;
      }

      state = state.copyWith(
        isLoading: false,
        items: items,
        errorMessage: null,
        currentPage: currentPage,
        lastPage: lastPage,
        total: total,
        perPage: perPageResp,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> getDetail(int id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final resp = await _service.getCashBalanceDetailed(id);
      final data = resp['data'] is Map<String, dynamic>
          ? resp['data'] as Map<String, dynamic>
          : <String, dynamic>{};
      state = state.copyWith(
        isLoading: false,
        currentDetail: data,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<Map<String, dynamic>> open({
    int? cobradorId,
    String? date,
    double? initialAmount,
  }) async {
    try {
      final resp = await _service.openCashBalance(
        cobradorId: cobradorId,
        date: date,
        initialAmount: initialAmount,
      );
      return resp;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    try {
      final resp = await _service.createCashBalance(payload);
      return resp;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    try {
      final resp = await _service.updateCashBalance(id, payload);
      return resp;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> autoCalculate({
    required int cobradorId,
    required String date,
    double? initialAmount,
    double? finalAmount,
  }) async {
    try {
      final resp = await _service.autoCalculate(
        cobradorId: cobradorId,
        date: date,
        initialAmount: initialAmount,
        finalAmount: finalAmount,
      );
      return resp;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> close(
    int id, {
    double? finalAmount,
    String? notes,
    String status = 'closed', // Añadimos el parámetro status con valor predeterminado 'closed'
  }) async {
    try {
      final resp = await _service.closeCashBalance(
        id,
        finalAmount: finalAmount,
        notes: notes,
        status: status, // Pasamos el status al servicio API
      );
      return resp;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener cajas pendientes de cierre
  Future<Map<String, dynamic>> getPendingClosures({int? cobradorId}) async {
    try {
      final resp = await _service.getPendingClosures(cobradorId: cobradorId);
      return resp;
    } catch (e) {
      rethrow;
    }
  }
}

final cashBalanceProvider =
    StateNotifierProvider<CashBalanceNotifier, CashBalanceState>((ref) {
      final service = CashBalanceApiService();
      return CashBalanceNotifier(service);
    });
