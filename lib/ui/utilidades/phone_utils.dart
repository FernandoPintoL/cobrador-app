/// Utilidades para validación de teléfonos celulares soportando
/// Bolivia, Brasil, Colombia, Argentina y EEUU (USA).
///
/// La validación es pragmática: permite formatos comunes con o sin
/// código de país, manejando espacios, guiones y paréntesis.
library phone_utils;

class PhoneUtils {
  /// Normaliza el teléfono:
  /// - Convierte prefijo internacional '00' a '+'
  /// - Elimina espacios, guiones, paréntesis y otros separadores
  /// - Mantiene el signo '+' si existe
  static String normalize(String input) {
    var s = input.trim();
    // Reemplaza prefijo 00 por +
    if (s.startsWith('00')) {
      s = '+${s.substring(2)}';
    }
    // Mantener '+' inicial y dígitos, eliminar otros caracteres
    final hasPlus = s.startsWith('+');
    s = s.replaceAll(RegExp(r'\D'), '');
    if (hasPlus) s = '+$s';
    return s;
  }

  /// Retorna true si el teléfono pertenece a alguno de los países soportados
  /// bajo reglas comunes para CELULARES.
  static bool isValidSupportedPhone(String raw) {
    if (raw.trim().isEmpty) return false;
    final s = normalize(raw);
    final digits = s.replaceAll(RegExp(r'\D'), '');

    bool isBolivia() {
      // BO: móvil 8 dígitos iniciando con 6 o 7. Internacional: +591 + (6|7) + 7d
      return (digits.length == 8 && RegExp(r'^[67]\d{7}$').hasMatch(digits)) ||
          (RegExp(r'^591[67]\d{7}$').hasMatch(digits));
    }

    bool isBrazil() {
      // BR: 11 dígitos: (AA) 9 dddddddd. Internacional: +55 + 11 dígitos
      return (digits.length == 11 && RegExp(r'^[1-9]\d9\d{8}$').hasMatch(digits)) ||
          (RegExp(r'^55[1-9]\d9\d{8}$').hasMatch(digits));
    }

    bool isColombia() {
      // CO: móvil 10 dígitos iniciando con 3. Internacional: +57 + 3xxxxxxxxx
      return (digits.length == 10 && RegExp(r'^3\d{9}$').hasMatch(digits)) ||
          (RegExp(r'^57[3]\d{9}$').hasMatch(digits));
    }

    bool isArgentina() {
      // AR: Internacional móvil: +54 9 + 10 dígitos (área+línea)
      // Aceptamos también +54 + 10 dígitos (algunos casos antiguos) y formato local de CABA 11xxxxxxxx
      return RegExp(r'^549\d{10}$').hasMatch(digits) ||
          RegExp(r'^54\d{10}$').hasMatch(digits) ||
          RegExp(r'^(11)\d{8}$').hasMatch(digits);
    }

    bool isUSA() {
      // US: 10 dígitos: NXXNXXXXXX (N=2-9). Internacional: +1 + 10 dígitos
      return (digits.length == 10 && RegExp(r'^[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits)) ||
          (digits.length == 11 && RegExp(r'^1[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits));
    }

    return isBolivia() || isBrazil() || isColombia() || isArgentina() || isUSA();
  }

  /// Valida el teléfono y retorna un mensaje de error en español si no es válido.
  /// Si [required] es true y está vacío, retorna el error de requerido.
  static String? validatePhone(String? value, {bool required = true}) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return required ? 'El teléfono es obligatorio' : null;
    }
    if (!isValidSupportedPhone(v)) {
      return 'Ingrese un teléfono válido (Bolivia, Brasil, Colombia, Argentina o EEUU)';
    }
    return null;
  }
}
