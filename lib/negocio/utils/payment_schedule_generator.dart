import '../../datos/modelos/credito.dart';
import '../../datos/modelos/credito/payment_schedule.dart';

/// Utilidad para generar un cronograma de pagos a partir de los datos de API
class PaymentScheduleGenerator {
  /// Genera cronograma a partir de un crédito con detalles del backend
  static List<PaymentSchedule> generateFromApiData(
    Map<String, dynamic> apiData,
  ) {
    final schedule = <PaymentSchedule>[];

    // Extraer información básica del crédito
    final creditData = apiData['data'];
    final startDate = DateTime.parse(creditData['start_date']);
    final frequency = creditData['frequency'] ?? 'daily';
    final totalInstallments = creditData['total_installments'] ?? 24;
    final installmentAmount = double.parse(
      creditData['installment_amount'].toString(),
    );

    // Pagos realizados para marcar cuotas como pagadas
    final payments = (creditData['payments'] as List? ?? []);

    // Determinar intervalo entre pagos basado en la frecuencia
    int daysBetweenPayments;
    switch (frequency) {
      case 'daily':
        daysBetweenPayments = 1;
        break;
      case 'weekly':
        daysBetweenPayments = 7;
        break;
      case 'biweekly':
        daysBetweenPayments = 14;
        break;
      case 'monthly':
        daysBetweenPayments = 30;
        break;
      default:
        daysBetweenPayments = 1;
    }

    // Generar fechas de vencimiento
    DateTime currentDueDate = startDate;
    for (int i = 1; i <= totalInstallments; i++) {
      // Para frecuencia diaria, avanzar saltándose domingos
      if (frequency == 'daily' && currentDueDate.weekday == DateTime.sunday) {
        currentDueDate = currentDueDate.add(const Duration(days: 1));
      }

      // Determinar si ya se pagó esta cuota
      bool isPaid = false;
      for (var payment in payments) {
        final paymentInstallment = payment['installment_number'] ?? 0;
        if (paymentInstallment == i && payment['status'] == 'completed') {
          isPaid = true;
          break;
        }
      }

      // Determinar estado de la cuota
      String status;
      if (isPaid) {
        status = 'paid';
      } else if (currentDueDate.isBefore(DateTime.now())) {
        status = 'overdue';
      } else {
        status = 'pending';
      }

      // Agregar cuota al cronograma
      schedule.add(
        PaymentSchedule(
          installmentNumber: i,
          dueDate: currentDueDate,
          amount: installmentAmount,
          status: status,
        ),
      );

      // Avanzar a la siguiente fecha de vencimiento
      currentDueDate = currentDueDate.add(Duration(days: daysBetweenPayments));
    }

    return schedule;
  }

  /// Método alternativo que extrae el cronograma directamente de los pagos
  static List<PaymentSchedule> extractFromPayments(
    Map<String, dynamic> apiData,
  ) {
    final schedule = <PaymentSchedule>[];

    final creditData = apiData['data'];
    final payments = (creditData['payments'] as List? ?? []);
    final startDate = DateTime.parse(creditData['start_date']);
    final frequency = creditData['frequency'] ?? 'daily';
    final totalInstallments = creditData['total_installments'] ?? 24;
    final installmentAmount = double.parse(
      creditData['installment_amount'].toString(),
    );

    // Organizar pagos por número de cuota
    final Map<int, Map<String, dynamic>> paidByInstallment = {};
    for (var payment in payments) {
      final installmentNumber = payment['installment_number'] ?? 0;
      if (installmentNumber > 0) {
        paidByInstallment[installmentNumber] = payment;
      }
    }

    // Determinar intervalo entre pagos
    int daysBetweenPayments;
    switch (frequency) {
      case 'daily':
        daysBetweenPayments = 1;
        break;
      case 'weekly':
        daysBetweenPayments = 7;
        break;
      case 'biweekly':
        daysBetweenPayments = 14;
        break;
      case 'monthly':
        daysBetweenPayments = 30;
        break;
      default:
        daysBetweenPayments = 1;
    }

    // Generar fechas de vencimiento y mapear con pagos reales
    DateTime currentDueDate = startDate;
    for (int i = 1; i <= totalInstallments; i++) {
      if (frequency == 'daily' && currentDueDate.weekday == DateTime.sunday) {
        currentDueDate = currentDueDate.add(const Duration(days: 1));
      }

      // Calcular la fecha de vencimiento para esta cuota
      // IMPORTANTE: La fecha de vencimiento es independiente de cuándo se pagó
      final dueDate = currentDueDate;

      // Verificar si hay un pago para esta cuota
      final payment = paidByInstallment[i];
      String status;
      double paidAmount = 0.0;
      double remainingAmount = installmentAmount;
      DateTime? lastPaymentDate;
      String? paymentMethod;
      int paymentCount = 0;

      if (payment != null) {
        // Existe un pago para esta cuota
        final paymentAmount = double.tryParse(payment['amount']?.toString() ?? '0') ?? 0.0;
        paidAmount = paymentAmount;
        remainingAmount = (installmentAmount - paymentAmount).clamp(0.0, installmentAmount);
        lastPaymentDate = DateTime.tryParse(payment['payment_date'] ?? '');
        paymentMethod = payment['payment_method']?.toString();
        paymentCount = 1; // Contamos el pago

        // Determinar status basado en el monto pagado
        if (payment['status'] == 'completed' && remainingAmount < 0.01) {
          status = 'paid';
        } else if (payment['status'] == 'partial' || remainingAmount > 0.01) {
          status = 'partial';
        } else {
          status = 'paid';
        }
      } else {
        // NO hay pago para esta cuota
        // Determinar status basado en la fecha de vencimiento
        if (dueDate.isBefore(DateTime.now())) {
          status = 'overdue';
        } else {
          status = 'pending';
        }
      }

      // Agregar cuota al cronograma
      schedule.add(
        PaymentSchedule(
          installmentNumber: i,
          dueDate: dueDate,
          amount: installmentAmount,
          status: status,
          paidAmount: paidAmount,
          remainingAmount: remainingAmount,
          isPaidFull: status == 'paid',
          isPartial: status == 'partial',
          paymentCount: paymentCount,
          lastPaymentDate: lastPaymentDate,
          paymentMethod: paymentMethod,
        ),
      );

      // Avanzar a la siguiente fecha de vencimiento
      currentDueDate = currentDueDate.add(Duration(days: daysBetweenPayments));
    }

    return schedule;
  }
}
