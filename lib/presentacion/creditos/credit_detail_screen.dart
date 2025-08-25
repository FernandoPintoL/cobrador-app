import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../ui/widgets/client_category_chip.dart';
import '../../datos/servicios/credit_api_service.dart';
import 'credit_form_screen.dart';
import 'credit_payment_screen.dart';
import '../widgets/contact_actions_widget.dart';
import '../../ui/widgets/loading_overlay.dart';
import '../cliente/location_picker_screen.dart';

class CreditDetailScreen extends ConsumerStatefulWidget {
  final Credito credit;

  const CreditDetailScreen({super.key, required this.credit});

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen>
    with SingleTickerProviderStateMixin {
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
  }

  Future<void> _loadCreditDetails() async {
    print("🪙 widget credito: " + widget.credit.toJson().toString());
    try {
      setState(() => _isLoadingDetails = true);
      // 1) Obtener y fusionar detalles del crédito (incluye cliente/ubicación)
      final details = await ref
          .read(creditProvider.notifier)
          .getCreditDetails(widget.credit.id);
      print("🪙 detalles obtenidos: " + (details?.toJson() ?? {}).toString());

      // 2) Obtener respuesta cruda del endpoint /details para extraer summary/schedule/history
      try {
        final api = CreditApiService();
        final raw = await api.getCreditDetails(widget.credit.id);
        debugPrint('🔍 Detalles crudos de /details: $raw');
        if (raw['success'] == true && raw['data'] is Map<String, dynamic>) {
          final data = raw['data'] as Map<String, dynamic>;
          // summary
          final summary = data['summary'];
          // schedule
          final schedule = data['payment_schedule'];
          // history
          final history = data['payments_history'];

          _creditSummary = summary is Map<String, dynamic> ? summary : null;

          if (schedule is List) {
            _apiPaymentSchedule = schedule
                .whereType<Map<String, dynamic>>()
                .map((e) => PaymentSchedule.fromJson(e))
                .toList();
          } else {
            _apiPaymentSchedule = null;
          }

          if (history is List) {
            _paymentsHistory = history
                .whereType<Map<String, dynamic>>()
                .map((e) => Pago.fromJson(e))
                .toList();
          } else {
            _paymentsHistory = null;
          }
        }
      } catch (e) {
        // Si falla la extracción de extras, continuar con lo disponible
        // ignore: avoid_print
        print('⚠️ No se pudieron obtener extras de /details: $e');
      }

      if (!mounted) return;
      setState(() {
        _detailedCredit = details ?? widget.credit;
        _isLoadingDetails = false;
      });
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

  // Cuenta días entre dos fechas excluyendo domingos (incluye sábados)
  /*int _countBusinessDaysExcludingSundays(DateTime from, DateTime to) {
    // Normalizar a fechas (sin tiempo)
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    if (start.isAfter(end)) return 0;

    int count = 0;
    DateTime current = start;
    while (!current.isAfter(end)) {
      if (current.weekday != DateTime.sunday) {
        count++;
      }
      current = current.add(const Duration(days: 1));
    }
    return count;
  }*/

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
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
                  Theme.of(context).colorScheme.surface.withOpacity(0.96),
                  Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.96),
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
          LoadingOverlay(isLoading: _isLoadingDetails, message: 'Cargando detalles...'),
        ],
      ),
      floatingActionButton:
          currentCredit.status == 'active'
          ? FloatingActionButton.extended(
              onPressed: () => _navigateToPaymentScreen(currentCredit),
              icon: const Icon(Icons.payment),
              label: const Text('Procesar Pago'),
            )
          : null,
    );
  }

  Future<void> _navigateToPaymentScreen(Credito credit) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreditPaymentScreen(credit: credit),
      ),
    );

    // Si se procesó un pago exitosamente, actualizar la pantalla
    if (result == true) {
      // Recargar créditos para obtener información actualizada
      ref.read(creditProvider.notifier).loadCredits();
    }
  }

  Widget _buildInformationTab(Credito credit) {
    // final total = credit.totalAmount ?? credit.amount;
    final total = widget.credit.totalAmount;
    final paid = (total! - widget.credit.balance).clamp(0, total);
    final progress = total > 0 ? (paid / total) : 0.0;
    final daysRemaining = widget.credit.frequency == 'daily'
        ? widget.credit.pendingInstallments
        : widget.credit.endDate.difference(DateTime.now()).inDays;
    print(daysRemaining.toString());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          if (_creditSummary != null)
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
                      'Resumen del crédito',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        _buildInfoChip(
                          'Monto Original',
                          _formatCurrency(_creditSummary!['original_amount']),
                        ),
                        _buildInfoChip(
                          'Interés %',
                          (_creditSummary!['interest_rate'] ?? '').toString(),
                        ),
                        _buildInfoChip(
                          'Total',
                          _formatCurrency(_creditSummary!['total_amount']),
                        ),
                        _buildInfoChip(
                          'Cuota',
                          _formatCurrency(
                            _creditSummary!['installment_amount'],
                          ),
                        ),
                        _buildInfoChip(
                          'Cuotas',
                          (_creditSummary!['total_installments'] ?? '')
                              .toString(),
                        ),
                        _buildInfoChip(
                          'Saldo',
                          _formatCurrency(_creditSummary!['current_balance']),
                        ),
                        _buildInfoChip(
                          'Pagado',
                          _formatCurrency(_creditSummary!['total_paid']),
                        ),
                        _buildInfoChip(
                          'Pendientes',
                          (_creditSummary!['pending_installments'] ?? '')
                              .toString(),
                        ),
                        // _buildInfoChip('Esperadas', (_creditSummary!['expected_installments'] ?? '').toString()),
                        // _buildInfoChip('Mora', ((_creditSummary!['is_overdue'] ?? false) ? 'Sí' : 'No')),
                        // _buildInfoChip('Monto en Mora', _formatCurrency(_creditSummary!['overdue_amount'])),
                      ],
                    ),
                    const SizedBox(height: 12,),
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
                      children: [
                        Expanded(child: _buildDateInfo('F. Inicio', credit.startDate)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildDateInfo('F. Vencimiento', credit.endDate)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDateInfo('Fecha para Entrega', credit.scheduledDeliveryDate!),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          // Información de lista de espera (solo si no está activo)
          if (!credit.isActive) _buildWaitingListInfo(credit),
          const SizedBox(height: 16),
          // Información del cliente
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
                    'Información del Cliente',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      credit.client?.nombre ?? 'Cliente #${credit.clientId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (credit.client?.clientCategory != null) ...[
                          ClientCategoryChip(
                            category: credit.client!.clientCategory,
                            compact: false,
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (credit.client?.telefono != null &&
                            credit.client!.telefono.isNotEmpty)
                          Text('Teléfono: ${credit.client!.telefono}'),
                        if (credit.client?.direccion != null &&
                            credit.client!.direccion.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Dirección: ${credit.client!.direccion}'),
                        ],
                        if (credit.client?.latitud != null &&
                            credit.client?.longitud != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ubicación GPS: ${credit.client!.latitud!.toStringAsFixed(6)}, ${credit.client!.longitud!.toStringAsFixed(6)}',
                          ),
                        ] else if (_isLoadingDetails) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Cargando datos de ubicación del cliente...',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                        const SizedBox(height: 8),
                        // Acciones de contacto y mapa
                        Row(
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
                                                // Modo solo visualización
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
                        if (credit.client == null) ...[
                          const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          if (_apiPaymentSchedule != null &&
              _apiPaymentSchedule!.isNotEmpty) ...[
            const SizedBox(height: 16),
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
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _apiPaymentSchedule!.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (context, index) {
                        final item = _apiPaymentSchedule![index];
                        Color color;
                        IconData icon;
                        switch (item.status) {
                          case 'paid':
                            color = Colors.green;
                            icon = Icons.check_circle;
                            break;
                          case 'overdue':
                            color = Colors.red;
                            icon = Icons.warning;
                            break;
                          default:
                            color = Colors.blueGrey;
                            icon = Icons.schedule;
                            break;
                        }
                        return Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: color.withOpacity(0.1),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Cuota ${item.installmentNumber} • ${DateFormat('dd/MM/yyyy').format(item.dueDate)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Monto: ${_formatCurrency(item.amount)}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                item.status.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        );
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

  Widget _buildInfoChip(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.5),
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
        // Resumen de pagos
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
                Theme.of(context).colorScheme.secondary.withOpacity(0.10),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(16),
            ),
          ),
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

              // En pantallas angostas, usar Wrap para que los ítems fluyan a múltiples filas
              if (constraints.maxWidth < 500) {
                return Center(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
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

              // En pantallas anchas, mantener distribución horizontal
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items,
              );
            },
          ),
        ),

        // Lista de pagos
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
      // Recargar créditos para obtener los datos actualizados
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
        Navigator.pop(context); // Regresar a la lista de créditos
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Estado de Lista de Espera',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildWaitingListStatusChip(credit.status),
              ],
            ),
            const SizedBox(height: 16),

            // Información específica según el estado
            if (credit.isPendingApproval) ...[
              _buildWaitingListRow(
                'Estado:',
                'Pendiente de aprobación por un manager',
                Icons.hourglass_empty,
                Colors.orange,
              ),
              if (credit.creator != null) ...[
                const SizedBox(height: 8),
                _buildWaitingListRow(
                  'Creado por:',
                  credit.creator!.nombre,
                  Icons.person,
                  Colors.blue,
                ),
              ],
            ],

            if (credit.isWaitingDelivery) ...[
              if (credit.scheduledDeliveryDate != null) ...[
                _buildWaitingListRow(
                  'Fecha programada:',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(credit.scheduledDeliveryDate!),
                  Icons.schedule,
                  credit.isReadyForDelivery ? Colors.green : Colors.blue,
                ),
                const SizedBox(height: 8),
                if (credit.isReadyForDelivery)
                  _buildWaitingListRow(
                    'Estado:',
                    'Listo para entrega',
                    Icons.check_circle,
                    Colors.green,
                  )
                else if (credit.isOverdueForDelivery)
                  _buildWaitingListRow(
                    'Estado:',
                    'Entrega atrasada (${credit.daysOverdueForDelivery} días)',
                    Icons.warning,
                    Colors.red,
                  )
                else
                  _buildWaitingListRow(
                    'Estado:',
                    'Programado para ${credit.daysUntilDelivery} días',
                    Icons.timer,
                    Colors.blue,
                  ),
              ],
              if (credit.approver != null) ...[
                const SizedBox(height: 8),
                _buildWaitingListRow(
                  'Aprobado por:',
                  credit.approver!.nombre,
                  Icons.person_outline,
                  Colors.green,
                ),
                if (credit.approvedAt != null) ...[
                  const SizedBox(height: 4),
                  _buildWaitingListRow(
                    'Fecha de aprobación:',
                    DateFormat('dd/MM/yyyy HH:mm').format(credit.approvedAt!),
                    Icons.calendar_today,
                    Colors.grey,
                  ),
                ],
              ],
              if (credit.deliveryNotes != null &&
                  credit.deliveryNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildWaitingListRow(
                  'Notas de entrega:',
                  credit.deliveryNotes!,
                  Icons.note,
                  Colors.blue,
                ),
              ],
            ],

            if (credit.isRejected) ...[
              _buildWaitingListRow(
                'Estado:',
                'Crédito rechazado',
                Icons.cancel,
                Colors.red,
              ),
              if (credit.rejectionReason != null &&
                  credit.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildWaitingListRow(
                  'Motivo del rechazo:',
                  credit.rejectionReason!,
                  Icons.info_outline,
                  Colors.red,
                ),
              ],
            ],

            if (credit.isActive) ...[
              _buildWaitingListRow(
                'Estado:',
                'Crédito entregado y activo',
                Icons.check_circle,
                Colors.green,
              ),
              if (credit.deliverer != null) ...[
                const SizedBox(height: 8),
                _buildWaitingListRow(
                  'Entregado por:',
                  credit.deliverer!.nombre,
                  Icons.person,
                  Colors.green,
                ),
              ],
              if (credit.deliveredAt != null) ...[
                const SizedBox(height: 4),
                _buildWaitingListRow(
                  'Fecha de entrega:',
                  DateFormat('dd/MM/yyyy HH:mm').format(credit.deliveredAt!),
                  Icons.calendar_today,
                  Colors.green,
                ),
              ],
            ],

            // Botones de acción según el estado y permisos del usuario
            const SizedBox(height: 20),
            _buildWaitingListActions(credit),
          ],
        ),
      ),
    );
  }

  Widget _buildWaitingListStatusChip(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'pending_approval':
        color = Colors.orange;
        label = 'Pendiente';
        icon = Icons.hourglass_empty;
        break;
      case 'waiting_delivery':
        color = Colors.blue;
        label = 'En Espera';
        icon = Icons.schedule;
        break;
      case 'active':
        color = Colors.green;
        label = 'Activo';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rechazado';
        icon = Icons.cancel;
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelado';
        icon = Icons.block;
        break;
      default:
        color = Colors.grey;
        label = status;
        icon = Icons.help;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
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

  Widget _buildWaitingListRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Flexible(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$label ',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color:
                        Theme.of(context).textTheme.bodyMedium?.color ??
                        Colors.black87,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingListActions(Credito credit) {
    final authState = ref.watch(authProvider);
    final isManager = authState.isManager || authState.isAdmin;
    final isCobrador = authState.isCobrador;

    // Si no hay permisos, no mostrar acciones
    if (!isManager && !isCobrador) {
      return const SizedBox.shrink();
    }

    // Construimos los botones sin Expanded; luego decidimos el layout
    List<Widget> buttons = [];

    // Acciones para managers/admins
    if (isManager) {
      if (credit.isPendingApproval) {
        buttons.addAll([
          ElevatedButton.icon(
            onPressed: () => _showApprovalDialog(credit),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Aprobar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _showRejectionDialog(credit),
            icon: const Icon(Icons.cancel, size: 18),
            label: const Text('Rechazar'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ]);
      } else if (credit.isWaitingDelivery) {
        buttons.addAll([
          OutlinedButton.icon(
            onPressed: () => _showRescheduleDialog(credit),
            icon: const Icon(Icons.schedule, size: 18),
            label: const Text('Reprogramar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
          ),
        ]);
      }
    }

    // Acciones para cobradores
    if ((isCobrador || isManager) &&
        credit.isWaitingDelivery &&
        credit.isReadyForDelivery) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: () => _showDeliveryDialog(credit),
          icon: const Icon(Icons.local_shipping, size: 18),
          label: const Text('Entregar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    // Distribuir acciones de forma responsiva segun el ancho disponible
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 420;
        if (isNarrow) {
          // En columnas (dentro de un scroll con altura no acotada), evitar Expanded
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < buttons.length; i++) ...[
                SizedBox(width: double.infinity, child: buttons[i]),
                if (i != buttons.length - 1) const SizedBox(height: 8),
              ],
            ],
          );
        }
        // En pantallas anchas, repartir con Expanded para ocupar el ancho
        final rowChildren = <Widget>[];
        for (int i = 0; i < buttons.length; i++) {
          rowChildren.add(Expanded(child: buttons[i]));
          if (i != buttons.length - 1) {
            rowChildren.add(const SizedBox(width: 8));
          }
        }
        return Row(children: rowChildren);
      },
    );
  }

  Future<void> _showApprovalDialog(Credito credit) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aprobar Crédito para Entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            const SizedBox(height: 16),
            const Text('Fecha programada de entrega:'),
            const SizedBox(height: 8),
            StatefulBuilder(
              builder: (context, setState) => Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDate),
                        );
                        if (time != null) {
                          setState(() {
                            selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                hintText: 'Instrucciones adicionales para la entrega',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .approveCreditForDelivery(
            creditId: credit.id,
            scheduledDeliveryDate: selectedDate,
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
          );

      if (success && mounted) {
        // Recargar créditos para obtener información actualizada
        ref.read(creditProvider.notifier).loadCredits();
      }
    }
  }

  Future<void> _showRejectionDialog(Credito credit) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo *',
                hintText: 'Explique por qué se rechaza este crédito',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Debe proporcionar un motivo para el rechazo',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .rejectCredit(
            creditId: credit.id,
            reason: reasonController.text.trim(),
          );

      if (success && mounted) {
        // Recargar créditos para obtener información actualizada
        ref.read(creditProvider.notifier).loadCredits();
      }
    }
  }

  Future<void> _showRescheduleDialog(Credito credit) async {
    DateTime selectedDate =
        credit.scheduledDeliveryDate ??
        DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reprogramar Entrega'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (credit.scheduledDeliveryDate != null)
                Text(
                  'Fecha actual: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                  style: const TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 16),
              const Text('Nueva fecha programada:'),
              const SizedBox(height: 8),
              StatefulBuilder(
                builder: (context, setState) => Row(
                  children: [
                    Flexible(
                      child: Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(selectedDate),
                          );
                          if (time != null) {
                            setState(() {
                              selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motivo de la reprogramación (opcional)',
                  hintText: 'Explique por qué se reprograma la entrega',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reprogramar'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .rescheduleCreditDelivery(
            creditId: credit.id,
            newScheduledDate: selectedDate,
            reason: reasonController.text.trim().isEmpty
                ? null
                : reasonController.text.trim(),
          );

      if (success && mounted) {
        // Recargar créditos para obtener información actualizada
        ref.read(creditProvider.notifier).loadCredits();
      }
    }
  }

  Future<void> _showDeliveryDialog(Credito credit) async {
    final notesController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Entregar Crédito al Cliente'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            if (credit.scheduledDeliveryDate != null)
              Text(
                'Programado para: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                style: const TextStyle(color: Colors.blue),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas de entrega (opcional)',
                hintText: 'Detalles sobre cómo se realizó la entrega',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmar Entrega'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .deliverCreditToClient(
            creditId: credit.id,
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
          );

      if (success && mounted) {
        // Recargar créditos para obtener información actualizada
        ref.read(creditProvider.notifier).loadCredits();
      }
    }
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'pending_approval':
        color = Colors.orange;
        label = 'Pendiente de Aprobación';
        break;
      case 'waiting_delivery':
        color = Colors.blue;
        label = 'En Lista de Espera';
        break;
      case 'active':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'completed':
        color = Colors.blue;
        label = 'Completado';
        break;
      case 'defaulted':
        color = Colors.red;
        label = 'En Mora';
        break;
      case 'rejected':
        color = Colors.red;
        label = 'Rechazado';
        break;
      case 'cancelled':
        color = Colors.grey;
        label = 'Cancelado';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        gradient: LinearGradient(
          colors: [Colors.white.withOpacity(0.9), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getAttentionReason(Credito credit) {
    if (credit.endDate.isBefore(DateTime.now())) {
      return 'crédito vencido';
    }
    if (credit.endDate.difference(DateTime.now()).inDays <= 7) {
      return 'próximo a vencer';
    }
    if (credit.balance > credit.amount * 0.8) {
      return 'poco progreso en pagos';
    }
    return 'requiere seguimiento';
  }
}
