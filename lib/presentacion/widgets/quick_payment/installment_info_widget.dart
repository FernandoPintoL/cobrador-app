import 'package:flutter/material.dart';
import '../../../datos/modelos/credito.dart';
import 'package:intl/intl.dart';

/// Widget que muestra información de cuotas: próxima cuota, vencimiento y estado
class InstallmentInfoWidget extends StatelessWidget {
  final Credito credit;

  const InstallmentInfoWidget({
    super.key,
    required this.credit,
  });

  @override
  Widget build(BuildContext context) {
    final totalInstallments = credit.backendTotalInstallments ?? credit.totalInstallments;
    final paidInstallments = credit.paidInstallmentsCount ?? credit.paidInstallments;
    final pendingInstallments = credit.backendPendingInstallments ?? credit.pendingInstallments;
    final nextInstallmentNumber = paidInstallments + 1;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Cuotas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Grid de información
            Row(
              children: [
                // Próxima cuota
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.payment,
                    label: 'Próxima Cuota',
                    value: nextInstallmentNumber <= totalInstallments
                        ? '#$nextInstallmentNumber'
                        : 'Completado',
                    subtitle: credit.installmentAmount != null
                        ? 'Bs ${credit.installmentAmount!.toStringAsFixed(2)}'
                        : null,
                    color: nextInstallmentNumber <= totalInstallments
                        ? Colors.blue
                        : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),

                // Cuotas pendientes
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.pending_actions,
                    label: 'Pendientes',
                    value: '$pendingInstallments',
                    subtitle: pendingInstallments == 1 ? 'cuota' : 'cuotas',
                    color: pendingInstallments > 3
                        ? Colors.red
                        : (pendingInstallments > 0 ? Colors.orange : Colors.green),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // Fecha de vencimiento
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.event,
                    label: 'Vencimiento',
                    value: DateFormat('dd/MM/yyyy').format(credit.endDate),
                    subtitle: _getDaysUntilDue(credit.endDate),
                    color: _getDueColor(credit.endDate),
                  ),
                ),
                const SizedBox(width: 12),

                // Frecuencia
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.schedule,
                    label: 'Frecuencia',
                    value: credit.frequencyLabel,
                    subtitle: 'de pago',
                    color: Colors.purple,
                  ),
                ),
              ],
            ),

            // Alerta de cuotas atrasadas
            if (credit.backendIsOverdue == true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Crédito con Cuotas Atrasadas',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          if (credit.overdueAmount != null)
                            Text(
                              'Monto en mora: Bs ${credit.overdueAmount!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: Colors.red[800],
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

            // Información adicional del crédito
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSmallInfo('Inicio', DateFormat('dd/MM/yy').format(credit.startDate)),
                  Container(width: 1, height: 30, color: Colors.grey[400]),
                  _buildSmallInfo('Tasa', '${credit.interestRate?.toStringAsFixed(0) ?? "0"}%'),
                  Container(width: 1, height: 30, color: Colors.grey[400]),
                  _buildSmallInfo('Total Cuotas', '$totalInstallments'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSmallInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _getDaysUntilDue(DateTime endDate) {
    final now = DateTime.now();
    final daysUntilDue = endDate.difference(now).inDays;

    if (daysUntilDue < 0) {
      final daysOverdue = -daysUntilDue;
      return daysOverdue == 1 ? 'Vencido 1 día' : 'Vencido $daysOverdue días';
    } else if (daysUntilDue == 0) {
      return 'Vence hoy';
    } else if (daysUntilDue == 1) {
      return 'Vence mañana';
    } else if (daysUntilDue <= 7) {
      return 'En $daysUntilDue días';
    } else {
      return 'En ${(daysUntilDue / 7).floor()} semanas';
    }
  }

  Color _getDueColor(DateTime endDate) {
    final daysUntilDue = endDate.difference(DateTime.now()).inDays;

    if (daysUntilDue < 0) {
      return Colors.red; // Vencido
    } else if (daysUntilDue <= 3) {
      return Colors.orange; // Próximo a vencer
    } else if (daysUntilDue <= 7) {
      return Colors.amber; // Advertencia
    } else {
      return Colors.green; // Tiempo suficiente
    }
  }
}
