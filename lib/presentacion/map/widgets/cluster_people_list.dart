import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../datos/modelos/map/location_cluster.dart';
import '../../../datos/modelos/credito.dart';
import '../../widgets/payment_dialog.dart';
import '../../../negocio/providers/credit_provider.dart';
import '../utils/client_data_extractor.dart';
import '../utils/translations.dart';

/// Widget que muestra el listado de personas en un cluster
/// Permite seleccionar a una persona para ver sus detalles y hacer pagos
class ClusterPeopleList extends ConsumerStatefulWidget {
  final LocationCluster cluster;
  final ValueChanged<ClusterPerson> onPersonSelected;

  const ClusterPeopleList({
    super.key,
    required this.cluster,
    required this.onPersonSelected,
  });

  @override
  ConsumerState<ClusterPeopleList> createState() => _ClusterPeopleListState();
}

class _ClusterPeopleListState extends ConsumerState<ClusterPeopleList> {
  // Tracking de créditos expandidos por persona
  final Map<int, bool> _expandedCredits = {};
  final Map<int, bool> _expandedPerson = {};

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator
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
              Text(
                'Ubicación',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                widget.cluster.location.address,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${widget.cluster.people.length} ${widget.cluster.people.length == 1 ? 'persona' : 'personas'} en esta ubicación',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Monto total: ${ClientDataExtractor.formatSoles(widget.cluster.clusterSummary.totalBalance)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Lista de personas
        Expanded(
          child: ListView.separated(
            itemCount: widget.cluster.people.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final person = widget.cluster.people[index];
              return _buildPersonCard(context, person);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPersonCard(BuildContext context, ClusterPerson person) {
    final paidToday = ClientDataExtractor.extractPaidToday(person);
    final (statusIcon, statusColor) =
        ClientDataExtractor.getStatusIconAndColor(person.personStatus);
    final isExpanded = _expandedPerson[person.personId] ?? false;

    return Column(
      children: [
        // Card principal de la persona
        InkWell(
          onTap: () {
            setState(() {
              _expandedPerson[person.personId] =
                  !_expandedPerson[person.personId]!;
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar con icono de estado
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.2),
                    border: Border.all(color: statusColor, width: 2),
                  ),
                  child: Center(
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                // Información de la persona
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre
                      Text(
                        person.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Teléfono
                      if (person.phone.isNotEmpty)
                        Row(
                          children: [
                            Icon(Icons.phone,
                                size: 12, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text(
                              person.phone,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      // Balance y créditos
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet,
                              size: 12, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${person.totalCredits} crédito${person.totalCredits != 1 ? 's' : ''} • ${ClientDataExtractor.formatSoles(person.totalBalance)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Badges de estado
                      Wrap(
                        spacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              MapTranslations.getPersonStatusLabel(person.personStatus),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          if (paidToday != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: paidToday ? Colors.green : Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                paidToday ? '✓ PAGÓ' : '✗ NO PAGÓ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Icono de expandir/contraer
                Icon(
                  isExpanded
                      ? Icons.expand_less
                      : Icons.expand_more,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
        // Créditos expandibles
        if (isExpanded && person.credits.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Text(
                  'Créditos (${person.credits.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...person.credits.map(
                  (credit) => _buildCreditCard(context, person, credit),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCreditCard(
    BuildContext context,
    ClusterPerson person,
    ClusterCredit credit,
  ) {
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
                      'Balance: ${ClientDataExtractor.formatSoles(credit.balance)}',
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
          if (credit.nextPaymentDue != null) ...[
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
          ],
          // Botón de pago
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showPaymentDialog(context, person, credit),
              icon: const Icon(Icons.payment, size: 18),
              label: const Text('Registrar Pago'),
            ),
          ),
        ],
      ),
    );
  }

  /// Convierte un ClusterCredit a un Credito para usar con PaymentDialog
  Credito _clusterCreditToCredito(
    ClusterCredit clusterCredit,
    ClusterPerson person,
  ) {
    return Credito(
      id: clusterCredit.creditId,
      clientId: person.personId,
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
    ClusterPerson person,
    ClusterCredit credit,
  ) async {
    // Convertir ClusterCredit a Credito
    final creditoObj = _clusterCreditToCredito(credit, person);

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
              'Pago registrado para ${person.name}',
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
