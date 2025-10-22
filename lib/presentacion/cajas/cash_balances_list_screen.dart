import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../datos/modelos/usuario.dart';
import 'cash_balance_detail_screen.dart';
import 'open_cash_balance_dialog.dart';

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

class CashBalancesListScreen extends ConsumerStatefulWidget {
  const CashBalancesListScreen({super.key});

  @override
  ConsumerState<CashBalancesListScreen> createState() =>
      _CashBalancesListScreenState();
}

class _CashBalancesListScreenState
    extends ConsumerState<CashBalancesListScreen> {
  // Filtros y paginación
  String? _dateFrom;
  String? _dateTo;
  Usuario? _selectedCobrador;
  int _page = 1;
  final int _perPage = 15;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authProvider);
      if (auth.isAdmin || auth.isManager) {
        ref.read(cobradorAssignmentProvider.notifier).cargarCobradores();
        _page = 1;
        ref
            .read(cashBalanceProvider.notifier)
            .list(
              cobradorId: _selectedCobrador?.id.toInt(),
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              page: _page,
              perPage: _perPage,
            );
      } else if (auth.isCobrador) {
        _page = 1;
        final id = auth.usuario?.id.toInt();
        ref
            .read(cashBalanceProvider.notifier)
            .list(
              cobradorId: id,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              page: _page,
              perPage: _perPage,
            );
      } else {
        // Otros roles: carga básica
        ref
            .read(cashBalanceProvider.notifier)
            .list(page: _page, perPage: _perPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cashBalanceProvider);
    final auth = ref.watch(authProvider);
    final isCobrador = auth.usuario?.esCobrador() ?? false;
    final isAdminOrManager = auth.isAdmin || auth.isManager;
    final assignState = ref.watch(cobradorAssignmentProvider);

    Future<void> _pickDate({required bool from}) async {
      final now = DateTime.now();
      final initialDate = now;
      final firstDate = DateTime(now.year - 1);
      final lastDate = DateTime(now.year + 1);
      final picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
      );
      if (picked != null) {
        setState(() {
          final value = picked.toIso8601String().split('T').first;
          if (from) {
            _dateFrom = value;
          } else {
            _dateTo = value;
          }
        });
      }
    }

    void _buscar() {
      _page = 1;
      ref
          .read(cashBalanceProvider.notifier)
          .list(
            cobradorId: isCobrador
                ? auth.usuario?.id.toInt()
                : (isAdminOrManager ? _selectedCobrador?.id.toInt() : null),
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            page: _page,
            perPage: _perPage,
          );
    }

    void _limpiar() {
      setState(() {
        _dateFrom = null;
        _dateTo = null;
        if (isAdminOrManager) _selectedCobrador = null;
        _page = 1;
      });
      ref
          .read(cashBalanceProvider.notifier)
          .list(
            cobradorId: isCobrador ? auth.usuario?.id.toInt() : null,
            page: _page,
            perPage: _perPage,
          );
    }

    void _cambiarPagina(int nueva) {
      if (nueva < 1) return;
      if (nueva > state.lastPage) return;
      setState(() => _page = nueva);
      ref
          .read(cashBalanceProvider.notifier)
          .list(
            cobradorId: isCobrador
                ? auth.usuario?.id.toInt()
                : (isAdminOrManager ? _selectedCobrador?.id.toInt() : null),
            dateFrom: _dateFrom,
            dateTo: _dateTo,
            page: _page,
            perPage: _perPage,
          );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance de Cajas'),
        actions: [
          if (isCobrador || isAdminOrManager)
            IconButton(
              icon: const Icon(Icons.add_box),
              tooltip: 'Abrir caja',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => const OpenCashBalanceDialog(),
                );
                _buscar();
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de filtros modernizada
          Container(
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  if (isAdminOrManager)
                    Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: DropdownButtonFormField<Usuario>(
                          isExpanded: true,
                          value: _selectedCobrador,
                          decoration: const InputDecoration(
                            labelText: 'Cobrador',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          items: assignState.cobradores
                              .map(
                                (u) => DropdownMenuItem<Usuario>(
                                  value: u,
                                  child: Text(u.nombre),
                                ),
                              )
                              .toList(),
                          onChanged: (val) =>
                              setState(() => _selectedCobrador = val),
                        ),
                      ),
                    ),
                  if (isAdminOrManager) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _dateFrom ?? 'Desde',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _pickDate(from: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            _dateTo ?? 'Hasta',
                            style: const TextStyle(fontSize: 13),
                          ),
                          onPressed: () => _pickDate(from: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: state.isLoading ? null : _buscar,
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.isLoading ? null : _limpiar,
                          icon: const Icon(Icons.clear),
                          label: const Text('Limpiar'),
                        ),
                      ),
                    ],
                  ),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (state.isLoading) const LinearProgressIndicator(minHeight: 3),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Sin resultados',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index] as Map<String, dynamic>;
                      final date = item['date'] ?? '';
                      final cobrador = item['cobrador'] is Map
                          ? (item['cobrador']['name']?.toString() ?? '')
                          : (item['cobrador_name'] ??
                                item['cobrador_id']?.toString() ??
                                '—');
                      final status = item['status']?.toString() ?? '—';
                      final initialRaw = item['initial_amount'];
                      String initial;
                      if (initialRaw is num) {
                        initial = initialRaw.toStringAsFixed(2);
                      } else {
                        final parsed = double.tryParse(
                          initialRaw?.toString() ?? '',
                        );
                        initial = parsed != null
                            ? parsed.toStringAsFixed(2)
                            : (initialRaw?.toString() ?? '0.00');
                      }

                      final isOpen = status.toLowerCase() == 'open';
                      final statusColor = isOpen
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.tertiary;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CashBalanceDetailScreen(
                                  id: (item['id'] as int),
                                ),
                              ),
                            );
                          },
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
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        isOpen ? Icons.lock_open : Icons.lock,
                                        color: statusColor,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cobrador,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('dd/MM/yyyy').format(
                                                  date is DateTime
                                                      ? date
                                                      : DateTime.tryParse(
                                                              date.toString(),
                                                            ) ??
                                                            DateTime(
                                                              1970,
                                                              1,
                                                              1,
                                                            ),
                                                ),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _translateStatus(status),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Monto inicial: ',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          'Bs $initial',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Icon(
                                      Icons.chevron_right,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // Paginación mejorada
          if (state.lastPage > 1)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Página ${state.currentPage} de ${state.lastPage}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: state.currentPage > 1 && !state.isLoading
                            ? () => _cambiarPagina(state.currentPage - 1)
                            : null,
                        child: const Icon(Icons.chevron_left, size: 20),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed:
                            state.currentPage < state.lastPage &&
                                !state.isLoading
                            ? () => _cambiarPagina(state.currentPage + 1)
                            : null,
                        child: const Icon(Icons.chevron_right, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
