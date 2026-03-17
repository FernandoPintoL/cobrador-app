/// Normaliza una cadena de búsqueda:
/// - Si contiene letras → convierte a MAYÚSCULAS
/// - Si es solo números/símbolos telefónicos → devuelve tal cual
String normalizeSearchQuery(String v) {
  final trimmed = v.trim();
  if (trimmed.isEmpty) return trimmed;
  final hasLetter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(trimmed);
  return hasLetter ? trimmed.toUpperCase() : trimmed;
}
