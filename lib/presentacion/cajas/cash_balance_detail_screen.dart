import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import 'close_cash_balance_dialog.dart';

// Función auxiliar para traducir estados
String _translateStatus(String? status) {
  if (status == null) return '—';
  final lower = status.toLowerCase().trim();
  return switch (lower) {
    'open' => 'Abierta',
    'closed' => 'Cerrada',
    'reconciled' => 'Reconciliada',
    _ => status,
  };
}

class CashBalanceDetailScreen extends ConsumerStatefulWidget {
  final int id;
  const CashBalanceDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CashBalanceDetailScreen> createState() =>
      _CashBalanceDetailScreenState();
}

class _CashBalanceDetailScreenState
    extends ConsumerState<CashBalanceDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cashBalanceProvider.notifier).getDetail(widget.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashBalanceProvider);
    final auth = ref.watch(authProvider);
    final detail = state.currentDetail;
    // determinar si mostrar botón de cerrar
    final canClose = (() {
      final status = detail?['cash_balance']?['status'] as String? ?? '';
      if (status.toLowerCase() == 'closed') return false;
      if (auth.isAdmin || auth.isManager) return true;
      if (auth.isCobrador) {
        final ownerId = detail?['cash_balance']?['cobrador_id'];
        if (ownerId != null && auth.usuario != null) {
          return ownerId.toString() == auth.usuario!.id.toString();
        }
      }
      return false;
    })();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Caja'),
        actions: [
          if (canClose)
            IconButton(
              tooltip: 'Cerrar caja',
              icon: const Icon(Icons.lock_open),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (_) =>
                      CloseCashBalanceDialog(cashBalanceId: widget.id),
                );
                if (result == true) {
                  // ya se refrescó en el diálogo, simplemente reconstruir
                  if (!mounted) return;
                }
              },
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : detail == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay detalle',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card de información general
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Información de Caja',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      detail['cash_balance']?['cobrador_name'] ??
                                          detail['cash_balance']?['cobrador_id']
                                              ?.toString() ??
                                          '—',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            Icons.calendar_today,
                            'Fecha',
                            detail['cash_balance']?['date'] != null
                                ? (() {
                                    final dateStr =
                                        detail['cash_balance']?['date']
                                            ?.toString() ??
                                        '';
                                    final date = DateTime.tryParse(dateStr);
                                    if (date != null) {
                                      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                    }
                                    return dateStr.isNotEmpty ? dateStr : '—';
                                  })()
                                : '—',
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            context,
                            Icons.flag_outlined,
                            'Estado',
                            _translateStatus(detail['cash_balance']?['status']),
                            valueColor:
                                (detail['cash_balance']?['status']
                                        ?.toString()
                                        .toLowerCase() ==
                                    'open')
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.tertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Sección de Pagos
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pagos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (detail['payments'] is List &&
                      (detail['payments'] as List).isNotEmpty)
                    ...((detail['payments'] as List).map((p) {
                      final amount = p['amount'];
                      String amountStr;
                      if (amount is num) {
                        amountStr = amount.toStringAsFixed(2);
                      } else {
                        final parsed = double.tryParse(
                          amount?.toString() ?? '',
                        );
                        amountStr = parsed != null
                            ? parsed.toStringAsFixed(2)
                            : (amount?.toString() ?? '');
                      }
                      final clientName = (p['client'] is Map)
                          ? (p['client']['name']?.toString() ?? '')
                          : (p['client_name']?.toString() ?? '');
                      final creditInfo = (p['credit'] is Map)
                          ? '#${p['credit']['id']?.toString() ?? ''}'
                          : (p['credit_id'] != null
                                ? '#${p['credit_id']}'
                                : '');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.attach_money,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Bs $amountStr',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (clientName.isNotEmpty) Text(clientName),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  if (p['payment_method'] != null &&
                                      p['payment_method'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondaryContainer
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.payment,
                                            size: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSecondaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            p['payment_method'].toString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (p['payment_date'] != null &&
                                      p['payment_date'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiaryContainer
                                            .withOpacity(0.5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_today,
                                            size: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onTertiaryContainer,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (() {
                                              final dateStr = p['payment_date']
                                                  .toString();
                                              final date = DateTime.tryParse(
                                                dateStr,
                                              );
                                              if (date != null) {
                                                return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
                                              }
                                              return dateStr;
                                            })(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onTertiaryContainer,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              if (creditInfo.isNotEmpty)
                                Text(
                                  'Crédito $creditInfo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }))
                  else
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sin pagos registrados',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Sección de Créditos
                  Row(
                    children: [
                      Icon(
                        Icons.request_page_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Créditos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (detail['credits'] is List &&
                      (detail['credits'] as List).isNotEmpty)
                    ...((detail['credits'] as List).map((c) {
                      final amount = c['amount'];
                      String amountStr;
                      if (amount is num) {
                        amountStr = amount.toStringAsFixed(2);
                      } else {
                        final parsed = double.tryParse(
                          amount?.toString() ?? '',
                        );
                        amountStr = parsed != null
                            ? parsed.toStringAsFixed(2)
                            : (amount?.toString() ?? '');
                      }
                      final clientName = (c['client'] is Map)
                          ? (c['client']['name']?.toString() ?? '')
                          : (c['client_name']?.toString() ?? '');
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Theme.of(
                                context,
                              ).colorScheme.onTertiaryContainer,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Bs $amountStr',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (clientName.isNotEmpty) Text(clientName),
                              Text(
                                c['created_at'] != null
                                    ? DateTime.tryParse(c['created_at']) != null
                                          ? '${DateTime.parse(c['created_at']).day.toString().padLeft(2, '0')}/${DateTime.parse(c['created_at']).month.toString().padLeft(2, '0')}/${DateTime.parse(c['created_at']).year}'
                                          : c['created_at']
                                    : '',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      );
                    }))
                  else
                    Card(
                      elevation: 0,
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sin créditos registrados',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Sección de Conciliación
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_outlined,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Conciliación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (_) {
                      final rec = detail['reconciliation'] as Map?;
                      final expected = rec?['expected_final'];
                      final actual = rec?['actual_final'];
                      final diff = rec?['difference'];
                      final isBalanced = rec?['is_balanced'] == true;
                      String fmt(dynamic v) {
                        if (v == null) return '—';
                        if (v is num) return v.toStringAsFixed(2);
                        final parsed = double.tryParse(v.toString());
                        return parsed != null
                            ? parsed.toStringAsFixed(2)
                            : v.toString();
                      }

                      final expectedStr = fmt(expected);
                      final actualStr = fmt(actual);
                      final diffStr = fmt(diff);
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isBalanced
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                            width: 2,
                          ),
                        ),
                        color: isBalanced
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isBalanced
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isBalanced
                                              ? Icons.check_circle
                                              : Icons.warning,
                                          color: isBalanced
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isBalanced
                                              ? 'Cuadrado'
                                              : 'Con Diferencia',
                                          style: TextStyle(
                                            color: isBalanced
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              _buildReconciliationRow(
                                context,
                                'Esperado',
                                'Bs $expectedStr',
                                isBalanced
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(height: 12),
                              _buildReconciliationRow(
                                context,
                                'Final reportado',
                                'Bs $actualStr',
                                isBalanced
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                              ),
                              const SizedBox(height: 12),
                              _buildReconciliationRow(
                                context,
                                'Diferencia',
                                'Bs $diffStr',
                                isBalanced
                                    ? Colors.green.shade700
                                    : Colors.red.shade700,
                                isBold: true,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildReconciliationRow(
    BuildContext context,
    String label,
    String value,
    Color color, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: color,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
