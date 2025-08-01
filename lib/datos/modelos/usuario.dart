class Usuario {
  final BigInt id;
  final String nombre;
  final String email;
  final String telefono;
  final String direccion;
  final double? latitud;
  final double? longitud;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final List<String> roles;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.direccion,
    this.latitud,
    this.longitud,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.roles,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: BigInt.parse(json['id'].toString()),
      nombre: json['name'] ?? '',
      email: json['email'] ?? '',
      telefono: json['phone'] ?? '',
      direccion: json['address'] ?? '',
      latitud: json['location']?['coordinates']?[1]?.toDouble(),
      longitud: json['location']?['coordinates']?[0]?.toDouble(),
      fechaCreacion: DateTime.parse(json['created_at']),
      fechaActualizacion: DateTime.parse(json['updated_at']),
      roles: List<String>.from(
        json['roles']?.map((role) => role['name']) ?? [],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.toString(),
      'name': nombre,
      'email': email,
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
      'roles': roles.map((role) => {'name': role}).toList(),
    };
  }

  bool tieneRol(String rol) => roles.contains(rol);
  bool esCobrador() => tieneRol('cobrador');
  bool esCliente() => tieneRol('cliente');
  bool esJefe() => tieneRol('jefe');

  Usuario copyWith({
    BigInt? id,
    String? nombre,
    String? email,
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
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
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
