import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/client_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/usuario.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/api_services/credit_api_service.dart';
import '../cliente/cliente_form_screen.dart';
import '../cliente/location_picker_screen.dart';
import '../widgets/client_search_widget.dart';
import '../../ui/widgets/loading_overlay.dart';
import '../../negocio/utils/schedule_utils.dart';

class CreditFormScreen extends ConsumerStatefulWidget {
  final Credito? credit; // Para edición
  final Usuario? preselectedClient; // Cliente preseleccionado

  const CreditFormScreen({super.key, this.credit, this.preselectedClient});

  @override
  ConsumerState<CreditFormScreen> createState() => _CreditFormScreenState();
}

class _CreditFormScreenState extends ConsumerState<CreditFormScreen> {
  final Map<String, String> _fieldErrors = {};
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _balanceController = TextEditingController();
  final _totalAmountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _notesController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _durationDaysController = TextEditingController(text: '24');
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _addressController = TextEditingController();
  final _scheduledDeliveryDateController = TextEditingController();

  // Claves globales para hacer scroll a campos con errores
  final _clientFieldKey = GlobalKey();
  final _amountFieldKey = GlobalKey();
  final _balanceFieldKey = GlobalKey();
  final _durationFieldKey = GlobalKey();
  final _interestRateFieldKey = GlobalKey();
  final _startDateFieldKey = GlobalKey();
  final _endDateFieldKey = GlobalKey();
  final _scheduledDeliveryDateFieldKey = GlobalKey();
  final _locationFieldKey = GlobalKey();

  // Variables para errores de campo específicos
  String? _clientError;
  String? _amountError;
  String? _balanceError;
  String? _durationError;
  String? _interestRateError;
  String? _startDateError;
  String? _endDateError;
  String? _scheduledDeliveryDateError;
  String? _locationError;

  Usuario? _selectedClient;
  String _selectedFrequency = 'daily'; // Por defecto diario para 24 días
  String _selectedStatus = 'active';
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _scheduledDeliveryDate;
  bool _isLoading = false;
  bool _isLocating =
      false; // Para indicar cuando se está obteniendo la ubicación

  // Configuración del formulario desde el backend
  bool _canEditInterest = false;
  bool _canEditFrequency = false;
  double _defaultInterestRate = 20.0;
  String _defaultFrequency = 'daily';
  bool _isLoadingConfig = true;
  List<Map<String, dynamic>> _availableFrequencies = [];

  // ✅ NUEVO: Variables para controlar la edición de campos según frecuencia
  bool _canEditInstallments = true; // Si se pueden editar las cuotas
  Map<String, dynamic>?
  _currentFrequencyConfig; // Configuración de la frecuencia actual

  // ✅ NUEVO: Variable para expandir/colapsar card de ubicación
  bool _isLocationCardExpanded = false; // Por defecto colapsado

  @override
  void initState() {
    super.initState();
    _loadFormConfig(); // Cargar configuración del backend PRIMERO
    _initializeForm();
    // Usar addPostFrameCallback para cargar clientes después del build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadClients();
      // Obtener ubicación automáticamente al abrir la pantalla
      _useCurrentLocation();
    });
  }

  /// Cargar configuración del formulario desde el backend
  Future<void> _loadFormConfig() async {
    try {
      final creditApi = CreditApiService();

      // ✅ NUEVO: Cargar configuraciones de frecuencias desde loan_frequencies
      final loanFrequencies = await creditApi.getLoanFrequencies();

      // Cargar configuración antigua (para compatibilidad)
      final config = await creditApi.getFormConfig();
      final interestConfig = config['interest'] as Map<String, dynamic>?;
      final frequencyConfig =
          config['payment_frequency'] as Map<String, dynamic>?;

      setState(() {
        // Configuración de interés
        _canEditInterest = interestConfig?['can_edit'] ?? false;
        _defaultInterestRate =
            (interestConfig?['default'] as num?)?.toDouble() ?? 20.0;

        // ✅ NUEVO: Usar loan_frequencies como fuente de verdad
        _availableFrequencies = loanFrequencies;

        // Determinar si puede editar frecuencia (si tiene más de una opción)
        _canEditFrequency =
            loanFrequencies.length > 1 ||
            (frequencyConfig?['can_edit'] ?? false);

        // Seleccionar frecuencia por defecto (la primera habilitada)
        if (loanFrequencies.isNotEmpty) {
          final defaultFreq = loanFrequencies.first;
          _selectedFrequency = defaultFreq['code'] as String;
          _defaultFrequency = defaultFreq['name'] as String;
        } else {
          _selectedFrequency = 'daily';
          _defaultFrequency = 'Diario';
        }

        // Aplicar valores por defecto
        if (!_canEditInterest) {
          _interestRateController.text = _defaultInterestRate.toString();
        }

        _isLoadingConfig = false;
      });

      // ✅ NUEVO: Auto-completar campos después de cargar configuración
      _updateCalculations();
    } catch (e) {
      debugPrint('❌ Error al cargar configuración del formulario: $e');
      setState(() {
        _isLoadingConfig = false;
        // Usar valores por defecto en caso de error
        _canEditInterest = false;
        _canEditFrequency = false;
        _defaultInterestRate = 20.0;
        _selectedFrequency = 'daily';
        _interestRateController.text = '20';
        _availableFrequencies = [
          {
            'code': 'daily',
            'name': 'Diario',
            'period_days': 1,
            'is_fixed_duration': true,
            'fixed_installments': 24,
            'is_editable': false,
            'suggested_installments': 24,
          },
        ];
      });

      // ✅ NUEVO: Auto-completar campos con valores por defecto
      _updateCalculations();
    }
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

      // Calcular la duración usando la misma lógica que ScheduleUtils
      if (credit.frequency == 'daily') {
        int payments = 0;
        DateTime current = credit.startDate;
        while (current.isBefore(credit.endDate)) {
          current = current.add(const Duration(days: 1));
          // Usar la misma lógica que ScheduleUtils: solo días hábiles (lunes a sábado)
          if (current.weekday != DateTime.sunday) {
            payments++;
          }
        }
        if (payments > 0) {
          _durationDaysController.text = payments.toString();
        }
      }
    } else {
      // Modo creación con valores por defecto optimizados
      _selectedClient = widget.preselectedClient;
      _interestRateController.text = '20'; // Por defecto 20% de interés
      _selectedFrequency = 'daily'; // Por defecto diario
      // _startDate = DateTime.now().add(const Duration(days: 1));
      _startDate = DateTime.now(); // Hoy
      final durationDays = int.tryParse(_durationDaysController.text) ?? 24;
      _endDate = ScheduleUtils.computeDailyEndDate(_startDate!, durationDays);
      _startDateController.text = DateFormat('dd/MM/yyyy').format(_startDate!);
      _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);

      // Programar entrega por defecto para mañana (día siguiente a la creación)
      _scheduledDeliveryDate = DateTime.now().add(const Duration(days: 1));
      _scheduledDeliveryDateController.text = DateFormat(
        'dd/MM/yyyy',
      ).format(_scheduledDeliveryDate!);
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
      } else if (currentUser.esManager()) {
        // Manager: cargar todos sus clientes (directos + indirectos)
        ref
            .read(clientProvider.notifier)
            .cargarClientes(
              managerId: currentUser.id.toString(),
              managerAllClients: true,
            );
      } else {
        // Admin u otros: cargar todos los clientes generales
        ref.read(clientProvider.notifier).cargarClientes();
      }
    }
  }

  void _updateCalculations() {
    // ✅ PASO 1: Obtener configuración de la frecuencia seleccionada
    _currentFrequencyConfig = _availableFrequencies.firstWhere(
      (freq) => freq['code'] == _selectedFrequency,
      orElse: () => {
        'code': 'daily',
        'name': 'Diario',
        'is_fixed_duration': true,
        'fixed_installments': 24,
        'fixed_duration_days': 28,
        'period_days': 1,
        'is_editable': false,
        'suggested_installments': 24,
      },
    );

    // ✅ PASO 2: Determinar si se pueden editar las cuotas
    final isFixedDuration =
        _currentFrequencyConfig?['is_fixed_duration'] ?? false;
    _canEditInstallments = !isFixedDuration;

    // ✅ PASO 3: Auto-completar días de duración según el tipo de frecuencia
    if (isFixedDuration) {
      // FRECUENCIA FIJA (Diaria): Usar valor fijo de 28 días / 24 cuotas
      final fixedDurationDays =
          _currentFrequencyConfig?['fixed_duration_days'] ?? 28;
      final fixedInstallments =
          _currentFrequencyConfig?['fixed_installments'] ?? 24;

      _durationDaysController.text = fixedInstallments.toString();

      // ✅ PASO 4: Calcular fecha fin automáticamente para frecuencia diaria
      if (_startDate != null) {
        _endDate = ScheduleUtils.computeDailyEndDate(
          _startDate!,
          fixedDurationDays,
        );
        _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
      }
    } else {
      // FRECUENCIA FLEXIBLE (Semanal, Quincenal, Mensual)
      // ℹ️ NO auto-completar aquí - dejar que el usuario escriba libremente
      // El auto-completado solo ocurre al cambiar de frecuencia (ver onChanged del dropdown)

      // ✅ PASO 5: Calcular fecha fin estimada para frecuencias flexibles
      final installments = int.tryParse(_durationDaysController.text);
      final periodDays = _currentFrequencyConfig?['period_days'] ?? 7;

      if (_startDate != null && installments != null && installments > 0) {
        // Calcular duración estimada: installments * period_days
        final estimatedDurationDays = (installments * periodDays).toInt();
        _endDate = _startDate!.add(Duration(days: estimatedDurationDays));
        _endDateController.text = DateFormat('dd/MM/yyyy').format(_endDate!);
      }
    }

    // ✅ PASO 6: Calcular monto total con interés y cuota sugerida
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final interestRate = double.tryParse(_interestRateController.text) ?? 0.0;

    if (amount > 0 && interestRate >= 0) {
      final totalAmount = amount + (amount * interestRate / 100);

      // Actualizar el saldo total automáticamente
      _balanceController.text = totalAmount.toStringAsFixed(2);

      // Calcular cuota sugerida basada en las cuotas (no en las fechas)
      final numberOfPayments = int.tryParse(_durationDaysController.text) ?? 1;
      if (numberOfPayments > 0) {
        final suggestedPayment = totalAmount / numberOfPayments;
        _installmentAmountController.text = suggestedPayment.toStringAsFixed(2);
      }
    }
  }

  int _calculateNumberOfPayments() {
    if (_startDate == null || _endDate == null) return 0;

    final daysDifference = _endDate!.difference(_startDate!).inDays;

    switch (_selectedFrequency) {
      case 'daily':
        return int.tryParse(_durationDaysController.text) ?? 24;
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
          final durationDays = int.tryParse(_durationDaysController.text) ?? 24;
          _endDate = ScheduleUtils.computeDailyEndDate(date, durationDays);
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

  Future<void> _selectScheduledDeliveryDate() async {
    final now = DateTime.now();
    final initial = _scheduledDeliveryDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day), // hoy o futuro
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _scheduledDeliveryDate = date;
        _scheduledDeliveryDateController.text = DateFormat(
          'dd/MM/yyyy',
        ).format(date);
      });
    }
  }

  Future<void> _useCurrentLocation() async {
    try {
      setState(() {
        _isLocating = true;
      });
      // Verificar y solicitar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permisos de ubicación denegados. Habilítalos en ajustes.',
              ),
            ),
          );
        }
        return;
      }

      // Obtener ubicación actual
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _latitudeController.text = pos.latitude.toStringAsFixed(6);
        _longitudeController.text = pos.longitude.toStringAsFixed(6);
        _clearFieldError('location');
        _fieldErrors.remove('latitude');
        _fieldErrors.remove('longitude');
      });
      // intentar obtener dirección legible
      try {
        final placemarks = await placemarkFromCoordinates(
          pos.latitude,
          pos.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks[0];
          final dir = [
            p.street,
            p.subLocality,
            p.locality,
            p.administrativeArea,
          ].where((e) => e != null && e.isNotEmpty).map((e) => e!).join(', ');
          setState(() {
            _addressController.text = dir;
          });
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo obtener la ubicación actual: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocating = false;
        });
      }
    }
  }

  Future<void> _openLocationPicker() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LocationPickerScreen(
            allowSelection: true,
            customTitle: 'Seleccionar ubicación del crédito',
          ),
        ),
      );
      if (result is Map) {
        final lat = result['latitud'] as double?;
        final lng = result['longitud'] as double?;
        final dir = result['direccion'] as String?;
        if (lat != null && lng != null) {
          setState(() {
            _latitudeController.text = lat.toStringAsFixed(6);
            _longitudeController.text = lng.toStringAsFixed(6);
            _addressController.text = dir ?? '';
            _clearFieldError('location');
            _fieldErrors.remove('latitude');
            _fieldErrors.remove('longitude');
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo abrir el selector de ubicación: $e'),
          ),
        );
      }
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
    final totalInstallments = int.tryParse(_durationDaysController.text) ?? 24;
    final latitude = _latitudeController.text.isNotEmpty
        ? double.tryParse(_latitudeController.text)
        : null;
    final longitude = _longitudeController.text.isNotEmpty
        ? double.tryParse(_longitudeController.text)
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
            totalInstallments: totalInstallments,
            latitude: latitude,
            longitude: longitude,
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
            totalInstallments: totalInstallments,
            latitude: latitude,
            longitude: longitude,
            scheduledDeliveryDate: _scheduledDeliveryDate,
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
    _scrollController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
    _balanceController.dispose();
    _totalAmountController.dispose();
    _notesController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _durationDaysController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _scheduledDeliveryDateController.dispose();
    super.dispose();
  }

  bool _hasLocation() {
    return _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty;
  }

  void _setFieldErrorsFromMessage(String msg) {
    final lower = msg.toLowerCase();
    setState(() {
      // Limpiar errores anteriores
      _clientError = null;
      _amountError = null;
      _balanceError = null;
      _durationError = null;
      _interestRateError = null;
      _startDateError = null;
      _endDateError = null;
      _scheduledDeliveryDateError = null;
      _locationError = null;
      _fieldErrors.clear();

      // Analizar el mensaje y asignar errores específicos
      if (lower.contains('client') || lower.contains('cliente')) {
        _clientError = 'Error en la selección del cliente';
        _fieldErrors['client'] = msg;
      }
      if (lower.contains('monto') || lower.contains('amount')) {
        _amountError = 'Error en el monto del crédito';
        _fieldErrors['amount'] = msg;
      }
      if (lower.contains('saldo') ||
          lower.contains('total') ||
          lower.contains('balance')) {
        _balanceError = 'Error en el saldo total';
        _fieldErrors['balance'] = msg;
      }
      if (lower.contains('duración') ||
          lower.contains('duracion') ||
          lower.contains('días') ||
          lower.contains('dias') ||
          lower.contains('cuotas') ||
          lower.contains('installments')) {
        _durationError = 'Error en la duración del crédito';
        _fieldErrors['duration'] = msg;
      }
      if (lower.contains('interés') ||
          lower.contains('interes') ||
          lower.contains('interest') ||
          lower.contains('tasa')) {
        _interestRateError = 'Error en la tasa de interés';
        _fieldErrors['interestRate'] = msg;
      }
      if (lower.contains('fecha inicio') ||
          lower.contains('start date') ||
          (lower.contains('fecha') && lower.contains('inicio'))) {
        _startDateError = 'Error en la fecha de inicio';
        _fieldErrors['startDate'] = msg;
      }
      if (lower.contains('fecha fin') ||
          lower.contains('end date') ||
          (lower.contains('fecha') && lower.contains('fin'))) {
        _endDateError = 'Error en la fecha de finalización';
        _fieldErrors['endDate'] = msg;
      }
      if (lower.contains('entrega') ||
          lower.contains('delivery') ||
          lower.contains('programada') ||
          lower.contains('scheduled')) {
        _scheduledDeliveryDateError = 'Error en la fecha de entrega';
        _fieldErrors['scheduledDeliveryDate'] = msg;
      }
      if (lower.contains('latitud') ||
          lower.contains('longitud') ||
          lower.contains('ubicación') ||
          lower.contains('ubicacion') ||
          lower.contains('location') ||
          lower.contains('coordenadas')) {
        _locationError = 'Error en la ubicación del crédito';
        _fieldErrors['latitude'] = msg;
        _fieldErrors['longitude'] = msg;
      }
      // Error general si no se pudo categorizar
      if (_clientError == null &&
          _amountError == null &&
          _balanceError == null &&
          _durationError == null &&
          _interestRateError == null &&
          _startDateError == null &&
          _endDateError == null &&
          _scheduledDeliveryDateError == null &&
          _locationError == null) {
        // Si no se pudo identificar un campo específico, mostrar en el campo más relevante
        if (lower.contains('crédito') || lower.contains('credit')) {
          _amountError = msg;
        }
      }
    });

    // Hacer scroll al primer campo con error después de un pequeño delay
    print('🚀 DEBUG: Programando scroll automático a error...');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Añadir un delay adicional para evitar interferencia con SnackBar y renderizado
      Future.delayed(const Duration(milliseconds: 300), () {
        print('🎬 DEBUG: Ejecutando scroll automático con delay extendido...');
        if (mounted) {
          _scrollToFirstError();
        }
      });
    });
  }

  /// Hace scroll automático al primer campo que tiene error
  void _scrollToFirstError() {
    print('🎯 DEBUG: Intentando scroll automático a error...');

    GlobalKey? firstErrorField;
    String? errorFieldName;

    // Buscar el primer campo con error en orden de aparición en la UI
    if (_clientError != null) {
      firstErrorField = _clientFieldKey;
      errorFieldName = 'cliente';
    } else if (_amountError != null) {
      firstErrorField = _amountFieldKey;
      errorFieldName = 'monto';
    } else if (_interestRateError != null) {
      firstErrorField = _interestRateFieldKey;
      errorFieldName = 'tasa de interés';
    } else if (_balanceError != null) {
      firstErrorField = _balanceFieldKey;
      errorFieldName = 'balance';
    } else if (_durationError != null) {
      firstErrorField = _durationFieldKey;
      errorFieldName = 'duración';
    } else if (_startDateError != null) {
      firstErrorField = _startDateFieldKey;
      errorFieldName = 'fecha inicio';
    } else if (_endDateError != null) {
      firstErrorField = _endDateFieldKey;
      errorFieldName = 'fecha fin';
    } else if (_scheduledDeliveryDateError != null) {
      firstErrorField = _scheduledDeliveryDateFieldKey;
      errorFieldName = 'entrega programada';
    } else if (_locationError != null) {
      firstErrorField = _locationFieldKey;
      errorFieldName = 'ubicación';
    }

    print('🔍 DEBUG: Campo con error encontrado: $errorFieldName');
    print('🔍 DEBUG: GlobalKey válido: ${firstErrorField != null}');
    print(
      '🔍 DEBUG: Context disponible: ${firstErrorField?.currentContext != null}',
    );

    if (firstErrorField != null && firstErrorField.currentContext != null) {
      try {
        final RenderBox renderBox =
            firstErrorField.currentContext!.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);

        print('🎯 DEBUG: Posición del campo: ${position.dy}');
        print('📜 DEBUG: Scroll actual: ${_scrollController.offset}');

        // Calcular la posición de scroll, restando un poco para que el campo no quede pegado arriba
        final scrollPosition = _scrollController.offset + position.dy - 120;
        final clampedPosition = scrollPosition.clamp(
          0.0,
          _scrollController.position.maxScrollExtent,
        );

        print('🎯 DEBUG: Nueva posición scroll: $clampedPosition');

        // Hacer scroll animado al campo con error
        _scrollController
            .animateTo(
              clampedPosition,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
            )
            .then((_) {
              print('✅ DEBUG: Scroll completado exitosamente');
            })
            .catchError((error) {
              print('❌ DEBUG: Error en scroll: $error');
            });
      } catch (e) {
        print('❌ DEBUG: Error al calcular posición: $e');
      }
    } else {
      print('❌ DEBUG: No se pudo hacer scroll - clave o contexto no válidos');
    }
  }

  /// Limpia los errores específicos de un campo cuando el usuario lo modifica
  void _clearFieldError(String fieldName) {
    setState(() {
      switch (fieldName) {
        case 'client':
          _clientError = null;
          break;
        case 'amount':
          _amountError = null;
          break;
        case 'balance':
          _balanceError = null;
          break;
        case 'duration':
          _durationError = null;
          break;
        case 'interestRate':
          _interestRateError = null;
          break;
        case 'startDate':
          _startDateError = null;
          break;
        case 'endDate':
          _endDateError = null;
          break;
        case 'scheduledDeliveryDate':
          _scheduledDeliveryDateError = null;
          break;
        case 'location':
          _locationError = null;
          break;
      }
      _fieldErrors.remove(fieldName);
    });
  }

  /// Maneja la respuesta del ClienteFormScreen y selecciona el cliente apropiado
  Future<void> _handleClientCreationResult(dynamic result) async {
    if (result is Usuario) {
      // Cliente devuelto directamente desde el form
      setState(() {
        _selectedClient = result;
        _clearFieldError('client');
        _fieldErrors.remove('client');
      });
      // Recargar clientes para mantener la lista actualizada
      _loadClients();
    } else if (result == true) {
      // Fallback: recargar clientes y seleccionar el último
      await Future.delayed(const Duration(milliseconds: 300));
      _loadClients();
      await Future.delayed(const Duration(milliseconds: 500));
      final clientList = ref.read(clientProvider).clientes;
      if (clientList.isNotEmpty) {
        setState(() {
          _selectedClient = clientList.last;
          _clearFieldError('client');
          _fieldErrors.remove('client');
        });
      }
    }
  }

  // ============================================================================
  // 🎨 WIDGETS HELPER PARA NUEVA ESTRUCTURA UI
  // ============================================================================

  /// Widget para títulos de sección
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para card de ubicación
  Widget _buildLocationCard() {
    final hasLocation =
        _latitudeController.text.isNotEmpty &&
        _longitudeController.text.isNotEmpty;

    return Card(
      elevation: 0,
      color: hasLocation ? Colors.green.shade50 : Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasLocation ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasLocation ? Icons.location_on : Icons.location_off,
                  color: hasLocation
                      ? Colors.green.shade700
                      : Colors.grey.shade600,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasLocation ? 'Ubicación registrada' : 'Sin ubicación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: hasLocation
                              ? Colors.green.shade900
                              : Colors.grey.shade700,
                        ),
                      ),
                      // Mostrar detalles solo cuando está expandido
                      if (_isLocationCardExpanded) ...[
                        if (_addressController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              _addressController.text,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (hasLocation)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Lat: ${double.tryParse(_latitudeController.text)?.toStringAsFixed(6) ?? ""}, '
                              'Lng: ${double.tryParse(_longitudeController.text)?.toStringAsFixed(6) ?? ""}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                // Botón para expandir/colapsar
                IconButton(
                  icon: Icon(
                    _isLocationCardExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isLocationCardExpanded = !_isLocationCardExpanded;
                    });
                  },
                  tooltip: _isLocationCardExpanded ? 'Ocultar detalles' : 'Ver detalles',
                ),
                // Botón para refrescar ubicación
                IconButton(
                  icon: Icon(
                    _isLocating ? Icons.hourglass_empty : Icons.my_location,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _isLocating ? null : _useCurrentLocation,
                  tooltip: 'Obtener ubicación actual',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para card de fecha fin (calculada)
  Widget _buildEndDateCard() {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blue.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.event_available, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fecha estimada de finalización',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _endDate != null
                        ? DateFormat(
                            'EEEE, dd \'de\' MMMM \'de\' yyyy',
                            'es',
                          ).format(_endDate!)
                        : 'Selecciona fecha de inicio y cuotas',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _endDate != null
                          ? Colors.blue.shade900
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para una fila del resumen financiero
  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget compacto para mostrar fechas (versión más pequeña)
  Widget _buildCompactDateRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Widget para el resumen financiero completo con todas las fechas
  Widget _buildFinancialSummary() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final installmentAmount =
        double.tryParse(_installmentAmountController.text) ?? 0.0;
    final installments = int.tryParse(_durationDaysController.text) ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade50, Colors.orange.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.orange.shade700, size: 28),
              const SizedBox(width: 8),
              Text(
                '📊 Resumen del Crédito',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ============================================================
          // FECHAS CENTRALIZADAS (Formato Compacto)
          // ============================================================
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                _buildCompactDateRow(
                  icon: Icons.event_note,
                  label: 'Inicio:',
                  value: _startDate != null
                      ? DateFormat('dd/MM/yyyy').format(_startDate!)
                      : 'No seleccionada',
                  color: Colors.blue.shade700,
                ),
                _buildCompactDateRow(
                  icon: Icons.event_available,
                  label: 'Finalización:',
                  value: _endDate != null
                      ? DateFormat('dd/MM/yyyy').format(_endDate!)
                      : 'Pendiente',
                  color: Colors.blue.shade700,
                ),
                if (_scheduledDeliveryDate != null)
                  _buildCompactDateRow(
                    icon: Icons.local_shipping,
                    label: 'Entrega:',
                    value: DateFormat(
                      'dd/MM/yyyy',
                    ).format(_scheduledDeliveryDate!),
                    color: Colors.purple.shade700,
                  ),
              ],
            ),
          ),

          // ============================================================
          // VALORES FINANCIEROS
          // ============================================================
          Divider(color: Colors.orange.shade300, thickness: 2),
          _buildSummaryRow(
            icon: Icons.account_balance_wallet,
            label: 'Saldo Total a Pagar',
            value: balance > 0
                ? 'Bs. ${balance.toStringAsFixed(2)}'
                : 'Bs. 0.00',
            color: Colors.orange,
          ),
          Divider(color: Colors.orange.shade300),
          _buildSummaryRow(
            icon: Icons.payments,
            label: 'Cuota Sugerida ($installments cuotas)',
            value: installmentAmount > 0
                ? 'Bs. ${installmentAmount.toStringAsFixed(2)}'
                : 'Bs. 0.00',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clientState = ref.watch(clientProvider);

    // Escuchar y mostrar mensajes del backend (errores/éxitos)
    ref.listen<CreditState>(creditProvider, (previous, next) {
      print('🎭 DEBUG: CreditState cambió - Error: ${next.errorMessage}');
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        print('🔥 DEBUG: Nuevo error detectado, procesando...');
        _setFieldErrorsFromMessage(next.errorMessage!);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final notifier = ref.read(creditProvider.notifier);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                notifier.clearError();
              },
            ),
          ),
        );
        print(
          '🍞 DEBUG: SnackBar mostrado, scroll debería ejecutarse pronto...',
        );
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        setState(() {
          // Limpiar todos los errores cuando hay un éxito
          _clientError = null;
          _amountError = null;
          _balanceError = null;
          _durationError = null;
          _interestRateError = null;
          _startDateError = null;
          _endDateError = null;
          _scheduledDeliveryDateError = null;
          _locationError = null;
          _fieldErrors.clear();
        });
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final notifier = ref.read(creditProvider.notifier);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                notifier.clearSuccess();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.credit != null ? 'Editar Crédito' : 'Nuevo Crédito',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        // backgroundColor: Theme.of(context).colorScheme.primary,
        // foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón de ubicación GPS
          IconButton(
            onPressed: _isLoading || _isLocating ? null : _useCurrentLocation,
            icon: _isLocating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.my_location),
            tooltip: _isLocating ? 'Obteniendo ubicación...' : 'Mi Ubicación',
          ),
          // Botón de mapa
          IconButton(
            onPressed: _isLoading ? null : _openLocationPicker,
            icon: const Icon(Icons.map),
            tooltip: 'Elegir en mapa',
          ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(width: 12),
                  // Geolocalización opcional
                  // Estado de ubicación
                  /*Container(
                    key: _locationFieldKey,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: _locationError != null
                          ? Colors.red.withValues(alpha: 0.1)
                          : _hasLocation()
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _locationError != null
                            ? Colors.red.withValues(alpha: 0.3)
                            : _hasLocation()
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isLocating
                              ? Icons.location_searching
                              : _locationError != null
                              ? Icons.location_off
                              : _hasLocation()
                              ? Icons.location_on
                              : Icons.location_off,
                          color: _isLocating
                              ? Colors.blue
                              : _locationError != null
                              ? Colors.red
                              : _hasLocation()
                              ? Colors.green
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isLocating
                                ? 'Obteniendo ubicación...'
                                : _locationError != null
                                ? 'Error en ubicación: ${_locationError!}'
                                : _hasLocation()
                                ? 'Ubicación obtenida correctamente'
                                : 'Ubicación no disponible',
                            style: TextStyle(
                              color: _isLocating
                                  ? Colors.blue
                                  : _locationError != null
                                  ? Colors.red
                                  : _hasLocation()
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),*/
                  // ============================================================
                  // 📍 SECCIÓN: UBICACIÓN DEL CRÉDITO
                  // ============================================================
                  /*_buildSectionHeader(
                    'Ubicación del Crédito',
                    Icons.location_on,
                  ),*/
                  _buildLocationCard(),
                  const SizedBox(height: 16),
                  if (widget.credit != null &&
                      widget.credit!.status != 'pending_approval')
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.5),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Este crédito no se puede editar porque no está pendiente de aprobación.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
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
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),

                          // Selector de cliente
                          if (widget.credit == null) ...[
                            clientState.isLoading
                                ? const SizedBox(
                                    height: 56,
                                    child: Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceVariant
                                              .withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'No hay clientes registrados. Crea uno nuevo para continuar.',
                                                style: TextStyle(
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
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
                                        label: const Text(
                                          'Crear nuevo cliente',
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const ClienteFormScreen(),
                                            ),
                                          );
                                          await _handleClientCreationResult(
                                            result,
                                          );
                                        },
                                      ),
                                    ],
                                  )
                                : Container(
                                    key: _clientFieldKey,
                                    child: ClientSearchWidget(
                                      mode: 'dropdown',
                                      selectedClient: _selectedClient,
                                      onClientSelected: (Usuario? value) {
                                        setState(() {
                                          _selectedClient = value;
                                          _clearFieldError('client');
                                        });
                                      },
                                      hint: 'Cliente',
                                      isRequired: true,
                                      errorText: _clientError,
                                      allowCreate: true,
                                      onCreateClient:
                                          (String searchText) async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    ClienteFormScreen(
                                                      initialName: searchText,
                                                    ),
                                              ),
                                            );
                                            await _handleClientCreationResult(
                                              result,
                                            );
                                          },
                                      allowClear: false,
                                      showClientDetails: true,
                                    ),
                                  ),

                            // Mostrar error si hay problemas cargando clientes
                            if (clientState.error != null)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.error.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withOpacity(0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Error: ${clientState.error}',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
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
                          ],
                          const SizedBox(height: 16),
                          // Monto del crédito
                          TextFormField(
                            key: _amountFieldKey,
                            controller: _amountController,
                            decoration: InputDecoration(
                              labelText: 'Monto del Crédito *',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.attach_money),
                              prefixText: 'Bs. ',
                              helperText:
                                  'Monto principal del crédito sin intereses',
                              errorText: _amountError,
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
                              // Validación por categoría del cliente (A/B/C)
                              final category =
                                  _selectedClient?.clientCategory
                                      ?.toUpperCase() ??
                                  'B';
                              double maxAmount = 5000;
                              switch (category) {
                                case 'A':
                                  maxAmount = 10000;
                                  break;
                                case 'C':
                                  maxAmount = 2000;
                                  break;
                                default:
                                  maxAmount = 5000;
                              }
                              if (amount > maxAmount) {
                                return 'Para categoría $category el monto máximo es Bs. ${maxAmount.toStringAsFixed(0)}';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              _clearFieldError('amount');
                              _updateCalculations();
                            },
                          ),

                          const SizedBox(height: 16),
                          // Frecuencia de pago - editable si lo permite la config
                          if (_canEditFrequency)
                            DropdownButtonFormField<String>(
                              value: _selectedFrequency,
                              decoration: const InputDecoration(
                                labelText: 'Frecuencia de Pago *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                                helperText:
                                    'Selecciona la frecuencia de las cuotas',
                              ),
                              items: _availableFrequencies
                                  .map(
                                    (freq) => DropdownMenuItem(
                                      value:
                                          freq['code']
                                              as String, // ✅ Usar 'code'
                                      child: Text(
                                        freq['name'] as String,
                                      ), // ✅ Usar 'name'
                                    ),
                                  )
                                  .toList(),
                              onChanged: (String? value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedFrequency = value;

                                    // ✅ Auto-completar número de cuotas cuando cambia la frecuencia
                                    final newFreqConfig = _availableFrequencies
                                        .firstWhere(
                                          (freq) => freq['code'] == value,
                                          orElse: () => {},
                                        );

                                    // Si la nueva frecuencia es fija, usar el valor fijo
                                    if (newFreqConfig['is_fixed_duration'] ==
                                        true) {
                                      _durationDaysController.text =
                                          (newFreqConfig['fixed_installments'] ??
                                                  24)
                                              .toString();
                                    } else {
                                      // Para frecuencias flexibles, usar el valor sugerido
                                      final suggested =
                                          newFreqConfig['suggested_installments'] ??
                                          newFreqConfig['default_installments'] ??
                                          12;
                                      _durationDaysController.text = suggested
                                          .toString();
                                    }
                                  });
                                  _updateCalculations();
                                }
                              },
                            )
                          else
                            TextFormField(
                              initialValue:
                                  _availableFrequencies.firstWhere(
                                        (freq) =>
                                            freq['code'] ==
                                            _selectedFrequency, // ✅ Usar 'code'
                                        orElse: () => {
                                          'name': 'Diario',
                                        }, // ✅ Usar 'name'
                                      )['name']
                                      as String, // ✅ Usar 'name'
                              decoration: const InputDecoration(
                                labelText: 'Frecuencia de Pago',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.schedule),
                                helperText:
                                    'Frecuencia configurada por tu empresa',
                              ),
                              readOnly: true,
                            ),

                          // ✅ NUEVO: Información de la frecuencia seleccionada
                          if (_currentFrequencyConfig != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 12.0,
                                left: 4.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Información del período
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: Colors.blue.shade600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pagos cada ${_currentFrequencyConfig!['period_days']} día${_currentFrequencyConfig!['period_days'] == 1 ? '' : 's'}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Información de rango de cuotas (solo para frecuencias flexibles)
                                  if (_currentFrequencyConfig!['is_editable'] ==
                                      true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.tune,
                                            size: 16,
                                            color: Colors.green.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Rango sugerido: ${_currentFrequencyConfig!['min_installments']} - ${_currentFrequencyConfig!['max_installments']} cuotas',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.green.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Duración estimada total
                                  if (_durationDaysController.text.isNotEmpty &&
                                      int.tryParse(
                                            _durationDaysController.text,
                                          ) !=
                                          null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Colors.orange.shade600,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Duración estimada: ${int.parse(_durationDaysController.text) * (_currentFrequencyConfig!['period_days'] as int)} días',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                          // dias de duracion
                          const SizedBox(height: 16),
                          // Frecuencia de pago y Tasa de interés lado a lado
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: _durationFieldKey,
                                  controller: _durationDaysController,
                                  decoration: InputDecoration(
                                    labelText: _canEditInstallments
                                        ? 'Número de Cuotas *'
                                        : 'Número de Cuotas (fijo)',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.timelapse),
                                    helperText: _canEditInstallments
                                        ? 'Ingresa el número de cuotas para este crédito'
                                        : 'Cantidad de cuotas configurada automáticamente',
                                    errorText: _durationError,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: false,
                                        signed: false,
                                      ),
                                  readOnly: !_canEditInstallments,
                                  enabled: _canEditInstallments,
                                  validator: (value) {
                                    final v = int.tryParse(value ?? '');
                                    if (v == null || v <= 0) {
                                      return 'Ingresa un número de cuotas válido';
                                    }

                                    // ℹ️ Los rangos son solo referenciales, no obligatorios
                                    // El usuario puede elegir libremente el número de cuotas

                                    return null;
                                  },
                                  onChanged: _canEditInstallments
                                      ? (value) {
                                          _clearFieldError('duration');
                                          _updateCalculations();
                                        }
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Tasa de interés - editable si lo permite la config
                              Expanded(
                                child: TextFormField(
                                  key: _interestRateFieldKey,
                                  controller: _interestRateController,
                                  decoration: InputDecoration(
                                    labelText: _canEditInterest
                                        ? 'Tasa de Interés (%) *'
                                        : 'Tasa de Interés (%)',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.percent),
                                    helperText: _canEditInterest
                                        ? 'Puedes personalizar el interés'
                                        : 'Interés configurado por tu empresa',
                                    errorText: _interestRateError,
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  readOnly: !_canEditInterest,
                                  enabled: _canEditInterest,
                                  onChanged: _canEditInterest
                                      ? (value) {
                                          _clearFieldError('interestRate');
                                          _updateCalculations();

                                          // Advertir si el interés es 0
                                          final rate =
                                              double.tryParse(value) ?? 0.0;
                                          if (rate == 0.0 && value.isNotEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  '⚠️ Interés en 0% - Este crédito NO generará intereses',
                                                ),
                                                backgroundColor: Colors.orange,
                                                duration: Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        }
                                      : null,
                                  validator: (value) {
                                    if (_canEditInterest &&
                                        (value == null || value.isEmpty)) {
                                      return 'Ingresa la tasa de interés';
                                    }
                                    if (value != null && value.isNotEmpty) {
                                      final rate = double.tryParse(value);
                                      if (rate == null ||
                                          rate < 0 ||
                                          rate > 100) {
                                        return 'Ingresa una tasa válida (0-100%)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),

                          // Estado (solo para edición cuando está pendiente)
                          if (widget.credit != null &&
                              widget.credit!.status == 'pending_approval') ...[
                            DropdownButtonFormField<String>(
                              value: _selectedStatus == 'pending_approval'
                                  ? 'active'
                                  : _selectedStatus,
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
                  // const SizedBox(height: 16),
                  // Fechas
                  /*Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fechas del Crédito',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  key: _startDateFieldKey,
                                  controller: _startDateController,
                                  decoration: InputDecoration(
                                    labelText: 'Fecha de Inicio *',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(
                                      Icons.calendar_today,
                                    ),
                                    errorText: _startDateError,
                                  ),
                                  enabled: false,
                                  readOnly: true,
                                  validator: (value) {
                                    if (_startDate == null) {
                                      return 'Selecciona la fecha de inicio';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),*/
                  const SizedBox(height: 16),
                  // Entrega programada - Solo para managers
                  Builder(
                    builder: (context) {
                      final authState = ref.watch(authProvider);
                      final currentUser = authState.usuario;
                      final isManager = currentUser?.esManager() ?? false;
                      final isCobrador = currentUser?.esCobrador() ?? false;

                      // Ocultar completamente la sección para cobradores
                      if (isCobrador) {
                        return const SizedBox.shrink();
                      }

                      final isDirectClient =
                          _selectedClient != null &&
                          currentUser != null &&
                          _selectedClient!.assignedManagerId == currentUser.id;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_available,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Entrega Programada',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (isManager && isDirectClient)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.green.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.flash_on,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Fast‑track: Eres manager del cliente directo. Este crédito irá a espera de entrega sin aprobación. Puedes programar entrega hoy o una fecha futura.',
                                          style: TextStyle(
                                            color: Colors.green[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  'La entrega se programa al aprobar el crédito. Por defecto es al día siguiente. Los managers pueden permitir entrega el mismo día.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                key: _scheduledDeliveryDateFieldKey,
                                controller: _scheduledDeliveryDateController,
                                decoration: InputDecoration(
                                  labelText:
                                      'Fecha de entrega (por defecto: mañana)',
                                  border: const OutlineInputBorder(),
                                  prefixIcon: const Icon(Icons.event_note),
                                  helperText:
                                      'Puedes ajustar a una fecha futura. Por defecto se programa al día siguiente.',
                                  errorText: _scheduledDeliveryDateError,
                                ),
                                readOnly: true,
                                onTap: _selectScheduledDeliveryDate,
                                validator: (value) {
                                  // opcional; si está, debe ser >= hoy
                                  if (value == null || value.isEmpty)
                                    return null;
                                  final now = DateTime.now();
                                  if (_scheduledDeliveryDate != null) {
                                    final today = DateTime(
                                      now.year,
                                      now.month,
                                      now.day,
                                    );
                                    final chosen = DateTime(
                                      _scheduledDeliveryDate!.year,
                                      _scheduledDeliveryDate!.month,
                                      _scheduledDeliveryDate!.day,
                                    );
                                    if (chosen.isBefore(today)) {
                                      return 'La fecha debe ser hoy o futura';
                                    }
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // ============================================================
                  // 📊 SECCIÓN: RESUMEN DEL CRÉDITO
                  // ============================================================
                  _buildSectionHeader('Resumen del Crédito', Icons.assessment),
                  _buildFinancialSummary(),
                  const SizedBox(height: 24),
                  // Botón temporal para probar scroll automático
                  /* SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        print(
                          '🧪 DEBUG: Simulando error para probar scroll...',
                        );
                        _setFieldErrorsFromMessage(
                          'Error en el cliente seleccionado',
                        );
                      },
                      child: const Text('🧪 PROBAR SCROLL A ERROR'),
                    ),
                  ),
                  const SizedBox(height: 16), */
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
                          onPressed:
                              _isLoading ||
                                  (widget.credit != null &&
                                      widget.credit!.status !=
                                          'pending_approval')
                              ? null
                              : _saveCredit,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.credit != null
                                      ? 'Actualizar'
                                      : 'Crear',
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          LoadingOverlay(
            isLoading: clientState.isLoading || _isLoading,
            message: clientState.isLoading
                ? 'Cargando clientes...'
                : 'Guardando crédito...',
          ),
        ],
      ),
    );
  }
}
