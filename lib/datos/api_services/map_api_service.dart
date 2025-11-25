import 'package:dio/dio.dart';
import 'base_api_service.dart';

/// Servicio API para endpoints del mapa (coordenadas, clientes, stats y rutas)
class MapApiService extends BaseApiService {
  static final MapApiService _instance = MapApiService._internal();
  factory MapApiService() => _instance;
  MapApiService._internal();

  /// GET /api/map/coordinates
  Future<Map<String, dynamic>> getCoordinates({int? cobradorId}) async {
    try {
      final query = <String, dynamic>{};
      if (cobradorId != null) query['cobrador_id'] = cobradorId;
      final resp = await get('/map/coordinates', queryParameters: query);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener coordenadas: $e');
    }
  }

  /// GET /api/map/clients
  Future<Map<String, dynamic>> getClients({String? status, int? cobradorId}) async {
    try {
      final query = <String, dynamic>{};
      if (status != null) query['status'] = status;
      if (cobradorId != null) query['cobrador_id'] = cobradorId;
      final resp = await get('/map/clients', queryParameters: query);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener clientes del mapa: $e');
    }
  }

  /// GET /api/map/stats
  Future<Map<String, dynamic>> getStats({int? cobradorId}) async {
    try {
      final query = <String, dynamic>{};
      if (cobradorId != null) query['cobrador_id'] = cobradorId;
      final resp = await get('/map/stats', queryParameters: query);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener estadísticas del mapa: $e');
    }
  }

  /// GET /api/map/clients-by-area
  Future<Map<String, dynamic>> getClientsByArea({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    try {
      final query = <String, dynamic>{
        'north': north,
        'south': south,
        'east': east,
        'west': west,
      };
      final resp = await get('/map/clients-by-area', queryParameters: query);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener clientes por área: $e');
    }
  }

  /// GET /api/map/cobrador-routes
  Future<Map<String, dynamic>> getCobradorRoutes() async {
    try {
      final resp = await get('/map/cobrador-routes');
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener rutas de cobradores: $e');
    }
  }

  /// GET /api/map/location-clusters
  /// Endpoint unificado que trae clusters de ubicaciones con toda la información de clientes
  Future<Map<String, dynamic>> getLocationClusters({
    String? search,
    String? status,
    int? cobradorId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.isNotEmpty) query['search'] = search;
      if (status != null) query['status'] = status;
      if (cobradorId != null) query['cobrador_id'] = cobradorId;
      final resp = await get('/map/location-clusters', queryParameters: query);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener clusters de ubicaciones: $e');
    }
  }

  /// GET /api/map/clients-to-visit-today
  /// Obtiene lista de clientes que deben ser visitados hoy (para optimización de rutas)
  Future<Map<String, dynamic>> getClientsToVisitToday({int? cobradorId}) async {
    try {
      final query = <String, dynamic>{};
      if (cobradorId != null) query['cobrador_id'] = cobradorId;
      final resp = await get('/map/clients-to-visit-today', queryParameters: query);
      return Map<String, dynamic>.from(resp.data as Map);
    } on DioException catch (e) {
      throw Exception(handleDioError(e));
    } catch (e) {
      throw Exception('Error al obtener clientes para visitar: $e');
    }
  }
}
