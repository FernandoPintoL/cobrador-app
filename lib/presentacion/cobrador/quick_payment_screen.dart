import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/pago_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/modelos/usuario.dart';
import '../widgets/error_handler.dart';

class QuickPaymentScreen extends ConsumerStatefulWidget {
  const QuickPaymentScreen({super.key});

  @override
  ConsumerState<QuickPaymentScreen> createState() => _QuickPaymentScreenState();
}

class _QuickPaymentScreenState extends ConsumerState<QuickPaymentScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Usuario? _selectedClient;
  Credito? _selectedCredit;
  String _paymentMethod = 'cash';
  bool _isProcessing = false;
  List<Credito> _searchResults = [];
  bool _loadingResults = false;
  bool _showSearchResults = false;

  /// Busca créditos por CI o nombre de cliente
  /// Usa el mismo endpoint que credit_type_screen: GET /api/credits?search=...
  Future<void> _searchCredits(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _loadingResults = true;
      _showSearchResults = true;
    });

    try {
      // Usar el mismo endpoint de credit_type_screen
      // GET /api/credits?search=8956887&page=1&per_page=15
      await ref
          .read(creditProvider.notifier)
          .loadCredits(
            search: query,
            status: 'active', // Solo créditos activos
            page: 1,
          );

      final creditState = ref.read(creditProvider);

      // Extraer créditos que tengan cliente asociado
      final creditsWithClient = creditState.credits
          .where((c) => c.client != null)
          .toList();

      setState(() {
        _searchResults = creditsWithClient;
        _loadingResults = false;
      });

      if (_searchResults.isEmpty) {
        _showError('No hay créditos activos para "$query"');
      }
    } catch (e) {
      setState(() {
        _loadingResults = false;
      });
      _showError('Error al buscar: $e');
    }
  }

  /// Selecciona un cliente y crédito desde los resultados de búsqueda
  void _selectFromSearchResults(Credito credit) {
    if (credit.client == null) {
      _showError('Información de cliente incompleta');
      return;
    }

    setState(() {
      _selectedClient = credit.client;
      _selectedCredit = credit;
      _searchResults = [];
      _showSearchResults = false;
      _searchController.text =
          '${credit.client!.nombre} (CI: ${credit.client!.ci})';
      _amountController.text =
          credit.installmentAmount?.toStringAsFixed(2) ?? '';
    });
    _searchFocusNode.unfocus();
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
        'El monto ingresado (Bs ${amount.toStringAsFixed(2)}) es mayor al balance (Bs ${_selectedCredit!.balance.toStringAsFixed(2)}). ¿Deseas continuar?',
      );
      if (!confirmar) return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await ref
          .read(creditProvider.notifier)
          .processPayment(
            creditId: _selectedCredit!.id,
            amount: amount,
            paymentType: _paymentMethod,
          );

      if (result != null && mounted) {
        _showSuccess('Pago registrado exitosamente');
        _resetForm();

        // Recargar créditos del cliente si es necesario
        if (_selectedClient != null) {
          _searchCredits(_searchController.text);
        }
      } else if (mounted) {
        // Obtener el mensaje de error del estado del provider de pago
        final pagoState = ref.read(pagoProvider);
        final errorMsg = pagoState.errorMessage ?? 'Error al procesar el pago';
        _showError(errorMsg);
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
      _searchController.clear();
      _paymentMethod = 'cash';
      _searchResults = [];
      _showSearchResults = false;
    });
  }

  void _showError(String message) {
    if (mounted) {
      ErrorHandler.showError(context, message);
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ErrorHandler.showSuccess(context, message);
    }
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
            // Búsqueda de cliente/crédito
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buscar Cliente por CI o Nombre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo de búsqueda dinámica
                    TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText:
                            'Ingresa CI o nombre del cliente (ej: 8956887)',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _selectedClient != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _resetForm,
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: _searchCredits,
                    ),

                    // Resultados de búsqueda
                    if (_showSearchResults && _searchResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 300),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final credit = _searchResults[index];
                            final isSelected = _selectedCredit?.id == credit.id;

                            return ListTile(
                              dense: true,
                              selected: isSelected,
                              title: Text(
                                '${credit.client?.nombre ?? "N/A"} - Crédito #${credit.id}',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(
                                'CI: ${credit.client?.ci ?? "N/A"} | Balance: Bs ${credit.balance.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () => _selectFromSearchResults(credit),
                            );
                          },
                        ),
                      ),
                    ],

                    if (_loadingResults) ...[
                      const SizedBox(height: 12),
                      const Center(child: CircularProgressIndicator()),
                    ],
                  ],
                ),
              ),
            ),

            // Detalles del crédito seleccionado
            if (_selectedCredit != null) ...[
              const SizedBox(height: 16),
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
                      'Detalles del Crédito Seleccionado',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const Divider(),
                    _buildInfoRow('Cliente:', _selectedClient?.nombre ?? 'N/A'),
                    _buildInfoRow(
                      'Balance:',
                      'Bs ${_selectedCredit!.balance.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      'Monto Original:',
                      'Bs ${_selectedCredit!.amount.toStringAsFixed(2)}',
                    ),
                    _buildInfoRow(
                      'Cuota:',
                      'Bs ${_selectedCredit!.installmentAmount?.toStringAsFixed(2) ?? 'N/A'}',
                    ),
                    _buildInfoRow(
                      'Frecuencia:',
                      _selectedCredit!.frequencyLabel,
                    ),
                    _buildInfoRow(
                      'Tasa de Interés:',
                      '${_selectedCredit!.interestRate ?? 0}%',
                    ),
                    if (_selectedCredit!.backendIsOverdue == true)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.warning,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Crédito con mora: Bs ${_selectedCredit!.overdueAmount?.toStringAsFixed(2) ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Monto a cobrar
            if (_selectedCredit != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Monto a Cobrar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'Bs ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        enabled: !_isProcessing,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Método de pago
            if (_selectedCredit != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Método de Pago',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Efectivo'),
                            selected: _paymentMethod == 'cash',
                            onSelected: !_isProcessing
                                ? (selected) {
                                    if (selected) {
                                      setState(() => _paymentMethod = 'cash');
                                    }
                                  }
                                : null,
                          ),
                          ChoiceChip(
                            label: const Text('Transferencia'),
                            selected: _paymentMethod == 'transfer',
                            onSelected: !_isProcessing
                                ? (selected) {
                                    if (selected) {
                                      setState(
                                        () => _paymentMethod = 'transfer',
                                      );
                                    }
                                  }
                                : null,
                          ),
                          ChoiceChip(
                            label: const Text('Tarjeta'),
                            selected: _paymentMethod == 'card',
                            onSelected: !_isProcessing
                                ? (selected) {
                                    if (selected) {
                                      setState(() => _paymentMethod = 'card');
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            if (_selectedCredit == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Busca un cliente para ver sus créditos activos',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Botón de registro
            ElevatedButton(
              onPressed: _selectedCredit != null && !_isProcessing
                  ? _processPayment
                  : null,
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
                      'Procesar Pago',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
