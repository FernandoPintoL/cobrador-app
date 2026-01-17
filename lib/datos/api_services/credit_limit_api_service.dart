import 'base_api_service.dart';
import '../modelos/client_category.dart';

/// Servicio API para gestión de límites de crédito
class CreditLimitApiService extends BaseApiService {
  static final CreditLimitApiService _instance =
      CreditLimitApiService._internal();
  factory CreditLimitApiService() => _instance;
  CreditLimitApiService._internal();

  // ================== MÉTODOS PARA CATEGORÍAS ==================

  /// Obtiene todas las categorías de cliente con sus límites
  Future<List<ClientCategory>> getAllCategories() async {
    try {
      print('📋 Obteniendo todas las categorías de cliente');

      final response = await get('/client-categories/all');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final categoriesJson = data['data'] as List<dynamic>? ?? [];
        final categories = categoriesJson
            .map((json) => ClientCategory.fromJson(json as Map<String, dynamic>))
            .toList();
        print('✅ ${categories.length} categorías obtenidas');
        return categories;
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener categorías: $e');
      throw Exception('Error al obtener categorías: $e');
    }
  }

  /// Obtiene una categoría por código
  Future<ClientCategory> getCategoryByCode(String code) async {
    try {
      print('📋 Obteniendo categoría: $code');

      final response = await get('/client-categories/$code/details');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return ClientCategory.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception('Error al obtener categoría: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error al obtener categoría: $e');
      throw Exception('Error al obtener categoría: $e');
    }
  }

  /// Actualiza los límites de una categoría
  Future<ClientCategory> updateCategoryLimits(
    String code, {
    double? maxAmount,
    double? minAmount,
    int? maxCredits,
  }) async {
    try {
      print('📋 Actualizando límites de categoría: $code');

      final body = <String, dynamic>{};
      if (maxAmount != null) body['max_amount'] = maxAmount;
      if (minAmount != null) body['min_amount'] = minAmount;
      if (maxCredits != null) body['max_credits'] = maxCredits;

      final response = await patch('/client-categories/$code/limits', data: body);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Límites de categoría actualizados');
        return ClientCategory.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Error al actualizar límites de categoría: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al actualizar límites de categoría: $e');
      throw Exception('Error al actualizar límites de categoría: $e');
    }
  }

  /// Obtiene estadísticas extendidas por categoría
  Future<List<Map<String, dynamic>>> getCategoryStats() async {
    try {
      print('📋 Obteniendo estadísticas por categoría');

      final response = await get('/client-categories/stats-extended');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final stats = (data['data'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];
        print('✅ Estadísticas obtenidas');
        return stats;
      } else {
        throw Exception(
          'Error al obtener estadísticas: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener estadísticas: $e');
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // ================== MÉTODOS PARA LÍMITES INDIVIDUALES ==================

  /// Obtiene los límites de crédito de un cliente
  Future<ClientCreditLimits> getClientCreditLimits(String clientId) async {
    try {
      print('📋 Obteniendo límites de crédito del cliente: $clientId');

      final response = await get('/users/$clientId/credit-limits');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Límites del cliente obtenidos');
        return ClientCreditLimits.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Error al obtener límites del cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al obtener límites del cliente: $e');
      throw Exception('Error al obtener límites del cliente: $e');
    }
  }

  /// Actualiza los límites de crédito individuales de un cliente
  Future<ClientCreditLimits> updateClientCreditLimits(
    String clientId, {
    double? creditLimitOverride,
    int? maxCreditsOverride,
  }) async {
    try {
      print('📋 Actualizando límites de crédito del cliente: $clientId');

      final body = <String, dynamic>{};
      // Incluir el campo incluso si es null para poder limpiar el override
      body['credit_limit_override'] = creditLimitOverride;
      body['max_credits_override'] = maxCreditsOverride;

      final response = await patch('/users/$clientId/credit-limits', data: body);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Límites del cliente actualizados');
        return ClientCreditLimits.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Error al actualizar límites del cliente: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al actualizar límites del cliente: $e');
      throw Exception('Error al actualizar límites del cliente: $e');
    }
  }

  /// Elimina los límites personalizados de un cliente (vuelve a usar los de categoría)
  Future<ClientCreditLimits> clearClientCreditLimits(String clientId) async {
    try {
      print('📋 Eliminando límites personalizados del cliente: $clientId');

      final response = await delete('/users/$clientId/credit-limits');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('✅ Límites personalizados eliminados');
        return ClientCreditLimits.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        throw Exception(
          'Error al eliminar límites personalizados: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error al eliminar límites personalizados: $e');
      throw Exception('Error al eliminar límites personalizados: $e');
    }
  }
}
