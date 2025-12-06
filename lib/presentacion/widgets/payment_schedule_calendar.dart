import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../negocio/utils/schedule_utils.dart';
import '../../datos/modelos/credito.dart';

class PaymentScheduleCalendar extends StatelessWidget {
  final List<PaymentSchedule> schedule;
  final Credito credit; // to infer paid installments
  final void Function(PaymentSchedule)? onTapInstallment;

  const PaymentScheduleCalendar({
    super.key,
    required this.schedule,
    required this.credit,
    this.onTapInstallment,
  });

  /// Determina si una cuota está completamente pagada.
  /// Ahora simplificado: confía en el backend que ya calcula el estado real.
  bool _isInstallmentPaid(PaymentSchedule installment) {
    // El backend ya calcula el estado correcto basándose en payments reales
    return installment.isPaid || installment.status == 'paid';
  }

  int? _currentInstallmentNumber() {
    return ScheduleUtils.findCurrentInstallmentNumber<PaymentSchedule>(
      schedule,
      getDueDate: (x) => x.dueDate,
      getInstallmentNumber: (x) => x.installmentNumber,
      isPaid: (x) => _isInstallmentPaid(x),
      refDate: ScheduleUtils.referenceDate(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsPerRow = 6;
    final currentNumber = _currentInstallmentNumber();
    final refDate = ScheduleUtils.referenceDate();

    return Column(
      children: [
        // Header compacto con información clave
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _compactInfoChip(
                context,
                'Cuota',
                'Bs. ${(credit.installmentAmount ?? 0).toStringAsFixed(0)}',
                Icons.payments,
                Colors.blue,
              ),
              _compactInfoChip(
                context,
                'Saldo',
                'Bs. ${(credit.balance).toStringAsFixed(0)}',
                Icons.account_balance_wallet,
                Colors.orange,
              ),
              _compactInfoChip(
                context,
                'Cuotas',
                '${credit.paidInstallments}/${credit.totalInstallments}',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Fecha de referencia: ${DateFormat('dd/MM/yyyy').format(refDate)}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        // Cambiar Row por Wrap para evitar overflow en pantallas pequeñas
        Wrap(
          spacing: 8.0, // Espaciado horizontal entre elementos
          runSpacing: 4.0, // Espaciado vertical entre filas
          alignment: WrapAlignment.center,
          children: [
            _legendItem(Colors.green, 'Pagado'),
            _legendItem(Colors.yellow.shade700, 'Parcial'),
            _legendItem(Colors.grey.shade300, 'Pendiente'),
            _legendItem(Colors.lightBlueAccent, 'Actual'),
            _legendItem(Colors.red, 'Vencido'),
          ],
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemsPerRow,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final installment = schedule[index];
            final consideredPaid = _isInstallmentPaid(installment);
            final due = ScheduleUtils.normalize(installment.dueDate);
            // Resaltar la cuota "actual" según el número devuelto por ScheduleUtils,
            // incluso si su due_date no coincide exactamente con la fecha de referencia.
            // Esto permite que, si ya se pagó hoy la cuota que vencía hoy, se destaque la
            // próxima impaga (caso típico en cobros diarios).
            final isCurrent =
                !consideredPaid &&
                currentNumber != null &&
                installment.installmentNumber == currentNumber;
            final isOverdueLocal = !consideredPaid && (due.isBefore(refDate));

            // Determinar color basándose en el status del backend
            Color backgroundColor;
            Color textColor = Colors.white;

            if (consideredPaid || installment.status == 'paid') {
              backgroundColor = Colors.green;
            } else if (installment.isPartial || installment.status == 'partial') {
              // Pago parcial: amarillo/naranja
              backgroundColor = Colors.yellow.shade700;
              textColor = Colors.black;
            } else if (isCurrent) {
              backgroundColor = Colors.lightBlueAccent;
              textColor = Colors.black;
            } else if (isOverdueLocal || installment.status == 'overdue') {
              backgroundColor = Colors.red;
            } else {
              // Pendiente
              backgroundColor = Colors.grey.shade300;
              textColor = Colors.black87;
            }
            // Calcular monto restante (por si el backend no lo envía)
            final double remaining = installment.remainingAmount > 0
                ? installment.remainingAmount
                : (installment.amount - installment.paidAmount).clamp(0.0, installment.amount);

            // Verificar si la cuota puede ser pagada
            final bool canPay = installment.status != 'paid' &&
                                !installment.isPaidFull &&
                                remaining > 0;

            return GestureDetector(
              onTap: () => onTapInstallment?.call(installment),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    padding: const EdgeInsets.all(2),
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${installment.installmentNumber}',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM').format(installment.dueDate),
                            style: TextStyle(color: textColor, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Indicador de pago disponible
                  if (canPay)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.payment,
                          size: 10,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _compactInfoChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
