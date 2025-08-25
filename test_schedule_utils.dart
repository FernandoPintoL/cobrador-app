import 'lib/negocio/utils/schedule_utils.dart';

void main() {
  // Prueba con diferentes escenarios
  print('=== Pruebas de computeDailyEndDate ===\n');

  // Escenario 1: Empezar un viernes
  DateTime startFriday = DateTime(2025, 8, 22); // Viernes 22 de agosto 2025
  print('Escenario 1: Inicio viernes ${startFriday.toString().substring(0, 10)}');
  print('Día de la semana: ${_getDayName(startFriday.weekday)}');

  DateTime endDate5 = ScheduleUtils.computeDailyEndDate(startFriday, 5);
  print('5 cuotas -> Fecha final: ${endDate5.toString().substring(0, 10)} (${_getDayName(endDate5.weekday)})');

  DateTime endDate10 = ScheduleUtils.computeDailyEndDate(startFriday, 10);
  print('10 cuotas -> Fecha final: ${endDate10.toString().substring(0, 10)} (${_getDayName(endDate10.weekday)})');

  // Escenario 2: Empezar un sábado
  DateTime startSaturday = DateTime(2025, 8, 23); // Sábado 23 de agosto 2025
  print('\nEscenario 2: Inicio sábado ${startSaturday.toString().substring(0, 10)}');
  print('Día de la semana: ${_getDayName(startSaturday.weekday)}');

  DateTime endDate5Sat = ScheduleUtils.computeDailyEndDate(startSaturday, 5);
  print('5 cuotas -> Fecha final: ${endDate5Sat.toString().substring(0, 10)} (${_getDayName(endDate5Sat.weekday)})');

  // Escenario 3: Empezar un domingo (para ver cómo se maneja)
  DateTime startSunday = DateTime(2025, 8, 24); // Domingo 24 de agosto 2025
  print('\nEscenario 3: Inicio domingo ${startSunday.toString().substring(0, 10)}');
  print('Día de la semana: ${_getDayName(startSunday.weekday)}');

  DateTime endDate5Sun = ScheduleUtils.computeDailyEndDate(startSunday, 5);
  print('5 cuotas -> Fecha final: ${endDate5Sun.toString().substring(0, 10)} (${_getDayName(endDate5Sun.weekday)})');

  // Verificar que no hay domingos en el cronograma
  print('\n=== Verificación del cronograma ===');
  List<DateTime> schedule = ScheduleUtils.buildDailySchedule(startFriday, 10);
  print('Cronograma de 10 días desde viernes:');
  for (int i = 0; i < schedule.length; i++) {
    DateTime date = schedule[i];
    print('${i + 1}. ${date.toString().substring(0, 10)} (${_getDayName(date.weekday)})');
  }

  // Verificar que no hay ningún domingo
  bool hasSunday = schedule.any((date) => date.weekday == DateTime.sunday);
  print('\n¿Hay domingos en el cronograma? ${hasSunday ? "SÍ ❌" : "NO ✅"}');
}

String _getDayName(int weekday) {
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
