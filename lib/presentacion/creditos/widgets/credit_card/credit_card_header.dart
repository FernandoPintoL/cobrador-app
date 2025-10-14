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
        CreditStatusChip(status: credit.status),
      ],
    );
  }
}
