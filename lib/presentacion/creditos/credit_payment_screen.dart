import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../datos/modelos/credito.dart';
import '../../negocio/providers/credit_provider.dart';

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

  List<PaymentSchedule>? _paymentSchedule;
  PaymentAnalysis? _paymentSimulation;
  bool _isLoadingSchedule = true;
  bool _isSimulating = false;
  bool _isProcessing = false;
  String _selectedPaymentType = 'cash';

  @override
  void initState() {
    super.initState();
    print('datos del crédito: ${widget.credit.toJson()}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPaymentSchedule();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentSchedule() async {
    setState(() {
      _isLoadingSchedule = true;
    });

    final schedule = await ref
        .read(creditProvider.notifier)
        .getPaymentSchedule(widget.credit.id);

    setState(() {
      _paymentSchedule = schedule;
      _isLoadingSchedule = false;
    });
  }

  Future<void> _simulatePayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isSimulating = true;
    });

    final simulation = await ref
        .read(creditProvider.notifier)
        .simulatePayment(creditId: widget.credit.id, amount: amount);

    setState(() {
      _paymentSimulation = simulation;
      _isSimulating = false;
    });
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    setState(() {
      _isProcessing = true;
    });

    final result = await ref
        .read(creditProvider.notifier)
        .processPayment(
          creditId: widget.credit.id,
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
      // Recargar cronograma después del pago exitoso
      await _loadPaymentSchedule();

      // Mostrar resultado del pago
      if (mounted) {
        _showPaymentResult(result);
      }

      // Limpiar formulario
      _amountController.clear();
      _notesController.clear();
      setState(() {
        _paymentSimulation = null;
      });
    }
  }

  void _showPaymentResult(Map<String, dynamic> result) {
    final analysis = result['payment_analysis'];
    final message = analysis['message'] ?? 'Pago procesado exitosamente';

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
            if (analysis['type'] == 'multiple_installments')
              Text('Cuotas cubiertas: ${analysis['installments_covered']}'),
            if (analysis['excess_amount'] != null)
              Text('Exceso: Bs. ${analysis['excess_amount']}'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Procesar Pagos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
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
    );
  }

  Widget _buildCreditInfo() {
    final totalAmount = widget.credit.totalAmount ?? widget.credit.amount;
    final installmentAmount =
        widget.credit.installmentAmount ??
        (totalAmount / widget.credit.totalInstallments);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información del Crédito',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cliente:'),
                Text(
                  widget.credit.client?.nombre ??
                      'Cliente #${widget.credit.clientId}',
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
                  'Bs. ${widget.credit.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),

            if (widget.credit.interestRate != null &&
                widget.credit.interestRate! > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Interés:'),
                  Text(
                    '${widget.credit.interestRate!.toStringAsFixed(1)}%',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total a Pagar:'),
                Text(
                  'Bs. ${totalAmount.toStringAsFixed(2)}',
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
                  'Bs. ${widget.credit.balance.toStringAsFixed(2)}',
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
                  'Bs. ${installmentAmount.toStringAsFixed(2)}',
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
                  widget.credit.frequencyLabel,
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
    final itemsPerRow = 7; // Una semana

    return Column(
      children: [
        // Leyenda
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildLegendItem(Colors.green, 'Pagado'),
            _buildLegendItem(Colors.grey.shade300, 'Pendiente'),
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

  Widget _buildInstallmentTile(PaymentSchedule installment) {
    Color backgroundColor;
    Color textColor = Colors.white;

    if (installment.isPaid) {
      backgroundColor = Colors.green;
    } else if (installment.isOverdue) {
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
        child: Column(
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
                // Limpiar simulación previa cuando cambie el monto
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
                DropdownMenuItem(value: 'card', child: Text('Tarjeta')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPaymentType = value ?? 'cash';
                });
              },
            ),
            const SizedBox(height: 16),

            // Notas
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (Opcional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
                helperText: 'Información adicional sobre el pago',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isSimulating ? null : _simulatePayment,
                    icon: _isSimulating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.calculate),
                    label: const Text('Simular'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _processPayment,
                    icon: _isProcessing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payment),
                    label: const Text('Procesar Pago'),
                  ),
                ),
              ],
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
