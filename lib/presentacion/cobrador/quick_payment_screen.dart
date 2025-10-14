import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/modelos/usuario.dart';
import '../widgets/client_search_widget.dart';
import 'package:intl/intl.dart';

class QuickPaymentScreen extends ConsumerStatefulWidget {
  const QuickPaymentScreen({super.key});

  @override
  ConsumerState<QuickPaymentScreen> createState() => _QuickPaymentScreenState();
}

class _QuickPaymentScreenState extends ConsumerState<QuickPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  Usuario? _selectedClient;
  Credito? _selectedCredit;
  String _paymentMethod = 'cash';
  bool _isProcessing = false;
  String? _clientError;

  @override
  void initState() {
    super.initState();
    // Cargar clientes y créditos activos al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authProvider);
      if (authState.usuario != null) {
        // Cargar clientes
        ref.read(clientProvider.notifier).cargarClientes(
          cobradorId: authState.usuario!.id.toString(),
        );
        // Cargar créditos activos
        ref.read(creditProvider.notifier).loadCredits(
          cobradorId: authState.usuario!.id.toInt(),
          status: 'active',
        );
      }
    });
  }

  void _onClientSelected(Usuario? client) {
    setState(() {
      _selectedClient = client;
      _clientError = null;

      if (client != null) {
        // Buscar el crédito activo de este cliente
        final creditState = ref.read(creditProvider);
        final credit = creditState.credits.firstWhere(
          (c) => c.clientId == client.id && c.isActive,
          orElse: () => creditState.credits.first, // Fallback
        );

        _selectedCredit = credit;
        // Sugerir el monto de la cuota
        _amountController.text = credit.installmentAmount?.toStringAsFixed(2) ?? '';
      } else {
        _selectedCredit = null;
        _amountController.clear();
      }
    });
  }

  Future<void> _processPayment() async {
    if (_selectedCredit == null) {
      _showError('Por favor selecciona un crédito');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Por favor ingresa un monto válido');
      return;
    }

    if (amount > _selectedCredit!.balance) {
      final confirmar = await _showConfirmDialog(
        '¿Confirmar pago?',
        'El monto ingresado (\$${amount.toStringAsFixed(2)}) es mayor al balance (\$${_selectedCredit!.balance.toStringAsFixed(2)}). ¿Deseas continuar?',
      );
      if (!confirmar) return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ref.read(creditProvider.notifier).processPayment(
        creditId: _selectedCredit!.id,
        amount: amount,
        paymentType: _paymentMethod,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      if (result != null && mounted) {
        _showSuccess('Pago registrado exitosamente');
        _resetForm();

        // Recargar créditos
        final authState = ref.read(authProvider);
        if (authState.usuario != null) {
          ref.read(creditProvider.notifier).loadCredits(
            cobradorId: authState.usuario!.id.toInt(),
            status: 'active',
          );
        }
      } else {
        final errorMsg = ref.read(creditProvider).errorMessage;
        _showError(errorMsg ?? 'Error al procesar el pago');
      }
    } catch (e) {
      _showError('Error al procesar el pago: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _selectedClient = null;
      _selectedCredit = null;
      _amountController.clear();
      _notesController.clear();
      _paymentMethod = 'cash';
      _clientError = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final creditState = ref.watch(creditProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro Rápido de Cobros'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Búsqueda de cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buscar Cliente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Usar el widget reutilizable en modo inline
                    ClientSearchWidget(
                      mode: 'inline',
                      selectedClient: _selectedClient,
                      onClientSelected: _onClientSelected,
                      hint: 'Buscar por nombre, teléfono, CI, categoría...',
                      errorText: _clientError,
                      allowClear: true,
                      showClientDetails: true,
                      allowCreate: false, // No permitir crear clientes en quick payment
                    ),

                    // Información del crédito seleccionado
                    if (_selectedClient != null && _selectedCredit != null) ...[
                      const SizedBox(height: 16),
                      SelectedClientCard(
                        cliente: _selectedClient!,
                        onClear: _resetForm,
                        showActions: true,
                      ),

                      // Información adicional del crédito
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Información del Crédito',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const Divider(),
                            _buildInfoRow('Balance:', 'Bs ${_selectedCredit!.balance.toStringAsFixed(2)}'),
                            _buildInfoRow('Cuota:', 'Bs ${_selectedCredit!.installmentAmount?.toStringAsFixed(2) ?? 'N/A'}'),
                            _buildInfoRow('Frecuencia:', _selectedCredit!.frequencyLabel),
                            if (_selectedCredit!.backendIsOverdue == true)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning, size: 16, color: Colors.red),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Crédito con mora: Bs ${_selectedCredit!.overdueAmount?.toStringAsFixed(2) ?? 'N/A'}',
                                      style: const TextStyle(color: Colors.red, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Monto a cobrar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monto a Cobrar',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: 'Bs ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      enabled: _selectedCredit != null && !_isProcessing,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Método de pago
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Método de Pago',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Efectivo'),
                          selected: _paymentMethod == 'cash',
                          onSelected: _selectedCredit != null && !_isProcessing
                              ? (selected) {
                                  if (selected) setState(() => _paymentMethod = 'cash');
                                }
                              : null,
                        ),
                        ChoiceChip(
                          label: const Text('Transferencia'),
                          selected: _paymentMethod == 'transfer',
                          onSelected: _selectedCredit != null && !_isProcessing
                              ? (selected) {
                                  if (selected) setState(() => _paymentMethod = 'transfer');
                                }
                              : null,
                        ),
                        ChoiceChip(
                          label: const Text('Tarjeta'),
                          selected: _paymentMethod == 'card',
                          onSelected: _selectedCredit != null && !_isProcessing
                              ? (selected) {
                                  if (selected) setState(() => _paymentMethod = 'card');
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /*const SizedBox(height: 16),

            // Notas opcionales
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas (opcional)',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Observaciones sobre el pago...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      enabled: _selectedCredit != null && !_isProcessing,
                    ),
                  ],
                ),
              ),
            ),*/

            const SizedBox(height: 24),

            // Botón de registro
            ElevatedButton(
              onPressed: _selectedCredit != null && !_isProcessing ? _processPayment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Registrar Cobro',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
