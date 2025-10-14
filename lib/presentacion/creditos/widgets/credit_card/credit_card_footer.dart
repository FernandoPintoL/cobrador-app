import 'package:flutter/material.dart';
import '../../../../datos/modelos/credito.dart';

/// Footer de la tarjeta de crédito con los botones de acción
/// según el tipo de lista y permisos del usuario
class CreditCardFooter extends StatelessWidget {
  final Credito credit;
  final String listType;
  final bool canApprove;
  final bool canDeliver;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDeliver;
  final VoidCallback? onPayment;

  const CreditCardFooter({
    super.key,
    required this.credit,
    required this.listType,
    required this.canApprove,
    required this.canDeliver,
    this.onApprove,
    this.onReject,
    this.onDeliver,
    this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = _buildButtons();

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: buttons);
  }

  List<Widget> _buildButtons() {
    List<Widget> buttons = [];

    // Botones para créditos pendientes de aprobación
    if (listType == 'pending_approval' && canApprove) {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aprobar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Rechazar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      ]);
    }
    // Botones para créditos listos para entrega
    else if ((listType == 'ready_for_delivery' ||
            (listType == 'waiting_delivery' && credit.isReadyForDelivery)) &&
        canDeliver) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDeliver,
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('Entregar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      );
    }
    // Botón para pagos en créditos activos
    else if (listType == 'active' && credit.isActive) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onPayment,
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Pagar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      );
    }

    return buttons;
  }
}
