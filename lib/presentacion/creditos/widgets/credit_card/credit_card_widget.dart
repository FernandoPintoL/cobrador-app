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
    final VoidCallback? onCancel;

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
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    // Obtener información del tema
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Obtener cuotas atrasadas del backend (las que ya vencieron sin pagar)
    final overdueInstallments = credit.backendOverdueInstallments ?? 0;

    // Color basado en severidad del backend
    final overdueSeverity = credit.backendOverdueSeverity ?? 'none';
    late Color overdueColor;
    late IconData overdueIcon;

    switch (overdueSeverity) {
      case 'light':
        overdueColor = Colors.amber;
        overdueIcon = Icons.warning_amber;
        break;
      case 'moderate':
        overdueColor = Colors.orange;
        overdueIcon = Icons.warning;
        break;
      case 'critical':
        overdueColor = Colors.red;
        overdueIcon = Icons.error;
        break;
      default: // 'none'
        overdueColor = Colors.green;
        overdueIcon = Icons.check_circle;
    }

    // Solo mostrar indicadores para créditos activos CON cuotas atrasadas
    final isActiveCredit = credit.status == 'active';
    final showOverdueIndicators = isActiveCredit && overdueInstallments > 0;

    // Colores para borde - Solo el borde indica el estado de mora
    late Color borderColor;
    late double borderWidth;

    if (showOverdueIndicators) {
      // Crédito activo con cuotas atrasadas: borde con color de severidad
      borderColor = overdueColor;
      borderWidth = 2.5;
    } else {
      // Crédito sin cuotas atrasadas: borde neutro
      borderColor = isDarkMode
          ? colorScheme.outline.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.25);
      borderWidth = 1.5;
    }

    // Fondo neutro adaptado al modo oscuro
    final backgroundColor = isDarkMode
        ? colorScheme.surface
        : Colors.white;

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
                color: showOverdueIndicators
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
                // Banner de cuotas ATRASADAS en la parte superior
                // Solo mostrar para créditos activos con cuotas vencidas sin pagar
                if (showOverdueIndicators &&
                    listType != 'ready_for_delivery' &&
                    listType != 'overdue_delivery')
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          overdueColor,
                          overdueColor.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: overdueColor.withValues(alpha: 0.3),
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
                        Icon(overdueIcon, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          '$overdueInstallments cuota${overdueInstallments > 1 ? 's' : ''} atrasada${overdueInstallments > 1 ? 's' : ''}',
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
                            onCancel: onCancel,
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
