import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../datos/modelos/credito.dart';
import '../../../../negocio/providers/credit_provider.dart';

Future<void> showRejectionDialog(
  BuildContext context,
  WidgetRef ref,
  Credito credit, {
  required VoidCallback onSuccess,
}) async {
  final reasonController = TextEditingController();

  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Rechazar Crédito'),
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
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo del rechazo',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                autofocus: true,
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
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Debe proporcionar un motivo'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              Navigator.pop(dialogContext, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(creditProvider.notifier)
          .rejectCredit(
            creditId: credit.id,
            reason: reasonController.text.trim(),
          );
      onSuccess();
    }
  } finally {
    reasonController.dispose();
  }
}
