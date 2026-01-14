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
    final paymentStatusColor = ReportFormatters.colorForPaymentStatus(
      totalInstallments,
      paidInstallments,
    );
    final paymentStatusIcon = ReportFormatters.getPaymentStatusIcon(
      totalInstallments,
      paidInstallments,
    );

    // Determinar cuotas pendientes
    final pendingInstallments = ReportFormatters.calculatePendingInstallments(
      totalInstallments,
      paidInstallments,
    );

    // Solo mostrar indicadores de cuotas para créditos activos
    final isActiveCredit = credit.status == 'active';
    final showPaymentIndicators = isActiveCredit && pendingInstallments > 0;

    // Colores para borde - Solo el borde indica el estado
    late Color borderColor;
    late double borderWidth;

    if (showPaymentIndicators) {
      // Crédito activo con cuotas pendientes: borde con color del estado
      borderColor = paymentStatusColor;
      borderWidth = 2.5;
    } else {
      // Crédito no activo o sin cuotas pendientes: borde neutro
      borderColor = isDarkMode
          ? colorScheme.outline.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.25);
      borderWidth = 1.5;
    }

    // Fondo neutro adaptado al modo oscuro
    final backgroundColor = isDarkMode
        ? colorScheme.surface
        : Colors.white;

    // Icono diferencial para el estado de pago
    final statusBadgeIcon = paymentStatusIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 0,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: showPaymentIndicators
                    ? borderColor.withValues(alpha: isDarkMode ? 0.4 : 0.25)
                    : (isDarkMode
                        ? Colors.black.withValues(alpha: 0.3)
                        : Colors.grey.withValues(alpha: 0.1)),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Banner de cuotas pendientes en la parte superior
                // Solo mostrar para créditos activos (no pending_approval, waiting_delivery, etc.)
                if (showPaymentIndicators &&
                    listType != 'ready_for_delivery' &&
                    listType != 'overdue_delivery')
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          paymentStatusColor,
                          paymentStatusColor.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: paymentStatusColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(statusBadgeIcon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '$pendingInstallments cuota${pendingInstallments > 1 ? 's' : ''} pendiente${pendingInstallments > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Contenido principal con InkWell para ripple effect
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(20),
                    splashColor: borderColor.withValues(alpha: 0.1),
                    highlightColor: borderColor.withValues(alpha: 0.05),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header con cliente y estado
                          CreditCardHeader(credit: credit),

                          const SizedBox(height: 16),

                          // Divider sutil
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  (isDarkMode ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Body con información del crédito
                          CreditCardBody(
                            credit: credit,
                            listType: listType,
                          ),

                          // Footer con botones de acción
                          const SizedBox(height: 16),
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
