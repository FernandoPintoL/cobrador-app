import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../ui/widgets/client_category_chip.dart';
import '../widgets/payment_dialog.dart';
import '../cliente/cliente_perfil_screen.dart';
import 'credit_form_screen.dart';
import '../widgets/contact_actions_widget.dart';
import '../../ui/widgets/loading_overlay.dart';
import '../cliente/location_picker_screen.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/payment_schedule_calendar.dart';
import 'package:cobrador_app/presentacion/creditos/payment_history_screen.dart';

class CreditDetailScreen extends ConsumerStatefulWidget {
  final Credito credito;

  // Accept both `credito` and `credit` as named parameters for backward compatibility
  CreditDetailScreen({Key? key, Credito? credito, Credito? credit})
    : assert(credito != null || credit != null),
      credito = credito ?? credit!,
      super(key: key);

  @override
  ConsumerState<CreditDetailScreen> createState() => _CreditDetailScreenState();
}

class _CreditDetailScreenState extends ConsumerState<CreditDetailScreen> {
  late Credito _credito;
  bool _isLoadingDetails = false;
  bool _paymentRecentlyProcessed = false;
  Map<String, dynamic>? _creditSummary;
  List<PaymentSchedule>? _apiPaymentSchedule;

  @override
  void initState() {
    super.initState();
    _credito = widget.credito;
    _loadCreditDetails();
  }

  Future<void> _loadCreditDetails() async {
    setState(() {
      _isLoadingDetails = true;
    });

    try {
      // Obtener detalles completos desde el provider (credit + summary + schedule + payments)
      final details = await ref
          .read(creditProvider.notifier)
          .getCreditFullDetails(_credito.id);

      if (details != null) {
        setState(() {
          // Actualizar resumen, cronograma y historial desde la respuesta
          _creditSummary = details.summary;
          _apiPaymentSchedule = details.schedule;
          // paymentsHistory is provided in details.paymentsHistory but this screen
          // uses calendar/list widgets which can read the provider or details.credit.payments
          // Mantener la referencia del crédito actualizada con los datos retornados
          _credito = details.credit;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar detalles del crédito: $e',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCredit = _credito;

    return Scaffold(
      appBar: AppBar(
        title: Text('Crédito #'+currentCredit.id.toString()),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Historial de pagos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PaymentHistoryScreen(creditId: currentCredit.id),
                ),
              );
            },
          ),
          if (ref.watch(authProvider).isManager) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editCredit(currentCredit),
              tooltip: 'Editar Crédito',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, currentCredit),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Eliminar Crédito'),
                ),
                const PopupMenuItem<String>(
                  value: 'cancel',
                  child: Text('Anular Crédito'),
                ),
              ],
            ),
          ],
        ],
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
            child: _buildInformationTab(currentCredit),
          ),
          LoadingOverlay(
            isLoading: _isLoadingDetails || _paymentRecentlyProcessed,
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
                _paymentRecentlyProcessed
                    ? 'Actualizando...'
                    : 'Procesar Pagos',
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
    // Mostrar el diálogo; el diálogo retorna true en caso de éxito.
    final result = await PaymentDialog.show(
      context,
      ref,
      credit,
      creditSummary: _creditSummary,
    );

    if (result != null && result['success'] == true) {
      // Marcar estado para bloquear reintentos inmediatos
      if (mounted) {
        setState(() {
          _paymentRecentlyProcessed = true;
          _isLoadingDetails = true;
        });
      }

      final message = result['message'] as String?;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message ?? 'Pago registrado. Actualizando información...',
            ),
          ),
        );
      }

      // Recargar créditos y detalles para obtener información actualizada
      ref.read(creditProvider.notifier).loadCredits();
      await _loadCreditDetails();
    } else if (result != null && result['success'] == false) {
      // Mostrar mensaje de error devuelto por el diálogo
      final message = result['message'] as String?;
      if (mounted && message != null && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    }

    // Si no se procesó o se canceló, reactivar el FAB
    if (mounted) {
      setState(() {
        _paymentRecentlyProcessed = false;
        _isLoadingDetails = false;
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
                            credit.client!.telefono.isNotEmpty) ...[
                          Text('Teléfono: ${credit.client!.telefono}'),
                          const SizedBox(height: 4),
                          Text('CI: ${credit.client?.ci ?? 'N/A'}'),
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
                        _buildStatusBadge(credit),
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
                          'Pagadas',
                          (_creditSummary!['completed_installments_count'] ?? '')
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
      case 'cancelled':
        color = Colors.grey.shade600;
        icon = Icons.cancel;
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

  // Payments are displayed in calendar/list views elsewhere; the tabbed payments UI was removed.

  // Payment summary widgets are rendered in calendar/list views; helper removed.

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
      case 'cancel':
        _showCancelConfirmation(credit);
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

  Future<void> _showCancelConfirmation(Credito credit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Anulación'),
        content: Text(
          '¿Estás seguro de que deseas anular este crédito?\n\n'
          'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}\n'
          'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}\n\n'
          'El crédito será marcado como cancelado pero se mantendrá '
          'el historial de pagos realizados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .cancelCredit(credit.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Crédito anulado exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
        // Recargar los datos para mostrar el estado actualizado
        _loadCreditDetails();
        ref.read(creditProvider.notifier).loadCredits();
      }
    }
  }
}
