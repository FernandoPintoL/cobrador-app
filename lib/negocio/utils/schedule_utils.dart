import 'package:flutter/foundation.dart';

/// Utilidades para cálculo de cronogramas de pagos
///
/// Reglas de negocio consideradas:
/// - El cronograma inicia un día después de la fecha de inicio del crédito.
/// - Solo se pagan de lunes a sábado (días hábiles, se excluyen los domingos).
/// - Todo el cronograma se arma en función del número de cuotas (totalInstallments).
class ScheduleUtils {
  ScheduleUtils._();

  /// Calcula la fecha de fin para un crédito diario, avanzando solo por días hábiles
  /// (lunes a sábado) y cubriendo exactamente [totalInstallments] cuotas.
  ///
  /// start: fecha de inicio (el cronograma comienza al día siguiente de esta fecha)
  /// totalInstallments: número total de cuotas diarias
  static DateTime computeDailyEndDate(DateTime start, int totalInstallments) {
    if (kDebugMode) {
      print('computeDailyEndDate -> start: $start, totalInstallments: $totalInstallments');
    }
    final target = totalInstallments <= 0 ? 1 : totalInstallments;
    int payments = 0;
    DateTime current = start;

    while (payments < target) {
      current = current.add(const Duration(days: 1));
      // Solo contar días hábiles (lunes a sábado)
      if (_isWorkingDay(current)) {
        payments++;
      }

    }

    if (kDebugMode) {
      debugPrint('🗓️ computeDailyEndDate -> start: $start, installments: $target, end: $current');
    }
    return current;
  }

  /// Construye el listado de fechas de vencimiento para un cronograma diario.
  /// Devuelve exactamente [totalInstallments] fechas, saltando domingos.
  static List<DateTime> buildDailySchedule(DateTime start, int totalInstallments) {
    final target = totalInstallments <= 0 ? 1 : totalInstallments;
    final List<DateTime> dates = [];
    DateTime current = start;

    while (dates.length < target) {
      current = current.add(const Duration(days: 1));
      // Solo incluir días hábiles (lunes a sábado)
      if (_isWorkingDay(current)) {
        dates.add(current);
      }
    }

    if (kDebugMode) {
      debugPrint('🗓️ buildDailySchedule -> start: $start, installments: $target, dates: ${dates.length}');
    }
    return dates;
  }

  /// Verifica si una fecha corresponde a un día hábil (lunes a sábado)
  /// Excluye únicamente los domingos
  static bool _isWorkingDay(DateTime date) {
    // En Dart: Monday = 1, Tuesday = 2, ..., Saturday = 6, Sunday = 7
    return date.weekday != DateTime.sunday;
  }

  /// Verifica si una fecha es domingo
  /// @deprecated Usar _isWorkingDay en su lugar para mayor claridad
  static bool _isSunday(DateTime d) => d.weekday == DateTime.sunday;
}
