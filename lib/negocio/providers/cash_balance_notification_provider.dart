import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../datos/api_services/websocket_service.dart';
import '../../datos/modelos/cash_balance_notification.dart';

/// Estado de las notificaciones de cajas
class CashBalanceNotificationState {
  final List<CashBalanceNotification> notifications;
  final int reconciliationCount;
  final CashBalanceNotification? lastNotification;
  final bool hasUnreviewedAutoClosed;

  const CashBalanceNotificationState({
    this.notifications = const [],
    this.reconciliationCount = 0,
    this.lastNotification,
    this.hasUnreviewedAutoClosed = false,
  });

  CashBalanceNotificationState copyWith({
    List<CashBalanceNotification>? notifications,
    int? reconciliationCount,
    CashBalanceNotification? lastNotification,
    bool? hasUnreviewedAutoClosed,
    bool clearLastNotification = false,
  }) {
    return CashBalanceNotificationState(
      notifications: notifications ?? this.notifications,
      reconciliationCount: reconciliationCount ?? this.reconciliationCount,
      lastNotification: clearLastNotification ? null : (lastNotification ?? this.lastNotification),
      hasUnreviewedAutoClosed: hasUnreviewedAutoClosed ?? this.hasUnreviewedAutoClosed,
    );
  }

  // Estadísticas computadas
  int get totalNotifications => notifications.length;
  int get autoClosedCount => notifications.where((n) => n.action == 'auto_closed').length;
  int get autoCreatedCount => notifications.where((n) => n.action == 'auto_created').length;
}

/// Provider para gestionar notificaciones WebSocket de cajas
/// Escucha eventos en tiempo real de operaciones de caja
class CashBalanceNotificationNotifier extends StateNotifier<CashBalanceNotificationState> {
  final WebSocketService _wsService = WebSocketService();
  StreamSubscription? _cashBalanceSubscription;

  CashBalanceNotificationNotifier() : super(const CashBalanceNotificationState()) {
    _listenToCashBalanceEvents();
  }

  /// Escuchar eventos de cajas desde WebSocket
  void _listenToCashBalanceEvents() {
    _cashBalanceSubscription = _wsService.cashBalanceStream.listen(
      (data) {
        if (kDebugMode) {
          print('📦 [CashBalanceNotificationProvider] Event received: ${data['type']}');
        }

        try {
          final notification = CashBalanceNotification.fromJson(data);
          _addNotification(notification);
        } catch (e) {
          if (kDebugMode) {
            print('❌ Error parsing cash balance notification: $e');
          }
        }
      },
      onError: (error) {
        if (kDebugMode) {
          print('❌ Error in cash balance stream: $error');
        }
      },
    );
  }

  /// Agregar nueva notificación y actualizar contadores
  void _addNotification(CashBalanceNotification notification) {
    final newNotifications = [notification, ...state.notifications];

    // Calcular nuevo contador de conciliación
    int newReconciliationCount = state.reconciliationCount;
    if (notification.requiresReconciliation || notification.action == 'requires_reconciliation') {
      newReconciliationCount++;
    }

    // Actualizar flag de auto-cerradas sin revisar
    bool newHasUnreviewed = state.hasUnreviewedAutoClosed;
    if (notification.action == 'auto_closed') {
      newHasUnreviewed = true;
    }

    // Mantener solo las últimas 50 notificaciones en memoria
    if (newNotifications.length > 50) {
      newNotifications.removeRange(50, newNotifications.length);
    }

    state = state.copyWith(
      notifications: newNotifications,
      reconciliationCount: newReconciliationCount,
      lastNotification: notification,
      hasUnreviewedAutoClosed: newHasUnreviewed,
    );

    if (kDebugMode) {
      print('📦 Notification added: ${notification.actionText}');
      print('   Total notifications: ${newNotifications.length}');
      print('   Reconciliation count: $newReconciliationCount');
    }
  }

  /// Marcar caja como conciliada
  void markAsReconciled(int cashBalanceId) {
    final newNotifications = state.notifications
        .where((n) => n.cashBalance.id != cashBalanceId)
        .toList();

    final newReconciliationCount = state.reconciliationCount > 0
        ? state.reconciliationCount - 1
        : 0;

    state = state.copyWith(
      notifications: newNotifications,
      reconciliationCount: newReconciliationCount,
    );

    if (kDebugMode) {
      print('✅ Cash balance $cashBalanceId marked as reconciled');
    }
  }

  /// Marcar caja auto-cerrada como revisada
  void markAutoClosedAsReviewed(int cashBalanceId) {
    final notification = state.notifications
        .where((n) => n.cashBalance.id == cashBalanceId)
        .firstOrNull;

    if (notification != null && notification.action == 'auto_closed') {
      final newNotifications = state.notifications
          .where((n) => n.cashBalance.id != cashBalanceId)
          .toList();

      // Si no hay más auto-cerradas, actualizar flag
      final hasMoreAutoClosed = newNotifications.any((n) => n.action == 'auto_closed');

      state = state.copyWith(
        notifications: newNotifications,
        hasUnreviewedAutoClosed: hasMoreAutoClosed,
      );

      if (kDebugMode) {
        print('✅ Auto-closed cash balance $cashBalanceId marked as reviewed');
      }
    }
  }

  /// Obtener notificaciones por tipo
  List<CashBalanceNotification> getNotificationsByAction(String action) {
    return state.notifications.where((n) => n.action == action).toList();
  }

  /// Obtener notificaciones que requieren conciliación
  List<CashBalanceNotification> getReconciliationNotifications() {
    return state.notifications
        .where((n) => n.requiresReconciliation || n.action == 'requires_reconciliation')
        .toList();
  }

  /// Obtener notificaciones de cajas auto-cerradas
  List<CashBalanceNotification> getAutoClosedNotifications() {
    return state.notifications.where((n) => n.action == 'auto_closed').toList();
  }

  /// Obtener notificaciones de cajas auto-creadas
  List<CashBalanceNotification> getAutoCreatedNotifications() {
    return state.notifications.where((n) => n.action == 'auto_created').toList();
  }

  /// Limpiar todas las notificaciones
  void clearAllNotifications() {
    state = const CashBalanceNotificationState();

    if (kDebugMode) {
      print('🗑️ All cash balance notifications cleared');
    }
  }

  /// Limpiar notificaciones por acción
  void clearNotificationsByAction(String action) {
    final newNotifications = state.notifications
        .where((n) => n.action != action)
        .toList();

    // Recalcular contadores
    final newReconciliationCount = newNotifications
        .where((n) => n.requiresReconciliation || n.action == 'requires_reconciliation')
        .length;

    final newHasUnreviewed = newNotifications.any((n) => n.action == 'auto_closed');

    state = state.copyWith(
      notifications: newNotifications,
      reconciliationCount: newReconciliationCount,
      hasUnreviewedAutoClosed: newHasUnreviewed,
    );

    if (kDebugMode) {
      print('🗑️ Cleared notifications for action: $action');
    }
  }

  /// Eliminar notificación específica
  void removeNotification(CashBalanceNotification notification) {
    final newNotifications = state.notifications
        .where((n) => n != notification)
        .toList();

    // Recalcular contadores
    int newReconciliationCount = state.reconciliationCount;
    if (notification.requiresReconciliation || notification.action == 'requires_reconciliation') {
      if (newReconciliationCount > 0) {
        newReconciliationCount--;
      }
    }

    bool newHasUnreviewed = state.hasUnreviewedAutoClosed;
    if (notification.action == 'auto_closed') {
      newHasUnreviewed = newNotifications.any((n) => n.action == 'auto_closed');
    }

    state = state.copyWith(
      notifications: newNotifications,
      reconciliationCount: newReconciliationCount,
      hasUnreviewedAutoClosed: newHasUnreviewed,
    );

    if (kDebugMode) {
      print('🗑️ Notification removed: ${notification.cashBalance.id}');
    }
  }

  @override
  void dispose() {
    _cashBalanceSubscription?.cancel();

    if (kDebugMode) {
      print('🧹 CashBalanceNotificationNotifier disposed');
    }

    super.dispose();
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider principal para notificaciones de cajas
final cashBalanceNotificationProvider =
    StateNotifierProvider<CashBalanceNotificationNotifier, CashBalanceNotificationState>((ref) {
  return CashBalanceNotificationNotifier();
});

/// Provider derivado: Lista de notificaciones
final cashBalanceNotificationsListProvider = Provider<List<CashBalanceNotification>>((ref) {
  return ref.watch(cashBalanceNotificationProvider).notifications;
});

/// Provider derivado: Contador de cajas que requieren conciliación
final cashBalanceReconciliationCountProvider = Provider<int>((ref) {
  return ref.watch(cashBalanceNotificationProvider).reconciliationCount;
});

/// Provider derivado: Última notificación recibida
final lastCashBalanceNotificationProvider = Provider<CashBalanceNotification?>((ref) {
  return ref.watch(cashBalanceNotificationProvider).lastNotification;
});

/// Provider derivado: Flag de cajas auto-cerradas sin revisar
final hasUnreviewedAutoClosedProvider = Provider<bool>((ref) {
  return ref.watch(cashBalanceNotificationProvider).hasUnreviewedAutoClosed;
});

/// Provider derivado: Total de notificaciones
final totalCashBalanceNotificationsProvider = Provider<int>((ref) {
  return ref.watch(cashBalanceNotificationProvider).totalNotifications;
});

/// Provider derivado: Contador de auto-cerradas
final autoClosedCountProvider = Provider<int>((ref) {
  return ref.watch(cashBalanceNotificationProvider).autoClosedCount;
});

/// Provider derivado: Contador de auto-creadas
final autoCreatedCountProvider = Provider<int>((ref) {
  return ref.watch(cashBalanceNotificationProvider).autoCreatedCount;
});
