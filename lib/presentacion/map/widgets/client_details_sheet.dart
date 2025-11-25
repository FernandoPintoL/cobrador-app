import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../../datos/modelos/map/location_cluster.dart';
import '../../../datos/modelos/credito.dart';
import '../../widgets/payment_dialog.dart';
import '../../../negocio/providers/credit_provider.dart';
import '../utils/client_data_extractor.dart';
import '../utils/translations.dart';

/// Widget modal que muestra los detalles completos de un cliente
class ClientDetailsSheet extends ConsumerStatefulWidget {
  final ClusterPerson person;
  final ScrollController scrollController;
  final double? latitude;
  final double? longitude;

  const ClientDetailsSheet({
    super.key,
    required this.person,
    required this.scrollController,
    this.latitude,
    this.longitude,
  });

  @override
  ConsumerState<ClientDetailsSheet> createState() => _ClientDetailsSheetState();
}

class _ClientDetailsSheetState extends ConsumerState<ClientDetailsSheet> {
  /// Calcula la distancia desde la ubicación actual del usuario
  Future<String?> _calculateDistanceFromUser() async {
    if (widget.latitude == null || widget.longitude == null) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        widget.latitude!,
        widget.longitude!,
      );

      if (distanceInMeters < 1000) {
        return '${distanceInMeters.round()}m';
      } else {
        return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.person.personStatus;
    final (statusIcon, statusColor) =
        ClientDataExtractor.getStatusIconAndColor(status);

    return SingleChildScrollView(
      controller: widget.scrollController,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎯 Handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 🎨 Header con gradiente
          _buildHeader(context, status, statusIcon, statusColor),

          /*const SizedBox(height: 16),

          // 💰 Balance destacado
          _buildBalanceCard(),*/

          const SizedBox(height: 16),

          // 📊 Estadísticas
          _buildStatsSection(context),

          const SizedBox(height: 16),

          // 💳 Créditos
          if (widget.person.credits.isNotEmpty) ...[
            _buildCreditsSection(context),
            const SizedBox(height: 12),
          ],

          // 💸 Pagos recientes
          if (widget.person.paymentStats.totalPayments > 0) ...[
            _buildRecentPaymentsSection(context),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String status, IconData icon,
      Color color) {
    final paidToday = ClientDataExtractor.extractPaidToday(widget.person);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.person.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            MapTranslations.getPersonStatusLabel(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        if (paidToday != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: paidToday ? Colors.green : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              paidToday ? '✓ PAGÓ HOY' : '✗ NO PAGÓ HOY',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.person.address.isNotEmpty || widget.person.phone.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
          ],
          if (widget.person.address.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.person.address,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (widget.latitude != null && widget.longitude != null)
                        FutureBuilder<String?>(
                          future: _calculateDistanceFromUser(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              return Text(
                                '📍 A ${snapshot.data}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          if (widget.person.phone.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.person.phone,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ],
          // Botón "Cómo llegar"
          if (widget.latitude != null && widget.longitude != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openNavigation(context),
                icon: const Icon(Icons.directions, size: 20),
                label: const Text('Cómo llegar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Abre la navegación en Google Maps o Waze
  Future<void> _openNavigation(BuildContext context) async {
    if (widget.latitude == null || widget.longitude == null) return;

    final lat = widget.latitude!;
    final lng = widget.longitude!;
    final address = Uri.encodeComponent(widget.person.address);

    // Intentar abrir en Google Maps primero
    final googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng');
    final googleMapsWebUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$address');

    // Intentar Waze como alternativa
    final wazeUrl = Uri.parse('waze://?ll=$lat,$lng&navigate=yes');

    // Mostrar diálogo de selección
    if (!context.mounted) return;

    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Navegar con'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('Google Maps'),
              onTap: () => Navigator.pop(ctx, 'google'),
            ),
            ListTile(
              leading: const Icon(Icons.navigation, color: Colors.cyan),
              title: const Text('Waze'),
              onTap: () => Navigator.pop(ctx, 'waze'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    try {
      if (choice == 'google') {
        // Intentar abrir app de Google Maps
        if (await canLaunchUrl(googleMapsUrl)) {
          await launchUrl(googleMapsUrl);
        } else {
          // Si no tiene la app, abrir en navegador
          await launchUrl(googleMapsWebUrl, mode: LaunchMode.externalApplication);
        }
      } else if (choice == 'waze') {
        if (await canLaunchUrl(wazeUrl)) {
          await launchUrl(wazeUrl);
        } else {
          // Waze no instalado, mostrar mensaje
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waze no está instalado'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir navegación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.purple.shade400,
            Colors.deepPurple.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'BALANCE TOTAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ClientDataExtractor.formatSoles(widget.person.totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _modernBadge(
            'Créditos activos',
            widget.person.totalCredits.toString(),
            Icons.account_balance_wallet,
            Colors.blue,
          ),
          _modernBadge(
            'Total pagado',
            ClientDataExtractor.formatSoles(widget.person.totalPaid),
            Icons.check_circle,
            Colors.green,
          ),
          _modernBadge(
            'Pagos registrados',
            widget.person.paymentStats.totalPayments.toString(),
            Icons.history,
            Colors.orange,
          ),
          _modernBadge(
            'Categoría',
            widget.person.clientCategory,
            Icons.category,
            Colors.teal,
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.credit_card,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Créditos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...widget.person.credits.map((cr) => _buildCreditCard(context, cr)),
      ],
    );
  }

  Widget _buildCreditCard(BuildContext context, ClusterCredit credit) {
    final statusColor = credit.status.toLowerCase() == 'active'
        ? Colors.blue.shade600
        : credit.status.toLowerCase() == 'completed'
            ? Colors.green.shade600
            : Colors.orange.shade600;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crédito #${credit.creditId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monto: ${ClientDataExtractor.formatSoles(credit.amount)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Saldo: ${ClientDataExtractor.formatSoles(credit.balance)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  MapTranslations.getCreditStatusLabel(credit.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (credit.nextPaymentDue != null) ...{
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Próximo pago: ${credit.nextPaymentDue!.date} (Cuota #${credit.nextPaymentDue!.installment})',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.money, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Monto: ${ClientDataExtractor.formatSoles(credit.nextPaymentDue!.amount)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          },
          // Botón de pago
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showPaymentDialog(context, credit),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Registrar Pago'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPaymentsSection(BuildContext context) {
    final recentPayments = widget.person.credits
        .expand((c) => c.recentPayments)
        .toList()
        .take(3)
        .toList();

    if (recentPayments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Últimos pagos',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...recentPayments.map((p) => _buildPaymentCard(context, p)),
      ],
    );
  }

  Widget _buildPaymentCard(BuildContext context, PaymentRecord payment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.payments_outlined,
            color: Colors.green.shade700,
          ),
        ),
        title: Text(
          '${ClientDataExtractor.formatSoles(payment.amount)} • Completado',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${payment.method} • ${payment.date}',
        ),
      ),
    );
  }

  Widget _modernBadge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
              ),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Convierte un ClusterCredit a un Credito para usar con PaymentDialog
  Credito _clusterCreditToCredito(ClusterCredit clusterCredit) {
    return Credito(
      id: clusterCredit.creditId,
      clientId: widget.person.personId,
      amount: clusterCredit.amount,
      balance: clusterCredit.balance,
      installmentAmount: clusterCredit.nextPaymentDue?.amount,
      frequency: 'monthly', // Default
      status: clusterCredit.status,
      startDate: DateTime.tryParse(clusterCredit.startDate) ?? DateTime.now(),
      endDate: DateTime.tryParse(clusterCredit.endDate) ?? DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      totalPaid: clusterCredit.paidAmount,
      backendTotalInstallments: clusterCredit.nextPaymentDue?.installment,
    );
  }

  /// Muestra el diálogo de pago
  Future<void> _showPaymentDialog(
    BuildContext context,
    ClusterCredit credit,
  ) async {
    // Convertir ClusterCredit a Credito
    final creditoObj = _clusterCreditToCredito(credit);

    // Preparar credit summary
    final creditSummary = <String, dynamic>{
      'total_installments': credit.nextPaymentDue?.installment ?? 1,
      'pending_installments': 1,
      'next_payment_due': credit.nextPaymentDue?.amount ?? credit.balance,
    };

    // Mostrar PaymentDialog
    final result = await PaymentDialog.show(
      context,
      ref,
      creditoObj,
      creditSummary: creditSummary,
    );

    // Procesar resultado
    if (result != null && result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pago registrado para ${widget.person.name}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        // Recargar créditos
        ref.invalidate(creditProvider);
      }
    } else if (result != null && result['success'] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${result['message'] ?? 'Error al registrar pago'}',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
