import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/role_colors.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../ui/widgets/validation_error_display.dart';
import '../../ui/widgets/loading_overlay.dart';
import '../widgets/payment_dialog.dart';
import 'credit_detail_screen.dart';
import 'credit_form_screen.dart';
import 'widgets/credits_list_widget.dart';
import 'widgets/filters/filters.dart';

class CreditTypeScreen extends ConsumerStatefulWidget {
  const CreditTypeScreen({super.key});

  @override
  ConsumerState<CreditTypeScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends ConsumerState<CreditTypeScreen>
    with SingleTickerProviderStateMixin {
  // Estado unificado de filtros
  CreditFilterState _filterState = CreditFilterState.empty();

  // UI state
  bool _showAdvancedFilters = false;
  bool _showQuickFilters = false;

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _quickFiltersController = ScrollController();
  late TabController _tabController;

  DateTime? _lastSearchTime;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Listener para búsqueda en tiempo real desactivado (se usará botón de búsqueda u onSubmitted)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _quickFiltersController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // NOTE: Mantener para posible reactivación con debounce y _normalizeQuery
    // Implementar debounce para búsqueda en tiempo real
    _lastSearchTime = DateTime.now();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_lastSearchTime != null &&
          DateTime.now().difference(_lastSearchTime!) >=
              const Duration(milliseconds: 500)) {
        final newSearch = _searchController.text.trim();
        if (_filterState.search != newSearch) {
          setState(() {
            _filterState = _filterState.copyWith(search: newSearch);
          });
          _loadInitialData();
        }
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _filterState = CreditFilterState.empty();
      _searchController.clear();
    });
    _loadInitialData();
  }

  void _loadInitialData() {
    print('📱 CreditTypeScreen: Cargando datos iniciales');

    // Cargar usuarios si es manager (para selector de cobradores)
    if (ref.read(authProvider).isManager) {
      print(
        '📱 CreditTypeScreen: Usuario es manager, cargando lista de usuarios',
      );
      // Obtener usuarios usando el método correcto
      try {
        ref
            .read(userManagementProvider.notifier)
            .cargarUsuarios(role: 'cobrador');
      } catch (e) {
        print('📱 Error al cargar usuarios: $e');
      }
    } else {
      print(
        '📱 CreditTypeScreen: Usuario NO es manager, rol: ${ref.read(authProvider).usuario?.roles.join(", ")}',
      );
    }

    // Verificar estado de filtros
    print('📱 CreditTypeScreen: Filtros activos - ${_filterState.toString()}');

    ref
        .read(creditProvider.notifier)
        .loadCredits(
          status: _filterState.statusFilter,
          search: _filterState.search.isEmpty ? null : _filterState.search,
          frequencies: _filterState.frequencies.isEmpty
              ? null
              : _filterState.frequencies.toList(),
          startDateFrom: _filterState.startDateFrom,
          startDateTo: _filterState.startDateTo,
          amountMin: _filterState.amountMin,
          amountMax: _filterState.amountMax,
          cobradorId: _filterState.selectedCobradorId,
          isOverdue: _filterState.isOverdue,
          overdueAmountMin: _filterState.overdueAmountMin,
          overdueAmountMax: _filterState.overdueAmountMax,
          page: 1,
        );
  }

  // Handler methods for new filter widgets
  void _handleSearch() {
    setState(() {
      _filterState = _filterState.copyWith(
        search: _normalizeQuery(_searchController.text),
      );
    });
    _loadInitialData();
  }

  void _handleClearSearch() {
    setState(() {
      _filterState = _filterState.copyWith(search: '');
      _searchController.clear();
    });
    _loadInitialData();
  }

  void _toggleAdvancedFilters() {
    setState(() {
      _showAdvancedFilters = !_showAdvancedFilters;
    });
  }

  void _handleApplyFilters(CreditFilterState newFilterState) {
    setState(() {
      _filterState = newFilterState;
      _showAdvancedFilters = false;
    });
    _loadInitialData();
  }

  void _handleApplyQuickFilter(CreditFilterState quickFilter) {
    setState(() {
      _filterState = quickFilter;
    });
    _loadInitialData();
  }

  // Normaliza la consulta: si contiene letras -> MAYÚSCULAS, si es solo números/símbolos telefónicos -> tal cual
  String _normalizeQuery(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return trimmed;
    final hasLetter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(trimmed);
    return hasLetter ? trimmed.toUpperCase() : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final creditState = ref.watch(creditProvider);
    final authState = ref.watch(authProvider);
    // Obtener el rol del usuario actual
    String currentUserRole = 'cliente';
    if (authState.usuario != null) {
      if (authState.usuario!.roles.contains('admin')) {
        currentUserRole = 'admin';
      } else if (authState.usuario!.roles.contains('manager')) {
        currentUserRole = 'manager';
      } else if (authState.usuario!.roles.contains('cobrador')) {
        currentUserRole = 'cobrador';
      }
    }

    // Verificar permisos - Admins, managers y cobradores pueden ver esta pantalla
    if (!authState.isManager && !authState.isAdmin && !authState.isCobrador) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Acceso Denegado'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No tienes permisos para acceder a la lista de espera',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Listener para mensajes de error y éxito
    ref.listen<CreditState>(creditProvider, (previous, next) {
      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(creditProvider.notifier).clearError();
              },
            ),
          ),
        );
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ref.read(creditProvider.notifier).clearSuccess();
              },
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Créditos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: RoleColors.getPrimaryColor(currentUserRole),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Actualizar',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabAlignment: MediaQuery.of(context).size.width > 600
              ? TabAlignment.center
              : TabAlignment.start,
          tabs: [
            Tab(
              text:
                  'Activos ('
                  '${creditState.credits.where((c) => c.status == 'active').length}'
                  ')',
              icon: const Icon(Icons.playlist_add_check_circle),
            ),
            Tab(
              text:
                  'Pendientes ('
                  '${creditState.credits.where((c) => c.status == 'pending_approval').length}'
                  ')',
              icon: const Icon(Icons.hourglass_empty),
            ),
            Tab(
              text:
                  'En Espera ('
                  '${creditState.credits.where((c) => c.status == 'waiting_delivery').length}'
                  ')',
              icon: const Icon(Icons.schedule),
            ),
            Tab(
              text:
                  'Entregar ('
                  '${creditState.credits.where((c) => c.isReadyForDelivery).length}'
                  ')',
              icon: const Icon(Icons.today),
            ),
            Tab(
              text:
                  'Entregas Atrasadas ('
                  '${creditState.credits.where((c) => c.isOverdueForDelivery).length}'
                  ')',
              icon: const Icon(Icons.warning),
            ),
            Tab(
              text:
                  'Con Mora ('
                  '${creditState.credits.where((c) => c.isOverdue).length}'
                  ')',
              icon: const Icon(Icons.money_off),
            ),
          ],
        ),
      ),
      // drawer: AppDrawer(role: currentUserRole),
      body: Stack(
        children: [
          Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  // allow the header/filter area to scroll if it grows too tall
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SearchHeader(
                          searchController: _searchController,
                          currentSearch: _filterState.search,
                          showAdvancedFilters: _showAdvancedFilters,
                          onSearch: _handleSearch,
                          onClearSearch: _handleClearSearch,
                          onToggleAdvanced: _toggleAdvancedFilters,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _showAdvancedFilters
                            ? AdvancedFiltersWidget(
                                filterState: _filterState,
                                onApply: _handleApplyFilters,
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (_showQuickFilters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: QuickFiltersWidget(
                            filterState: _filterState,
                            onClearFilters: _clearAllFilters,
                            onApplyQuickFilter: _handleApplyQuickFilter,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.status == 'active')
                          .toList(),
                      listType: 'active',
                      clientCategoryFilters: _filterState.clientCategories,
                      isLoadingMore: creditState.isLoading,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            creditState.totalPages > creditState.currentPage) {
                          ref
                              .read(creditProvider.notifier)
                              .loadCredits(page: creditState.currentPage + 1);
                        }
                      },
                      onCardTap: _navigateToCreditDetail,
                      canDeliver: true,
                      onDeliver: _showQuickDeliveryDialog,
                      onPayment: _showPaymentDialogFromList,
                    ),
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.status == 'pending_approval')
                          .toList(),
                      listType: 'pending',
                      isLoadingMore: creditState.isLoading,
                      clientCategoryFilters: _filterState.clientCategories,
                      onCardTap: _navigateToCreditDetail,
                      canApprove: true,
                      // canReject: true,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            creditState.totalPages > creditState.currentPage) {
                          ref
                              .read(creditProvider.notifier)
                              .loadCredits(page: creditState.currentPage + 1);
                        }
                      },
                      onApprove: _showQuickApprovalDialog,
                      onReject: _showQuickRejectionDialog,
                    ),
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.status == 'waiting_delivery')
                          .toList(),
                      listType: 'waiting',
                      clientCategoryFilters: _filterState.clientCategories,
                      isLoadingMore: creditState.isLoading,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onCardTap: _navigateToCreditDetail,
                      canDeliver: true,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            creditState.totalPages > creditState.currentPage) {
                          ref
                              .read(creditProvider.notifier)
                              .loadCredits(page: creditState.currentPage + 1);
                        }
                      },
                      onDeliver: _showQuickDeliveryDialog,
                    ),
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.isReadyForDelivery)
                          .toList(),
                      listType: 'ready',
                      clientCategoryFilters: _filterState.clientCategories,
                      isLoadingMore: creditState.isLoading,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onCardTap: _navigateToCreditDetail,
                      canDeliver: true,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            creditState.totalPages > creditState.currentPage) {
                          ref
                              .read(creditProvider.notifier)
                              .loadCredits(page: creditState.currentPage + 1);
                        }
                      },
                      onDeliver: _showQuickDeliveryDialog,
                    ),
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.isOverdueForDelivery)
                          .toList(),
                      listType: 'overdue',
                      clientCategoryFilters: _filterState.clientCategories,
                      isLoadingMore: creditState.isLoading,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            creditState.totalPages > creditState.currentPage) {
                          ref
                              .read(creditProvider.notifier)
                              .loadCredits(page: creditState.currentPage + 1);
                        }
                      },
                      onCardTap: _navigateToCreditDetail,
                      canDeliver: true,
                      onDeliver: _showQuickDeliveryDialog,
                    ),
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.isOverdue)
                          .toList(),
                      listType: 'overdue',
                      clientCategoryFilters: _filterState.clientCategories,
                      isLoadingMore: creditState.isLoading,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            creditState.totalPages > creditState.currentPage) {
                          ref
                              .read(creditProvider.notifier)
                              .loadCredits(page: creditState.currentPage + 1);
                        }
                      },
                      onCardTap: _navigateToCreditDetail,
                      enablePayment: true,
                      onPayment: _showPaymentDialogFromList,
                    ),
                  ],
                ),
              ),
            ],
          ),
          LoadingOverlay(
            isLoading: creditState.isLoading,
            message: 'Cargando créditos...',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: RoleColors.getPrimaryColor(currentUserRole),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreditFormScreen()),
          );
          _loadInitialData();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Nuevo Crédito',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _navigateToCreditDetail(Credito credit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreditDetailScreen(credit: credit),
      ),
    ).then((_) {
      // Recargar datos después de regresar
      _loadInitialData();
    });
  }

  Future<void> _showPaymentDialogFromList(Credito credit) async {
    // Mostrar indicador de carga mientras obtenemos los detalles completos
    print(
      'Cargando detalles completos para crédito ID ${credit.toString()}...',
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Cargando detalles del crédito...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // Obtener los detalles completos del crédito incluyendo el resumen
      final details = await ref
          .read(creditProvider.notifier)
          .getCreditFullDetails(credit.id);

      // Cerrar el indicador de carga
      if (mounted) Navigator.of(context).pop();

      if (details == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudieron cargar los detalles del crédito',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Mostrar diálogo de pago con los detalles completos
      final result = await PaymentDialog.show(
        context,
        ref,
        credit,
        creditSummary: details.summary,
      );

      if (result != null && result['success'] == true) {
        final message = result['message'] as String?;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message ?? 'Pago registrado. Actualizando créditos...',
              ),
            ),
          );
        }
        ref.read(creditProvider.notifier).loadCredits();
        _loadInitialData();
      } else if (result != null && result['success'] == false) {
        final message = result['message'] as String?;
        if (message != null && message.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      // Cerrar el indicador de carga si aún está abierto
      if (mounted) Navigator.of(context).pop();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar detalles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showQuickApprovalDialog(Credito credit) async {
    final DateTime now = DateTime.now();
    // Por defecto, programar para el día siguiente a las 09:00 (fecha posterior al día)
    final DateTime tomorrow = now.add(const Duration(days: 1));
    DateTime selectedDate = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      9,
      0,
    );

    bool deliverImmediately = false;

    // Usamos StatefulBuilder para poder actualizar el diálogo cuando cambian los errores
    await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final creditState = ref.watch(creditProvider);
          return AlertDialog(
            title: const Text('Aprobar para Entrega'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
                ),
                Text(
                  'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
                ),
                const SizedBox(height: 16),
                const Text('Fecha y hora de entrega programada:'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 30)),
                    );
                    if (pickedDate != null) {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDate),
                      );
                      if (pickedTime != null) {
                        setState(() {
                          selectedDate = DateTime(
                            pickedDate.year,
                            pickedDate.month,
                            pickedDate.day,
                            pickedTime.hour,
                            pickedTime.minute,
                          );
                        });
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                        ),
                        const Spacer(),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  value: deliverImmediately,
                  onChanged: (v) =>
                      setState(() => deliverImmediately = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Entregar inmediatamente al aprobar'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),

                // Mostrar errores de validación si existen
                if (creditState.validationErrors.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: ValidationErrorDisplay(
                      errors: creditState.validationErrors,
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  bool result = false;
                  if (deliverImmediately) {
                    result = await ref
                        .read(creditProvider.notifier)
                        .approveAndDeliverCredit(
                          creditId: credit.id,
                          scheduledDeliveryDate: DateTime.now(),
                          approvalNotes:
                              'Aprobación y entrega desde lista de espera',
                        );
                  } else {
                    result = await ref
                        .read(creditProvider.notifier)
                        .approveCreditForDelivery(
                          creditId: credit.id,
                          scheduledDeliveryDate: selectedDate,
                        );
                  }

                  if (result) {
                    Navigator.pop(context, true);
                    _loadInitialData();
                  } else {
                    // Actualizar el diálogo para mostrar los errores
                    setState(() {});
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  deliverImmediately ? 'Aprobar y Entregar' : 'Aprobar',
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showQuickRejectionDialog(Credito credit) async {
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar Crédito'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
            ),
            Text(
              'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Motivo del rechazo',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debe proporcionar un motivo'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );

    if (result == true) {
      await ref
          .read(creditProvider.notifier)
          .rejectCredit(
            creditId: credit.id,
            reason: reasonController.text.trim(),
          );
      _loadInitialData();
    }
  }

  Future<void> _showQuickDeliveryDialog(Credito credit) async {
    DateTime now = DateTime.now();
    DateTime selectedDate = credit.scheduledDeliveryDate ?? now;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Confirmar Entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cliente: ${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}',
              ),
              Text(
                'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
              ),
              const SizedBox(height: 12),
              if (credit.scheduledDeliveryDate != null)
                Text(
                  'Programado: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                  style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              if (credit.scheduledDeliveryDate == null)
                const Text(
                  'Sin fecha programada. Puedes programar una antes de entregar.',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              const SizedBox(height: 16),
              const Text('¿Cómo deseas proceder?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'cancel'),
              child: const Text('Cancelar'),
            ),
            TextButton.icon(
              onPressed: () async {
                final DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: now.subtract(const Duration(days: 0)),
                  lastDate: DateTime(now.year + 1),
                );
                if (pickedDate != null) {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(selectedDate),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedDate = DateTime(
                        pickedDate.year,
                        pickedDate.month,
                        pickedDate.day,
                        pickedTime.hour,
                        pickedTime.minute,
                      );
                    });

                    // Llamar a reprogramación inmediatamente para dejar "fecha marcada"
                    final ok = await ref
                        .read(creditProvider.notifier)
                        .rescheduleCreditDelivery(
                          creditId: credit.id,
                          newScheduledDate: selectedDate,
                          reason: 'Reprogramación desde diálogo de entrega',
                        );
                    if (ok) {
                      if (context.mounted)
                        Navigator.pop(context, 'rescheduled');
                    }
                  }
                }
              },
              icon: const Icon(Icons.event),
              label: const Text('Reprogramar fecha'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, 'deliver_now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Entregar ahora'),
            ),
          ],
        ),
      ),
    );

    if (result == 'deliver_now') {
      await ref
          .read(creditProvider.notifier)
          .deliverCreditToClient(
            creditId: credit.id,
            notes: 'Entrega confirmada desde lista de espera',
          );
      _loadInitialData();
    } else if (result == 'rescheduled') {
      // Tras reprogramar, refrescar listas para reflejar la nueva fecha
      _loadInitialData();
    }
  }
}
