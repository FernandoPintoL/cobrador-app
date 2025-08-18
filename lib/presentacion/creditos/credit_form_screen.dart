import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/modelos/credito.dart';
import '../cliente/cliente_form_screen.dart';

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
  final _totalAmountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
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

      _totalAmountController.text = credit.totalAmount?.toString() ?? '';
      _installmentAmountController.text =
          credit.installmentAmount?.toString() ?? '';
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
      _endDate = _selectedFrequency == 'daily'
          ? _computeDailyEndDateFromStart(_startDate!)
          : DateTime.now().add(const Duration(days: 30)); // por defecto mensual aprox
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

  DateTime _computeDailyEndDateFromStart(DateTime start) {
    int payments = 0;
    DateTime current = start;
    while (payments < 24) {
      current = current.add(const Duration(days: 1));
      // Skips Sundays (7)
      if (current.weekday != DateTime.sunday) {
        payments++;
      }
    }
    return current; // last due date after 24 Mon-Sat days
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
          _installmentAmountController.text = suggestedPayment.toStringAsFixed(
            2,
          );
        }
      }
    }
  }

  int _calculateNumberOfPayments() {
    if (_startDate == null || _endDate == null) return 0;

    final daysDifference = _endDate!.difference(_startDate!).inDays;

    switch (_selectedFrequency) {
      case 'daily':
        return 24;
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
        if (_selectedFrequency == 'daily') {
          _endDate = _computeDailyEndDateFromStart(date);
          _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
        } else if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = date.add(const Duration(days: 30));
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
    final installmentAmount = _installmentAmountController.text.isNotEmpty
        ? double.parse(_installmentAmountController.text)
        : null;

    bool success = false;

    if (widget.credit != null) {
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
            installmentAmount: installmentAmount,
            totalAmount: balance,
          );
    } else {
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
            installmentAmount: installmentAmount,
            totalAmount: balance,
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

  @override
  void dispose() {
    _amountController.dispose();
    _interestRateController.dispose();
    _balanceController.dispose();
    _totalAmountController.dispose();
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
              if (widget.credit != null && widget.credit!.status != 'pending_approval')
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    border: Border.all(color: Colors.orange.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este crédito no se puede editar porque no está pendiente de aprobación.',
                          style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                            : clientState.clientes.isEmpty
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.yellow.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.yellow.shade200,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'No hay clientes registrados. Crea uno nuevo para continuar.',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Crear nuevo cliente'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const ClienteFormScreen(),
                                        ),
                                      );
                                      if (result == true) {
                                        // Recargar clientes automáticamente después de crear uno nuevo
                                        await Future.delayed(
                                          const Duration(milliseconds: 300),
                                        );
                                        _loadClients();
                                        // Esperar a que los clientes se carguen
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );
                                        final clientList = ref
                                            .read(clientProvider)
                                            .clientes;
                                        if (clientList.isNotEmpty) {
                                          setState(() {
                                            _selectedClient = clientList.last;
                                          });
                                        }
                                      }
                                    },
                                  ),
                                ],
                              )
                            : DropdownSearch<Usuario>(
                                items: clientState.clientes,
                                selectedItem: _selectedClient,
                                itemAsString: (Usuario u) =>
                                    '${u.nombre} - ${u.telefono}',
                                filterFn: (usuario, searchText) {
                                  // Buscar por nombre o teléfono
                                  final searchLower = searchText.toLowerCase();
                                  return usuario.nombre.toLowerCase().contains(
                                        searchLower,
                                      ) ||
                                      usuario.telefono.toLowerCase().contains(
                                        searchLower,
                                      );
                                },
                                dropdownDecoratorProps: DropDownDecoratorProps(
                                  dropdownSearchDecoration: InputDecoration(
                                    labelText: 'Cliente *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                ),
                                onChanged: (Usuario? value) {
                                  setState(() {
                                    _selectedClient = value;
                                  });
                                },
                                validator: (Usuario? value) {
                                  if (value == null) {
                                    return 'Por favor selecciona un cliente';
                                  }
                                  return null;
                                },
                                popupProps: PopupProps.menu(
                                  showSearchBox: true,
                                  searchFieldProps: TextFieldProps(
                                    decoration: const InputDecoration(
                                      labelText: 'Buscar por nombre o teléfono',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.search),
                                      hintText: 'Ej: Juan Pérez o 77123456',
                                    ),
                                  ),
                                  emptyBuilder: (context, searchEntry) {
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_search,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'No se encontró ningún cliente',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              searchEntry.isEmpty
                                                  ? 'No hay clientes registrados'
                                                  : 'No hay coincidencias para "$searchEntry"',
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey[500],
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                Navigator.pop(
                                                  context,
                                                ); // Cerrar el dropdown
                                                final result = await Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => ClienteFormScreen(
                                                      initialName: searchEntry,
                                                    ),
                                                  ),
                                                );
                                                if (result == true) {
                                                  await Future.delayed(
                                                    const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                  );
                                                  _loadClients();
                                                  await Future.delayed(
                                                    const Duration(
                                                      milliseconds: 500,
                                                    ),
                                                  );
                                                  final clientList = ref
                                                      .read(clientProvider)
                                                      .clientes;
                                                  if (clientList.isNotEmpty) {
                                                    setState(() {
                                                      _selectedClient =
                                                          clientList.last;
                                                    });
                                                  }
                                                }
                                              },
                                              icon: const Icon(
                                                Icons.person_add,
                                              ),
                                              label: const Text(
                                                'Crear nuevo cliente',
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
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
                            if (_startDate != null && _selectedFrequency == 'daily') {
                              _endDate = _computeDailyEndDateFromStart(_startDate!);
                              _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
                            }
                          });
                          // Recalcular cuando cambie la frecuencia
                          _updateCalculations();
                        },
                      ),
                      const SizedBox(height: 16),

                      // Estado (solo para edición cuando está pendiente)
                      if (widget.credit != null && widget.credit!.status == 'pending_approval') ...[
                        DropdownButtonFormField<String>(
                          value: _selectedStatus == 'pending_approval' ? 'active' : _selectedStatus,
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
                        controller: _installmentAmountController,
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
                      onPressed: _isLoading || (widget.credit != null && widget.credit!.status != 'pending_approval')
                          ? null
                          : _saveCredit,
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
}
