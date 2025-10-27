import 'package:flutter/material.dart';
import '../../../../datos/modelos/credito.dart';
import '../../../reports/utils/report_formatters.dart';
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
    // Obtener información del tema
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Obtener estado de pago basado en cuotas (prioridad sobre fechas)
    final totalInstallments = credit.backendTotalInstallments;
    final paidInstallments = credit.paidInstallmentsCount;
    final paymentStatusColor = ReportFormatters.colorForPaymentStatus(totalInstallments, paidInstallments);
    final paymentStatusIcon = ReportFormatters.getPaymentStatusIcon(totalInstallments, paidInstallments);
    final paymentStatusLabel = ReportFormatters.getPaymentStatusLabel(totalInstallments, paidInstallments);

    // Determinar severidad basada en estado de pago
    final pendingInstallments = ReportFormatters.calculatePendingInstallments(totalInstallments, paidInstallments);
    final isCriticalPayment = pendingInstallments > 3;

    // Colores para fondo y borde - Adaptables a modo oscuro/claro
    late Color backgroundColor;
    late Color borderColor;

    if (pendingInstallments > 0) {
      // Con cuotas pendientes: usar color semi-transparente basado en estado de pago
      // Opacidad aumentada para mejor visibilidad del color
      final alpha = 0.25; // 25% - Balance entre visibilidad y legibilidad
      backgroundColor = paymentStatusColor.withValues(alpha: alpha);
      borderColor = paymentStatusColor.withValues(alpha: 0.6);
    } else {
      // Todas las cuotas pagadas: blanco en claro, superficie oscura en oscuro
      backgroundColor = isDarkMode
          ? colorScheme.surface
          : Colors.white;
      borderColor = isDarkMode
          ? colorScheme.outline.withValues(alpha: 0.2)
          : Colors.grey.withValues(alpha: 0.2);
    }

    // Icono diferencial para el estado de pago
    final statusBadgeIcon = paymentStatusIcon;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCriticalPayment ? 4 : 2,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: pendingInstallments > 0 ? 2.5 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: backgroundColor,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Contenido principal
              Padding(
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
              // Badge de estado de pago en la esquina superior derecha - Adaptable a tema
              if (pendingInstallments > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: paymentStatusColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: paymentStatusColor.withValues(
                            alpha: isDarkMode ? 0.6 : 0.4,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          statusBadgeIcon,
                          size: 16,
                          color: isDarkMode ? Colors.black : Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$pendingInstallments',
                          style: TextStyle(
                            color: isDarkMode ? Colors.black : Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
