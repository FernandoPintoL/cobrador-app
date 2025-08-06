// Exportaciones de todos los servicios API
export 'base_api_service.dart';
export 'auth_api_service.dart';
export 'user_api_service.dart';
export 'client_api_service.dart';
export 'credit_api_service.dart';
export 'payment_api_service.dart';
export 'manager_api_service.dart';

// Importaciones para uso interno
import 'auth_api_service.dart';
import 'user_api_service.dart';
import 'client_api_service.dart';
import 'credit_api_service.dart';
import 'payment_api_service.dart';
import 'manager_api_service.dart';

// Clase fachada que combina todos los servicios para retrocompatibilidad
class ApiService {
  // Singleton instances
  static final AuthApiService auth = AuthApiService();
  static final UserApiService users = UserApiService();
  static final ClientApiService clients = ClientApiService();
  static final CreditApiService credits = CreditApiService();
  static final PaymentApiService payments = PaymentApiService();
  static final ManagerApiService managers = ManagerApiService();

  // Métodos de conveniencia para mantener retrocompatibilidad
  // Autenticación
  Future<Map<String, dynamic>> login(String emailOrPhone, String password) =>
      auth.login(emailOrPhone, password);

  Future<void> logout() => auth.logout();

  Future<Map<String, dynamic>> getMe() => auth.getMe();

  Future<Map<String, dynamic>> checkExists(String emailOrPhone) =>
      auth.checkExists(emailOrPhone);

  // Usuarios
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) =>
      users.createUser(userData);

  Future<Map<String, dynamic>> updateUser(
    String userId,
    Map<String, dynamic> userData,
  ) => users.updateUser(userId, userData);

  Future<Map<String, dynamic>> deleteUser(String userId) =>
      users.deleteUser(userId);

  // Clientes
  Future<Map<String, dynamic>> createClient(Map<String, dynamic> clientData) =>
      clients.createClient(clientData);

  Future<Map<String, dynamic>> updateClient(
    String clientId,
    Map<String, dynamic> clientData,
  ) => clients.updateClient(clientId, clientData);

  Future<Map<String, dynamic>> deleteClient(String clientId) =>
      clients.deleteClient(clientId);

  // Créditos
  Future<Map<String, dynamic>> getCredits({
    int? clientId,
    int? cobradorId,
    String? status,
    String? search,
    int page = 1,
    int perPage = 50,
  }) => credits.getCredits(
    clientId: clientId,
    cobradorId: cobradorId,
    status: status,
    search: search,
    page: page,
    perPage: perPage,
  );

  Future<Map<String, dynamic>> createCredit(Map<String, dynamic> creditData) =>
      credits.createCredit(creditData);

  Future<Map<String, dynamic>> getCredit(int creditId) =>
      credits.getCredit(creditId);

  Future<Map<String, dynamic>> updateCredit(
    int creditId,
    Map<String, dynamic> creditData,
  ) => credits.updateCredit(creditId, creditData);

  Future<Map<String, dynamic>> deleteCredit(int creditId) =>
      credits.deleteCredit(creditId);

  // Otros métodos que pueden ser necesarios para retrocompatibilidad
  Future<bool> hasValidSession() => auth.hasValidSession();
  Future<bool> restoreSession() => auth.restoreSession();
}
