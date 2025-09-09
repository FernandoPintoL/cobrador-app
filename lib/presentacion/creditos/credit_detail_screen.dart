import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../ui/widgets/client_category_chip.dart';
import 'credit_form_screen.dart';
import '../widgets/contact_actions_widget.dart';
import '../../ui/widgets/loading_overlay.dart';
import '../cliente/location_picker_screen.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/payment_schedule_calendar.dart';
import '../cliente/cliente_perfil_screen.dart';
import '../widgets/payment_dialog.dart';

class CreditDetailScreen extends ConsumerStatefulWidget {
  final Credito credit;

  const CreditDetailScreen({super.key, required this.credit});

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _paymentRecentlyProcessed = false;
  DateTime? _lastPaymentRefresh;
  late TabController _tabController;
  final _paymentAmountController = TextEditingController();

  // Detalles enriquecidos del crédito (incluye cliente con ubicación)
  Credito? _detailedCredit;
  bool _isLoadingDetails = false;

  // Datos extra del endpoint /details
  Map<String, dynamic>? _creditSummary; // summary
  List<PaymentSchedule>? _apiPaymentSchedule; // payment_schedule
  List<Pago>? _paymentsHistory; // payments_history

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Cargar detalles desde endpoints (crédito + cliente) siempre que se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCreditDetails();
    });

    // Nota: No usar ref.listen aquí; Riverpod exige que listen ocurra durante build.
    // El listener a lastPaymentUpdateProvider se agrega dentro de build().
  }

  Future<void> _loadCreditDetails() async {
    try {
      setState(() => _isLoadingDetails = true);
      // Obtener TODO desde el provider (una sola llamada al backend)
      final full = await ref
          .read(creditProvider.notifier)
          .getCreditFullDetails(widget.credit.id);

      if (!mounted) return;
      setState(() {
        _detailedCredit = full?.credit ?? widget.credit;
        _creditSummary = full?.summary;
        _apiPaymentSchedule = full?.schedule;
        _paymentsHistory = full?.paymentsHistory;
        _isLoadingDetails = false;
        _paymentRecentlyProcessed = false; // reactivar FAB tras actualizar datos
      });
      debugPrint('✅ Detalles cargados vía provider (única llamada).');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingDetails = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudieron cargar todos los datos del cliente: $e',
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _paymentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listener de actualizaciones de pago (Riverpod: debe ejecutarse durante build)
    ref.listen<Map<String, dynamic>?>(lastPaymentUpdateProvider, (prev, next) {
      if (next == null) return;
      try {
        final dynamic creditIdDyn = next['credit']?['id'] ?? next['payment']?['credit_id'] ?? next['creditId'];
        final int? creditId = creditIdDyn is int ? creditIdDyn : int.tryParse(creditIdDyn?.toString() ?? '');
        if (creditId == null) return;
        if (creditId != widget.credit.id) return;

        // Evitar recargas en ráfaga si llegan múltiples eventos similares
        final now = DateTime.now();
        if (_lastPaymentRefresh != null && now.difference(_lastPaymentRefresh!) < const Duration(seconds: 2)) {
          return;
        }
        _lastPaymentRefresh = now;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago aplicado. Actualizando información del crédito...')),
          );
        }
        _loadCreditDetails();
        ref.read(creditProvider.notifier).loadCredits();
      } catch (_) {}
    });
    final creditState = ref.watch(creditProvider);

    // Buscar el crédito actualizado en el estado, pero si el de estado está incompleto (sin totalAmount)
    // y el widget.credit sí lo trae, preferir el del widget para no perder datos.
    Credito baseCredit;
    try {
      final stateCredit = creditState.credits.firstWhere(
        (c) => c.id == widget.credit.id,
      );
      if (stateCredit.totalAmount == null &&
          widget.credit.totalAmount != null) {
        baseCredit = widget.credit;
      } else {
        baseCredit = stateCredit;
      }
    } catch (_) {
      baseCredit = widget.credit;
    }
    final currentCredit = _detailedCredit ?? baseCredit;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Crédito #${currentCredit.id}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: currentCredit.status == 'pending_approval'
                ? () => _editCredit(currentCredit)
                : null,
            tooltip: currentCredit.status == 'pending_approval'
                ? 'Editar crédito'
                : 'Solo se puede editar cuando está pendiente',
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, currentCredit),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Eliminar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Información', icon: Icon(Icons.info_outline)),
            Tab(text: 'Pagos', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                  Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.96),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInformationTab(currentCredit),
                _buildPaymentsTab(currentCredit),
              ],
            ),
          ),
          LoadingOverlay(
            isLoading: _isLoadingDetails,
            message: 'Cargando detalles...',
          ),
        ],
      ),
      floatingActionButton: currentCredit.status == 'active'
          ? FloatingActionButton.extended(
              onPressed: (_paymentRecentlyProcessed || _isLoadingDetails)
                  ? null
                  : () => _navigateToPaymentScreen(currentCredit),
              icon: const Icon(Icons.payment),
              label: Text(
                _paymentRecentlyProcessed ? 'Actualizando...' : 'Procesar Pago',
              ),
            )
          : null,
    );
  }

  Future<void> _navigateToPaymentScreen(Credito credit) async {
    // En lugar de navegar a otra pantalla, mostrar un diálogo de pago
    await _showPaymentDialog(credit);
  }

  Future<void> _showPaymentDialog(Credito credit) async {
    final result = await PaymentDialog.show(
      context,
      ref,
      credit,
      creditSummary: _creditSummary,
      onPaymentSuccess: () {
        // Marcar como pagado recientemente para evitar reintentos inmediatos
        if (mounted) {
          setState(() {
            _paymentRecentlyProcessed = true;
          });
        }

        // Establecer marca de tiempo para evitar recargas duplicadas por WebSocket
        _lastPaymentRefresh = DateTime.now();

        // Informar al usuario y recargar datos
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pago registrado. Actualizando información...'),
            ),
          );
        }
        // Recargar créditos y detalles para obtener información actualizada
        ref.read(creditProvider.notifier).loadCredits();
        _loadCreditDetails();
      },
    );

    // Si se procesó el pago exitosamente, no necesitamos hacer nada más
    // porque el callback onPaymentSuccess ya maneja la recarga de datos
    // Si el usuario canceló o falló, aseguramos que el botón quede habilitado
    if (result != true && mounted) {
      setState(() {
        _paymentRecentlyProcessed = false;
      });
    }
  }

  Widget _buildInformationTab(Credito credit) {
    final total = (credit.totalAmount ?? credit.amount);
    final paid = (total - credit.balance).clamp(0, total);
    final progress = total > 0 ? (paid / total) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          // Información de lista de espera (solo si no está activo)
          // if (!credit.isActive) _buildWaitingListInfo(credit),
          const SizedBox(height: 4),
          // Información del cliente
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Información del Cliente',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "#${credit.clientId}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ListTile(
                    onTap: credit.client != null
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ClientePerfilScreen(
                                  cliente: credit.client!,
                                ),
                              ),
                            );
                          }
                        : null,
                    leading: ProfileImageWidget(
                      profileImage: credit.client?.profileImage,
                      size: 44,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            credit.client?.nombre ??
                                'Cliente #${credit.clientId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (credit.client?.clientCategory != null)
                          ClientCategoryChip(
                            category: credit.client!.clientCategory,
                            compact: true,
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (credit.client?.telefono != null &&
                            credit.client!.telefono.isNotEmpty)
                          ...[
                            Text('Teléfono: ${credit.client!.telefono}'),
                            const SizedBox(height: 4),
                            Text(
                              'CI: ${credit.client?.ci ?? 'N/A'}',
                            ),
                            const SizedBox(height: 4),
                            // Acciones de contacto y mapa
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              // mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                // Llamada normal
                                IconButton(
                                  tooltip: 'Llamar',
                                  icon: const Icon(
                                    Icons.phone,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                  (credit.client?.telefono != null &&
                                      credit.client!.telefono.isNotEmpty)
                                      ? () async {
                                    try {
                                      await ContactActionsWidget.makePhoneCall(
                                        credit.client!.telefono,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                      : null,
                                ),
                                // WhatsApp
                                IconButton(
                                  tooltip: 'WhatsApp',
                                  icon: const Icon(
                                    Icons.message,
                                    color: Colors.green,
                                  ),
                                  onPressed:
                                  (credit.client?.telefono != null &&
                                      credit.client!.telefono.isNotEmpty)
                                      ? () async {
                                    try {
                                      await ContactActionsWidget.openWhatsApp(
                                        credit.client!.telefono,
                                        message:
                                        'Hola ${credit.client!.nombre}, me comunico desde la aplicación.',
                                        context: context,
                                      );
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(e.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                      : null,
                                ),
                                // Ver ubicación en mapa
                                IconButton(
                                  tooltip: 'Ver ubicación en mapa',
                                  icon: const Icon(Icons.map, color: Colors.blue),
                                  onPressed:
                                  (credit.client?.latitud != null &&
                                      credit.client?.longitud != null)
                                      ? () {
                                    // Crear marcador para la ubicación del cliente
                                    final clienteMarker = Marker(
                                      markerId: MarkerId(
                                        'cliente_${credit.client!.id}',
                                      ),
                                      position: LatLng(
                                        credit.client!.latitud!,
                                        credit.client!.longitud!,
                                      ),
                                      infoWindow: InfoWindow(
                                        title: credit.client!.nombre,
                                        snippet:
                                        'Cliente ${credit.client!.clientCategory ?? 'B'} - ${credit.client!.telefono}',
                                      ),
                                      icon:
                                      BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueBlue,
                                      ),
                                    );

                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocationPickerScreen(
                                              allowSelection: false,
                                              extraMarkers: {clienteMarker},
                                              customTitle:
                                              'Ubicación de ${credit.client!.nombre}',
                                            ),
                                      ),
                                    );
                                  }
                                      : () {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Este cliente no tiene ubicación GPS registrada',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        if (_isLoadingDetails) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Cargando datos de ubicación del cliente...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                        if (credit.client == null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _isLoadingDetails
                                  ? null
                                  : _loadCreditDetails,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Recargar datos del cliente'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Resumen del crédito
          if (_creditSummary != null)
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.05),
                      Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Resumen',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        _buildStatusBadge(credit)
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildKpisRow(credit, _creditSummary!),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 3,
                      runSpacing: 6,
                      alignment: WrapAlignment.spaceAround,
                      runAlignment: WrapAlignment.spaceAround,
                      children: [
                        _buildInfoChip(
                          'Total',
                          _formatCurrency(_creditSummary!['total_amount']),
                        ),
                        _buildInfoChip(
                          'Monto Prestamo',
                          _formatCurrency(_creditSummary!['original_amount']),
                        ),
                        _buildInfoChip(
                          'Cuota',
                          _formatCurrency(
                            _creditSummary!['installment_amount'],
                          ),
                        ),
                        _buildInfoChip(
                          'N° Cuotas',
                          (_creditSummary!['total_installments'] ?? '')
                              .toString(),
                        ),
                        _buildInfoChip(
                          'Pendientes',
                          (_creditSummary!['pending_installments'] ?? '')
                              .toString(),
                        ),
                        _buildInfoChip(
                          'Interés',
                          ((_creditSummary!['interest_rate'] ?? 0).toString() +
                              ' %'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress < 0.5
                            ? Colors.red
                            : (progress < 0.8 ? Colors.orange : Colors.green),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildDateInfo('F. Inicio', credit.startDate),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDateInfo(
                            'F. Vencimiento',
                            credit.endDate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (credit.scheduledDeliveryDate != null)
                      _buildDateInfo(
                        'Fecha para Entrega',
                        credit.scheduledDeliveryDate!,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // Cronograma de pagos desde API (si está disponible)
          if (_apiPaymentSchedule != null &&
              _apiPaymentSchedule!.isNotEmpty) ...[
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cronograma de pagos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PaymentScheduleCalendar(
                      schedule: _apiPaymentSchedule!,
                      credit: credit,
                      onTapInstallment: (ins) {
                        _showInstallmentDialog(ins);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
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

  void _showInstallmentDialog(PaymentSchedule installment) {
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
            Text('Estado: ${installment.status.toUpperCase()}'),
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

  Widget _buildStatusBadge(Credito credit) {
    Color color;
    IconData icon;
    switch (credit.status) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'pending_approval':
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        break;
      case 'waiting_delivery':
        color = Colors.blue;
        icon = Icons.schedule;
        break;
      case 'completed':
        color = Colors.teal;
        icon = Icons.verified;
        break;
      case 'defaulted':
        color = Colors.red;
        icon = Icons.warning;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            credit.statusLabel,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpisRow(Credito credit, Map<String, dynamic> summary) {
    final total = (credit.totalAmount ?? credit.amount);
    final paid = (total - credit.balance).clamp(0, total);
    final progress = total > 0 ? (paid / total) : 0.0;
    final overdue = (summary['is_overdue'] ?? false) as bool;
    final overdueAmount = (summary['overdue_amount'] ?? 0) as num;

    Widget kpi(String title, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        kpi('Pagado', _formatCurrency(paid), Icons.payments, Colors.green),
        const SizedBox(width: 8),
        kpi(
          'Saldo',
          _formatCurrency(credit.balance),
          Icons.account_balance_wallet,
          Colors.orange,
        ),
        const SizedBox(width: 8),
        kpi(
          overdue ? 'En Mora' : 'Al Día',
          overdue
              ? _formatCurrency(overdueAmount)
              : '${(progress * 100).toStringAsFixed(0)}%',
          overdue ? Icons.warning : Icons.trending_up,
          overdue ? Colors.red : Colors.blue,
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTab(Credito credit) {
    final payments = (_paymentsHistory != null && _paymentsHistory!.isNotEmpty)
        ? _paymentsHistory!
        : (credit.payments ?? []);
    final total = credit.totalAmount ?? credit.amount;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final items = <Widget>[
                _buildPaymentSummary(
                  'Total Pagado',
                  'Bs. ${NumberFormat('#,##0.00').format((total - credit.balance).clamp(0, total))}',
                  Icons.payment,
                  Colors.green,
                ),
                _buildPaymentSummary(
                  'Número de Pagos',
                  '${payments.length}',
                  Icons.receipt,
                  Colors.blue,
                ),
                if (credit.installmentAmount != null)
                  _buildPaymentSummary(
                    'Cuota Sugerida',
                    'Bs. ${NumberFormat('#,##0.00').format(credit.installmentAmount!)}',
                    Icons.schedule,
                    Colors.orange,
                  ),
              ];

              if (constraints.maxWidth < 500) {
                return Center(
                  child: Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    alignment: WrapAlignment.spaceAround,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: items
                        .map(
                          (w) => ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 120),
                            child: w,
                          ),
                        )
                        .toList(),
                  ),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items,
              );
            },
          ),
        ),
        Expanded(
          child: payments.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.payment, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No hay pagos registrados',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Los pagos aparecerán aquí una vez registrados',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            Icons.payment,
                            color: Colors.green.shade700,
                          ),
                        ),
                        title: Text(
                          'Bs. ${NumberFormat('#,##0.00').format(payment.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy HH:mm',
                              ).format(payment.paymentDate),
                            ),
                            if (payment.notes != null &&
                                payment.notes!.isNotEmpty)
                              Text(
                                payment.notes!,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          '#${payment.id}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildDateInfo(String label, DateTime date) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            DateFormat('dd/MM/yyyy').format(date),
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Future<void> _editCredit(Credito credit) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => CreditFormScreen(credit: credit)),
    );

    if (result == true) {
      ref.read(creditProvider.notifier).loadCredits();
    }
  }

  void _handleMenuAction(String action, Credito credit) {
    switch (action) {
      case 'delete':
        _showDeleteConfirmation(credit);
        break;
    }
  }

  Future<void> _showDeleteConfirmation(Credito credit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que deseas eliminar este crédito?\n\n'
          'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}\n'
          'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .deleteCredit(credit.id);
      if (success && mounted) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildWaitingListInfo(Credito credit) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Estado de Lista de Espera',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            /*Text(
              'Estado: ${credit.status}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),*/
          ],
        ),
      ),
    );
  }
}
