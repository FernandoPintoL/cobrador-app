import 'payment_schedule.dart';
import 'pago.dart';
import '../usuario.dart';

/// ✅ OPTIMIZACIÓN: Helper para convertir PaymentSchedule a Pago
/// Permite mantener compatibilidad con widgets que esperan `List<Pago>`
/// sin necesidad de que el backend envíe el array completo de payments
class PaymentScheduleHelper {
  /// Convierte una lista de PaymentSchedule a `List<Pago>`
  /// Solo genera Pago para las cuotas que tienen pagos (paidAmount > 0)
  static List<Pago> scheduleToPayments({
    required List<PaymentSchedule> schedule,
    required int creditId,
  }) {
    final List<Pago> payments = [];
    final now = DateTime.now();

    for (final installment in schedule) {
      // Solo crear Pago si hay monto pagado
      if (installment.paidAmount > 0 && installment.lastPaymentDate != null) {
        // Crear Usuario simple con la info del cobrador
        Usuario? cobrador;
        if (installment.receivedById != null && installment.receivedByName != null) {
          cobrador = Usuario(
            id: BigInt.from(installment.receivedById!),
            nombre: installment.receivedByName!,
            telefono: '',
            ci: '0',
            email: '',
            profileImage: '', // Usuario sin imagen de perfil
            direccion: '',
            roles: [],
            fechaCreacion: now,
            fechaActualizacion: now,
          );
        }

        payments.add(
          Pago(
            id: 0, // No disponible en schedule, pero no es crítico
            cobradorId: installment.receivedById,
            creditId: creditId,
            amount: installment.paidAmount,
            paymentDate: installment.lastPaymentDate!,
            paymentType: installment.paymentMethod ?? 'cash',
            latitude: null,
            longitude: null,
            status: 'completed',
            installmentNumber: installment.installmentNumber,
            receivedBy: installment.receivedById,
            cashBalanceId: null,
            cobrador: cobrador,
            createdAt: installment.lastPaymentDate!,
            updatedAt: installment.lastPaymentDate!,
          ),
        );
      }
    }

    // Ordenar por número de cuota
    payments.sort((a, b) =>
      (a.installmentNumber ?? 0).compareTo(b.installmentNumber ?? 0)
    );

    return payments;
  }

  /// Filtra el schedule para obtener solo cuotas pagadas
  static List<PaymentSchedule> getPaidInstallments(List<PaymentSchedule> schedule) {
    return schedule.where((s) => s.isPaidFull || s.paidAmount > 0).toList();
  }

  /// Filtra el schedule para obtener solo cuotas pendientes/vencidas
  static List<PaymentSchedule> getPendingInstallments(List<PaymentSchedule> schedule) {
    return schedule.where((s) => !s.isPaidFull && s.status != 'paid').toList();
  }

  /// Obtiene estadísticas del cronograma
  static Map<String, dynamic> getScheduleStats(List<PaymentSchedule> schedule) {
    int paid = 0;
    int overdue = 0;
    int pending = 0;
    int partial = 0;
    double totalPaid = 0.0;
    double totalRemaining = 0.0;

    for (final installment in schedule) {
      if (installment.isPaidFull) {
        paid++;
      } else if (installment.isPartial) {
        partial++;
        overdue++; // Parcial se considera vencido
      } else if (installment.isOverdue) {
        overdue++;
      } else {
        pending++;
      }

      totalPaid += installment.paidAmount;
      totalRemaining += installment.remainingAmount;
    }

    return {
      'paid': paid,
      'overdue': overdue,
      'pending': pending,
      'partial': partial,
      'total': schedule.length,
      'total_paid': totalPaid,
      'total_remaining': totalRemaining,
    };
  }
}
