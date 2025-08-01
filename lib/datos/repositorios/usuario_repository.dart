import '../modelos/usuario.dart';

abstract class UsuarioRepository {
  Future<List<Usuario>> obtenerTodos();
  Future<Usuario?> obtenerPorId(BigInt id);
  Future<Usuario> crear(Usuario usuario);
  Future<Usuario> actualizar(Usuario usuario);
  Future<void> eliminar(BigInt id);
  Future<List<Usuario>> obtenerClientes();
  Future<List<Usuario>> obtenerCobradores();
}

class UsuarioRepositoryImpl implements UsuarioRepository {
  // TODO: Implementar con ApiService cuando las dependencias estén disponibles

  @override
  Future<List<Usuario>> obtenerTodos() async {
    // Implementación temporal
    return [];
  }

  @override
  Future<Usuario?> obtenerPorId(BigInt id) async {
    // Implementación temporal
    return null;
  }

  @override
  Future<Usuario> crear(Usuario usuario) async {
    // Implementación temporal
    return usuario;
  }

  @override
  Future<Usuario> actualizar(Usuario usuario) async {
    // Implementación temporal
    return usuario;
  }

  @override
  Future<void> eliminar(BigInt id) async {
    // Implementación temporal
  }

  @override
  Future<List<Usuario>> obtenerClientes() async {
    // Implementación temporal
    return [];
  }

  @override
  Future<List<Usuario>> obtenerCobradores() async {
    // Implementación temporal
    return [];
  }
}
