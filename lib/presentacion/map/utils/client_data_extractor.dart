import 'package:flutter/material.dart';
import '../../../datos/modelos/map/location_cluster.dart';
import 'translations.dart';

/// Utilidades para extraer y procesar datos de clientes/créditos
class ClientDataExtractor {
  /// Verifica si una persona pagó hoy basado en sus pagos recientes
  static bool? extractPaidToday(ClusterPerson person) {
    try {
      final now = DateTime.now();
      final lastPayment = person.paymentStats.lastPayment;

      if (lastPayment != null) {
        final paymentDate = _tryParseFlexibleDate(lastPayment.date);
        if (paymentDate != null && _isSameDay(paymentDate, now)) {
          final status = lastPayment.status.toLowerCase();
          if (status == 'paid' ||
              status == 'completed' ||
              status == 'success' ||
              status == 'pagado') {
            return true;
          }
        }
      }

      // Buscar en créditos si hay pagos recientes
      for (final credit in person.credits) {
        if (credit.lastPayment != null) {
          final paymentDate = _tryParseFlexibleDate(credit.lastPayment!.date);
          if (paymentDate != null && _isSameDay(paymentDate, now)) {
            return true;
          }
        }
      }

      return false;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el color para el estado de pago de hoy
  static Color colorForPaidToday(bool? paid) {
    if (paid == true) return Colors.green.shade600;
    if (paid == false) return Colors.red.shade400;
    return Colors.blue.shade400;
  }

  /// Obtiene el label para el estado de pago de hoy
  static String labelForPaidToday(bool? paid) {
    if (paid == true) return 'Pagó hoy';
    if (paid == false) return 'No pagó hoy';
    return 'Sin datos de hoy';
  }

  /// Obtiene el hue de BitmapDescriptor para el estado
  static double hueForPaidToday(bool? paid) {
    if (paid == true) return 5; // Verde
    if (paid == false) return 0; // Rojo
    return 210; // Azul
  }

  /// Extrae información de la próxima cuota y monto a pagar
  static Map<String, dynamic> extractNextPaymentInfo(ClusterPerson person) {
    double? amount;
    int? installment;

    if (person.credits.isEmpty) {
      return {'amount': amount, 'installment': installment};
    }

    // Priorizar crédito activo
    final activeCredit = person.credits.firstWhere(
      (c) =>
          c.status.toLowerCase() == 'active' ||
          c.status.toLowerCase() == 'vigente' ||
          c.status.toLowerCase() == 'en_curso',
      orElse: () => person.credits.first,
    );

    if (activeCredit.nextPaymentDue != null) {
      amount = activeCredit.nextPaymentDue!.amount;
      installment = activeCredit.nextPaymentDue!.installment;
    }

    return {'amount': amount, 'installment': installment};
  }

  /// Calcula estadísticas de todo el cluster
  static Map<String, dynamic> calculateClusterStats(LocationCluster cluster) {
    int totalPeople = 0;
    int totalCredits = 0;
    double totalBalance = 0.0;
    int overduePeople = 0;
    int paidPeople = 0;
    int pendingPeople = 0;

    for (final person in cluster.people) {
      totalPeople++;
      totalCredits += person.totalCredits;
      totalBalance += person.totalBalance;

      final status = person.personStatus.toLowerCase();
      if (status == 'overdue') {
        overduePeople++;
      } else if (status == 'paid') {
        paidPeople++;
      } else if (status == 'pending') {
        pendingPeople++;
      }
    }

    return {
      'total_people': totalPeople,
      'total_credits': totalCredits,
      'total_balance': totalBalance,
      'overdue_people': overduePeople,
      'paid_people': paidPeople,
      'pending_people': pendingPeople,
    };
  }

  /// Formatea un número como moneda Bolivianos
  static String formatSoles(num value) =>
      MapTranslations.formatBolivianos(value);

  /// Intenta parsear una fecha flexible (ISO 8601, YYYY-MM-DD, etc)
  static DateTime? _tryParseFlexibleDate(String input) {
    if (input.isEmpty) return null;

    // Intento estándar ISO
    final iso = DateTime.tryParse(input);
    if (iso != null) return iso.toLocal();

    // Intento con sólo fecha (YYYY-MM-DD)
    try {
      final y = int.parse(input.substring(0, 4));
      final m = int.parse(input.substring(5, 7));
      final d = int.parse(input.substring(8, 10));
      return DateTime(y, m, d);
    } catch (_) {}

    return null;
  }

  /// Verifica si dos fechas son del mismo día
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Obtiene el resumen de un cliente en formato amigable
  static String getClientSummary(ClusterPerson person) {
    final credits = person.totalCredits;
    final balance = formatSoles(person.totalBalance);
    return '$credits crédito${credits != 1 ? 's' : ''} • $balance';
  }

  /// Determina el icono y color para el estado de una persona
  static (IconData, Color) getStatusIconAndColor(String status) {
    switch (status.toLowerCase()) {
      case 'overdue':
        return (Icons.warning_rounded, Colors.red.shade400);
      case 'pending':
        return (Icons.schedule_rounded, Colors.amber.shade700);
      case 'paid':
        return (Icons.check_circle_rounded, Colors.green.shade600);
      default:
        return (Icons.info_rounded, Colors.blue.shade400);
    }
  }

  /// Calcula el porcentaje de deuda del total
  static int getDebtPercentage(double balance, double totalAmount) {
    if (totalAmount == 0) return 0;
    return ((balance / totalAmount) * 100).round();
  }

  /// Obtiene la fecha del próximo pago vencido más cercano
  static DateTime? getNextDueDate(List<ClusterCredit> credits) {
    DateTime? nearest;

    for (final credit in credits) {
      if (credit.nextPaymentDue != null) {
        final date = _tryParseFlexibleDate(credit.nextPaymentDue!.date);
        if (date != null) {
          if (nearest == null || date.isBefore(nearest)) {
            nearest = date;
          }
        }
      }
    }

    return nearest;
  }

  /// Calcula días desde la fecha última actualización
  static String daysSinceLastPayment(DateTime? lastPaymentDate) {
    if (lastPaymentDate == null) return 'Sin información';

    final days = DateTime.now().difference(lastPaymentDate).inDays;
    if (days == 0) return 'Hoy';
    if (days == 1) return 'Ayer';
    if (days < 7) return 'Hace $days días';
    if (days < 30) return 'Hace ${(days / 7).floor()} semanas';
    return 'Hace ${(days / 30).floor()} meses';
  }
}
