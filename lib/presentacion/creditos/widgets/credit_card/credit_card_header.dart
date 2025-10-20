import 'package:flutter/material.dart';
import '../../../../datos/modelos/credito.dart';
import '../../../../ui/widgets/client_category_chip.dart';
import '../../../widgets/profile_image_widget.dart';
import '../credit_status_chip.dart';

/// Header de la tarjeta de crédito que muestra:
/// - Foto del cliente
/// - ID del crédito
/// - Nombre del cliente
/// - CI y teléfono
/// - Categoría del cliente
/// - Estado del crédito
class CreditCardHeader extends StatelessWidget {
  final Credito credit;

  const CreditCardHeader({
    super.key,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileImageWidget(
          profileImage: credit.client?.profileImage,
          size: 40,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crédito #${credit.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                credit.client?.nombre ?? 'Cliente #${credit.clientId}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "CI.: ${credit.client?.ci ?? ''}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              Text(
                "Cel.: ${credit.client?.telefono ?? ''}",
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                ),
              ),
              // Categoría del cliente (chip)
              if (credit.client?.clientCategory != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: ClientCategoryChip(
                    category: credit.client!.clientCategory,
                    compact: true,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Badge de MORA si tiene pagos atrasados
            if (credit.isOverdue && credit.status == 'active')
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'MORA',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            CreditStatusChip(status: credit.status),
          ],
        ),
      ],
    );
  }
}
