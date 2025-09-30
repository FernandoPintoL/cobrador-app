import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import 'close_cash_balance_dialog.dart';

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
          ? const Center(child: Text('No hay detalle'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fecha: ${detail['cash_balance']?['date'] ?? ''}'),
                  Text(
                    'Cobrador: ${detail['cash_balance']?['cobrador_name'] ?? detail['cash_balance']?['cobrador_id'] ?? ''}',
                  ),
                  Text('Estado: ${detail['cash_balance']?['status'] ?? ''}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Pagos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (detail['payments'] is List && (detail['payments'] as List).isNotEmpty)
                    ...((detail['payments'] as List).map(
                      (p) {
                        final amount = p['amount'];
                        String amountStr;
                        if (amount is num) {
                          amountStr = amount.toStringAsFixed(2);
                        } else {
                          final parsed = double.tryParse(amount?.toString() ?? '');
                          amountStr = parsed != null ? parsed.toStringAsFixed(2) : (amount?.toString() ?? '');
                        }
                        final clientName = (p['client'] is Map)
                            ? (p['client']['name']?.toString() ?? '')
                            : (p['client_name']?.toString() ?? '');
                        final creditInfo = (p['credit'] is Map)
                            ? '#${p['credit']['id']?.toString() ?? ''}'
                            : (p['credit_id'] != null ? '#${p['credit_id']}' : '');
                        return ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text('Pago #${p['id']} — $amountStr ${clientName.isNotEmpty ? '• $clientName' : ''}'),
                          subtitle: Text(
                            '${p['payment_method'] ?? ''} - ${p['payment_date'] ?? ''} ${creditInfo.isNotEmpty ? '• Crédito $creditInfo' : ''}',
                          ),
                        );
                      },
                    ))
                  else
                    const Text('Sin pagos'),
                  const SizedBox(height: 12),
                  const Text(
                    'Créditos:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (detail['credits'] is List && (detail['credits'] as List).isNotEmpty)
                    ...((detail['credits'] as List).map(
                      (c) {
                        final amount = c['amount'];
                        String amountStr;
                        if (amount is num) {
                          amountStr = amount.toStringAsFixed(2);
                        } else {
                          final parsed = double.tryParse(amount?.toString() ?? '');
                          amountStr = parsed != null ? parsed.toStringAsFixed(2) : (amount?.toString() ?? '');
                        }
                        final clientName = (c['client'] is Map)
                            ? (c['client']['name']?.toString() ?? '')
                            : (c['client_name']?.toString() ?? '');
                        return ListTile(
                          leading: const Icon(Icons.request_page_outlined),
                          title: Text('Crédito #${c['id']} — $amountStr ${clientName.isNotEmpty ? '• $clientName' : ''}'),
                          subtitle: Text('${c['created_at'] ?? ''}'),
                        );
                      },
                    ))
                  else
                    const Text('Sin créditos'),
                  const SizedBox(height: 12),
                  const Text(
                    'Conciliación:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Builder(builder: (_) {
                    final rec = detail['reconciliation'] as Map?;
                    final expected = rec?['expected_final'];
                    final actual = rec?['actual_final'];
                    final diff = rec?['difference'];
                    final isBalanced = rec?['is_balanced'] == true;
                    String fmt(dynamic v) {
                      if (v == null) return '—';
                      if (v is num) return v.toStringAsFixed(2);
                      final parsed = double.tryParse(v.toString());
                      return parsed != null ? parsed.toStringAsFixed(2) : v.toString();
                    }
                    final expectedStr = fmt(expected);
                    final actualStr = fmt(actual);
                    final diffStr = fmt(diff);
                    return Card(
                      color: isBalanced ? Colors.green.shade50 : Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Esperado: $expectedStr'),
                                  Text('Final reportado: $actualStr'),
                                  Text('Diferencia: $diffStr'),
                                ],
                              ),
                            ),
                            Chip(
                              label: Text(isBalanced ? 'Cuadrado' : 'Diferencia'),
                              backgroundColor: isBalanced
                                  ? Colors.green.shade200
                                  : Colors.red.shade200,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
