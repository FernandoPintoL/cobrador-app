import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../datos/modelos/api_exception.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/modelos/cash_balance_status.dart';
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
  CashBalanceStatus? cashBalanceStatus;

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
    // 🔒 Validación de seguridad: Verificar estado de caja ANTES de procesar
    if (isCobrador) {
      if (cashBalanceStatus == null) {
        _showSnackBar(
          'No se pudo verificar el estado de caja. Intenta reabrir el diálogo de pago.',
          isError: true,
        );
        return;
      }

      if (!cashBalanceStatus!.isOpen) {
        final message = cashBalanceStatus!.hasPendingClosures
            ? 'No puedes procesar pagos. Debes cerrar las cajas pendientes de días anteriores.'
            : 'No puedes procesar pagos. Debes abrir la caja de hoy primero.';
        _showSnackBar(message, isError: true);
        return;
      }
    }

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

      // Verificar estado de la caja usando el nuevo endpoint
      setState(() => isCajaOpenChecking = true);
      try {
        final cobradorId = usuario!.id.toInt();
        debugPrint('🔍 Verificando estado de caja para cobrador=$cobradorId');

        final cashApi = CashBalanceApiService();
        final response = await cashApi.getCurrentStatus(cobradorId: cobradorId);

        if (response['success'] == true) {
          final data = response['data'];
          final status = CashBalanceStatus.fromJson(data as Map<String, dynamic>);
          debugPrint('✅ Estado de caja obtenido: $status');

          setState(() {
            cashBalanceStatus = status;
          });

          // Mostrar diálogo según el estado
          if (mounted) {
            _handleCashBalanceStatus(status);
          }
        } else {
          debugPrint('❌ Error al obtener estado de caja');
          setState(() {
            cashBalanceStatus = null;
          });
        }
      } catch (e) {
        debugPrint('❌ Error al verificar estado de caja: $e');
        setState(() {
          cashBalanceStatus = null;
        });
      } finally {
        setState(() => isCajaOpenChecking = false);
      }
    } catch (e) {
      debugPrint('❌ Error en _checkIfCobrador: $e');
    }
  }

  /// Maneja el estado de la caja y muestra diálogos según sea necesario
  void _handleCashBalanceStatus(CashBalanceStatus status) {
    // Caso 1: Todo OK - caja abierta sin pendientes
    if (status.isOpen && !status.hasPendingClosures) {
      // Todo bien, no hacer nada
      return;
    }

    // Caso 2: Caja NO abierta, CON cajas pendientes
    if (!status.isOpen && status.hasPendingClosures) {
      _showCashBalanceErrorDialog(
        title: 'Cajas Pendientes de Cerrar',
        message:
            'Tienes ${status.pendingClosures.length} caja(s) pendiente(s) de cerrar:\n\n'
            '${status.pendingClosures.map((c) => '• ${DateFormat('dd/MM/yyyy').format(DateTime.parse(c.date))}').join('\n')}\n\n'
            'Debes cerrar estas cajas antes de poder procesar pagos.',
        icon: Icons.warning_amber_rounded,
        iconColor: Colors.orange,
      );
      return;
    }

    // Caso 3: Caja NO abierta, sin pendientes
    if (!status.isOpen && !status.hasPendingClosures) {
      _showCashBalanceErrorDialog(
        title: 'Caja No Abierta',
        message:
            'No has abierto la caja de hoy (${DateFormat('dd/MM/yyyy').format(DateTime.parse(status.date))}).\n\n'
            'Debes abrir la caja antes de poder procesar pagos.',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    // Caso 4: Caja abierta, PERO hay cajas pendientes
    if (status.isOpen && status.hasPendingClosures) {
      _showCashBalanceWarningDialog(
        title: 'Advertencia: Cajas Pendientes',
        message:
            'Tu caja de hoy está abierta, pero tienes ${status.pendingClosures.length} caja(s) pendiente(s) de cerrar:\n\n'
            '${status.pendingClosures.map((c) => '• ${DateFormat('dd/MM/yyyy').format(DateTime.parse(c.date))}').join('\n')}\n\n'
            'Puedes procesar el pago, pero recuerda cerrar estas cajas pronto.',
      );
      return;
    }
  }

  /// Muestra un diálogo de error con opción de ir a la pantalla de cajas
  Future<void> _showCashBalanceErrorDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo de error
              Navigator.pop(context); // Cerrar diálogo de pago
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo de error
              Navigator.pop(context); // Cerrar diálogo de pago
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashBalancesListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Ir a Cajas'),
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo de advertencia
  Future<void> _showCashBalanceWarningDialog({
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo de advertencia
              Navigator.pop(context); // Cerrar diálogo de pago
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CashBalancesListScreen(),
                ),
              );
            },
            icon: const Icon(Icons.account_balance_wallet),
            label: const Text('Ir a Cajas'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context), // Solo cerrar advertencia
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
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

  /// Determina si el botón de pago debe estar deshabilitado
  /// basándose en el estado de la caja del cobrador
  bool _shouldDisablePaymentButton() {
    // Si no es cobrador, no aplicar restricción
    if (!isCobrador) return false;

    // Bloquear si no se pudo verificar el estado de la caja
    if (cashBalanceStatus == null) return true;

    // Bloquear si la caja no está abierta
    if (!cashBalanceStatus!.isOpen) return true;

    // Permitir el pago si la caja está abierta
    // (incluso si hay cajas pendientes, se permite con advertencia)
    return false;
  }

  /// Obtiene el mensaje de error para mostrar cuando el botón está deshabilitado
  String? _getDisabledButtonMessage() {
    if (!isCobrador) return null;

    if (cashBalanceStatus == null) {
      return 'No se pudo verificar el estado de caja';
    }

    if (!cashBalanceStatus!.isOpen) {
      if (cashBalanceStatus!.hasPendingClosures) {
        return 'Debes cerrar las cajas pendientes antes de procesar pagos';
      } else {
        return 'Debes abrir la caja de hoy antes de procesar pagos';
      }
    }

    return null;
  }

  /// Determina el color del estado de la caja
  Color _getCajaStatusColor() {
    if (cashBalanceStatus == null) return Colors.grey;

    // Caso 1: Todo OK - caja abierta sin pendientes
    if (cashBalanceStatus!.isOpen && !cashBalanceStatus!.hasPendingClosures) {
      return Colors.green;
    }

    // Caso 2 y 3: Problemas que impiden procesar el pago
    if (!cashBalanceStatus!.isOpen) {
      return Colors.orange;
    }

    // Caso 4: Advertencia - caja abierta pero con pendientes
    if (cashBalanceStatus!.isOpen && cashBalanceStatus!.hasPendingClosures) {
      return Colors.orange;
    }

    return Colors.grey;
  }

  /// Construye el widget de estado de la caja
  Widget _buildCajaStatusWidget() {
    if (cashBalanceStatus == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.grey.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No se pudo verificar el estado de caja',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openCajaManual,
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Ir a Cajas'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.grey.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Caso 1: Todo OK - caja abierta sin pendientes
    if (cashBalanceStatus!.isOpen && !cashBalanceStatus!.hasPendingClosures) {
      return Row(
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
      );
    }

    // Caso 2 y 3: Caja no abierta
    if (!cashBalanceStatus!.isOpen) {
      final hasPending = cashBalanceStatus!.hasPendingClosures;
      return Column(
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
                  hasPending ? 'Cajas pendientes de cerrar' : 'Caja no abierta',
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
            hasPending
                ? 'Debes cerrar ${cashBalanceStatus!.pendingClosures.length} caja(s) pendiente(s) antes de procesar pagos.'
                : 'Debes abrir la caja antes de procesar pagos.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _openCajaManual,
              icon: const Icon(Icons.account_balance_wallet, size: 18),
              label: const Text('Ir a Cajas'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    // Caso 4: Caja abierta pero con pendientes
    if (cashBalanceStatus!.isOpen && cashBalanceStatus!.hasPendingClosures) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Caja abierta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tienes ${cashBalanceStatus!.pendingClosures.length} caja(s) pendiente(s) de cerrar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return const SizedBox.shrink();
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
                    : (_getCajaStatusColor().withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCajaOpenChecking
                      ? Colors.blue.shade200
                      : _getCajaStatusColor().withOpacity(0.3),
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
                  : _buildCajaStatusWidget(),
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
              Tooltip(
                message: _getDisabledButtonMessage() ?? '',
                child: ElevatedButton(
                  onPressed: (isProcessing || _shouldDisablePaymentButton())
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
