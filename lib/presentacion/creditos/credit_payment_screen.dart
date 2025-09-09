import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../datos/modelos/credito.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/pago_provider.dart';
import '../../negocio/utils/schedule_utils.dart';
import '../../ui/widgets/validation_error_display.dart';
import '../../ui/widgets/loading_overlay.dart';

class CreditPaymentScreen extends ConsumerStatefulWidget {
  final Credito credit;

  const CreditPaymentScreen({super.key, required this.credit});

  @override
  ConsumerState<CreditPaymentScreen> createState() =>
      _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends ConsumerState<CreditPaymentScreen> {
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  Credito? _credit; // Crédito actualizado desde backend
  bool _isLoadingCredit = true;

  List<PaymentSchedule>? _paymentSchedule;
  PaymentAnalysis? _paymentSimulation;
  bool _isLoadingSchedule = true;
  bool _isProcessing = false;
  String _selectedPaymentType = 'cash';
  int? _currentInstallmentNumber; // cuota a pagar actualmente
  bool _amountEdited = false;

  Credito get _effectiveCredit => _credit ?? widget.credit;

  double _computeSuggestedInstallment() {
    // Calcular cuota sugerida basada en los datos del crédito
    final c = _effectiveCredit;
    final totalAmount = c.totalAmount ??
        (c.interestRate != null
            ? c.amount * (1 + (c.interestRate! / 100))
            : c.amount);
    final rawInstallment = c.installmentAmount ??
        (totalAmount / c.totalInstallments);
    // Sugerir no más que el saldo pendiente
    final balance = c.balance;
    final suggested = balance > 0
        ? (rawInstallment <= balance ? rawInstallment : balance)
        : rawInstallment;
    // Evitar números negativos o NaN
    return suggested.isFinite && suggested > 0 ? suggested : rawInstallment;
  }

  // Fecha de referencia centralizada en ScheduleUtils.referenceDate()
  DateTime _referenceDate() => ScheduleUtils.referenceDate();

  int? _findCurrentInstallmentNumber() {
    final schedule = _paymentSchedule;
    if (schedule == null || schedule.isEmpty) return null;
    return ScheduleUtils.findCurrentInstallmentNumber<PaymentSchedule>(
      schedule,
      getDueDate: (x) => x.dueDate,
      getInstallmentNumber: (x) => x.installmentNumber,
      isPaid: (x) => _isInstallmentPaid(x),
      refDate: _referenceDate(),
    );
  }

  @override
  void initState() {
    super.initState();
    print('datos del crédito (pasado): ${widget.credit.toJson()}');
    // Prefijar el campo de monto con la "Cuota Sugerida" a partir de los datos disponibles
    try {
      final suggested = _computeSuggestedInstallment();
      _amountController.text = suggested.toStringAsFixed(2);
    } catch (_) {
      // Si algo falla, dejar vacío sin bloquear la pantalla
    }
    // Programar carga de datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCredit();
      _loadPaymentSchedule();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadCredit() async {
    setState(() {
      _isLoadingCredit = true;
    });
    final fetched = await ref.read(creditProvider.notifier).fetchCreditById(widget.credit.id);
    setState(() {
      _credit = fetched ?? _credit; // mantener el previo si ya existía
      _isLoadingCredit = false;
    });
    // Actualizar el monto sugerido solo si el usuario no lo ha modificado o está vacío
    if (!_amountEdited || _amountController.text.trim().isEmpty) {
      try {
        final suggested = _computeSuggestedInstallment();
        _amountController.text = suggested.toStringAsFixed(2);
      } catch (_) {
        // Silenciar errores de cálculo para no interrumpir la UI
      }
    }
  }

  Future<void> _loadPaymentSchedule() async {
    setState(() {
      _isLoadingSchedule = true;
    });

    final schedule = await ref
        .read(creditProvider.notifier)
        .getPaymentSchedule(_effectiveCredit.id);

    setState(() {
      _paymentSchedule = schedule;
      _currentInstallmentNumber = _findCurrentInstallmentNumber();
      _isLoadingSchedule = false;
    });
  }

  Future<void> _processPayment() async {
    final c = _effectiveCredit;
    // Bloquear si el crédito no está activo
    if (c.status != 'active') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solo se pueden registrar pagos para créditos activos'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0.01) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await ref
        .read(pagoProvider.notifier)
        .processPaymentForCredit(
          creditId: c.id,
          amount: amount,
          paymentType: _selectedPaymentType,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

    setState(() {
      _isProcessing = false;
    });

    if (result != null) {
      // Pago exitoso: regresar a la pantalla anterior y solicitar actualización
      if (mounted) {
        Navigator.pop(context, true);
        return;
      }
    }
  }

  void _showPaymentResult(Map<String, dynamic>? result) {
    final dynamic analysisDyn = (result ?? const {})['payment_analysis'];
    final Map<String, dynamic>? analysis =
        analysisDyn is Map<String, dynamic> ? analysisDyn : null;

    final String message = (analysis != null && analysis['message'] is String)
        ? (analysis!['message'] as String)
        : 'Pago procesado exitosamente';

    final String? type = analysis != null && analysis['type'] is String
        ? analysis!['type'] as String
        : null;
    final int? installmentsCovered =
        analysis != null && analysis['installments_covered'] is int
            ? analysis!['installments_covered'] as int?
            : null;
    final double? excessAmount = analysis != null && analysis['excess_amount'] is num
        ? (analysis!['excess_amount'] as num).toDouble()
        : null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pago Procesado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 8),
            if (type == 'multiple_installments' && installmentsCovered != null)
              Text('Cuotas cubiertas: $installmentsCovered'),
            if (excessAmount != null)
              Text('Exceso: Bs. ${excessAmount.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar mensajes del PagoProvider dentro de build (requerido por Riverpod)
    final pagoStateWatch = ref.watch(pagoProvider);
    ref.listen<PagoState>(pagoProvider, (prev, next) {
      if (!mounted) return;
      if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: Colors.red),
        );
      } else if (next.successMessage != null && next.successMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.successMessage!), backgroundColor: Colors.green),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Procesar Pagos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Información del crédito
                _buildCreditInfo(),
                const SizedBox(height: 16),

                // Cronograma de pagos (calendario)
                _buildPaymentSchedule(),
                const SizedBox(height: 16),

                // Formulario de pago
                _buildPaymentForm(),
                const SizedBox(height: 16),

                // Simulación de pago
                if (_paymentSimulation != null) _buildPaymentSimulation(),
              ],
            ),
          ),
          LoadingOverlay(
            isLoading: _isLoadingCredit || _isLoadingSchedule || _isProcessing || pagoStateWatch.isLoading,
            message: _isProcessing ? 'Procesando pago...' : 'Cargando información...'
          ),
        ],
      ),
    );
  }

  Widget _buildCreditInfo() {
    if (_isLoadingCredit) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final c = _effectiveCredit;
    print("🪙 credit: "+c.toJson().toString());
    final String? id = c.id != null ? '#${c.id}' : null;
    // Usar valores seguros calculando total con interés si es necesario
    final totalAmountSafe = c.totalAmount ??
        (c.interestRate != null ? c.amount * (1 + (c.interestRate! / 100)) : c.amount);
    final installmentAmountSafe = c.installmentAmount ??
        (totalAmountSafe / c.totalInstallments);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Información del Crédito',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  id != null ? ' $id' : '',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cliente:'),
                Text(
                  c.client?.nombre ?? 'Cliente #${c.clientId}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monto Original:'),
                Text(
                  'Bs. ${c.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a Pagar:'),
                Text(
                  'Bs. ${totalAmountSafe!.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo Pendiente:'),
                Text(
                  'Bs. ${c.balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cuota Sugerida:'),
                Text(
                  'Bs. ${installmentAmountSafe.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frecuencia:'),
                Text(
                  c.frequencyLabel,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSchedule() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cronograma de Pagos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (_isLoadingSchedule)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_paymentSchedule == null || _paymentSchedule!.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No se pudo cargar el cronograma de pagos'),
                ),
              )
            else
              _buildScheduleCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCalendar() {
    final schedule = _paymentSchedule!;
    final itemsPerRow = 6; // Una semana

    return Column(
      children: [
        // Fecha actual de referencia
        Builder(builder: (context) {
          final refDate = _referenceDate();
          final isSunday = DateTime.now().weekday == DateTime.sunday;
          final label = 'Fecha de referencia: ' + DateFormat('dd/MM/yyyy').format(refDate);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(label, style: const TextStyle(fontSize: 12)),
            ),
          );
        }),

        // Leyenda
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.green, 'Pagado'),
            _buildLegendItem(Colors.grey.shade300, 'Pendiente'),
            _buildLegendItem(Colors.lightBlueAccent, 'Actual (día de referencia)'),
            _buildLegendItem(Colors.red, 'Vencido'),
          ],
        ),
        const SizedBox(height: 16),

        // Calendario de cuotas
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: itemsPerRow,
            childAspectRatio: 1,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: schedule.length,
          itemBuilder: (context, index) {
            final installment = schedule[index];
            return _buildInstallmentTile(installment);
          },
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  bool _isInstallmentPaid(PaymentSchedule installment) {
    final c = _effectiveCredit;
    // 1) Trust backend status if provided
    if (installment.isPaid) return true;

    // 2) Infer by number of cuotas pagadas según el crédito
    // paidInstallments usa balance e installmentAmount para estimar cuántas cuotas ya se cubrieron
    final paidCount = c.paidInstallments;
    if (paidCount >= installment.installmentNumber) return true;

    // 3) Infer by exact/same-day payment date
    final pagos = c.payments;
    if (pagos != null && pagos.isNotEmpty) {
      for (final p in pagos) {
        final diff = p.paymentDate.difference(installment.dueDate).inDays.abs();
        if (diff <= 1 && (p.status == 'completed' || p.status == 'paid')) {
          return true;
        }
      }
    }

    return false;
  }

  Widget _buildInstallmentTile(PaymentSchedule installment) {
    Color backgroundColor;
    Color textColor = Colors.white;

    final consideredPaid = _isInstallmentPaid(installment);

    // Determinar estados usando utilidades centralizadas
    final refDate = _referenceDate();
    final due = ScheduleUtils.normalize(installment.dueDate);

    final isCurrent = !consideredPaid && (due == refDate) &&
        _currentInstallmentNumber != null &&
        installment.installmentNumber == _currentInstallmentNumber;

    final isOverdueLocal = !consideredPaid && (due.isBefore(refDate));

    if (consideredPaid) {
      backgroundColor = Colors.green;
    } else if (isCurrent) {
      backgroundColor = Colors.lightBlueAccent;
      textColor = Colors.black;
    } else if (isOverdueLocal) {
      backgroundColor = Colors.red;
    } else {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.black87;
    }

    return GestureDetector(
      onTap: () => _showInstallmentDetails(installment),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade400),
        ),
        padding: const EdgeInsets.all(2),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${installment.installmentNumber}',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                DateFormat('dd/MM').format(installment.dueDate),
                style: TextStyle(color: textColor, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInstallmentDetails(PaymentSchedule installment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cuota #${installment.installmentNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Fecha de vencimiento: ${DateFormat('dd/MM/yyyy').format(installment.dueDate)}',
            ),
            const SizedBox(height: 8),
            Text('Monto: Bs. ${installment.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            Text('Estado: ${_getStatusLabel(installment.status)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid':
        return 'Pagado';
      case 'overdue':
        return 'Vencido';
      case 'pending':
        return 'Pendiente';
      default:
        return status;
    }
  }

  Widget _buildPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Procesar Pago',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Monto del pago
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto del Pago *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                prefixText: 'Bs. ',
                helperText: 'Ingresa el monto que está pagando el cliente',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) {
                // Marcar que el usuario editó el campo y limpiar simulación previa
                _amountEdited = true;
                setState(() {
                  _paymentSimulation = null;
                });
              },
            ),
            const SizedBox(height: 16),

            // Tipo de pago
            DropdownButtonFormField<String>(
              value: _selectedPaymentType,
              decoration: const InputDecoration(
                labelText: 'Tipo de Pago',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.payment),
              ),
              items: const [
                DropdownMenuItem(value: 'cash', child: Text('Efectivo')),
                DropdownMenuItem(
                  value: 'transfer',
                  child: Text('Transferencia'),
                ),
                DropdownMenuItem(value: 'check', child: Text('Cheque')),
                DropdownMenuItem(value: 'other', child: Text('Otro')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPaymentType = value ?? 'cash';
                });
              },
            ),
            const SizedBox(height: 16),

            // Notas
            /*TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                helperText: 'Información adicional sobre el pago',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),*/

            // Errores de validación del backend
            Consumer(builder: (context, ref, _) {
              final pagoState = ref.watch(pagoProvider);
              if (pagoState.validationErrors.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ValidationErrorDisplay(errors: pagoState.validationErrors),
              );
            }),

            // Botones de acción
            ElevatedButton.icon(
              onPressed: (_isProcessing || _isLoadingCredit) ? null : _processPayment,
              icon: _isProcessing
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.payment),
              label: const Text('Procesar Pago'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSimulation() {
    final simulation = _paymentSimulation!;

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Simulación de Pago',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(simulation.message),
            const SizedBox(height: 8),

            if (simulation.installmentsCovered != null)
              Text('Cuotas cubiertas: ${simulation.installmentsCovered}'),

            if (simulation.excessAmount != null && simulation.excessAmount! > 0)
              Text(
                'Exceso: Bs. ${simulation.excessAmount!.toStringAsFixed(2)}',
              ),

            Text(
              'Saldo restante: Bs. ${simulation.remainingBalance.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }
}
