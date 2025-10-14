import 'package:flutter/material.dart';
import '../../../../datos/modelos/credito.dart';
import 'credit_card_header.dart';
import 'credit_card_body.dart';
import 'credit_card_footer.dart';

/// Widget principal de la tarjeta de crédito
/// Ensambla el header, body y footer en una tarjeta interactiva
class CreditCardWidget extends StatelessWidget {
  final Credito credit;
  final String listType;
  final bool canApprove;
  final bool canDeliver;
  final VoidCallback? onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onDeliver;
  final VoidCallback? onPayment;

  const CreditCardWidget({
    super.key,
    required this.credit,
    required this.listType,
    this.canApprove = false,
    this.canDeliver = false,
    this.onTap,
    this.onApprove,
    this.onReject,
    this.onDeliver,
    this.onPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con cliente y estado
              CreditCardHeader(credit: credit),

              const SizedBox(height: 12),

              // Body con información del crédito
              CreditCardBody(
                credit: credit,
                listType: listType,
              ),

              // Footer con botones de acción
              const SizedBox(height: 12),
              CreditCardFooter(
                credit: credit,
                listType: listType,
                canApprove: canApprove,
                canDeliver: canDeliver,
                onApprove: onApprove,
                onReject: onReject,
                onDeliver: onDeliver,
                onPayment: onPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
