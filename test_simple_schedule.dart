void main() {
  print('=== Análisis de la función computeDailyEndDate ===\n');

  // Simulamos la función _isWorkingDay
  bool isWorkingDay(DateTime date) {
    // En Dart: Monday = 1, Tuesday = 2, ..., Saturday = 6, Sunday = 7
    return date.weekday != DateTime.sunday;
  }

  // Simulamos computeDailyEndDate
  DateTime computeDailyEndDate(DateTime start, int totalInstallments) {
    final target = totalInstallments <= 0 ? 1 : totalInstallments;
    int payments = 0;
    DateTime current = start;

    while (payments < target) {
      current = current.add(const Duration(days: 1));
      // Solo contar días hábiles (lunes a sábado)
      if (isWorkingDay(current)) {
        payments++;
      }
    }
    return current;
  }

  // Función auxiliar para obtener el nombre del día
  String getDayName(int weekday) {
    const days = {
      1: 'Lunes',
      2: 'Martes',
      3: 'Miércoles',
      4: 'Jueves',
      5: 'Viernes',
      6: 'Sábado',
      7: 'Domingo'
    };
    return days[weekday] ?? 'Desconocido';
  }

  // Prueba con diferentes escenarios
  print('Escenario 1: Empezar un viernes');
  DateTime startFriday = DateTime(2025, 8, 22); // Viernes 22 de agosto 2025
  print('Inicio: ${startFriday.toString().substring(0, 10)} (${getDayName(startFriday.weekday)})');

  DateTime endDate5 = computeDailyEndDate(startFriday, 5);
  print('5 cuotas -> Fecha final: ${endDate5.toString().substring(0, 10)} (${getDayName(endDate5.weekday)})');

  DateTime endDate10 = computeDailyEndDate(startFriday, 10);
  print('10 cuotas -> Fecha final: ${endDate10.toString().substring(0, 10)} (${getDayName(endDate10.weekday)})');

  print('\nEscenario 2: Empezar un sábado');
  DateTime startSaturday = DateTime(2025, 8, 23); // Sábado 23 de agosto 2025
  print('Inicio: ${startSaturday.toString().substring(0, 10)} (${getDayName(startSaturday.weekday)})');

  DateTime endDate5Sat = computeDailyEndDate(startSaturday, 5);
  print('5 cuotas -> Fecha final: ${endDate5Sat.toString().substring(0, 10)} (${getDayName(endDate5Sat.weekday)})');

  print('\nEscenario 3: Empezar un domingo');
  DateTime startSunday = DateTime(2025, 8, 24); // Domingo 24 de agosto 2025
  print('Inicio: ${startSunday.toString().substring(0, 10)} (${getDayName(startSunday.weekday)})');

  DateTime endDate5Sun = computeDailyEndDate(startSunday, 5);
  print('5 cuotas -> Fecha final: ${endDate5Sun.toString().substring(0, 10)} (${getDayName(endDate5Sun.weekday)})');

  // Verificación detallada para 5 cuotas desde viernes
  print('\n=== Verificación detallada ===');
  print('Cronograma de 5 cuotas desde viernes ${startFriday.toString().substring(0, 10)}:');

  DateTime current = startFriday;
  int cuota = 0;

  while (cuota < 5) {
    current = current.add(const Duration(days: 1));
    String dayName = getDayName(current.weekday);
    bool isWorking = isWorkingDay(current);

    if (isWorking) {
      cuota++;
      print('${cuota}. ${current.toString().substring(0, 10)} ($dayName) ✅');
    } else {
      print('   ${current.toString().substring(0, 10)} ($dayName) ❌ DOMINGO - NO CUENTA');
    }
  }

  print('\n✅ CONFIRMACIÓN: La función excluye correctamente los domingos');
  print('✅ Solo cuenta días hábiles (lunes a sábado)');
  print('✅ La fecha final será siempre un día hábil');
}

