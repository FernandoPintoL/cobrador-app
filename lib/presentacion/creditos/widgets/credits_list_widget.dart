import 'package:flutter/material.dart';
import '../../../datos/modelos/credito.dart';
import 'credit_card/credit_card_widget.dart';

/// Widget que muestra una lista de créditos con paginación infinita
class CreditsListWidget extends StatelessWidget {
  final List<Credito> credits;
  final String listType;
  final Set<String> clientCategoryFilters;
  final bool canApprove;
  final bool canDeliver;
  final bool enablePayment;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onLoadMore;
  final void Function(Credito credit)? onCardTap;
  final void Function(Credito credit)? onApprove;
  final void Function(Credito credit)? onReject;
  final void Function(Credito credit)? onDeliver;
  final void Function(Credito credit)? onPayment;
  final void Function(Credito credit)? onCancel;

  const CreditsListWidget({
    super.key,
    required this.credits,
    required this.listType,
    this.clientCategoryFilters = const {},
    this.canApprove = false,
    this.canDeliver = false,
    this.enablePayment = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.onLoadMore,
    this.onCardTap,
    this.onApprove,
    this.onReject,
    this.onDeliver,
    this.onPayment,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    print(
      '📱 CreditsListWidget.build - tipo: $listType, créditos recibidos: ${credits.length}',
    );

    // Aplicar filtro por categorías de cliente (solo en UI)
    List<Credito> filtered = credits;
    if (clientCategoryFilters.isNotEmpty) {
      filtered = credits.where((c) {
        final cat = c.client?.clientCategory;
        return cat != null && clientCategoryFilters.contains(cat);
      }).toList();
      print(
        '📱 CreditsListWidget - Aplicado filtro por categorías: ${clientCategoryFilters.join(", ")}. Resultado: ${filtered.length} créditos',
      );
    }

    // Debug: Mostrar lista de IDs para verificar
    if (credits.isNotEmpty) {
      print(
        '📱 CreditsListWidget - Primer crédito: ID=${credits.first.id}, Monto=${credits.first.amount}, Cliente=${credits.first.client?.nombre ?? "Sin cliente"}',
      );
      if (credits.length > 1) {
        print(
          '📱 CreditsListWidget - Último crédito: ID=${credits.last.id}, Monto=${credits.last.amount}, Cliente=${credits.last.client?.nombre ?? "Sin cliente"}',
        );
      }
    } else {
      print('📱 CreditsListWidget - No hay créditos para mostrar');
    }

    // Mostrar estado vacío si no hay créditos
    if (filtered.isEmpty) {
      print(
        '📱 CreditsListWidget - Mostrando estado vacío para tipo: $listType',
      );
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyStateIcon(listType),
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(listType),
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Lista de créditos con scroll infinito
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          // Cerca del final, intentar cargar más
          if (hasMore && !isLoadingMore && onLoadMore != null) {
            onLoadMore!();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filtered.length + 1,
        itemBuilder: (context, index) {
          if (index < filtered.length) {
            final credit = filtered[index];
            return CreditCardWidget(
              credit: credit,
              listType: listType,
              canApprove: canApprove,
              canDeliver: canDeliver,
              onTap: onCardTap != null ? () => onCardTap!(credit) : null,
              onApprove: onApprove != null ? () => onApprove!(credit) : null,
              onReject: onReject != null ? () => onReject!(credit) : null,
              onDeliver: onDeliver != null ? () => onDeliver!(credit) : null,
              onPayment: onPayment != null ? () => onPayment!(credit) : null,
              onCancel: onCancel != null ? () => onCancel!(credit) : null,
            );
          }

          // Footer de la lista (loading o fin de datos)
          if (isLoadingMore) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }

          if (currentPage >= totalPages) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No existen más datos',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Obtener el icono del estado vacío según el tipo de lista
  IconData _getEmptyStateIcon(String listType) {
    switch (listType) {
      case 'pending_approval':
        return Icons.inbox;
      case 'waiting_delivery':
        return Icons.schedule;
      case 'ready_for_delivery':
        return Icons.check_circle_outline;
      case 'overdue_delivery':
        return Icons.warning_amber;
      case 'active':
        return Icons.playlist_add_check_circle_outlined;
      case 'overdue_payments':
        return Icons.money_off;
      default:
        return Icons.folder_open;
    }
  }

  /// Obtener el mensaje del estado vacío según el tipo de lista
  String _getEmptyStateMessage(String listType) {
    switch (listType) {
      case 'pending_approval':
        return 'No hay créditos pendientes de aprobación';
      case 'waiting_delivery':
        return 'No hay créditos en lista de espera';
      case 'ready_for_delivery':
        return 'No hay créditos listos para entrega hoy';
      case 'overdue_delivery':
        return 'No hay créditos con entrega atrasada';
      case 'active':
        return 'No hay créditos activos';
      case 'overdue_payments':
        return 'No hay créditos con cuotas atrasadas';
      default:
        return 'No hay créditos';
    }
  }
}
