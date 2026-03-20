import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/role_colors.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/utils/text_utils.dart';
import '../../datos/modelos/credito.dart';
import '../../datos/api_services/notification_service.dart';
import '../../ui/widgets/loading_overlay.dart';
import '../widgets/payment_dialog.dart';
import 'credit_detail_screen.dart';
import 'credit_form_screen.dart';
import 'widgets/credits_list_widget.dart';
import 'widgets/dialogs/approval_dialog.dart';
import 'widgets/dialogs/rejection_dialog.dart';
import 'widgets/dialogs/delivery_dialog.dart';
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

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _quickFiltersController = ScrollController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Al cambiar de tab solo recargamos el contenido (no los contadores)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadTabContent();
      }
    });
    // Carga inicial completa: contadores + contenido
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

  /// Obtiene el status de filtro según el tab actual
  String? _getStatusForCurrentTab() {
    switch (_tabController.index) {
      case 0: // Tab Activos
        return 'active';
      case 1: // Tab Pendientes
        return 'pending_approval';
      case 2: // Tab Para Entregar - status waiting_delivery pero se filtran los ready
        return 'waiting_delivery';
      default:
        return null;
    }
  }

  /// Carga completa: contadores de badges + contenido del tab actual.
  /// Úsalo en la carga inicial y después de mutaciones.
  void _loadInitialData() {
    // Cargar usuarios si es manager (para selector de cobradores)
    if (ref.read(authProvider).isManager) {
      try {
        ref
            .read(userManagementProvider.notifier)
            .cargarUsuarios(role: 'cobrador');
      } catch (e) {
        print('📱 Error al cargar usuarios: $e');
      }
    }

    // 1 request para todos los badges
    ref.read(creditProvider.notifier).loadTabCounts(
      search: _filterState.search.isEmpty ? null : _filterState.search,
      cobradorId: _filterState.selectedCobradorId,
    );

    // Contenido del tab actual
    _loadTabContent();
  }

  /// Carga solo el contenido del tab activo (sin recargar contadores).
  /// Úsalo en cambios de tab.
  void _loadTabContent() {
    final String? tabStatus = _getStatusForCurrentTab();
    final String? finalStatus = _filterState.statusFilter ?? tabStatus;

    ref
        .read(creditProvider.notifier)
        .loadCredits(
          status: finalStatus,
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
        search: normalizeSearchQuery(_searchController.text),
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
        NotificationService().showGeneralNotification(
          title: 'Error',
          body: next.errorMessage!,
          type: 'error',
        );
        ref.read(creditProvider.notifier).clearError();
      }

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null) {
        ref.read(creditProvider.notifier).clearSuccess();
      }
    });

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Créditos',
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 120),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: TextButton.icon(
                  onPressed: _checkCashBalanceAndNavigateToForm,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.add, color: Colors.white, size: 18),
                  label: const Text(
                    'Nuevo',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  RoleColors.getPrimaryColor(currentUserRole),
                  RoleColors.getPrimaryColor(
                    currentUserRole,
                  ).withValues(alpha: 0.85),
                ],
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              isScrollable: true,
              tabAlignment: MediaQuery.of(context).size.width > 600
                  ? TabAlignment.center
                  : TabAlignment.start,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.playlist_add_check_circle, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Activos (${creditState.tabCounts['active'] ?? 0})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.hourglass_empty, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Pendientes (${creditState.tabCounts['pending_approval'] ?? 0})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                /*Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.schedule, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'En Espera (${creditState.waitingDeliveryCredits.where((c) => !c.isReadyForDelivery && !c.isOverdueForDelivery).length})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),*/
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping, size: 18),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Para Entregar (${creditState.tabCounts['waiting_delivery'] ?? 0})',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // drawer: AppDrawer(role: currentUserRole),
      body: Stack(
        children: [
          Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.5,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: SearchHeader(
                          searchController: _searchController,
                          currentSearch: _filterState.search,
                          showAdvancedFilters: _showAdvancedFilters,
                          onSearch: _handleSearch,
                          onClearSearch: _handleClearSearch,
                          onToggleAdvanced: _toggleAdvancedFilters,
                        ),
                      ),
                      if (_showAdvancedFilters)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: AdvancedFiltersWidget(
                            filterState: _filterState,
                            onApply: _handleApplyFilters,
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
                      isLoadingMore: creditState.isLoadingMore,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            !creditState.isLoadingMore &&
                            creditState.totalPages > creditState.currentPage) {
                          ref.read(creditProvider.notifier).loadMoreCredits();
                        }
                      },
                      onCardTap: _navigateToCreditDetail,
                      // Créditos activos ya fueron entregados, no necesitan botón de entrega
                      // Todos los roles pueden registrar pagos
                      enablePayment: true,
                      onPayment: _showPaymentDialogFromList,
                    ),
                    CreditsListWidget(
                      credits: creditState.credits
                          .where((c) => c.status == 'pending_approval')
                          .toList(),
                      listType: 'pending_approval',
                      isLoadingMore: creditState.isLoadingMore,
                      clientCategoryFilters: _filterState.clientCategories,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onCardTap: _navigateToCreditDetail,
                      // SOLO managers y admins pueden aprobar/rechazar créditos
                      canApprove:
                          currentUserRole == 'manager' ||
                          currentUserRole == 'admin',
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            !creditState.isLoadingMore &&
                            creditState.totalPages > creditState.currentPage) {
                          ref.read(creditProvider.notifier).loadMoreCredits();
                        }
                      },
                      onApprove:
                          currentUserRole == 'manager' ||
                              currentUserRole == 'admin'
                          ? _showQuickApprovalDialog
                          : null,
                      onReject:
                          currentUserRole == 'manager' ||
                              currentUserRole == 'admin'
                          ? _showQuickRejectionDialog
                          : null,
                    ),
                    // Tab "Para Entregar": muestra TODOS los créditos waiting_delivery
                    CreditsListWidget(
                      credits: () {
                        final credits = creditState.waitingDeliveryCredits;

                        print('🔍 DEBUG Tab Para Entregar:');
                        print('  - waitingDeliveryCredits: ${credits.length}');
                        if (credits.isNotEmpty) {
                          print(
                            '  - Primer crédito ID: ${credits.first.id}, scheduledDate: ${credits.first.scheduledDeliveryDate}',
                          );
                        }

                        return credits;
                      }(),
                      listType: 'ready_for_delivery',
                      clientCategoryFilters: _filterState.clientCategories,
                      isLoadingMore: creditState.isLoadingMore,
                      hasMore: creditState.totalPages > creditState.currentPage,
                      currentPage: creditState.currentPage,
                      totalPages: creditState.totalPages,
                      onCardTap: _navigateToCreditDetail,
                      // Managers, cobradores y admins pueden entregar créditos
                      canDeliver:
                          currentUserRole == 'manager' ||
                          currentUserRole == 'cobrador' ||
                          currentUserRole == 'admin',
                      onLoadMore: () {
                        if (!creditState.isLoading &&
                            !creditState.isLoadingMore &&
                            creditState.totalPages > creditState.currentPage) {
                          ref.read(creditProvider.notifier).loadMoreCredits();
                        }
                      },
                      onDeliver:
                          currentUserRole == 'manager' ||
                              currentUserRole == 'cobrador' ||
                              currentUserRole == 'admin'
                          ? _showQuickDeliveryDialog
                          : null,
                      onCancel:
                          currentUserRole == 'manager' ||
                                  currentUserRole == 'admin'
                              ? _showQuickCancelDeliveryDialog
                              : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (creditState.isLoading)
            LoadingOverlay(
              isLoading: creditState.isLoading,
              message: 'Cargando créditos...',
            ),
        ],
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
        NotificationService().showGeneralNotification(
          title: 'Error',
          body: 'No se pudieron cargar los detalles del crédito',
          type: 'error',
        );
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
        NotificationService().showPaymentNotification(
          title: 'Pago registrado',
          body: message ?? 'Pago registrado. Actualizando créditos...',
        );
        ref.read(creditProvider.notifier).loadCredits();
        _loadInitialData();
      } else if (result != null && result['success'] == false) {
        final message = result['message'] as String?;
        if (message != null && message.isNotEmpty) {
          NotificationService().showPaymentNotification(
            title: 'Error al registrar pago',
            body: message,
          );
        }
      }
    } catch (e) {
      // Cerrar el indicador de carga si aún está abierto
      if (mounted) Navigator.of(context).pop();

      NotificationService().showGeneralNotification(
        title: 'Error',
        body: 'Error al cargar detalles: $e',
        type: 'error',
      );
    }
  }

  Future<void> _showQuickApprovalDialog(Credito credit) =>
      showApprovalDialog(context, ref, credit, onSuccess: _loadInitialData);

  Future<void> _showQuickRejectionDialog(Credito credit) =>
      showRejectionDialog(context, ref, credit, onSuccess: _loadInitialData);

  Future<void> _showQuickDeliveryDialog(Credito credit) =>
      showDeliveryDialog(context, ref, credit, onSuccess: _loadInitialData);

  Future<void> _showQuickCancelDeliveryDialog(Credito credit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar entrega'),
        content: Text(
          '¿Estás seguro de que deseas cancelar la entrega y anular este crédito?\n\n'
          'Cliente: \'${credit.client?.nombre ?? 'Cliente #${credit.clientId}'}\'\n'
          'Monto: Bs. ${credit.amount.toStringAsFixed(2)}\n\n'
          'El crédito será marcado como cancelado y no podrá entregarse.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Mantener'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancelar entrega'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(creditProvider.notifier)
          .cancelCredit(credit.id);

      if (success) {
        NotificationService().showCreditNotification(
          title: 'Entrega cancelada',
          body: 'Entrega cancelada y crédito anulado',
          creditId: credit.id.toString(),
        );
        if (mounted) _loadInitialData();
      }
    }
  }

  /// Navega al formulario de creación de crédito
  /// El backend se encarga de crear la caja automáticamente si es necesario
  Future<void> _checkCashBalanceAndNavigateToForm() async {
    // Navegar directamente al formulario
    // El backend creará la caja automáticamente si no existe
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreditFormScreen()),
    );
    _loadInitialData();
  }
}
