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
import '../../config/role_colors.dart';

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
  bool _showAllDetails = false;
  bool _showClientInfo = false;
  bool _showSummaryInfo = true; // Inicia abierto

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
          // ✅ OPTIMIZACIÓN: Actualizar resumen y cronograma desde la respuesta
          // El cronograma ahora incluye toda la información de pagos (incluyendo cobrador)
          _creditSummary = details.summary;
          _apiPaymentSchedule = details.schedule;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isManager = ref.watch(authProvider).isManager;
    final primaryColor = isManager
        ? RoleColors.managerPrimary
        : RoleColors.cobradorPrimary;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.credit_card_rounded, size: 18),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Credito #${currentCredit.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          _buildModernActionButton(
            icon: Icons.receipt_long_rounded,
            tooltip: 'Historial de pagos',
            color: Colors.white,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      PaymentHistoryScreen(creditId: currentCredit.id),
                ),
              );
            },
          ),
          if (isManager) ...[
            _buildModernActionButton(
              icon: Icons.edit_rounded,
              tooltip: 'Editar Crédito',
              color: Colors.orange,
              onPressed: () => _editCredit(currentCredit),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, currentCredit),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.grey.withValues(alpha: 0.15),
                      Colors.grey.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.more_vert_rounded, size: 20),
              ),
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      SizedBox(width: 12),
                      Text('Eliminar Crédito'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'cancel',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text('Anular Crédito'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Botón fijo en la parte superior (solo para créditos activos)
              if (currentCredit.status == 'active')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: FilledButton.icon(
                    onPressed: (_paymentRecentlyProcessed || _isLoadingDetails)
                        ? null
                        : () => _navigateToPaymentScreen(currentCredit),
                    icon: const Icon(Icons.payment, size: 22),
                    label: Text(
                      _paymentRecentlyProcessed
                          ? 'Actualizando...'
                          : 'Procesar Pagos',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
              // Contenido scrolleable
              Expanded(
                child: Container(
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
                  child: _buildInformationTab(currentCredit, primaryColor),
                ),
              ),
            ],
          ),
          LoadingOverlay(
            isLoading: _isLoadingDetails || _paymentRecentlyProcessed,
            message: 'Cargando detalles...',
          ),
        ],
      ),
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

  Widget _buildInformationTab(Credito credit, Color primaryColor) {
    final total = (credit.totalAmount ?? credit.amount);
    final paid = (total - credit.balance).clamp(0, total);
    final progress = total > 0 ? (paid / total) : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 4),
          // CRONOGRAMA DE PAGOS - LO MÁS IMPORTANTE PRIMERO
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
            const SizedBox(height: 12),
          ],
          // RESUMEN DEL CRÉDITO - Colapsable
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header colapsable del resumen
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showSummaryInfo = !_showSummaryInfo;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              flex: 2,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.summarize_rounded,
                                    size: 24,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Flexible(
                                    child: Text(
                                      'Resumen del Crédito',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              flex: 1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Flexible(child: _buildStatusBadge(credit)),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _showSummaryInfo
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Contenido expandible del resumen
                    if (_showSummaryInfo) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                    const SizedBox(height: 12),
                    _buildKpisRow(credit, _creditSummary!),
                    const SizedBox(height: 12),
                    // Información esencial en grid de 2 columnas
                    _buildEssentialInfoGrid(_creditSummary!),
                    const SizedBox(height: 12),
                    // Botón para expandir/colapsar detalles adicionales
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showAllDetails = !_showAllDetails;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .outlineVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showAllDetails
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 20,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showAllDetails
                                  ? 'Ocultar detalles'
                                  : 'Ver más detalles',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Detalles adicionales (expandibles)
                    if (_showAllDetails) ...[
                      const SizedBox(height: 12),
                      _buildAdditionalDetailsGrid(_creditSummary!),
                    ],
                    const SizedBox(height: 16),
                    // Barra de progreso moderna con gradiente
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progreso del crédito',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              '${(progress * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: progress < 0.5
                                    ? Colors.red
                                    : (progress < 0.8
                                          ? Colors.orange
                                          : Colors.green),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              Container(
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: progress < 0.5
                                          ? [
                                              Colors.red.shade400,
                                              Colors.red.shade600,
                                            ]
                                          : (progress < 0.8
                                                ? [
                                                    Colors.orange.shade400,
                                                    Colors.orange.shade600,
                                                  ]
                                                : [
                                                    Colors.green.shade400,
                                                    Colors.green.shade600,
                                                  ]),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            (progress < 0.5
                                                    ? Colors.red
                                                    : (progress < 0.8
                                                          ? Colors.orange
                                                          : Colors.green))
                                                .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    IntrinsicHeight(
                      child: Row(
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
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          // INFORMACIÓN DEL CLIENTE - Colapsable
          _buildCollapsableClientCard(credit),
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

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Pagado';
      case 'partial':
        return 'Parcial';
      case 'overdue':
        return 'Vencido';
      case 'pending':
        return 'Pendiente';
      default:
        return status.toUpperCase();
    }
  }

  void _showInstallmentDialog(PaymentSchedule installment) {
    // Determinar color del estado
    Color statusColor;
    switch (installment.status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'partial':
        statusColor = Colors.orange;
        break;
      case 'overdue':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    // Calcular monto restante (por si el backend no lo envía)
    final double remaining = installment.remainingAmount > 0
        ? installment.remainingAmount
        : (installment.amount - installment.paidAmount).clamp(0.0, installment.amount);

    // Verificar si la cuota puede ser pagada (no está completamente pagada)
    final bool canPay = installment.status != 'paid' &&
                        !installment.isPaidFull &&
                        remaining > 0;

    // Verificar si hay cuotas anteriores sin pagar (pago fuera de orden)
    final bool hasUnpaidPreviousInstallments = _apiPaymentSchedule
            ?.where((s) =>
                s.installmentNumber < installment.installmentNumber &&
                s.status != 'paid' &&
                !s.isPaidFull)
            .isNotEmpty ??
        false;

    // Debug: Imprimir información de la cuota
    debugPrint('🔍 Cuota #${installment.installmentNumber}:');
    debugPrint('   Status: ${installment.status}');
    debugPrint('   Amount: ${installment.amount}');
    debugPrint('   PaidAmount: ${installment.paidAmount}');
    debugPrint('   RemainingAmount (backend): ${installment.remainingAmount}');
    debugPrint('   Remaining (calculated): $remaining');
    debugPrint('   isPaidFull: ${installment.isPaidFull}');
    debugPrint('   canPay: $canPay');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              canPay ? Icons.payment_rounded : Icons.info_outline_rounded,
              color: canPay ? Colors.green : statusColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Cuota #${installment.installmentNumber}'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Advertencia de cuotas anteriores sin pagar
            if (hasUnpaidPreviousInstallments && canPay) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 2),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.orange, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '⚠️ Hay cuotas anteriores sin pagar. Se recomienda pagar en orden secuencial.',
                        style: TextStyle(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Fecha de vencimiento: ${DateFormat('dd/MM/yyyy').format(installment.dueDate)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (installment.lastPaymentDate != null) ...[
              const SizedBox(height: 4),
              Text(
                'Fecha de pago: ${DateFormat('dd/MM/yyyy').format(installment.lastPaymentDate!)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (installment.lastPaymentDate!.isAfter(installment.dueDate)) ...[
                const SizedBox(height: 2),
                Text(
                  '⚠️ Pagado ${installment.lastPaymentDate!.difference(installment.dueDate).inDays} día(s) tarde',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ] else if (installment.lastPaymentDate!.isBefore(installment.dueDate)) ...[
                const SizedBox(height: 2),
                Text(
                  '✓ Pagado ${installment.dueDate.difference(installment.lastPaymentDate!).inDays} día(s) antes',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 8),
            Text(
              'Monto de cuota: Bs. ${installment.amount.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Estado: '),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    _getStatusLabel(installment.status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            // Información de pagos
            Text(
              'Monto pagado: Bs. ${installment.paidAmount.toStringAsFixed(2)}',
              style: TextStyle(
                color: installment.paidAmount > 0 ? Colors.green : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (remaining > 0 && !installment.isPaidFull) ...[
              const SizedBox(height: 8),
              Text(
                'Falta por pagar: Bs. ${remaining.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            if (installment.paymentCount > 0) ...[
              const SizedBox(height: 8),
              Text('Pagos realizados: ${installment.paymentCount}'),
            ],
            if (installment.lastPaymentDate != null) ...[
              const SizedBox(height: 8),
              Text(
                'Último pago: ${DateFormat('dd/MM/yyyy').format(installment.lastPaymentDate!)}',
              ),
            ],
            if (installment.paymentMethod != null) ...[
              const SizedBox(height: 8),
              Text('Método de pago: ${installment.paymentMethod}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (canPay)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _paySpecificInstallment(installment);
              },
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Pagar'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _paySpecificInstallment(PaymentSchedule installment) async {
    // Verificar si hay cuotas anteriores sin pagar
    final unpaidPrevious = _apiPaymentSchedule
        ?.where((s) =>
            s.installmentNumber < installment.installmentNumber &&
            s.status != 'paid' &&
            !s.isPaidFull)
        .toList() ?? [];

    // Si hay cuotas anteriores sin pagar, mostrar confirmación
    if (unpaidPrevious.isNotEmpty) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Advertencia: Pago fuera de orden'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estás intentando pagar la cuota #${installment.installmentNumber}, pero hay ${unpaidPrevious.length} cuota(s) anterior(es) sin pagar:',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: unpaidPrevious.take(5).map((s) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 6, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Cuota #${s.installmentNumber} - ${_getStatusLabel(s.status)}',
                            style: TextStyle(fontSize: 13, color: Colors.orange.shade900),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (unpaidPrevious.length > 5) ...[
                const SizedBox(height: 8),
                Text(
                  'Y ${unpaidPrevious.length - 5} cuota(s) más...',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                '¿Deseas continuar con el pago de la cuota #${installment.installmentNumber} de todas formas?',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Recomendación: Es mejor pagar las cuotas en orden secuencial para mantener un mejor control del crédito.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar de todas formas'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return; // Usuario canceló
      }
    }

    // Mostrar el diálogo de pago con la cuota específica
    final result = await PaymentDialog.show(
      context,
      ref,
      _credito,
      creditSummary: _creditSummary,
      specificInstallment: installment,
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

    // Si no se procesó o se canceló, reactivar
    if (mounted) {
      setState(() {
        _paymentRecentlyProcessed = false;
        _isLoadingDetails = false;
      });
    }
  }

  Widget _buildCollapsableClientCard(Credito credit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    Theme.of(context).colorScheme.surface,
                  ]
                : [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header colapsable del cliente
            InkWell(
              onTap: () {
                setState(() {
                  _showClientInfo = !_showClientInfo;
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Foto
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ProfileImageWidget(
                        profileImage: credit.client?.profileImage,
                        size: 64,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info básica del cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                flex: 3,
                                child: Text(
                                  credit.client?.nombre ??
                                      'Cliente #${credit.clientId}',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (credit.client?.clientCategory != null) ...[
                                const SizedBox(width: 8),
                                ClientCategoryChip(
                                  category: credit.client!.clientCategory,
                                  compact: true,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ID: ${credit.clientId}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _showClientInfo
                          ? Icons.expand_less
                          : Icons.expand_more,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            // Contenido expandible del cliente
            if (_showClientInfo && credit.client != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Info adicional
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            credit.client!.telefono.isNotEmpty
                                ? credit.client!.telefono
                                : 'Sin teléfono',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_rounded,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            credit.client?.ci ?? 'Sin CI',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Botones de acción
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildContactButton(
                          icon: Icons.phone_rounded,
                          label: 'Llamar',
                          color: Colors.green,
                          onTap: (credit.client!.telefono.isNotEmpty)
                              ? () async {
                                  try {
                                    await ContactActionsWidget.makePhoneCall(
                                      credit.client!.telefono,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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
                        _buildContactButton(
                          icon: Icons.message_rounded,
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: (credit.client!.telefono.isNotEmpty)
                              ? () async {
                                  try {
                                    await ContactActionsWidget.openWhatsApp(
                                      credit.client!.telefono,
                                      message:
                                          'Hola ${credit.client!.nombre}, me comunico desde la aplicación.',
                                      context: context,
                                    );
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
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
                        _buildContactButton(
                          icon: Icons.map_rounded,
                          label: 'Ubicación',
                          color: Colors.blue,
                          onTap:
                              (credit.client?.latitud != null &&
                                  credit.client?.longitud != null)
                              ? () {
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
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueBlue,
                                    ),
                                  );
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => LocationPickerScreen(
                                        allowSelection: false,
                                        extraMarkers: {clienteMarker},
                                        customTitle:
                                            'Ubicación de ${credit.client!.nombre}',
                                      ),
                                    ),
                                  );
                                }
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
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
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernClientCard(Credito credit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    Theme.of(context).colorScheme.surface,
                  ]
                : [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.2),
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header con perfil e info básica
            Row(
              children: [
                // Foto con glow effect
                GestureDetector(
                  onTap: credit.client != null
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  ClientePerfilScreen(cliente: credit.client!),
                            ),
                          );
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ProfileImageWidget(
                      profileImage: credit.client?.profileImage,
                      size: 64,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Info del cliente
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              credit.client?.nombre ??
                                  'Cliente #${credit.clientId}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (credit.client?.clientCategory != null)
                            ClientCategoryChip(
                              category: credit.client!.clientCategory,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ID: ${credit.clientId}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (credit.client != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Info adicional
              Row(
                children: [
                  Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      credit.client!.telefono.isNotEmpty
                          ? credit.client!.telefono
                          : 'Sin teléfono',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.badge_rounded,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      credit.client?.ci ?? 'Sin CI',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Botones de acción con gradientes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildContactButton(
                    icon: Icons.phone_rounded,
                    label: 'Llamar',
                    color: Colors.green,
                    onTap: (credit.client!.telefono.isNotEmpty)
                        ? () async {
                            try {
                              await ContactActionsWidget.makePhoneCall(
                                credit.client!.telefono,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                  _buildContactButton(
                    icon: Icons.message_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: (credit.client!.telefono.isNotEmpty)
                        ? () async {
                            try {
                              await ContactActionsWidget.openWhatsApp(
                                credit.client!.telefono,
                                message:
                                    'Hola ${credit.client!.nombre}, me comunico desde la aplicación.',
                                context: context,
                              );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
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
                  _buildContactButton(
                    icon: Icons.map_rounded,
                    label: 'Ubicación',
                    color: Colors.blue,
                    onTap:
                        (credit.client?.latitud != null &&
                            credit.client?.longitud != null)
                        ? () {
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
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueBlue,
                              ),
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LocationPickerScreen(
                                  allowSelection: false,
                                  extraMarkers: {clienteMarker},
                                  customTitle:
                                      'Ubicación de ${credit.client!.nombre}',
                                ),
                              ),
                            );
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
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

            // Estado de carga o botón para recargar
            if (_isLoadingDetails) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Cargando datos del cliente...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            if (credit.client == null && !_isLoadingDetails) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _loadCreditDetails,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Recargar datos del cliente'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: onTap != null ? 0.2 : 0.1),
                    color.withValues(alpha: onTap != null ? 0.1 : 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: color.withValues(alpha: onTap != null ? 0.4 : 0.2),
                  width: 1.5,
                ),
                boxShadow: onTap != null
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: onTap != null ? color : color.withValues(alpha: 0.5),
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onTap != null
                          ? color
                          : color.withValues(alpha: 0.5),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernActionButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: tooltip,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.15),
                color.withValues(alpha: 0.08),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(icon, color: color, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(Credito credit) {
    Color color;
    IconData icon;
    switch (credit.status) {
      case 'active':
        color = Colors.green;
        icon = Icons.check_circle_rounded;
        break;
      case 'pending_approval':
        color = Colors.orange;
        icon = Icons.hourglass_empty_rounded;
        break;
      case 'waiting_delivery':
        color = Colors.blue;
        icon = Icons.schedule_rounded;
        break;
      case 'completed':
        color = Colors.teal;
        icon = Icons.verified_rounded;
        break;
      case 'defaulted':
        color = Colors.red;
        icon = Icons.warning_rounded;
        break;
      case 'cancelled':
        color = Colors.grey.shade600;
        icon = Icons.cancel_rounded;
        break;
      default:
        color = Colors.grey;
        icon = Icons.info_outline_rounded;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              credit.statusLabel,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Pagado
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.payments, size: 20, color: Colors.green),
              const SizedBox(height: 4),
              Text(
                'Pagado',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatCurrency(paid),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        // Saldo
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet, size: 20, color: Colors.orange),
              const SizedBox(height: 4),
              Text(
                'Saldo',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatCurrency(credit.balance),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
        // Mora o Al Día
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                overdue ? Icons.warning : Icons.trending_up,
                size: 20,
                color: overdue ? Colors.red : Colors.blue,
              ),
              const SizedBox(height: 4),
              Text(
                overdue ? 'En Mora' : 'Al Día',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                overdue
                    ? _formatCurrency(overdueAmount)
                    : '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                ]
              : [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
              fontSize: 14,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEssentialInfoGrid(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _buildInfoGridItem(
          'Total a Pagar',
          _formatCurrency(summary['total_amount']),
          Icons.attach_money,
          Colors.blue,
        ),
        _buildInfoGridItem(
          'Cuota',
          _formatCurrency(summary['installment_amount']),
          Icons.calendar_today,
          Colors.orange,
        ),
        _buildInfoGridItem(
          'N° Cuotas',
          (summary['total_installments'] ?? '').toString(),
          Icons.format_list_numbered,
          Colors.purple,
        ),
        _buildInfoGridItem(
          'Pagadas',
          (summary['completed_installments_count'] ?? '').toString(),
          Icons.check_circle,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsGrid(Map<String, dynamic> summary) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.0,
      children: [
        _buildInfoGridItem(
          'Monto Préstamo',
          _formatCurrency(summary['original_amount']),
          Icons.account_balance_wallet,
          Colors.teal,
        ),
        _buildInfoGridItem(
          'Interés',
          '${(summary['interest_rate'] ?? 0).toString()}%',
          Icons.percent,
          Colors.indigo,
        ),
        _buildInfoGridItem(
          'Pendientes',
          (summary['pending_installments'] ?? '').toString(),
          Icons.pending_actions,
          Colors.amber,
        ),
      ],
    );
  }

  Widget _buildInfoGridItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                ]
              : [
                  scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
              fontSize: 15,
              letterSpacing: -0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Payments are displayed in calendar/list views elsewhere; the tabbed payments UI was removed.

  // Payment summary widgets are rendered in calendar/list views; helper removed.

  Widget _buildDateInfo(String label, DateTime date) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          flex: 2,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          flex: 2,
          child: Text(
            DateFormat('dd/MM/yyyy').format(date),
            style: const TextStyle(fontSize: 13),
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
