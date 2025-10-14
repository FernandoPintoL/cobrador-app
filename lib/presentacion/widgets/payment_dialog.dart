import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../datos/modelos/api_exception.dart';
import '../../datos/modelos/credito.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/api_services/cash_balance_api_service.dart';
import '../cajas/cash_balances_list_screen.dart';

class PaymentDialog extends ConsumerStatefulWidget {
  final Credito credit;
  final Map<String, dynamic>? creditSummary;
  final VoidCallback? onPaymentSuccess;

  const PaymentDialog({
    super.key,
    required this.credit,
    this.creditSummary,
    this.onPaymentSuccess,
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
  }) async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        credit: credit,
        creditSummary: creditSummary,
        onPaymentSuccess: onPaymentSuccess,
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

  const PaymentForm({
    super.key,
    required this.credit,
    this.creditSummary,
    this.onPaymentSuccess,
    this.onCancel,
    this.onFinished,
  });

  @override
  ConsumerState<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<PaymentForm> {
  late TextEditingController amountController;
  late TextEditingController notesController;
  bool isProcessing = false;
  String selectedPaymentType = 'cash';
  bool isCobrador = false;
  bool isCajaOpenChecking = false;
  bool isCajaOpen = false;

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
    notesController = TextEditingController();
    _calculateSuggestedAmount();
    // Verificar rol de usuario y estado de caja al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkIfCobrador();
    });
  }

  @override
  void dispose() {
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _calculateSuggestedAmount() {
    double suggestedAmount = 0.0;

    if (widget.creditSummary != null) {
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
            message ?? result?['message'] ?? 'Error al procesar pago';
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

  Future<void> _checkIfCobrador() async {
    try {
      final authState = ref.read(authProvider);
      final usuario = authState.usuario;
      final esC = usuario?.esCobrador() ?? false;
      setState(() {
        isCobrador = esC;
      });
      if (!esC) return;

      // Verificar si hay caja abierta usando el endpoint idempotente
      setState(() => isCajaOpenChecking = true);
      try {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final resp = await CashBalanceApiService().openCashBalance(
          cobradorId: usuario!.id.toInt(),
          date: today,
        );
        // Consideramos 'success' o ausencia de excepción como caja abierta
        final ok = resp['success'] == true || resp['status'] == 'ok';
        setState(() {
          isCajaOpen = ok;
        });
      } on ApiException catch (e) {
        // Error 422: Cajas pendientes de cierre
        if (e.statusCode == 422) {
          setState(() {
            isCajaOpen = false;
          });
          if (mounted) {
            _mostrarDialogoCajasPendientes(
              e.errorData?['data']?['pending_boxes'],
            );
          }
        } else {
          setState(() {
            isCajaOpen = false;
          });
        }
      } catch (_) {
        setState(() {
          isCajaOpen = false;
        });
      } finally {
        setState(() => isCajaOpenChecking = false);
      }
    } catch (e) {
      // ignore errors silently
    }
  }

  void _openCajaManual() {
    // En lugar de intentar abrir la caja, redirigimos al usuario a la pantalla de cajas
    // para que pueda gestionar primero el cierre de la caja pendiente
    Navigator.pop(context); // Cerrar el diálogo de pago
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CashBalancesListScreen()),
    );
  }

  void _mostrarDialogoCajasPendientes(dynamic pendingBoxesData) {
    if (pendingBoxesData == null) return;

    // Convertir datos a lista
    final List<Map<String, dynamic>> pendingBoxes = [];
    if (pendingBoxesData is List) {
      for (final box in pendingBoxesData) {
        if (box is Map) {
          pendingBoxes.add(Map<String, dynamic>.from(box));
        }
      }
    }

    if (pendingBoxes.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: false, // No puede cerrar tocando fuera
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade700,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cajas Pendientes',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Debes cerrar las siguientes cajas antes de abrir una nueva:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                ...pendingBoxes.map((caja) {
                  final fechaStr = caja['date']?.toString() ?? '';
                  DateTime? fecha;
                  try {
                    fecha = DateTime.parse(fechaStr);
                  } catch (_) {}

                  final monto =
                      caja['final_amount'] ?? caja['collected_amount'] ?? 0;

                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.orange.shade700,
                        child: Icon(
                          Icons.money_off,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        'Caja #${caja['id']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (fecha != null)
                            Text(
                              'Fecha: ${DateFormat('dd/MM/yyyy').format(fecha)}',
                            ),
                          Text(
                            'Monto: Bs. ${NumberFormat('#,##0.00').format(monto)}',
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Entendido'),
            ),
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context); // Cerrar diálogo actual
                Navigator.pop(context); // Cerrar diálogo de pago
                // Navegar a la pantalla de cajas
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CashBalancesListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.account_balance_wallet),
              label: const Text('Ver Cajas'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: isError ? Colors.red : Colors.green,
          action: isError
              ? null
              : SnackBarAction(
                  label: 'OK',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
        ),
      );
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
                  'Información del Crédito',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                if (suggestedAmount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cuota sugerida:'),
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
          // Si el usuario es cobrador, mostrar estado de caja y opción para abrirla
          if (isCobrador) ...[
            Container(
              decoration: BoxDecoration(
                color: isCajaOpenChecking
                    ? Colors.blue.shade50
                    : (!isCajaOpen
                          ? Colors.orange.shade50
                          : Colors.green.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCajaOpenChecking
                      ? Colors.blue.shade200
                      : (!isCajaOpen
                            ? Colors.orange.shade300
                            : Colors.green.shade300),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: isCajaOpenChecking
                  ? Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Verificando estado de caja...',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    )
                  : (!isCajaOpen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Caja no abierta',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Debe abrir la caja antes de procesar pagos. Los pagos se registrarán en la caja del día actual.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: isCajaOpenChecking
                                      ? null
                                      : _openCajaManual,
                                  icon: const Icon(Icons.lock_open, size: 18),
                                  label: const Text('Abrir caja ahora'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.orange.shade700,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Caja abierta correctamente',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          )),
            ),
            const SizedBox(height: 16),
          ],
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
            children: [
              TextButton(
                onPressed: isProcessing
                    ? null
                    : () {
                        /* widget.onCancel?.call();
                        // Solo llamar a onFinished si está definido
                        if (widget.onFinished != null) {
                          widget.onFinished!({
                            'success': false,
                            'message': null,
                          });
                        } else {
                          Navigator.of(context).pop();
                        } */
                        Navigator.of(context).pop();
                      },
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
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
                    : const Text('Procesar Pago'),
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
