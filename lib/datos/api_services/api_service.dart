// ARCHIVO DEPRECADO - USO SOLO PARA RETROCOMPATIBILIDAD
// Los nuevos servicios están separados en archivos específicos:
// - auth_api_service.dart - Para autenticación
// - user_api_service.dart - Para gestión de usuarios
// - client_api_service.dart - Para gestión de clientes
// - credit_api_service.dart - Para gestión de créditos
// - payment_api_service.dart - Para gestión de pagos

import 'auth_api_service.dart';
import 'client_api_service.dart';
import 'credit_api_service.dart';
import 'user_api_service.dart';

/// DEPRECADO: Usar los servicios específicos en su lugar
/// Esta clase se mantiene solo para retrocompatibilidad
class ApiService {
  // Instancia singleton para retrocompatibilidad
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Delegates a los servicios específicos
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) =>
      AuthApiService().login(emailOrPhone, password);

  Future<void> logout() => AuthApiService().logout();

  Future<Map<String, dynamic>> getMe() => AuthApiService().getMe();

  Future<Map<String, dynamic>> checkExists(String emailOrPhone) =>
      AuthApiService().checkExists(emailOrPhone);

  Future<bool> hasValidSession() => AuthApiService().hasValidSession();

  Future<bool> restoreSession() => AuthApiService().restoreSession();

  // Métodos de usuario/cliente
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> clientData) =>
      ClientApiService().createClient(clientData);

  Future<Map<String, dynamic>> updateClient(
    String clientId,
    Map<String, dynamic> clientData,
  ) => ClientApiService().updateClient(clientId, clientData);

  Future<Map<String, dynamic>> deleteClient(String clientId) =>
      ClientApiService().deleteClient(clientId);

  Future<Map<String, dynamic>> getCobradorClients(
    String cobradorId, {
    String? search,
    int? perPage,
  }) => ClientApiService().getCobradorClients(
    cobradorId,
    search: search,
    perPage: perPage,
  );

  Future<Map<String, dynamic>> assignClientsToCollector(
    String cobradorId,
    List<String> clientIds,
  ) => ClientApiService().assignClientsToCollector(cobradorId, clientIds);

  Future<Map<String, dynamic>> removeClientFromCollector(
    String cobradorId,
    String clientId,
  ) => ClientApiService().removeClientFromCollector(cobradorId, clientId);

  Future<Map<String, dynamic>> getClientCobrador(String clientId) =>
      ClientApiService().getClientCobrador(clientId);

  // Métodos de créditos
  Future<Map<String, dynamic>> getCredits({
    int? clientId,
    int? cobradorId,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) => CreditApiService().getCredits(
    clientId: clientId,
    cobradorId: cobradorId,
    status: status,
    search: search,
    page: page,
    perPage: perPage,
  );

  Future<Map<String, dynamic>> createCredit(Map<String, dynamic> creditData) =>
      CreditApiService().createCredit(creditData);

  Future<Map<String, dynamic>> getCredit(int creditId) =>
      CreditApiService().getCredit(creditId);

  Future<Map<String, dynamic>> updateCredit(
    int creditId,
    Map<String, dynamic> creditData,
  ) => CreditApiService().updateCredit(creditId, creditData);

  Future<Map<String, dynamic>> deleteCredit(int creditId) =>
      CreditApiService().deleteCredit(creditId);

  Future<Map<String, dynamic>> getClientCredits(
    int clientId, {
    String? status,
    String? frequency,
    String? startDateFrom,
    String? startDateTo,
    String? endDateFrom,
    String? endDateTo,
    double? amountMin,
    double? amountMax,
    double? balanceMin,
    double? balanceMax,
    int page = 1,
    int perPage = 50,
  }) => CreditApiService().getClientCredits(
    clientId,
    status: status,
    frequency: frequency,
    startDateFrom: startDateFrom,
    startDateTo: startDateTo,
    endDateFrom: endDateFrom,
    endDateTo: endDateTo,
    amountMin: amountMin,
    amountMax: amountMax,
    balanceMin: balanceMin,
    balanceMax: balanceMax,
    page: page,
    perPage: perPage,
  );

  Future<Map<String, dynamic>> getCobradorCredits(
    int cobradorId, {
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) => CreditApiService().getCobradorCredits(
    cobradorId,
    status: status,
    search: search,
    page: page,
    perPage: perPage,
  );

  Future<Map<String, dynamic>> getCobradorStats(int cobradorId) =>
      CreditApiService().getCobradorStats(cobradorId);

  Future<Map<String, dynamic>> getCreditsRequiringAttention({
    int page = 1,
    int perPage = 50,
  }) => CreditApiService().getCreditsRequiringAttention(
    page: page,
    perPage: perPage,
  );

  // Métodos de imágenes de perfil (delegados a UserApiService)
  Future<Map<String, dynamic>> uploadProfileImage(dynamic imageFile) =>
      UserApiService().uploadProfileImage(imageFile);

  Future<Map<String, dynamic>> uploadUserProfileImage(
    BigInt userId,
    dynamic imageFile,
  ) => UserApiService().uploadUserProfileImage(userId, imageFile);

  String getProfileImageUrl(String? profileImage) =>
      UserApiService().getProfileImageUrl(profileImage);

  Future<Map<String, dynamic>> deleteProfileImage() =>
      UserApiService().deleteProfileImage();

  // Obtener usuario local (delegado a AuthApiService)
  Future<dynamic> getLocalUser() => AuthApiService().getLocalUser();
}
