import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../datos/modelos/credito.dart';
import '../../../../negocio/providers/credit_provider.dart';
import '../../../../ui/widgets/validation_error_display.dart';

Future<void> showApprovalDialog(
  BuildContext context,
  WidgetRef ref,
  Credito credit, {
  required VoidCallback onSuccess,
}) async {
  final DateTime now = DateTime.now();
  final DateTime tomorrow = now.add(const Duration(days: 1));
  DateTime selectedDate = DateTime(
    tomorrow.year,
    tomorrow.month,
    tomorrow.day,
    9,
    0,
  );
  bool deliverImmediately = false;

  await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        final creditState = ref.watch(creditProvider);
        return AlertDialog(
          title: const Text('Aprobar para Entrega'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
                ),
                Text(
                  'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
                ),
                const SizedBox(height: 16),
                const Text('Fecha y hora de entrega programada:'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 30)),
                    );
                    if (pickedDate != null && dialogContext.mounted) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: deliverImmediately,
                  onChanged: (v) =>
                      setState(() => deliverImmediately = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Entregar inmediatamente al aprobar'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
                if (creditState.validationErrors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ValidationErrorDisplay(
                      errors: creditState.validationErrors,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool result = false;
                if (deliverImmediately) {
                  result = await ref
                      .read(creditProvider.notifier)
                      .approveAndDeliverCredit(
                        creditId: credit.id,
                        approvalNotes:
                            'Aprobación y entrega desde lista de espera',
                      );
                } else {
                  result = await ref
                      .read(creditProvider.notifier)
                      .approveCreditForDelivery(
                        creditId: credit.id,
                        scheduledDeliveryDate: selectedDate,
                      );
                }
                if (result) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext, true);
                  onSuccess();
                } else {
                  setState(() {});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                deliverImmediately ? 'Aprobar y Entregar' : 'Aprobar',
              ),
            ),
          ],
        );
      },
    ),
  );
}
