class Usuario {
  final BigInt id;
  final BigInt? assignedCobradorId;
  final String nombre;
  final String email;
  final String profileImage;
  final String telefono;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final List<String> roles;

  Usuario({
    required this.id,
    this.assignedCobradorId,
    required this.nombre,
    required this.email,
    required this.profileImage,
    required this.telefono,
    required this.direccion,
    this.latitud,
    this.longitud,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.roles,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: imprimir el JSON recibido
      print('🔍 DEBUG: Parsing usuario JSON: $json');

      // Manejar diferentes formatos de ID
      BigInt id;
      if (json['id'] is String) {
        id = BigInt.parse(json['id']);
      } else if (json['id'] is int) {
        id = BigInt.from(json['id']);
      } else {
        id = BigInt.one; // Valor por defecto
      }

      BigInt? assignedCobradorId;
      if (json['assigned_cobrador_id'] is String) {
        assignedCobradorId = BigInt.parse(json['assigned_cobrador_id']);
      } else if (json['assigned_cobrador_id'] is int) {
        assignedCobradorId = BigInt.from(json['assigned_cobrador_id']);
      }

      // Manejar diferentes formatos de roles
      List<String> roles = [];
      if (json['roles'] is List) {
        roles = (json['roles'] as List)
            .map((role) {
              if (role is Map<String, dynamic>) {
                return role['name']?.toString() ?? '';
              } else if (role is String) {
                return role;
              } else {
                return '';
              }
            })
            .where((role) => role.isNotEmpty)
            .toList();
      }

      // Manejar fechas con diferentes formatos
      DateTime fechaCreacion;
      try {
        fechaCreacion = DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String(),
        );
      } catch (e) {
        fechaCreacion = DateTime.now();
      }

      DateTime fechaActualizacion;
      try {
        fechaActualizacion = DateTime.parse(
          json['updated_at'] ?? DateTime.now().toIso8601String(),
        );
      } catch (e) {
        fechaActualizacion = DateTime.now();
      }

      return Usuario(
        id: id,
        assignedCobradorId: assignedCobradorId,
        nombre: json['name']?.toString() ?? '',
        profileImage: json['profile_image']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        telefono: json['phone']?.toString() ?? '',
        direccion: json['address']?.toString() ?? '',
        latitud: json['location']?['coordinates']?[1]?.toDouble(),
        longitud: json['location']?['coordinates']?[0]?.toDouble(),
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion,
        roles: roles,
      );
    } catch (e) {
      print('❌ ERROR parsing Usuario.fromJson: $e');
      print('❌ JSON que causó el error: $json');
      // Retornar un usuario por defecto en caso de error
      return Usuario(
        id: BigInt.one,
        assignedCobradorId: null,
        nombre: 'Usuario Error',
        email: 'error@example.com',
        profileImage: '',
        telefono: '',
        direccion: '',
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        roles: ['client'],
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'assigned_cobrador_id': assignedCobradorId?.toString(),
      'name': nombre,
      'email': email,
      'profile_image': profileImage,
      'phone': telefono,
      'address': direccion,
      'location': latitud != null && longitud != null
          ? {
              'type': 'Point',
              'coordinates': [longitud, latitud],
            }
          : null,
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion.toIso8601String(),
      'roles':
          roles, // Guardar como lista simple de strings para almacenamiento local
    };
  }

  // Método para serializar en formato API (con roles como objetos)
  Map<String, dynamic> toApiJson() {
    return {
      'id': id.toString(),
      'assigned_cobrador_id': assignedCobradorId?.toString(),
      'name': nombre,
      'email': email,
      'profile_image': profileImage,
      'phone': telefono,
      'address': direccion,
      'location': latitud != null && longitud != null
          ? {
              'type': 'Point',
              'coordinates': [longitud, latitud],
            }
          : null,
      'created_at': fechaCreacion.toIso8601String(),
      'updated_at': fechaActualizacion.toIso8601String(),
      'roles': roles.map((role) => {'name': role}).toList(), // Formato API
    };
  }

  bool tieneRol(String rol) {
    final tiene = roles.contains(rol);
    print(
      '🔍 DEBUG: Verificando rol "$rol" - Resultado: $tiene (Roles disponibles: $roles)',
    );
    return tiene;
  }

  bool esCobrador() => tieneRol('cobrador');
  bool esCliente() => tieneRol('cliente');
  bool esJefe() => tieneRol('jefe');
  bool esAdmin() => tieneRol('admin');
  bool esManager() => tieneRol('manager');

  Usuario copyWith({
    BigInt? id,
    BigInt? assignedCobradorId,
    String? nombre,
    String? email,
    String? profileImage,
    String? telefono,
    String? direccion,
    double? latitud,
    double? longitud,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    List<String>? roles,
  }) {
    return Usuario(
      id: id ?? this.id,
      assignedCobradorId: assignedCobradorId ?? this.assignedCobradorId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      roles: roles ?? this.roles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Usuario{id: $id, nombre: $nombre, email: $email, roles: $roles}';
  }
}
