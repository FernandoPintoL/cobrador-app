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
          child: _ModernActionButton(
            onPressed: onApprove,
            icon: Icons.check_circle_rounded,
            label: 'Aprobar',
            gradientColors: const [
              Color(0xFF4CAF50),
              Color(0xFF45A049),
            ],
            shadowColor: Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ModernOutlinedButton(
            onPressed: onReject,
            icon: Icons.cancel_rounded,
            label: 'Rechazar',
            color: Colors.red,
          ),
        ),
      ]);
    }
    // Botones para créditos listos para entrega (solo en el tab "Para Entregar")
    else if (listType == 'ready_for_delivery' && canDeliver) {
      buttons.add(
        Expanded(
          child: _ModernActionButton(
            onPressed: onDeliver,
            icon: Icons.local_shipping_rounded,
            label: 'Confirmar Entrega',
            gradientColors: const [
              Color(0xFF4CAF50),
              Color(0xFF45A049),
            ],
            shadowColor: Colors.green,
          ),
        ),
      );
    }
    // Créditos en espera (aún no listos) solo pueden verse, no entregarse
    else if (listType == 'waiting_delivery') {
      // No hay botón de acción - solo información
      // Los créditos aquí tienen fecha programada futura
    }
    // Botón para pagos en créditos activos
    else if (listType == 'active' && credit.isActive) {
      buttons.add(
        Expanded(
          child: _ModernActionButton(
            onPressed: onPayment,
            icon: Icons.payment_rounded,
            label: 'Registrar Pago',
            gradientColors: const [
              Color(0xFF00897B),
              Color(0xFF00796B),
            ],
            shadowColor: Colors.teal,
          ),
        ),
      );
    }

    return buttons;
  }
}

/// Botón moderno con gradiente para acciones principales
class _ModernActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final List<Color> gradientColors;
  final Color shadowColor;

  const _ModernActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.gradientColors,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Botón moderno outlined para acciones secundarias
class _ModernOutlinedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _ModernOutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
