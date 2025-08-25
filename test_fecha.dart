import 'package:flutter/foundation.dart';

void main() {
  // Test de la función ScheduleUtils.computeDailyEndDate
  DateTime start = DateTime(2025, 8, 25); // 25/08/2025
  int totalInstallments = 24;

  print('Fecha de inicio: ${start.day}/${start.month}/${start.year}');
  print('Total de cuotas: $totalInstallments');

  DateTime result = computeDailyEndDate(start, totalInstallments);
  print('Fecha de fin calculada: ${result.day}/${result.month}/${result.year}');

  // Verificar manualmente
  int payments = 0;
  DateTime current = start;
  List<DateTime> fechasPago = [];

  while (payments < totalInstallments) {
    current = current.add(const Duration(days: 1));
    if (current.weekday != DateTime.sunday) {
      payments++;
      fechasPago.add(current);
    }
  }

  print('\nVerificación manual:');
  print('Primera fecha de pago: ${fechasPago.first.day}/${fechasPago.first.month}/${fechasPago.first.year}');
  print('Última fecha de pago: ${fechasPago.last.day}/${fechasPago.last.month}/${fechasPago.last.year}');
  print('Total de fechas generadas: ${fechasPago.length}');

  // Verificar cuántos domingos se saltaron
  DateTime temp = start;
  int domingosSaltados = 0;
  while (temp.isBefore(fechasPago.last) || temp.isAtSameMomentAs(fechasPago.last)) {
    temp = temp.add(const Duration(days: 1));
    if (temp.weekday == DateTime.sunday) {
      domingosSaltados++;
    }
  }
  print('Domingos saltados: $domingosSaltados');
}

DateTime computeDailyEndDate(DateTime start, int totalInstallments) {
  if (kDebugMode) {
    print('computeDailyEndDate -> start: $start, totalInstallments: $totalInstallments');
  }
  final target = totalInstallments <= 0 ? 1 : totalInstallments;
  int payments = 0;
  DateTime current = start;

  while (payments < target) {
    current = current.add(const Duration(days: 1));
    // Solo contar días hábiles (lunes a sábado)
    if (current.weekday != DateTime.sunday) {
      payments++;
    }
  }

  if (kDebugMode) {
    print('🗓️ computeDailyEndDate -> start: $start, installments: $target, end: $current');
  }
  return current;
}
