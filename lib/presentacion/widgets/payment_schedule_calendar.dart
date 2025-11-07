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

  bool _isInstallmentPaid(PaymentSchedule installment) {
    // Debug: Imprimir info de la cuota
    print('🔍 Evaluando cuota #${installment.installmentNumber}:');
    print('   - Status del schedule: ${installment.status}');
    print('   - isPaid del schedule: ${installment.isPaid}');

    if (installment.isPaid) {
      print('   ✅ Marcada como pagada por schedule.isPaid');
      return true;
    }

    final paidCount = credit.paidInstallments;
    print('   - paidInstallments del crédito: $paidCount');

    if (paidCount >= installment.installmentNumber) {
      print('   ✅ Marcada como pagada por paidCount ($paidCount >= ${installment.installmentNumber})');
      return true;
    }

    final pagos = credit.payments;
    print('   - Pagos en crédito: ${pagos?.length ?? 0}');

    if (pagos != null && pagos.isNotEmpty) {
      for (final p in pagos) {
        print('   - Pago con installment_number=${p.installmentNumber}: fecha=${p.paymentDate}, status=${p.status}');
        // Verificar si el installmentNumber del pago coincide con el de esta cuota
        if (p.installmentNumber == installment.installmentNumber &&
            (p.status == 'completed' || p.status == 'paid')) {
          print('   ✅ Marcada como pagada por installment_number coincidente (${p.installmentNumber})');
          return true;
        }
      }
    }

    print('   ❌ No pagada');
    return false;
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
            Color backgroundColor;
            Color textColor = Colors.white;
            if (consideredPaid) {
              backgroundColor = Colors.green;
            } else if (isCurrent) {
              backgroundColor = Colors.lightBlueAccent;
              textColor = Colors.black;
            } else if (isOverdueLocal) {
              backgroundColor = Colors.red;
            } else {
              backgroundColor = Colors.grey.shade300;
              textColor = Colors.black87;
            }
            return GestureDetector(
              onTap: () => onTapInstallment?.call(installment),
              child: Container(
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
}
