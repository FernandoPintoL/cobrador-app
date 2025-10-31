import '../modelos/filter_options.dart';
import 'base_api_service.dart';

class FilterOptionsApiService extends BaseApiService {
  FilterOptionsApiService() : super();

  /// Obtiene las frecuencias disponibles desde el backend
  Future<List<FrequencyOption>> getAvailableFrequencies() async {
    try {
      print('🔧 Obteniendo frecuencias disponibles...');

      final response = await get('/credits/frequencies/available');

      if (response.statusCode == 200) {
        final data = response.data;
        final frequencies = (data['data'] as List<dynamic>)
            .map((e) => FrequencyOption.fromJson(e as Map<String, dynamic>))
            .toList();

        print('✅ Frecuencias obtenidas: ${frequencies.length}');
        return frequencies;
      } else {
        print('❌ Error obteniendo frecuencias: ${response.statusCode}');
        throw Exception('Error al obtener frecuencias disponibles');
      }
    } catch (e) {
      print('❌ Excepción obteniendo frecuencias: $e');
      rethrow;
    }
  }

  /// Obtiene las categorías de clientes desde el backend
  Future<List<ClientCategoryOption>> getClientCategories() async {
    try {
      print('🔧 Obteniendo categorías de clientes...');

      final response = await get('/client-categories');

      if (response.statusCode == 200) {
        final data = response.data;
        final categories = (data['data'] as List<dynamic>)
            .map((e) => ClientCategoryOption.fromJson(e as Map<String, dynamic>))
            .toList();

        print('✅ Categorías obtenidas: ${categories.length}');
        return categories;
      } else {
        print('❌ Error obteniendo categorías: ${response.statusCode}');
        throw Exception('Error al obtener categorías de clientes');
      }
    } catch (e) {
      print('❌ Excepción obteniendo categorías: $e');
      rethrow;
    }
  }

  /// Obtiene todas las opciones de filtros en una sola llamada
  Future<FilterOptions> getAllFilterOptions() async {
    try {
      print('🔧 Obteniendo todas las opciones de filtros...');

      // Hacer las llamadas en paralelo para mejor rendimiento
      final results = await Future.wait([
        getAvailableFrequencies(),
        getClientCategories(),
      ]);

      final frequencies = results[0] as List<FrequencyOption>;
      final categories = results[1] as List<ClientCategoryOption>;

      // Estados de créditos hardcoded por ahora (podrían venir del backend también)
      final creditStatuses = [
        const CreditStatusOption(
          value: 'active',
          label: 'Activos',
          description: 'Créditos activos en proceso',
        ),
        const CreditStatusOption(
          value: 'pending_approval',
          label: 'Pendientes',
          description: 'Créditos pendientes de aprobación',
        ),
        const CreditStatusOption(
          value: 'waiting_delivery',
          label: 'En Espera',
          description: 'Créditos esperando entrega',
        ),
        const CreditStatusOption(
          value: 'approved',
          label: 'Aprobados',
          description: 'Créditos aprobados',
        ),
        const CreditStatusOption(
          value: 'completed',
          label: 'Completados',
          description: 'Créditos completamente pagados',
        ),
      ];

      // Métodos de pago hardcoded por ahora
      final paymentMethods = [
        const PaymentMethodOption(value: 'cash', label: 'Efectivo'),
        const PaymentMethodOption(value: 'transfer', label: 'Transferencia'),
        const PaymentMethodOption(value: 'card', label: 'Tarjeta'),
        const PaymentMethodOption(
          value: 'mobile_payment',
          label: 'Pago Móvil',
        ),
      ];

      final filterOptions = FilterOptions(
        frequencies: frequencies,
        clientCategories: categories,
        creditStatuses: creditStatuses,
        paymentMethods: paymentMethods,
      );

      print('✅ Opciones de filtros obtenidas exitosamente');
      return filterOptions;
    } catch (e) {
      print('❌ Error obteniendo opciones de filtros: $e');

      // Retornar opciones por defecto en caso de error
      return FilterOptions(
        frequencies: _getDefaultFrequencies(),
        clientCategories: _getDefaultCategories(),
        creditStatuses: _getDefaultCreditStatuses(),
        paymentMethods: _getDefaultPaymentMethods(),
      );
    }
  }

  // Métodos de fallback con valores por defecto
  List<FrequencyOption> _getDefaultFrequencies() {
    return const [
      FrequencyOption(
        value: 'daily',
        label: 'Diaria',
        description: 'Pago todos los días',
      ),
      FrequencyOption(
        value: 'weekly',
        label: 'Semanal',
        description: 'Pago una vez por semana',
      ),
      FrequencyOption(
        value: 'biweekly',
        label: 'Quincenal',
        description: 'Pago cada dos semanas',
      ),
      FrequencyOption(
        value: 'monthly',
        label: 'Mensual',
        description: 'Pago una vez al mes',
      ),
    ];
  }

  List<ClientCategoryOption> _getDefaultCategories() {
    return const [
      ClientCategoryOption(
        category: 'A',
        label: 'Categoría A - Premium',
        description: 'Clientes con excelente historial',
        totalClients: 0,
      ),
      ClientCategoryOption(
        category: 'B',
        label: 'Categoría B - Regular',
        description: 'Clientes con historial regular',
        totalClients: 0,
      ),
      ClientCategoryOption(
        category: 'C',
        label: 'Categoría C - Nuevo',
        description: 'Clientes nuevos',
        totalClients: 0,
      ),
    ];
  }

  List<CreditStatusOption> _getDefaultCreditStatuses() {
    return const [
      CreditStatusOption(
        value: 'active',
        label: 'Activos',
        description: 'Créditos activos en proceso',
      ),
      CreditStatusOption(
        value: 'pending_approval',
        label: 'Pendientes',
        description: 'Créditos pendientes de aprobación',
      ),
      CreditStatusOption(
        value: 'waiting_delivery',
        label: 'En Espera',
        description: 'Créditos esperando entrega',
      ),
    ];
  }

  List<PaymentMethodOption> _getDefaultPaymentMethods() {
    return const [
      PaymentMethodOption(value: 'cash', label: 'Efectivo'),
      PaymentMethodOption(value: 'transfer', label: 'Transferencia'),
      PaymentMethodOption(value: 'card', label: 'Tarjeta'),
      PaymentMethodOption(value: 'mobile_payment', label: 'Pago Móvil'),
    ];
  }
}
