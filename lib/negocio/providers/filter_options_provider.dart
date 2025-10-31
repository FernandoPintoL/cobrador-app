import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/filter_options.dart';
import '../../datos/api_services/filter_options_api_service.dart';

/// Estado para las opciones de filtros
class FilterOptionsState {
  final FilterOptions? options;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastLoadedAt;

  const FilterOptionsState({
    this.options,
    this.isLoading = false,
    this.errorMessage,
    this.lastLoadedAt,
  });

  FilterOptionsState copyWith({
    FilterOptions? options,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastLoadedAt,
    bool clearError = false,
  }) {
    return FilterOptionsState(
      options: options ?? this.options,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastLoadedAt: lastLoadedAt ?? this.lastLoadedAt,
    );
  }

  /// Verifica si los datos necesitan ser recargados
  /// Se considera que necesitan recarga si:
  /// - No hay opciones cargadas
  /// - Han pasado más de 5 minutos desde la última carga
  bool get needsReload {
    if (options == null) return true;
    if (lastLoadedAt == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastLoadedAt!);
    return difference.inMinutes > 5;
  }
}

/// Notifier para gestionar el estado de opciones de filtros
class FilterOptionsNotifier extends StateNotifier<FilterOptionsState> {
  final FilterOptionsApiService _apiService;

  FilterOptionsNotifier(this._apiService)
      : super(const FilterOptionsState());

  /// Carga las opciones de filtros desde el backend
  Future<void> loadFilterOptions({bool forceReload = false}) async {
    // Si ya está cargando, no hacer nada
    if (state.isLoading) return;

    // Si no necesita recarga y no es forzada, usar cache
    if (!forceReload && !state.needsReload) {
      print('📦 Usando opciones de filtros en cache');
      return;
    }

    print('🔄 Cargando opciones de filtros...');
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final options = await _apiService.getAllFilterOptions();

      state = state.copyWith(
        options: options,
        isLoading: false,
        lastLoadedAt: DateTime.now(),
      );

      print('✅ Opciones de filtros cargadas exitosamente');
    } catch (e) {
      print('❌ Error cargando opciones de filtros: $e');

      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar opciones de filtros: $e',
      );
    }
  }

  /// Obtiene las frecuencias disponibles
  List<FrequencyOption> get frequencies {
    return state.options?.frequencies ?? [];
  }

  /// Obtiene las categorías de clientes disponibles
  List<ClientCategoryOption> get clientCategories {
    return state.options?.clientCategories ?? [];
  }

  /// Obtiene los estados de créditos disponibles
  List<CreditStatusOption> get creditStatuses {
    return state.options?.creditStatuses ?? [];
  }

  /// Obtiene los métodos de pago disponibles
  List<PaymentMethodOption> get paymentMethods {
    return state.options?.paymentMethods ?? [];
  }

  /// Limpia el error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Limpia el cache (útil para logout o cambio de contexto)
  void clearCache() {
    state = const FilterOptionsState();
  }
}

/// Provider para las opciones de filtros
final filterOptionsProvider =
    StateNotifierProvider<FilterOptionsNotifier, FilterOptionsState>((ref) {
  final apiService = FilterOptionsApiService();
  return FilterOptionsNotifier(apiService);
});

/// Provider para acceso rápido a las frecuencias
final frequenciesProvider = Provider<List<FrequencyOption>>((ref) {
  return ref.watch(filterOptionsProvider.notifier).frequencies;
});

/// Provider para acceso rápido a las categorías
final clientCategoriesProvider = Provider<List<ClientCategoryOption>>((ref) {
  return ref.watch(filterOptionsProvider.notifier).clientCategories;
});

/// Provider para acceso rápido a los estados
final creditStatusesProvider = Provider<List<CreditStatusOption>>((ref) {
  return ref.watch(filterOptionsProvider.notifier).creditStatuses;
});

/// Provider para acceso rápido a los métodos de pago
final paymentMethodsProvider = Provider<List<PaymentMethodOption>>((ref) {
  return ref.watch(filterOptionsProvider.notifier).paymentMethods;
});
