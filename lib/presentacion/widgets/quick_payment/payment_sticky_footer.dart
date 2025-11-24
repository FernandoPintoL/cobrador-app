import 'package:flutter/material.dart';

/// Sticky footer para la acción de pago rápido
/// Siempre visible en la parte inferior de la pantalla
class PaymentStickyFooter extends StatelessWidget {
  final TextEditingController amountController;
  final String selectedPaymentMethod;
  final bool isProcessing;
  final VoidCallback onProcessPayment;
  final Function(String) onPaymentMethodChanged;

  const PaymentStickyFooter({
    super.key,
    required this.amountController,
    required this.selectedPaymentMethod,
    required this.isProcessing,
    required this.onProcessPayment,
    required this.onPaymentMethodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila principal con monto, método de pago y botón
              Row(
                children: [
                  // Campo de monto
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        prefixText: 'Bs ',
                        hintText: '0.00',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        prefixStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      enabled: !isProcessing,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Selector de método de pago
                  Expanded(
                    flex: 2,
                    child: PopupMenuButton<String>(
                      initialValue: selectedPaymentMethod,
                      enabled: !isProcessing,
                      onSelected: onPaymentMethodChanged,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _getPaymentMethodIcon(selectedPaymentMethod),
                              size: 18,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _getPaymentMethodLabel(selectedPaymentMethod),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 20,
                              color: Colors.grey[700],
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'cash',
                          child: Row(
                            children: [
                              Icon(
                                Icons.money,
                                size: 18,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 8),
                              const Text('Efectivo'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'transfer',
                          child: Row(
                            children: [
                              Icon(
                                Icons.account_balance,
                                size: 18,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              const Text('Transferencia'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'card',
                          child: Row(
                            children: [
                              Icon(
                                Icons.credit_card,
                                size: 18,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 8),
                              const Text('Tarjeta'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Botón de pago
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isProcessing ? null : onProcessPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'PAGAR',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'transfer':
        return Icons.account_balance;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transf.';
      case 'card':
        return 'Tarjeta';
      default:
        return method;
    }
  }
}
