import 'package:flutter/foundation.dart';

/// Utilidades para cálculo de cronogramas de pagos
///
/// Reglas de negocio consideradas:
/// - El cronograma inicia un día después de la fecha de inicio del crédito.
/// - Solo se pagan de lunes a sábado (días hábiles, se excluyen los domingos).
/// - Todo el cronograma se arma en función del número de cuotas (totalInstallments).
class ScheduleUtils {
  ScheduleUtils._();

  /// Normaliza una fecha a YYYY-MM-DD (sin hora)
  static DateTime normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Devuelve la fecha de referencia "hoy" considerando la regla de domingos:
  /// si hoy es domingo, usar el sábado anterior como referencia.
  static DateTime referenceDate([DateTime? now]) {
    final current = now ?? DateTime.now();
    final normalized = normalize(current);
    if (normalized.weekday == DateTime.sunday) {
      return normalized.subtract(const Duration(days: 1));
    }
    return normalized;
  }

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
      if (isWorkingDay(current)) {
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
      if (isWorkingDay(current)) {
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
  static bool isWorkingDay(DateTime date) {
    // En Dart: Monday = 1, Tuesday = 2, ..., Saturday = 6, Sunday = 7
    return date.weekday != DateTime.sunday;
  }

  /// Indica si una cuota (dueDate) está vencida respecto a una fecha de referencia
  static bool isOverdue(DateTime dueDate, {DateTime? refDate}) {
    final ref = referenceDate(refDate);
    return normalize(dueDate).isBefore(ref);
  }

  /// Dado un listado de cuotas, devuelve el número de cuota "actual" (según refDate):
  /// 1) Si existe una cuota impaga con dueDate == refDate, devuelve esa (menor número si hay varias)
  /// 2) Si no, devuelve la próxima impaga a futuro (la más cercana)
  /// 3) Si todas son pasadas, devuelve la última impaga
  /// El parámetro [isPaid] es un callback para que el llamador determine si una cuota está pagada.
  static int? findCurrentInstallmentNumber<T>(
    List<T> schedule, {
    required DateTime Function(T) getDueDate,
    required int Function(T) getInstallmentNumber,
    required bool Function(T) isPaid,
    DateTime? refDate,
  }) {
    if (schedule.isEmpty) return null;
    final ref = referenceDate(refDate);
    final unpaid = schedule.where((item) => !isPaid(item)).toList();
    if (unpaid.isEmpty) return null;

    final dueOnRef = unpaid
        .where((x) => normalize(getDueDate(x)) == ref)
        .toList();
    if (dueOnRef.isNotEmpty) {
      dueOnRef.sort((a, b) => getInstallmentNumber(a).compareTo(getInstallmentNumber(b)));
      return getInstallmentNumber(dueOnRef.first);
    }

    final future = unpaid.where((x) => getDueDate(x).isAfter(ref)).toList();
    if (future.isNotEmpty) {
      future.sort((a, b) {
        final cmp = getDueDate(a).compareTo(getDueDate(b));
        if (cmp != 0) return cmp;
        return getInstallmentNumber(a).compareTo(getInstallmentNumber(b));
      });
      return getInstallmentNumber(future.first);
    }

    unpaid.sort((a, b) => getInstallmentNumber(a).compareTo(getInstallmentNumber(b)));
    return getInstallmentNumber(unpaid.last);
  }

  /// Verifica si una fecha es domingo
  /// @deprecated Usar isWorkingDay en su lugar para mayor claridad
  static bool _isSunday(DateTime d) => d.weekday == DateTime.sunday;
}
