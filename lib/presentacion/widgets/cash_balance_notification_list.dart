import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../datos/modelos/cash_balance_notification.dart';
import '../../negocio/providers/cash_balance_notification_provider.dart';

/// Lista de notificaciones de cajas
/// Muestra todas las notificaciones recibidas via WebSocket
class CashBalanceNotificationList extends ConsumerWidget {
  const CashBalanceNotificationList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar lista de notificaciones
    final notifications = ref.watch(cashBalanceNotificationsListProvider);

    if (notifications.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_none,
                size: 64,
                color: Colors.grey,
              ),
              SizedBox(height: 16),
              Text(
                'No hay notificaciones de cajas',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Las notificaciones de cajas aparecerán aquí',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationCard(context, ref, notification);
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    CashBalanceNotification notification,
  ) {
    // Determinar ícono y color según el tipo de acción
    IconData icon;
    Color color;
    String subtitle;

    switch (notification.action) {
      case 'auto_closed':
        icon = Icons.lock_clock;
        color = Colors.blue;
        subtitle = 'Caja cerrada automáticamente a las 00:01';
        break;
      case 'auto_created':
        icon = Icons.add_circle_outline;
        color = Colors.green;
        subtitle = 'Caja virtual creada automáticamente';
        break;
      case 'requires_reconciliation':
        icon = Icons.warning_amber;
        color = Colors.orange;
        subtitle = 'Acción requerida: conciliar caja';
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
        subtitle = 'Notificación de caja';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // TODO: Navegar a detalle de caja
          _showNotificationDetails(context, notification);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícono
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),

              // Contenido
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título
                    Text(
                      notification.actionText,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Subtítulo
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Mensaje
                    Text(
                      notification.message,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),

                    // Información adicional
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _buildInfoChip(
                          Icons.calendar_today,
                          notification.cashBalance.formattedDate,
                        ),
                        _buildInfoChip(
                          Icons.attach_money,
                          '${notification.cashBalance.finalAmount.toStringAsFixed(2)} Bs',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Botón de acción
              const SizedBox(width: 8),
              _buildActionButton(context, ref, notification, color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    CashBalanceNotification notification,
    Color color,
  ) {
    if (notification.requiresReconciliation) {
      // Botón para conciliar
      return ElevatedButton(
        onPressed: () {
          _handleReconcileAction(context, ref, notification);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Conciliar',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Botón para descartar
    return IconButton(
      icon: const Icon(Icons.close, size: 20),
      color: Colors.grey,
      onPressed: () {
        _handleDismissAction(context, ref, notification);
      },
      tooltip: 'Descartar',
    );
  }

  void _handleReconcileAction(
    BuildContext context,
    WidgetRef ref,
    CashBalanceNotification notification,
  ) {
    // Marcar como conciliada
    ref
        .read(cashBalanceNotificationProvider.notifier)
        .markAsReconciled(notification.cashBalance.id);

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Caja ${notification.cashBalance.id} marcada como conciliada',
        ),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Ver Caja',
          onPressed: () {
            // TODO: Navegar a detalle de caja
          },
        ),
      ),
    );
  }

  void _handleDismissAction(
    BuildContext context,
    WidgetRef ref,
    CashBalanceNotification notification,
  ) {
    // Eliminar notificación
    ref
        .read(cashBalanceNotificationProvider.notifier)
        .removeNotification(notification);

    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación descartada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showNotificationDetails(
    BuildContext context,
    CashBalanceNotification notification,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              notification.action == 'auto_closed'
                  ? Icons.lock_clock
                  : notification.action == 'auto_created'
                      ? Icons.add_circle_outline
                      : Icons.warning_amber,
              color: notification.action == 'auto_closed'
                  ? Colors.blue
                  : notification.action == 'auto_created'
                      ? Colors.green
                      : Colors.orange,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                notification.actionText,
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('ID Caja', '${notification.cashBalance.id}'),
              _buildDetailRow('Fecha', notification.cashBalance.formattedDate),
              _buildDetailRow(
                'Saldo Final',
                '${notification.cashBalance.finalAmount.toStringAsFixed(2)} Bs',
              ),
              _buildDetailRow('Estado', notification.cashBalance.status),
              if (notification.reason != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('Motivo', notification.reason!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (notification.requiresReconciliation)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Navegar a pantalla de conciliación
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ir a Conciliar'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
