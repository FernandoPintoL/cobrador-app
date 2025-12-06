import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../datos/modelos/credito.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/pago_provider.dart';
import 'error_handler.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final Credito credit;
  final Map<String, dynamic>? creditSummary;
  final VoidCallback? onPaymentSuccess;
  final PaymentSchedule? specificInstallment;

  const PaymentDialog({
    super.key,
    required this.credit,
    this.creditSummary,
    this.onPaymentSuccess,
    this.specificInstallment,
  });

  @override
  ConsumerState<PaymentDialog> createState() => _PaymentDialogState();

  /// Método estático para mostrar el diálogo de pago desde cualquier lugar
  static Future<Map<String, dynamic>?> show(
    BuildContext context,
    WidgetRef ref,
    Credito credit, {
    Map<String, dynamic>? creditSummary,
    VoidCallback? onPaymentSuccess,
    PaymentSchedule? specificInstallment,
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        credit: credit,
        creditSummary: creditSummary,
        onPaymentSuccess: onPaymentSuccess,
        specificInstallment: specificInstallment,
      ),
    );
  }
}

class PaymentForm extends ConsumerStatefulWidget {
  final Credito credit;
  final Map<String, dynamic>? creditSummary;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onCancel;
  final void Function(Map<String, dynamic> result)? onFinished;
  final PaymentSchedule? specificInstallment;

  const PaymentForm({
    super.key,
    required this.credit,
    this.creditSummary,
    this.onPaymentSuccess,
    this.onCancel,
    this.onFinished,
    this.specificInstallment,
  });

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  late TextEditingController amountController;
  late TextEditingController notesController;
  bool isProcessing = false;
  String selectedPaymentType = 'cash';

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    notesController = TextEditingController();
    _calculateSuggestedAmount();
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _calculateSuggestedAmount() {
    double suggestedAmount = 0.0;

    // Si se especifica una cuota particular, usar su monto restante
    if (widget.specificInstallment != null) {
      final installment = widget.specificInstallment!;
      // Calcular remaining si no viene del backend
      suggestedAmount = installment.remainingAmount > 0
          ? installment.remainingAmount
          : (installment.amount - installment.paidAmount).clamp(
              0.0,
              installment.amount,
            );
    } else if (widget.creditSummary != null) {
      final installmentValue = widget.creditSummary!['installment_amount'];
      if (installmentValue != null) {
        if (installmentValue is num) {
          suggestedAmount = installmentValue.toDouble();
        } else if (installmentValue is String) {
          suggestedAmount = double.tryParse(installmentValue) ?? 0.0;
        }
      }
    } else if (widget.credit.installmentAmount != null) {
      suggestedAmount = widget.credit.installmentAmount!;
    } else {
      final pendingInstallmentsValue = widget.creditSummary != null
          ? widget.creditSummary!['pending_installments']
          : null;

      int pendingInstallments = 1;
      if (pendingInstallmentsValue != null) {
        if (pendingInstallmentsValue is num) {
          pendingInstallments = pendingInstallmentsValue.toInt();
        } else if (pendingInstallmentsValue is String) {
          pendingInstallments = int.tryParse(pendingInstallmentsValue) ?? 1;
        }
      }

      suggestedAmount = pendingInstallments > 0
          ? widget.credit.balance / pendingInstallments
          : widget.credit.balance;
    }

    suggestedAmount = suggestedAmount > widget.credit.balance
        ? widget.credit.balance
        : suggestedAmount;

    amountController.text = suggestedAmount.toStringAsFixed(2);
  }

  String _formatCurrency(dynamic value) {
    try {
      final num? n = value is num
          ? value
          : (value is String ? num.tryParse(value) : null);
      if (n == null) return 'Bs. 0.00';
      return 'Bs. ' + NumberFormat('#,##0.00').format(n);
    } catch (_) {
      return 'Bs. 0.00';
    }
  }

  Future<void> _processPayment(StateSetter setDialogState) async {
    // Validación de monto
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar('Ingrese un monto válido', isError: true);
      return;
    }
    if (amount > widget.credit.balance) {
      _showSnackBar(
        'El monto no puede ser mayor al saldo pendiente',
        isError: true,
      );
      return;
    }

    setDialogState(() {
      isProcessing = true;
    });

    try {
      Position? currentPosition;
      try {
        debugPrint('📍 Intentando obtener ubicación actual para el pago...');
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.deniedForever ||
            permission == LocationPermission.denied) {
          debugPrint(
            '⚠️ Permisos de ubicación denegados, continuando sin ubicación',
          );
        } else {
          currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );
          debugPrint(
            '✅ Ubicación obtenida: ${currentPosition.latitude}, ${currentPosition.longitude}',
          );
        }
      } catch (e) {
        debugPrint('⚠️ Error al obtener ubicación: $e');
      }

      final result = await ref
          .read(creditProvider.notifier)
          .processPayment(
            creditId: widget.credit.id,
            amount: amount,
            paymentType: selectedPaymentType,
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
            latitude: currentPosition?.latitude,
            longitude: currentPosition?.longitude,
          );
      debugPrint('💰 Resultado del pagos: $result');

      // Si result es null, obtener el error del estado del provider
      if (result == null) {
        final pagoState = ref.read(pagoProvider);
        final errorMessage = pagoState.errorMessage ?? 'Error al procesar pago';
        widget.onFinished?.call({'success': false, 'message': errorMessage});
        return;
      }

      // Normalizar: `result` normalmente es Map<String, dynamic>
      Map<String, dynamic>? mapResult;
      if (result is Map<String, dynamic>) {
        mapResult = result;
      } else {
        mapResult = null;
      }
      bool success = false;
      dynamic message;
      if (mapResult != null) {
        if (mapResult.containsKey('success')) {
          success = mapResult['success'] == true;
          message = mapResult['message'];
        } else {
          success = mapResult.isNotEmpty;
        }
      }

      if (success) {
        // No mostrar Snackbar de éxito aquí: la pantalla padre será la
        // responsable de mostrar el mensaje final y recargar los datos.
        widget.onFinished?.call({'success': true, 'message': null});
        return;
      } else {
        final errorMessage =
            message ?? result['message'] ?? 'Error al procesar pago';
        // Delegar la notificación de error a la pantalla padre
        widget.onFinished?.call({'success': false, 'message': errorMessage});
      }
    } catch (e) {
      // Delegar error al padre
      widget.onFinished?.call({'success': false, 'message': 'Error: $e'});
    } finally {
      if (mounted) {
        setDialogState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (context.mounted) {
      if (isError) {
        ErrorHandler.showError(context, message);
      } else {
        ErrorHandler.showSuccess(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final suggestedAmount = double.tryParse(amountController.text) ?? 0.0;

    return StatefulBuilder(
      builder: (context, setDialogState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del crédito
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.specificInstallment != null
                      ? 'Pago de Cuota #${widget.specificInstallment!.installmentNumber}'
                      : 'Registro de Pago',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.specificInstallment == null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'El sistema aplicará el pago a las cuotas en orden secuencial',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Crédito:'),
                    Text(
                      '#${widget.credit.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Cliente:'),
                    Flexible(
                      child: Text(
                        widget.credit.client?.nombre ??
                            'Cliente #${widget.credit.clientId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (widget.specificInstallment != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monto de cuota:'),
                      Text(
                        _formatCurrency(widget.specificInstallment!.amount),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Ya pagado:'),
                      Text(
                        _formatCurrency(widget.specificInstallment!.paidAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Falta por pagar:'),
                      Builder(
                        builder: (context) {
                          final installment = widget.specificInstallment!;
                          final remaining = installment.remainingAmount > 0
                              ? installment.remainingAmount
                              : (installment.amount - installment.paidAmount)
                                    .clamp(0.0, installment.amount);
                          return Text(
                            _formatCurrency(remaining),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Saldo pendiente:'),
                      Text(
                        _formatCurrency(widget.credit.balance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (suggestedAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.specificInstallment != null
                            ? 'Monto sugerido:'
                            : 'Cuota sugerida:',
                      ),
                      Text(
                        _formatCurrency(suggestedAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Monto del pago
          TextFormField(
            controller: amountController,
            decoration: InputDecoration(
              labelText: 'Monto del pago *',
              hintText: 'Ingrese el monto a pagar',
              prefixText: 'Bs. ',
              border: const OutlineInputBorder(),
              suffixIcon: suggestedAmount > 0
                  ? IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () {
                        _calculateSuggestedAmount();
                        setDialogState(() {});
                      },
                      tooltip: 'Recalcular cuota sugerida',
                    )
                  : null,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              setDialogState(() {});
            },
          ),
          const SizedBox(height: 16),
          // Tipo de pago
          DropdownButtonFormField<String>(
            value: selectedPaymentType,
            decoration: const InputDecoration(
              labelText: 'Tipo de pago',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
              DropdownMenuItem(value: 'transfer', child: Text('Transferencia')),
              DropdownMenuItem(value: 'check', child: Text('Cheque')),
              DropdownMenuItem(value: 'other', child: Text('Otro')),
            ],
            onChanged: (value) {
              if (value != null) {
                setDialogState(() {
                  selectedPaymentType = value;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: isProcessing
                      ? null
                      : () {
                          Navigator.of(context).pop();
                        },
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Cancelar', overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () => _processPayment(setDialogState),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Procesar Pago',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentDialogState extends ConsumerState<PaymentDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.payment, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Procesar Pago',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: PaymentForm(
          credit: widget.credit,
          creditSummary: widget.creditSummary,
          specificInstallment: widget.specificInstallment,
          onPaymentSuccess: widget.onPaymentSuccess,
          onCancel: () {
            if (Navigator.of(context).canPop()) {
              // Asegurar que siempre devolvemos un Map consistente
              Navigator.of(context).pop({'success': false, 'message': null});
            }
          },
          onFinished: (result) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(result);
            }
          },
        ),
      ),
    );
  }
}
