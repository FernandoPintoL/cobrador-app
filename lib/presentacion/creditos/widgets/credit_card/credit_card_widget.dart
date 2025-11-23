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

    // Determinar severidad basada en estado de pago
    final pendingInstallments = ReportFormatters.calculatePendingInstallments(
      totalInstallments,
      paidInstallments,
    );
    final isCriticalPayment = pendingInstallments > 3;

    // Colores para fondo y borde - Diseño modernizado con gradientes
    late Color borderColor;
    late List<Color> gradientColors;

    if (pendingInstallments > 0) {
      // Con cuotas pendientes: usar gradiente basado en estado de pago
      borderColor = paymentStatusColor.withValues(alpha: 0.3);
      gradientColors = [
        paymentStatusColor.withValues(alpha: 0.12),
        paymentStatusColor.withValues(alpha: 0.04),
      ];
    } else {
      // Todas las cuotas pagadas: gradiente neutro elegante
      borderColor = isDarkMode
          ? colorScheme.outline.withValues(alpha: 0.15)
          : Colors.grey.withValues(alpha: 0.15);
      gradientColors = isDarkMode
          ? [colorScheme.surface, colorScheme.surface.withValues(alpha: 0.95)]
          : [Colors.white, Colors.grey.withValues(alpha: 0.02)];
    }

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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: borderColor,
              width: pendingInstallments > 0 ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: pendingInstallments > 0
                    ? paymentStatusColor.withValues(alpha: 0.15)
                    : (isDarkMode
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.08)),
                blurRadius: isCriticalPayment ? 20 : 12,
                offset: const Offset(0, 6),
                spreadRadius: isCriticalPayment ? 2 : 0,
              ),
              if (!isDarkMode)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.5),
                  blurRadius: 1,
                  offset: const Offset(-1, -1),
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
                if (pendingInstallments > 0)
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

                // Contenido principal con Stack para patrón de fondo
                Stack(
                  children: [
                    // Patrón de fondo sutil
                    if (pendingInstallments > 0)
                      Positioned(
                        right: -30,
                        bottom: -30,
                        child: Opacity(
                          opacity: 0.03,
                          child: Icon(
                            statusBadgeIcon,
                            size: 120,
                            color: paymentStatusColor,
                          ),
                        ),
                      ),

                    // Contenido principal con InkWell para ripple effect
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(20),
                        splashColor: paymentStatusColor.withValues(alpha: 0.1),
                        highlightColor: paymentStatusColor.withValues(
                          alpha: 0.05,
                        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
