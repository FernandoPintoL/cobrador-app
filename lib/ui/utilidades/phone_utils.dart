/// Utilidades para validación de teléfonos celulares soportando
/// Bolivia, Brasil, Colombia, Argentina y EEUU (USA).
///
/// La validación es pragmática: permite formatos comunes con o sin
/// código de país, manejando espacios, guiones y paréntesis.
library phone_utils;

import 'package:flutter_libphonenumber/flutter_libphonenumber.dart' as flp;
import 'package:flutter/services.dart';

class PhoneUtils {
  static bool _initialized = false;
  static flp.CountryWithPhoneCode? _country;

  static Future<void> init({String defaultCountry = 'BO'}) async {
    if (_initialized) return;
    try {
      // Inicializa datos de países/máscaras
      await flp.init();
      // Seleccionar país por defecto (por código ISO-2, p.ej. "BO", "BR", "US")
      final code = defaultCountry.toUpperCase();
      final countries = flp.CountryManager().countries;
      _country = countries.firstWhere(
        (c) => c.countryCode.toUpperCase() == code,
        orElse: () => const flp.CountryWithPhoneCode.us(),
      );
      _initialized = true;
    } catch (_) {
      // En caso de fallo, seguimos con validación de respaldo
      _initialized = false;
      _country = const flp.CountryWithPhoneCode.us();
    }
  }
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
    final normalized = normalize(raw);

    try {
      // Intentar parsear con librería (detecta país automáticamente si empieza con +)
      final parsed = flp.formatNumberSync(
        normalized,
        country: normalized.startsWith('+') ? null : _country,
        phoneNumberType: flp.PhoneNumberType.mobile,
        phoneNumberFormat: flp.PhoneNumberFormat.international,
        inputContainsCountryCode: normalized.startsWith('+'),
      );
      // Si pudo formatear a E.164, lo consideramos válido
      return parsed.isNotEmpty;
    } catch (_) {
      // Si falla, caemos al validador anterior como fallback
    }

    // Fallback heurístico existente por si no hay datos para un país
    final s = normalize(raw);
    final digits = s.replaceAll(RegExp(r'\D'), '');

    bool isBolivia() {
      // BO: móvil 8 dígitos iniciando con 6 o 7. Internacional: +591 + (6|7) + 7d
      return (digits.length == 8 && RegExp(r'^[67]\d{7}$').hasMatch(digits)) ||
          (RegExp(r'^591[67]\d{7}$').hasMatch(digits));
    }

    bool isBrazil() {
      return (digits.length == 11 && RegExp(r'^[1-9]\d9\d{8}$').hasMatch(digits)) ||
          (RegExp(r'^55[1-9]\d9\d{8}$').hasMatch(digits));
    }

    bool isColombia() {
      return (digits.length == 10 && RegExp(r'^3\d{9}$').hasMatch(digits)) ||
          (RegExp(r'^57[3]\d{9}$').hasMatch(digits));
    }

    bool isArgentina() {
      return RegExp(r'^549\d{10}$').hasMatch(digits) ||
          RegExp(r'^54\d{10}$').hasMatch(digits) ||
          RegExp(r'^(11)\d{8}$').hasMatch(digits);
    }

    bool isUSA() {
      return (digits.length == 10 && RegExp(r'^[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits)) ||
          (digits.length == 11 && RegExp(r'^1[2-9]\d{2}[2-9]\d{6}$').hasMatch(digits));
    }

    return isBolivia() || isBrazil() || isColombia() || isArgentina() || isUSA();
  }

  /// Valida el teléfono y retorna un mensaje de error en español si no es válido.
  /// Si [required] es true y está vacío, retorna el error de requerido.
  static String? validatePhone(String? value, {bool required = true}) {
    // Intentar inicializar si no se hizo aún (no bloqueante para UI)
    if (!_initialized) {
      // fire-and-forget
      // ignore: discarded_futures
      init();
    }
    final v = value?.trim() ?? '';
    if (v.isEmpty) {
      return required ? 'El teléfono es obligatorio' : null;
    }
    if (!isValidSupportedPhone(v)) {
      return 'Ingrese un teléfono válido (Bolivia, Brasil, Colombia, Argentina o EEUU)';
    }
    return null;
  }

  /// Devuelve un input formatter que aplica formato nacional del país activo
  /// usando flutter_libphonenumber. Si no se pudo inicializar, retorna un
  /// formatter que no modifica la entrada.
  static TextInputFormatter inputFormatter() {
    try {
      final country = _country ?? const flp.CountryWithPhoneCode.us();
      return flp.LibPhonenumberTextFormatter(
        country: country,
        phoneNumberFormat: flp.PhoneNumberFormat.national,
        inputContainsCountryCode: false,
      );
    } catch (_) {
      // Fallback: no formatear
      return FilteringTextInputFormatter.allow(RegExp(r'.*'));
    }
  }
}
