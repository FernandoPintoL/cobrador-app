import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/cash_balance_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/cobrador_assignment_provider.dart';
import '../../datos/modelos/usuario.dart';
import 'cash_balance_detail_screen.dart';
import 'open_cash_balance_dialog.dart';

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
        ref.read(cashBalanceProvider.notifier).list(
              cobradorId: _selectedCobrador?.id.toInt(),
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              page: _page,
              perPage: _perPage,
            );
      } else if (auth.isCobrador) {
        _page = 1;
        final id = auth.usuario?.id.toInt();
        ref.read(cashBalanceProvider.notifier).list(
              cobradorId: id,
              dateFrom: _dateFrom,
              dateTo: _dateTo,
              page: _page,
              perPage: _perPage,
            );
      } else {
        // Otros roles: carga básica
        ref.read(cashBalanceProvider.notifier).list(
              page: _page,
              perPage: _perPage,
            );
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
      ref.read(cashBalanceProvider.notifier).list(
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
      ref.read(cashBalanceProvider.notifier).list(
            cobradorId: isCobrador ? auth.usuario?.id.toInt() : null,
            page: _page,
            perPage: _perPage,
          );
    }

    void _cambiarPagina(int nueva) {
      if (nueva < 1) return;
      if (nueva > state.lastPage) return;
      setState(() => _page = nueva);
      ref.read(cashBalanceProvider.notifier).list(
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
          // Barra de filtros
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                if (isAdminOrManager)
                  DropdownButtonFormField<Usuario>(
                    isExpanded: true,
                    value: _selectedCobrador,
                    decoration: const InputDecoration(
                      labelText: 'Cobrador',
                      border: OutlineInputBorder(),
                    ),
                    items: assignState.cobradores
                        .map((u) => DropdownMenuItem<Usuario>(
                              value: u,
                              child: Text(u.nombre),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _selectedCobrador = val),
                  ),
                if (isAdminOrManager) const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateFrom == null
                            ? 'Desde'
                            : 'Desde: ${_dateFrom}'),
                        onPressed: () => _pickDate(from: true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range),
                        label: Text(_dateTo == null
                            ? 'Hasta'
                            : 'Hasta: ${_dateTo}'),
                        onPressed: () => _pickDate(from: false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: state.isLoading ? null : _buscar,
                      icon: const Icon(Icons.search),
                      label: const Text('Buscar'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: state.isLoading ? null : _limpiar,
                      icon: const Icon(Icons.clear),
                      label: const Text('Limpiar'),
                    ),
                  ],
                ),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          if (state.isLoading)
            const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: state.items.isEmpty && !state.isLoading
                ? const Center(child: Text('Sin resultados'))
                : ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
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
                        final parsed = double.tryParse(initialRaw?.toString() ?? '');
                        initial = parsed != null ? parsed.toStringAsFixed(2) : (initialRaw?.toString() ?? '0.00');
                      }
                      return ListTile(
                        title: Text('$date — $cobrador'),
                        subtitle: Text('Inicial: $initial • Estado: $status'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CashBalanceDetailScreen(
                                  id: (item['id'] as int)),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          // Paginación
          if (state.lastPage > 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Página ${state.currentPage} de ${state.lastPage} (Total: ${state.total})'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: state.currentPage > 1 && !state.isLoading
                            ? () => _cambiarPagina(state.currentPage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                        tooltip: 'Anterior',
                      ),
                      IconButton(
                        onPressed: state.currentPage < state.lastPage && !state.isLoading
                            ? () => _cambiarPagina(state.currentPage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                        tooltip: 'Siguiente',
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
