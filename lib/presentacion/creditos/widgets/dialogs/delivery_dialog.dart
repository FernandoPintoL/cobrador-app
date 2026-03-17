import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../datos/modelos/credito.dart';
import '../../../../negocio/providers/credit_provider.dart';

Future<void> showDeliveryDialog(
  BuildContext context,
  WidgetRef ref,
  Credito credit, {
  required VoidCallback onSuccess,
}) async {
  final DateTime now = DateTime.now();
  DateTime selectedDate = credit.scheduledDeliveryDate ?? now;
  bool firstPaymentToday = false;

  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Confirmar Entrega'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
              ),
              Text(
                'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
              ),
              const SizedBox(height: 12),
              if (credit.scheduledDeliveryDate != null)
                Text(
                  'Programado: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              if (credit.scheduledDeliveryDate == null)
                const Text(
                  'Sin fecha programada. Puedes programar una antes de entregar.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                '¿El cliente realizará el primer pago HOY?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: firstPaymentToday,
                onChanged: (v) =>
                    setState(() => firstPaymentToday = v ?? false),
                title: const Text('Sí, primer pago hoy'),
                subtitle: Text(
                  firstPaymentToday
                      ? 'El cronograma iniciará desde HOY'
                      : 'El cronograma iniciará desde MAÑANA',
                  style: TextStyle(
                    fontSize: 12,
                    color: firstPaymentToday ? Colors.green : Colors.orange,
                  ),
                ),
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 8),
              const Text(
                '¿Cómo deseas proceder?',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, {'action': 'cancel'}),
            child: const Text('Cancelar'),
          ),
          TextButton.icon(
            onPressed: () async {
              final DateTime? pickedDate = await showDatePicker(
                context: dialogContext,
                initialDate: selectedDate,
                firstDate: now.subtract(const Duration(days: 0)),
                lastDate: DateTime(now.year + 1),
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
                  final ok = await ref
                      .read(creditProvider.notifier)
                      .rescheduleCreditDelivery(
                        creditId: credit.id,
                        newScheduledDate: selectedDate,
                        reason: 'Reprogramación desde diálogo de entrega',
                      );
                  if (ok && dialogContext.mounted) {
                    Navigator.pop(dialogContext, {'action': 'rescheduled'});
                  }
                }
              }
            },
            icon: const Icon(Icons.event),
            label: const Text('Reprogramar fecha'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, {
              'action': 'deliver_now',
              'first_payment_today': firstPaymentToday,
            }),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entregar ahora'),
          ),
        ],
      ),
    ),
  );

  if (result != null && result['action'] == 'deliver_now') {
    final bool payToday = result['first_payment_today'] ?? false;
    await ref
        .read(creditProvider.notifier)
        .deliverCreditToClient(
          creditId: credit.id,
          notes: 'Entrega confirmada desde lista de espera',
          firstPaymentToday: payToday,
        );
    onSuccess();
  } else if (result != null && result['action'] == 'rescheduled') {
    onSuccess();
  }
}
