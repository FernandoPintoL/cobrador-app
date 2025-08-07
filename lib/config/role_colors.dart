import 'package:flutter/material.dart';

/// Configuración de colores para cada rol del sistema
class RoleColors {
  // Colores primarios para cada rol
  static const Color adminPrimary = Color(0xFF8B0000); // Rojo oscuro
  static const Color adminSecondary = Color(0xFFCD5C5C); // Rojo claro
  static const Color adminAccent = Color(0xFFFFE4E1); // Rosa muy claro

  static const Color managerPrimary = Color(0xFF1565C0); // Azul oscuro
  static const Color managerSecondary = Color(0xFF42A5F5); // Azul claro
  static const Color managerAccent = Color(0xFFE3F2FD); // Azul muy claro

  static const Color cobradorPrimary = Color(0xFF2E7D32); // Verde oscuro
  static const Color cobradorSecondary = Color(0xFF66BB6A); // Verde claro
  static const Color cobradorAccent = Color(0xFFE8F5E8); // Verde muy claro

  static const Color clientePrimary = Color(0xFF7B1FA2); // Púrpura oscuro
  static const Color clienteSecondary = Color(0xFFBA68C8); // Púrpura claro
  static const Color clienteAccent = Color(0xFFF3E5F5); // Púrpura muy claro

  /// Obtiene el color primario según el rol
  static Color getPrimaryColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminPrimary;
      case 'manager':
        return managerPrimary;
      case 'cobrador':
        return cobradorPrimary;
      case 'client':
      case 'cliente':
        return clientePrimary;
      default:
        return Colors.grey[700]!;
    }
  }

  /// Obtiene el color secundario según el rol
  static Color getSecondaryColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminSecondary;
      case 'manager':
        return managerSecondary;
      case 'cobrador':
        return cobradorSecondary;
      case 'client':
      case 'cliente':
        return clienteSecondary;
      default:
        return Colors.grey[500]!;
    }
  }

  /// Obtiene el color de acento según el rol
  static Color getAccentColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminAccent;
      case 'manager':
        return managerAccent;
      case 'cobrador':
        return cobradorAccent;
      case 'client':
      case 'cliente':
        return clienteAccent;
      default:
        return Colors.grey[100]!;
    }
  }

  /// Obtiene un gradiente según el rol
  static LinearGradient getGradient(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [adminPrimary, adminSecondary],
        );
      case 'manager':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [managerPrimary, managerSecondary],
        );
      case 'cobrador':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cobradorPrimary, cobradorSecondary],
        );
      case 'client':
      case 'cliente':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [clientePrimary, clienteSecondary],
        );
      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[700]!, Colors.grey[500]!],
        );
    }
  }

  /// Obtiene el nombre legible del rol
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Manager';
      case 'cobrador':
        return 'Cobrador';
      case 'client':
      case 'cliente':
        return 'Cliente';
      default:
        return 'Usuario';
    }
  }

  /// Obtiene el icono representativo del rol
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.supervisor_account;
      case 'cobrador':
        return Icons.person_pin;
      case 'client':
      case 'cliente':
        return Icons.people;
      default:
        return Icons.person;
    }
  }
}
