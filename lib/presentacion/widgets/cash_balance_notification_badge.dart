import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_notification_provider.dart';

/// Badge que muestra el número de cajas que requieren conciliación
/// Se muestra en el AppBar como indicador visual
class CashBalanceNotificationBadge extends ConsumerWidget {
  const CashBalanceNotificationBadge({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el contador de cajas que requieren conciliación
    final reconciliationCount = ref.watch(cashBalanceReconciliationCountProvider);

    // No mostrar nada si no hay notificaciones
    if (reconciliationCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$reconciliationCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge simple que solo muestra el número (sin ícono)
/// Útil para espacios más reducidos
class CashBalanceNotificationBadgeSimple extends ConsumerWidget {
  const CashBalanceNotificationBadgeSimple({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciliationCount = ref.watch(cashBalanceReconciliationCountProvider);

    if (reconciliationCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(6),
      decoration: const BoxDecoration(
        color: Colors.orange,
        shape: BoxShape.circle,
      ),
      child: Text(
        reconciliationCount > 99 ? '99+' : '$reconciliationCount',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Badge con múltiples contadores (conciliación + auto-cerradas)
/// Muestra información más detallada
class CashBalanceNotificationBadgeDetailed extends ConsumerWidget {
  const CashBalanceNotificationBadgeDetailed({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reconciliationCount = ref.watch(cashBalanceReconciliationCountProvider);
    final autoClosedCount = ref.watch(autoClosedCountProvider);

    final totalCount = reconciliationCount + autoClosedCount;

    if (totalCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: reconciliationCount > 0 ? Colors.orange : Colors.blue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          if (reconciliationCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '⚠️ $reconciliationCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
