import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/modelos/credito.dart';

class CreditFormScreen extends ConsumerStatefulWidget {
  final Credito? credit; // Para edición
  final Usuario? preselectedClient; // Cliente preseleccionado

  const CreditFormScreen({super.key, this.credit, this.preselectedClient});

  @override
  ConsumerState<CreditFormScreen> createState() => _CreditFormScreenState();
}

class _CreditFormScreenState extends ConsumerState<CreditFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _balanceController = TextEditingController();
  final _paymentAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  Usuario? _selectedClient;
  String _selectedFrequency = 'daily'; // Por defecto diario para 24 días
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    // Usar addPostFrameCallback para cargar clientes después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClients();
    });
  }

  void _initializeForm() {
    if (widget.credit != null) {
      // Modo edición
      final credit = widget.credit!;
      _amountController.text = credit.amount.toString();
      _interestRateController.text = credit.interestRate?.toString() ?? '0';
      _balanceController.text = credit.balance.toString();
      _paymentAmountController.text = credit.paymentAmount?.toString() ?? '';
      _notesController.text = credit.notes ?? '';
      _selectedFrequency = credit.frequency;
      _selectedStatus = credit.status;
      _startDate = credit.startDate;
      _endDate = credit.endDate;
      _startDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(credit.startDate);
      _endDateController.text = DateFormat('dd/MM/yyyy').format(credit.endDate);
      _selectedClient = credit.client;
    } else {
      // Modo creación con valores por defecto optimizados
      _selectedClient = widget.preselectedClient;
      _interestRateController.text = '20'; // Por defecto 20% de interés
      _selectedFrequency = 'daily'; // Por defecto diario
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(
        const Duration(days: 24),
      ); // 24 días por defecto para cuotas diarias
      _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate!);
      _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
    }

    // Calcular automáticamente al inicializar el formulario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCalculations();
    });
  }

  void _loadClients() {
    // Obtener el usuario actual y cargar sus clientes asignados
    final authState = ref.read(authProvider);
    final currentUser = authState.usuario;

    if (currentUser != null) {
      // Si es cobrador, cargar solo sus clientes asignados
      if (currentUser.esCobrador()) {
        ref
            .read(clientProvider.notifier)
            .cargarClientes(cobradorId: currentUser.id.toString());
      } else {
        // Si es manager o admin, cargar todos los clientes
        ref.read(clientProvider.notifier).cargarClientes();
      }
    }
  }

  void _updateCalculations() {
    // Calcular monto total con interés y cuota sugerida
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;

    if (amount > 0 && interestRate >= 0) {
      final totalAmount = amount + (amount * interestRate / 100);

      // Actualizar el saldo total automáticamente
      _balanceController.text = totalAmount.toStringAsFixed(2);

      // Calcular cuota sugerida basada en la frecuencia y fechas
      if (_startDate != null && _endDate != null) {
        int numberOfPayments = _calculateNumberOfPayments();
        if (numberOfPayments > 0) {
          final suggestedPayment = totalAmount / numberOfPayments;
          _paymentAmountController.text = suggestedPayment.toStringAsFixed(2);
        }
      }
    }
  }

  int _calculateNumberOfPayments() {
    if (_startDate == null || _endDate == null) return 0;

    final daysDifference = _endDate!.difference(_startDate!).inDays;

    switch (_selectedFrequency) {
      case 'daily':
        return daysDifference; // +1 para incluir el día de inicio
      case 'weekly':
        return (daysDifference / 7).ceil();
      case 'biweekly':
        return (daysDifference / 14).ceil();
      case 'monthly':
        return (daysDifference / 30).ceil();
      default:
        return daysDifference + 1;
    }
  }

  String _getDurationInfo() {
    if (_startDate == null || _endDate == null) {
      return 'Selecciona las fechas para ver la duración';
    }

    final daysDifference = _endDate!.difference(_startDate!).inDays;
    final numberOfPayments = _calculateNumberOfPayments();

    String frequencyText;
    switch (_selectedFrequency) {
      case 'daily':
        frequencyText = 'cuotas diarias';
        break;
      case 'weekly':
        frequencyText = 'cuotas semanales';
        break;
      case 'biweekly':
        frequencyText = 'cuotas quincenales';
        break;
      case 'monthly':
        frequencyText = 'cuotas mensuales';
        break;
      default:
        frequencyText = 'cuotas';
    }

    return '$daysDifference días • $numberOfPayments $frequencyText';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _balanceController.dispose();
    _paymentAmountController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.credit != null ? 'Editar Crédito' : 'Nuevo Crédito',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Información del crédito
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información del Crédito',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Selector de cliente
                      if (widget.credit == null) ...[
                        clientState.isLoading
                            ? const SizedBox(
                                height: 56,
                                child: Center(
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text('Cargando clientes...'),
                                    ],
                                  ),
                                ),
                              )
                            : DropdownButtonFormField<Usuario>(
                                value: _selectedClient,
                                decoration: const InputDecoration(
                                  labelText: 'Cliente *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                items: clientState.clientes.map((cliente) {
                                  return DropdownMenuItem<Usuario>(
                                    value: cliente,
                                    child: Text(cliente.nombre),
                                  );
                                }).toList(),
                                onChanged: (Usuario? value) {
                                  setState(() {
                                    _selectedClient = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Por favor selecciona un cliente';
                                  }
                                  return null;
                                },
                              ),

                        // Mostrar error si hay problemas cargando clientes
                        if (clientState.error != null)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Error: ${clientState.error}',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    ref
                                        .read(clientProvider.notifier)
                                        .limpiarError();
                                    _loadClients();
                                  },
                                  child: const Text('Reintentar'),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),
                      ] else ...[
                        // Mostrar cliente en modo solo lectura para edición
                        TextFormField(
                          initialValue:
                              _selectedClient?.nombre ??
                              'Cliente #${widget.credit!.clientId}',
                          decoration: const InputDecoration(
                            labelText: 'Cliente',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Monto del crédito
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto del Crédito *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                          prefixText: 'Bs. ',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa el monto';
                          }
                          final amount = double.tryParse(value);
                          if (amount == null || amount <= 0) {
                            return 'Por favor ingresa un monto válido';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _updateCalculations();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Tasa de interés
                      TextFormField(
                        controller: _interestRateController,
                        decoration: const InputDecoration(
                          labelText: 'Tasa de Interés (%)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.percent),
                          helperText: 'Porcentaje de interés (ej: 20 para 20%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            final rate = double.tryParse(value);
                            if (rate == null || rate < 0 || rate > 100) {
                              return 'Ingresa una tasa válida (0-100%)';
                            }
                          }
                          return null;
                        },
                        onChanged: (value) {
                          _updateCalculations();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Saldo actual (Total con interés) - Calculado automáticamente
                      TextFormField(
                        controller: _balanceController,
                        decoration: const InputDecoration(
                          labelText: 'Saldo Total a Pagar *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.account_balance_wallet),
                          prefixText: 'Bs. ',
                          helperText:
                              'Calculado automáticamente (monto + intereses)',
                          suffixIcon: Icon(
                            Icons.calculate,
                            color: Colors.green,
                          ),
                        ),
                        readOnly:
                            true, // Solo lectura, se calcula automáticamente
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El saldo se calcula automáticamente';
                          }
                          final balance = double.tryParse(value);
                          if (balance == null || balance < 0) {
                            return 'Error en el cálculo automático';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Frecuencia de pago
                      DropdownButtonFormField<String>(
                        value: _selectedFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Frecuencia de Pago *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.schedule),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Diario'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Semanal'),
                          ),
                          DropdownMenuItem(
                            value: 'biweekly',
                            child: Text('Quincenal'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Mensual'),
                          ),
                        ],
                        onChanged: (String? value) {
                          setState(() {
                            _selectedFrequency = value ?? 'daily';
                          });
                          // Recalcular cuando cambie la frecuencia
                          _updateCalculations();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Estado (solo para edición)
                      if (widget.credit != null) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: const InputDecoration(
                            labelText: 'Estado *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.info),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'active',
                              child: Text('Activo'),
                            ),
                            DropdownMenuItem(
                              value: 'completed',
                              child: Text('Completado'),
                            ),
                            DropdownMenuItem(
                              value: 'defaulted',
                              child: Text('En Mora'),
                            ),
                          ],
                          onChanged: (String? value) {
                            setState(() {
                              _selectedStatus = value ?? 'active';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Fechas
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fechas del Crédito',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _startDateController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Inicio *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today),
                              ),
                              readOnly: true,
                              onTap: () => _selectStartDate(),
                              validator: (value) {
                                if (_startDate == null) {
                                  return 'Selecciona la fecha de inicio';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _endDateController,
                              decoration: const InputDecoration(
                                labelText: 'Fecha de Vencimiento *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.event),
                              ),
                              readOnly: true,
                              onTap: () => _selectEndDate(),
                              validator: (value) {
                                if (_endDate == null) {
                                  return 'Selecciona la fecha de vencimiento';
                                }
                                if (_startDate != null &&
                                    _endDate!.isBefore(_startDate!)) {
                                  return 'Debe ser posterior al inicio';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Información de duración del crédito
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDurationInfo(),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Información adicional
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información Adicional',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Monto de cuota sugerido - Calculado automáticamente
                      TextFormField(
                        controller: _paymentAmountController,
                        decoration: const InputDecoration(
                          labelText: 'Monto de Cuota Sugerido',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.payment),
                          prefixText: 'Bs. ',
                          helperText:
                              'Calculado automáticamente según frecuencia y fechas',
                          suffixIcon: Icon(
                            Icons.auto_awesome,
                            color: Colors.blue,
                          ),
                        ),
                        readOnly:
                            true, // Solo lectura, se calcula automáticamente
                        validator: (value) {
                          // No es obligatorio que tenga valor
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Notas
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notas',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                          helperText: 'Información adicional sobre el crédito',
                        ),
                        maxLines: 3,
                        maxLength: 500,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCredit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.credit != null ? 'Actualizar' : 'Crear',
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

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
        _startDateController.text = DateFormat('dd/MM/yyyy').format(date);

        // Si la fecha de fin es anterior a la nueva fecha de inicio, ajustarla
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = date.add(const Duration(days: 24)); // 24 días por defecto
          _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
        }
      });
      // Recalcular automáticamente después de cambiar las fechas
      _updateCalculations();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
        _endDateController.text = DateFormat('dd/MM/yyyy').format(date);
      });
      // Recalcular automáticamente después de cambiar las fechas
      _updateCalculations();
    }
  }

  Future<void> _saveCredit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final amount = double.parse(_amountController.text);
    final interestRate = _interestRateController.text.isNotEmpty
        ? double.parse(_interestRateController.text)
        : 0.0;
    final balance = double.parse(_balanceController.text);
    final paymentAmount = _paymentAmountController.text.isNotEmpty
        ? double.parse(_paymentAmountController.text)
        : null;

    bool success = false;

    if (widget.credit != null) {
      // Actualizar crédito existente - Nota: el backend calculará automáticamente total_amount e installment_amount
      success = await ref
          .read(creditProvider.notifier)
          .updateCredit(
            creditId: widget.credit!.id,
            amount: amount,
            interestRate: interestRate,
            balance: balance,
            frequency: _selectedFrequency,
            status: _selectedStatus,
            startDate: _startDate!,
            endDate: _endDate!,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            paymentAmount: paymentAmount,
          );
    } else {
      // Crear nuevo crédito - el backend calculará automáticamente total_amount e installment_amount
      success = await ref
          .read(creditProvider.notifier)
          .createCredit(
            clientId: _selectedClient!.id.toInt(),
            amount: amount,
            interestRate: interestRate,
            balance: balance,
            frequency: _selectedFrequency,
            startDate: _startDate!,
            endDate: _endDate!,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            paymentAmount: paymentAmount,
          );
    }

    setState(() {
      _isLoading = false;
    });

    if (success) {
      if (mounted) {
        Navigator.pop(context, true); // Devolver true para indicar éxito
      }
    }
  }
}
