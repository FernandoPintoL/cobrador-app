class Usuario {
  final BigInt id;
  final BigInt? assignedCobradorId;
  final BigInt? assignedManagerId;
  final String nombre;
  final String email;
  final String profileImage;
  final String telefono;
  final String direccion;
  final String ci;
  final double? latitud;
  final double? longitud;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final List<String> roles;
  final String? clientCategory; // 'A', 'B', or 'C'
  final int? assignedClientsCount; // Número de clientes asignados (para cobradores)

  Usuario({
    required this.id,
    this.assignedCobradorId,
    this.assignedManagerId,
    required this.nombre,
    required this.email,
    required this.profileImage,
    required this.telefono,
    required this.direccion,
    required this.ci,
    this.latitud,
    this.longitud,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.roles,
    this.clientCategory,
    this.assignedClientsCount,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    try {
      // Debug: imprimir el JSON recibido
      // print('🔍 DEBUG: Parsing usuario JSON: $json');

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

      BigInt? assignedManagerId;
      if (json['assigned_manager_id'] is String) {
        assignedManagerId = BigInt.parse(json['assigned_manager_id']);
      } else if (json['assigned_manager_id'] is int) {
        assignedManagerId = BigInt.from(json['assigned_manager_id']);
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

      // Parsear coordenadas con debug
      double? latitud =
          _parseDouble(json['latitude']) ??
          _parseDouble(json['latitud']) ??
          json['location']?['coordinates']?[1]?.toDouble();

      double? longitud =
          _parseDouble(json['longitude']) ??
          _parseDouble(json['longitud']) ??
          json['location']?['coordinates']?[0]?.toDouble();

      // Debug de coordenadas
      /* print(
        '🗺️ DEBUG coordenadas - Usuario: ${json['name']} | Lat: $latitud | Lng: $longitud',
      );
      print(
        '🗺️ JSON original - latitude: ${json['latitude']} | longitude: ${json['longitude']}',
      ); */

      return Usuario(
        id: id,
        assignedCobradorId: assignedCobradorId,
        assignedManagerId: assignedManagerId,
        nombre: json['name']?.toString() ?? '',
        profileImage:
            (json['profile_image_url']?.toString() ??
            json['profile_image']?.toString() ??
            ''),
        email: json['email']?.toString() ?? '',
        telefono: json['phone']?.toString() ?? '',
        direccion: json['address']?.toString() ?? '',
        ci: json['ci']?.toString() ?? '',
        latitud: latitud,
        longitud: longitud,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion,
        roles: roles,
        clientCategory: json['client_category']?.toString(),
        assignedClientsCount: json['assigned_clients_count'] is int
            ? json['assigned_clients_count']
            : (json['assigned_clients_count'] != null
                ? int.tryParse(json['assigned_clients_count'].toString())
                : null),
      );
    } catch (e) {
      print('❌ ERROR parsing Usuario.fromJson: $e');
      print('❌ JSON que causó el error: $json');
      // Retornar un usuario por defecto en caso de error
      return Usuario(
        id: BigInt.one,
        assignedCobradorId: null,
        assignedManagerId: null,
        nombre: 'Usuario Error',
        email: 'error@example.com',
        profileImage: '',
        telefono: '',
        direccion: '',
        ci: '',
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
        roles: ['client'],
        clientCategory: 'B',
        assignedClientsCount: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'assigned_cobrador_id': assignedCobradorId?.toString(),
      'assigned_manager_id': assignedManagerId?.toString(),
      'name': nombre,
      'email': email,
      'profile_image': profileImage,
      'phone': telefono,
      'address': direccion,
      'ci': ci,
      'client_category': clientCategory,
      'assigned_clients_count': assignedClientsCount,
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
      'assigned_manager_id': assignedManagerId?.toString(),
      'name': nombre,
      'email': email,
      'profile_image': profileImage,
      'phone': telefono,
      'address': direccion,
      'ci': ci,
      'client_category': clientCategory,
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
    /* print(
      '🔍 DEBUG: Verificando rol "$rol" - Resultado: $tiene (Roles disponibles: $roles)',
    ); */
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
    BigInt? assignedManagerId,
    String? nombre,
    String? email,
    String? profileImage,
    String? telefono,
    String? direccion,
    String? ci,
    double? latitud,
    double? longitud,
    DateTime? fechaCreacion,
    DateTime? fechaActualizacion,
    List<String>? roles,
    String? clientCategory,
  }) {
    return Usuario(
      id: id ?? this.id,
      assignedCobradorId: assignedCobradorId ?? this.assignedCobradorId,
      assignedManagerId: assignedManagerId ?? this.assignedManagerId,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      telefono: telefono ?? this.telefono,
      direccion: direccion ?? this.direccion,
      ci: ci ?? this.ci,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
      roles: roles ?? this.roles,
      clientCategory: clientCategory ?? this.clientCategory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Usuario && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  String get clientCategoryName {
    switch ((clientCategory ?? 'B').toUpperCase()) {
      case 'A':
        return 'Cliente VIP';
      case 'C':
        return 'Mal Cliente';
      default:
        return 'Cliente Normal';
    }
  }

  bool get isVipClient => (clientCategory ?? 'B').toUpperCase() == 'A';
  bool get isNormalClient => (clientCategory ?? 'B').toUpperCase() == 'B';
  bool get isBadClient => (clientCategory ?? 'B').toUpperCase() == 'C';

  @override
  String toString() {
    return 'Usuario{id: $id, nombre: $nombre, email: $email, ci: $ci, roles: $roles, clientCategory: $clientCategory}';
  }

  // Función auxiliar para parsear doubles de forma segura
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;

    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('⚠️ Warning: No se pudo parsear "$value" como double: $e');
        return null;
      }
    }

    return null;
  }
}
