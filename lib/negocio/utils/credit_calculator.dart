/// Centraliza todos los cálculos financieros de un crédito.
///
/// Uso:
///   final calc = CreditCalculation(
///     amount: 4200, interestRate: 20, downPayment: 500,
///     installments: 8, calcOnRemainingAmount: true,
///   );
///   print(calc.installmentAmount); // 555.00
///   print(calc.balance);           // 4440.00
class CreditCalculation {
  final double amount;
  final double interestRate;
  final double downPayment;
  final int installments;

  /// false = Opción 1: interés sobre monto total, anticipo descuenta del balance
  ///         cuota = (amount * (1 + i/100)) / N
  ///
  /// true  = Opción 2: interés sobre saldo restante (amount - downPayment)
  ///         cuota = ((amount - downPayment) * (1 + i/100)) / N
  final bool calcOnRemainingAmount;

  // ----------------------------------------------------------------
  // Valores derivados (calculados en el constructor)
  // ----------------------------------------------------------------

  /// Interés sobre el monto total (siempre sobre amount, para referencia)
  late final double interest;

  /// amount + interest (referencia del precio total con interés)
  late final double totalWithInterest;

  /// Base sobre la que se divide para obtener la cuota:
  /// - Opción 1: totalWithInterest
  /// - Opción 2: (amount - downPayment) * (1 + interestRate/100)
  late final double baseForInstallments;

  /// Saldo que el cliente pagará en cuotas
  late final double balance;

  /// Monto por cuota
  late final double installmentAmount;

  CreditCalculation({
    required this.amount,
    required this.interestRate,
    required this.downPayment,
    required this.installments,
    required this.calcOnRemainingAmount,
  }) {
    interest = amount * interestRate / 100;
    totalWithInterest = amount + interest;

    final bool useRemaining = calcOnRemainingAmount && downPayment > 0 && amount > downPayment;

    if (useRemaining) {
      // Opción 2: interés aplicado al saldo restante
      baseForInstallments = (amount - downPayment) * (1 + interestRate / 100);
      balance = baseForInstallments;
    } else {
      // Opción 1: interés sobre el total, anticipo reduce el balance
      baseForInstallments = totalWithInterest;
      balance = totalWithInterest - downPayment;
    }

    installmentAmount = installments > 0 ? baseForInstallments / installments : 0.0;
  }

  /// Cuotas completas que cubre el anticipo (solo Opción 1).
  /// En Opción 2 el anticipo es un pago separado → siempre 0.
  int get downPaymentInstallments {
    if (calcOnRemainingAmount || downPayment <= 0 || installmentAmount <= 0) return 0;
    return (downPayment / installmentAmount).floor();
  }

  /// Sobrante del anticipo después de cubrir cuotas completas (Opción 1).
  double get downPaymentRemainder {
    final covered = downPaymentInstallments * installmentAmount;
    final r = downPayment - covered;
    return r > 0.01 ? r : 0.0;
  }
}
