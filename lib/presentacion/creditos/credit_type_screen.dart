import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../config/role_colors.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../datos/modelos/credito.dart';
import '../../negocio/providers/websocket_provider.dart';
import '../../ui/widgets/validation_error_display.dart'; // Importar widget de errores
import '../../ui/widgets/loading_overlay.dart';
import '../../ui/widgets/client_category_chip.dart';
import '../pantallas/notifications_screen.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/payment_dialog.dart';
import '../widgets/app_drawer.dart';
import 'credit_detail_screen.dart';
import 'credit_form_screen.dart';

class CreditTypeScreen extends ConsumerStatefulWidget {
  const CreditTypeScreen({super.key});

  @override
  ConsumerState<CreditTypeScreen> createState() => _WaitingListScreenState();
}

class _WaitingListScreenState extends ConsumerState<CreditTypeScreen>
    with SingleTickerProviderStateMixin {
  // Advanced search UI (copied style from Clientes screen)
  bool _showAdvancedFilters = false;
  String _specificFilter = 'busqueda_general';
  final TextEditingController _specificController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _creditIdController = TextEditingController();
  // Estado simple de filtros para experiencia ágil
  String? _statusFilter;
  final Set<String> _frequency = {};
  double? _amountMin;
  double? _amountMax;
  DateTime? _startFrom;
  DateTime? _startTo;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();
  DateTime? _lastSearchTime;
  late TabController _tabController;

  int? _selectedCobradorId; // Filtro de cobrador

  // Nuevas variables para filtros de cuotas atrasadas
  bool? _isOverdue; // Filtro para créditos con cuotas atrasadas
  double? _overdueAmountMin; // Monto mínimo atrasado
  double? _overdueAmountMax; // Monto máximo atrasado

  // Nuevas variables para filtros rápidos
  bool _showQuickFilters = false;
  final ScrollController _quickFiltersController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    // Listener para búsqueda en tiempo real desactivado (se usará botón de búsqueda u onSubmitted)
    // _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _specificController.dispose();
    _clientController.dispose();
    _creditIdController.dispose();
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
        if (_search != _searchController.text.trim()) {
          setState(() {
            _search = _searchController.text.trim();
          });
          _loadInitialData();
        }
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _statusFilter = null;
      _frequency.clear();
      _amountMin = null;
      _amountMax = null;
      _startFrom = null;
      _startTo = null;
      _selectedCobradorId = null;
      _search = '';
      _searchController.clear();
      _isOverdue = null;
      _overdueAmountMin = null;
      _overdueAmountMax = null;
    });
    _loadInitialData();
  }

  bool get _hasActiveFilters {
    return _statusFilter != null ||
        _frequency.isNotEmpty ||
        _amountMin != null ||
        _amountMax != null ||
        _startFrom != null ||
        _startTo != null ||
        _selectedCobradorId != null ||
        _search.isNotEmpty ||
        _isOverdue != null ||
        _overdueAmountMin != null ||
        _overdueAmountMax != null;
  }

  void _loadInitialData() {
    ref
        .read(creditProvider.notifier)
        .loadCredits(
          status: _statusFilter,
          search: _search.isEmpty ? null : _search,
          frequencies: _frequency.isEmpty ? null : _frequency.toList(),
          startDateFrom: _startFrom,
          startDateTo: _startTo,
          amountMin: _amountMin,
          amountMax: _amountMax,
          cobradorId: _selectedCobradorId,
          isOverdue: _isOverdue,
          overdueAmountMin: _overdueAmountMin,
          overdueAmountMax: _overdueAmountMax,
          page: 1,
        );
  }

  Future<void> _openFilters() async {
    final authState = ref.read(authProvider);
    final isManagerOrAdmin = authState.isManager || authState.isAdmin;
    final cobradores = isManagerOrAdmin
        ? ref
              .read(userManagementProvider)
              .usuarios
              .where((u) => u.roles.contains('cobrador'))
              .toList()
        : [];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final amountMinController = TextEditingController(
          text: _amountMin?.toStringAsFixed(0) ?? '',
        );
        final amountMaxController = TextEditingController(
          text: _amountMax?.toStringAsFixed(0) ?? '',
        );
        String? tmpStatus = _statusFilter;
        final tmpFreq = Set<String>.from(_frequency);
        DateTime? tmpStartFrom = _startFrom;
        DateTime? tmpStartTo = _startTo;
        int? tmpCobradorId = _selectedCobradorId;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModal) => SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (isManagerOrAdmin) ...[
                    const Text('Filtrar por cobrador'),
                    DropdownButtonFormField<int?>(
                      initialValue: tmpCobradorId,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Cobrador'),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...cobradores.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.nombre),
                          ),
                        ),
                      ],
                      onChanged: (v) => setModal(() => tmpCobradorId = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Activos'),
                        selected: tmpStatus == 'active',
                        onSelected: (_) => setModal(() => tmpStatus = 'active'),
                      ),
                      FilterChip(
                        label: const Text('Pendientes'),
                        selected: tmpStatus == 'pending_approval',
                        onSelected: (_) =>
                            setModal(() => tmpStatus = 'pending_approval'),
                      ),
                      FilterChip(
                        label: const Text('En espera'),
                        selected: tmpStatus == 'waiting_delivery',
                        onSelected: (_) =>
                            setModal(() => tmpStatus = 'waiting_delivery'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Frecuencia'),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final f in [
                        'daily',
                        'weekly',
                        'biweekly',
                        'monthly',
                      ])
                        FilterChip(
                          label: Text(f),
                          selected: tmpFreq.contains(f),
                          onSelected: (v) => setModal(() {
                            if (v)
                              tmpFreq.add(f);
                            else
                              tmpFreq.remove(f);
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amountMinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monto mín.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: amountMaxController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Monto máx.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: tmpStartFrom ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setModal(() => tmpStartFrom = d);
                          },
                          icon: const Icon(Icons.date_range),
                          label: Text(
                            tmpStartFrom == null
                                ? 'Inicio desde'
                                : DateFormat(
                                    'dd/MM/yyyy',
                                  ).format(tmpStartFrom!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: tmpStartTo ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (d != null) setModal(() => tmpStartTo = d);
                          },
                          icon: const Icon(Icons.event),
                          label: Text(
                            tmpStartTo == null
                                ? 'Inicio hasta'
                                : DateFormat('dd/MM/yyyy').format(tmpStartTo!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _statusFilter = tmpStatus;
                              _frequency
                                ..clear()
                                ..addAll(tmpFreq);
                              _amountMin = double.tryParse(
                                amountMinController.text,
                              );
                              _amountMax = double.tryParse(
                                amountMaxController.text,
                              );
                              _startFrom = tmpStartFrom;
                              _startTo = tmpStartTo;
                              _selectedCobradorId = tmpCobradorId;
                            });
                            Navigator.pop(context);
                            _loadInitialData();
                          },
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
          // Botón de notificaciones
          Consumer(
            builder: (context, ref, child) {
              final wsState = ref.watch(webSocketProvider);
              final unreadCount = wsState.notifications
                  .where((n) => !n.isRead)
                  .length;

              return IconButton(
                icon: Badge(
                  label: unreadCount > 0 ? Text('$unreadCount') : null,
                  child: const Icon(Icons.notifications),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                ),
                tooltip: 'Notificaciones',
              );
            },
          ),
          /*const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Editar perfil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileSettingsScreen(),
              ),
            ),
          ),*/
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await showLogoutOptions(context: context, ref: ref);
            },
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
      drawer: AppDrawer(role: currentUserRole),
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
                      _buildQuickSearchBar(),
                      // Advanced filters panel similar to Clientes screen
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _showAdvancedFilters
                            ? _buildAdvancedFiltersPanel()
                            : const SizedBox.shrink(),
                      ),
                      if (_showQuickFilters) _buildQuickFilters(),
                      if (_hasActiveFilters) _buildActiveFiltersIndicator(),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCreditsList(
                      creditState.credits
                          .where((c) => c.status == 'active')
                          .toList(),
                      'active',
                    ),
                    _buildCreditsList(
                      creditState.credits
                          .where((c) => c.status == 'pending_approval')
                          .toList(),
                      'pending_approval',
                    ),
                    _buildCreditsList(
                      creditState.credits
                          .where((c) => c.status == 'waiting_delivery')
                          .toList(),
                      'waiting_delivery',
                    ),
                    _buildCreditsList(
                      creditState.credits
                          .where((c) => c.isReadyForDelivery)
                          .toList(),
                      'ready_for_delivery',
                    ),
                    _buildCreditsList(
                      creditState.credits
                          .where((c) => c.isOverdueForDelivery)
                          .toList(),
                      'overdue_delivery',
                    ),
                    _buildCreditsList(
                      creditState.credits.where((c) => c.isOverdue).toList(),
                      'overdue_payments',
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

  // Advanced filters UI builder (inspired by Clientes screen)
  Widget _buildAdvancedFiltersPanel() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget chip(String key, String label, IconData icon) {
      final selected = _specificFilter == key;
      return ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() {
          _specificFilter = key;
        }),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.filter_alt,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtros Específicos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = false;
                      _specificFilter = 'busqueda_general';
                      _specificController.clear();
                      _clientController.clear();
                      _creditIdController.clear();
                    });
                  },
                  tooltip: 'Cerrar filtros',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                chip('busqueda_general', 'General', Icons.search),
                chip('cliente', 'Cliente', Icons.person),
                chip('credit_id', 'ID Crédito', Icons.numbers),
                chip('estado', 'Estado', Icons.verified),
                chip('frecuencia', 'Frecuencia', Icons.event_repeat),
                chip('montos', 'Montos', Icons.attach_money),
                chip('fechas', 'Fechas', Icons.date_range),
                chip('cuotas_atrasadas', 'Cuotas Atrasadas', Icons.money_off),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildSpecificInputForFilter(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _specificFilter = 'busqueda_general';
                        _specificController.clear();
                        _clientController.clear();
                        _creditIdController.clear();
                        _amountMin = null;
                        _amountMax = null;
                        _startFrom = null;
                        _startTo = null;
                      });
                    },
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final s = _composeAdvancedSearch();
                      // Normalizar valores monto y fechas si aplica
                      if (_amountMin != null &&
                          _amountMax != null &&
                          _amountMin! > _amountMax!) {
                        final tmp = _amountMin!;
                        _amountMin = _amountMax;
                        _amountMax = tmp;
                      }
                      if (_startFrom != null &&
                          _startTo != null &&
                          _startFrom!.isAfter(_startTo!)) {
                        final tmp = _startFrom!;
                        _startFrom = _startTo;
                        _startTo = tmp;
                      }
                      setState(() {
                        _search = s ?? '';
                        _showAdvancedFilters = false;
                      });
                      _loadInitialData();
                    },
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificInputForFilter() {
    switch (_specificFilter) {
      case 'cliente':
        return TextField(
          key: const ValueKey('cliente'),
          controller: _clientController,
          decoration: const InputDecoration(
            labelText: 'Nombre del cliente',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
        );
      case 'credit_id':
        return TextField(
          key: const ValueKey('credit_id'),
          controller: _creditIdController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ID del crédito',
            prefixIcon: Icon(Icons.numbers),
            border: OutlineInputBorder(),
          ),
        );
      case 'estado':
        return Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Activos'),
              selected: _statusFilter == 'active',
              onSelected: (_) => setState(() => _statusFilter = 'active'),
            ),
            ChoiceChip(
              label: const Text('Pendientes'),
              selected: _statusFilter == 'pending_approval',
              onSelected: (_) =>
                  setState(() => _statusFilter = 'pending_approval'),
            ),
            ChoiceChip(
              label: const Text('En espera'),
              selected: _statusFilter == 'waiting_delivery',
              onSelected: (_) =>
                  setState(() => _statusFilter = 'waiting_delivery'),
            ),
          ],
        );
      case 'frecuencia':
        return Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Diaria'),
              selected: _frequency.contains('daily'),
              onSelected: (v) => setState(
                () => v ? _frequency.add('daily') : _frequency.remove('daily'),
              ),
            ),
            FilterChip(
              label: const Text('Semanal'),
              selected: _frequency.contains('weekly'),
              onSelected: (v) => setState(
                () =>
                    v ? _frequency.add('weekly') : _frequency.remove('weekly'),
              ),
            ),
            FilterChip(
              label: const Text('Quincenal'),
              selected: _frequency.contains('biweekly'),
              onSelected: (v) => setState(
                () => v
                    ? _frequency.add('biweekly')
                    : _frequency.remove('biweekly'),
              ),
            ),
            FilterChip(
              label: const Text('Mensual'),
              selected: _frequency.contains('monthly'),
              onSelected: (v) => setState(
                () => v
                    ? _frequency.add('monthly')
                    : _frequency.remove('monthly'),
              ),
            ),
          ],
        );
      case 'montos':
        final minCtrl = TextEditingController(
          text: _amountMin?.toStringAsFixed(0) ?? '',
        );
        final maxCtrl = TextEditingController(
          text: _amountMax?.toStringAsFixed(0) ?? '',
        );
        return Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('monto_min'),
                controller: minCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto mínimo',
                  prefixIcon: Icon(Icons.remove_circle_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  setState(() => _amountMin = parsed);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey('monto_max'),
                controller: maxCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monto máximo',
                  prefixIcon: Icon(Icons.add_circle_outline),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v.replaceAll(',', '.'));
                  setState(() => _amountMax = parsed);
                },
              ),
            ),
          ],
        );
      case 'fechas':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('fecha_desde'),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _startFrom ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _startFrom = d);
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _startFrom == null
                      ? 'Desde (inicio)'
                      : DateFormat('dd/MM/yyyy').format(_startFrom!),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('fecha_hasta'),
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _startTo ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) setState(() => _startTo = d);
                },
                icon: const Icon(Icons.event),
                label: Text(
                  _startTo == null
                      ? 'Hasta (inicio)'
                      : DateFormat('dd/MM/yyyy').format(_startTo!),
                ),
              ),
            ),
          ],
        );
      case 'cuotas_atrasadas':
        final overdueMinCtrl = TextEditingController(
          text: _overdueAmountMin?.toStringAsFixed(0) ?? '',
        );
        final overdueMaxCtrl = TextEditingController(
          text: _overdueAmountMax?.toStringAsFixed(0) ?? '',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              dense: true,
              title: const Text('Solo créditos con cuotas atrasadas'),
              value: _isOverdue ?? false,
              onChanged: (value) {
                setState(() => _isOverdue = value);
              },
            ),
            const SizedBox(height: 12),
            const Text('Rango de monto atrasado (opcional):'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('overdue_min'),
                    controller: overdueMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto mínimo atrasado',
                      prefixIcon: Icon(Icons.remove_circle_outline),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      setState(() => _overdueAmountMin = parsed);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    key: const ValueKey('overdue_max'),
                    controller: overdueMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Monto máximo atrasado',
                      prefixIcon: Icon(Icons.add_circle_outline),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      setState(() => _overdueAmountMax = parsed);
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      default:
        return TextField(
          key: const ValueKey('general'),
          controller: _specificController,
          decoration: const InputDecoration(
            labelText: 'Buscar en todos los campos (general)',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        );
    }
  }

  // Normaliza la consulta: si contiene letras -> MAYÚSCULAS, si es solo números/símbolos telefónicos -> tal cual
  String _normalizeQuery(String v) {
    final trimmed = v.trim();
    if (trimmed.isEmpty) return trimmed;
    final hasLetter = RegExp(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]').hasMatch(trimmed);
    return hasLetter ? trimmed.toUpperCase() : trimmed;
  }

  String? _composeAdvancedSearch() {
    switch (_specificFilter) {
      case 'cliente':
        final v = _clientController.text.trim();
        if (v.isEmpty) return null;
        return _normalizeQuery(
          v,
        ); // nombre o CI alfanumérico en MAYÚSCULAS; teléfono se envía tal cual
      case 'credit_id':
        final id = _creditIdController.text.trim();
        if (id.isEmpty) return null;
        return id; // soporta búsqueda por ID en backend
      case 'estado':
        // status se pasa por _statusFilter; mantener search intacto
        return _search.isEmpty ? null : _search;
      case 'frecuencia':
        // frequency se pasa por _frequency; mantener search intacto
        return _search.isEmpty ? null : _search;
      case 'montos':
        // Aplicar al estado al presionar Aplicar (se maneja fuera). No compone 'search'.
        return _search.isEmpty ? null : _search;
      case 'fechas':
        // Igual que montos; se pasa por parámetros dedicados
        return _search.isEmpty ? null : _search;
      case 'cuotas_atrasadas':
        // Se maneja por parámetros dedicados (_isOverdue, _overdueAmountMin, _overdueAmountMax)
        return _search.isEmpty ? null : _search;
      default:
        final v = _specificController.text.trim();
        if (v.isEmpty) return null;
        return _normalizeQuery(v);
    }
  }

  Widget _buildQuickSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController..text = _search,
        autofocus: false,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          isDense: true,
          labelText: 'Buscar por nombre, CI o celular del cliente',
          suffixIcon: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_search.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Limpiar',
                    onPressed: () {
                      setState(() {
                        _search = '';
                        _searchController.clear();
                      });
                      _loadInitialData();
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.search),
                  tooltip: 'Buscar',
                  onPressed: () {
                    setState(() {
                      _search = _normalizeQuery(_searchController.text);
                    });
                    _loadInitialData();
                  },
                ),
                IconButton(
                  icon: AnimatedRotation(
                    turns: _showAdvancedFilters ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.tune),
                  ),
                  onPressed: () {
                    setState(() {
                      _showAdvancedFilters = !_showAdvancedFilters;
                      if (!_showAdvancedFilters) {
                        _specificFilter = 'busqueda_general';
                        _specificController.clear();
                        _clientController.clear();
                        _creditIdController.clear();
                      }
                    });
                  },
                  tooltip: _showAdvancedFilters
                      ? 'Ocultar filtros avanzados'
                      : 'Mostrar filtros avanzados',
                ),
              ],
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
        onSubmitted: (value) {
          setState(() => _search = _normalizeQuery(value));
          _loadInitialData();
        },
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtros Rápidos',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'active';
                      _frequency.clear();
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue = null;
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('Activos'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'pending_approval';
                      _frequency.clear();
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue = null;
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('Pendientes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'waiting_delivery';
                      _frequency.clear();
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue = null;
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('En Espera'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _frequency
                        ..clear()
                        ..add('daily');
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue = null;
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('Hoy'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _frequency
                        ..clear()
                        ..add('weekly');
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue = null;
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('Esta Semana'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _frequency
                        ..clear()
                        ..add('monthly');
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue = null;
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('Este Mes'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _statusFilter = null;
                      _frequency.clear();
                      _amountMin = null;
                      _amountMax = null;
                      _startFrom = null;
                      _startTo = null;
                      _selectedCobradorId = null;
                      _isOverdue =
                          true; // Filtro para créditos con cuotas atrasadas
                      _overdueAmountMin = null;
                      _overdueAmountMax = null;
                    });
                    _loadInitialData();
                  },
                  child: const Text('Con Cuotas Atrasadas'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child:
                    Container(), // Espacio vacío para mantener la disposición
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFiltersIndicator() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtros activos: ${_statusFilter != null ? 'Estado: $_statusFilter' : ''}'
              '${_frequency.isNotEmpty ? ', Frecuencia: ${_frequency.join(', ')}' : ''}'
              '${_amountMin != null ? ', Monto mín.: $_amountMin' : ''}'
              '${_amountMax != null ? ', Monto máx.: $_amountMax' : ''}'
              '${_startFrom != null ? ', Desde: ${DateFormat('dd/MM/yyyy').format(_startFrom!)}' : ''}'
              '${_startTo != null ? ', Hasta: ${DateFormat('dd/MM/yyyy').format(_startTo!)}' : ''}'
              '${_selectedCobradorId != null ? ', Cobrador: $_selectedCobradorId' : ''}'
              '${_isOverdue != null ? ', Cuotas atrasadas: ${_isOverdue! ? 'Sí' : 'No'}' : ''}'
              '${_overdueAmountMin != null ? ', Monto atrasado mín.: $_overdueAmountMin' : ''}'
              '${_overdueAmountMax != null ? ', Monto atrasado máx.: $_overdueAmountMax' : ''}',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _clearAllFilters,
            icon: const Icon(Icons.clear, size: 16, color: Colors.red),
            label: const Text(
              'Limpiar filtros',
              style: TextStyle(color: Colors.red),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditsList(List<Credito> credits, String listType) {
    final creditState = ref.watch(creditProvider);

    if (credits.isEmpty) {
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

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - 200) {
          // Cerca del final, intentar cargar más
          final notifier = ref.read(creditProvider.notifier);
          if (notifier.hasMore &&
              !creditState.isLoadingMore &&
              !creditState.isLoading) {
            notifier.loadMoreCredits();
          }
        }
        return false;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: credits.length + 1,
        itemBuilder: (context, index) {
          if (index < credits.length) {
            final credit = credits[index];
            return _buildCreditCard(credit, listType);
          }
          // Footer
          if (creditState.isLoadingMore) {
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
          if (creditState.currentPage >= creditState.totalPages) {
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

  Widget _buildOverduePaymentsIndicator(Credito credit) {
    // Si no hay datos del backend, no mostrar nada
    if (credit.expectedInstallments == null ||
        credit.completedPaymentsCount == null) {
      return const SizedBox.shrink();
    }

    final expectedPayments = credit.expectedInstallments!;
    final completedPayments = credit.completedPaymentsCount!;
    final overduePayments = expectedPayments - completedPayments;
    final hasOverduePayments = credit.isOverdue && overduePayments > 0;

    if (!hasOverduePayments) {
      // Mostrar estado positivo si está al día
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 14, color: Colors.green),
            const SizedBox(width: 4),
            Text(
              'Al día ($completedPayments/$expectedPayments)',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    // Mostrar información de cuotas atrasadas
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.warning, size: 14, color: Colors.red),
          const SizedBox(width: 4),
          Text(
            '$overduePayments cuota${overduePayments > 1 ? 's' : ''} atrasada${overduePayments > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverdueAmountChip(Credito credit) {
    if (credit.overdueAmount == null || credit.overdueAmount! <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.money_off, size: 14, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            'Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProgressBar(Credito credit) {
    if (credit.expectedInstallments == null ||
        credit.completedPaymentsCount == null) {
      return const SizedBox.shrink();
    }

    final expectedPayments = credit.expectedInstallments!;
    final completedPayments = credit.completedPaymentsCount!;
    final progressPercentage = expectedPayments > 0
        ? (completedPayments / expectedPayments).clamp(0.0, 1.0)
        : 0.0;
    final isOverdue = credit.isOverdue;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Progreso de Pagos',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  '$completedPayments de $expectedPayments cuotas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isOverdue ? Colors.red : Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverdue ? Colors.red : Colors.green,
              ),
              minHeight: 6,
            ),
          ),
          if (isOverdue &&
              credit.overdueAmount != null &&
              credit.overdueAmount! > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Monto vencido: Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedPaymentInfo(Credito credit) {
    // Solo mostrar si tenemos datos del backend
    if (credit.expectedInstallments == null ||
        credit.completedPaymentsCount == null) {
      return const SizedBox.shrink();
    }

    final expectedPayments = credit.expectedInstallments!;
    final completedPayments = credit.completedPaymentsCount!;
    final totalPaid = credit.totalPaid ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estado de Pagos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: _buildInfoChip('Esperadas', '$expectedPayments')),
              const SizedBox(width: 4),
              Expanded(child: _buildInfoChip('Pagadas', '$completedPayments')),
              const SizedBox(width: 4),
              Expanded(
                child: _buildInfoChip(
                  'Total',
                  'Bs. ${NumberFormat('#,##0').format(totalPaid)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCard(Credito credit, String listType) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToCreditDetail(credit),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con cliente y estado
              Row(
                children: [
                  ProfileImageWidget(
                    profileImage: credit.client?.profileImage,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Crédito #${credit.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          credit.client?.nombre ??
                              'Cliente #${credit.clientId}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "CI.: ${credit.client?.ci ?? ''}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          "Cel.: ${credit.client?.telefono ?? ''}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        // categoría del cliente (chip)
                        if (credit.client?.clientCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: ClientCategoryChip(
                              category: credit.client!.clientCategory,
                              compact: true,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(credit.status),
                ],
              ),

              const SizedBox(height: 12),

              // Información del crédito
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto: Bs. ${NumberFormat('#,##0.00').format(credit.amount)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (credit.creator != null) ...[
                          Text(
                            'Creado por: ${credit.creator!.nombre}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(credit.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (credit.scheduledDeliveryDate != null)
                        Text(
                          'Entregado: ${DateFormat('dd/MM/yyyy HH:mm').format(credit.scheduledDeliveryDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: _getDeliveryDateColor(credit),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // Información específica según el tipo de lista
              if (listType == 'pending_approval') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amberAccent.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.77),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.hourglass_empty,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pendiente de aprobación por un manager',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (listType == 'ready_for_delivery') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.77)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Listo para entrega hoy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (listType == 'overdue_delivery') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.77)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.red, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Entrega atrasada (${credit.daysOverdueForDelivery} días)',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (listType == 'overdue_payments') ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0.1),
                        Colors.orange.withOpacity(0.1),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.4)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.money_off_csred,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Crédito con cuotas vencidas',
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (credit.expectedInstallments != null &&
                          credit.completedPaymentsCount != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Cuotas esperadas: ${credit.expectedInstallments}',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              'Pagadas: ${credit.completedPaymentsCount}',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (credit.overdueAmount != null &&
                            credit.overdueAmount! > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.attach_money,
                                size: 14,
                                color: Colors.red,
                              ),
                              Text(
                                'Monto vencido: Bs. ${NumberFormat('#,##0.00').format(credit.overdueAmount)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],

              // Datos adicionales del crédito en la lista
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildInfoChip(
                    'Saldo',
                    'Bs. ${NumberFormat('#,##0.00').format(credit.balance)}',
                  ),
                  _buildInfoChip(
                    'Pagado',
                    'Bs. ${NumberFormat('#,##0.00').format((credit.totalAmount ?? credit.amount) - credit.balance)}',
                  ),
                  if (credit.installmentAmount != null)
                    _buildInfoChip(
                      'Cuota',
                      'Bs. ${NumberFormat('#,##0.00').format(credit.installmentAmount)}',
                    ),
                  _buildInfoChip(
                    'Cuotas',
                    '${credit.paidInstallments}/${credit.totalInstallments}',
                  ),
                  _buildInfoChip('Frecuencia', credit.frequencyLabel),
                ],
              ),

              // Indicadores de cuotas atrasadas desde el backend
              const SizedBox(height: 8),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildOverduePaymentsIndicator(credit)),
                      const SizedBox(width: 8),
                      _buildOverdueAmountChip(credit),
                    ],
                  ),
                  // Mostrar barra de progreso de pagos para todos los créditos con datos del backend
                  if (credit.expectedInstallments != null &&
                      credit.completedPaymentsCount != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildPaymentProgressBar(credit),
                    ),
                ],
              ),

              // Información detallada de pagos (solo en créditos con datos del backend)
              if (credit.expectedInstallments != null &&
                  credit.completedPaymentsCount != null)
                _buildDetailedPaymentInfo(credit),

              // Botones de acción según el estado
              const SizedBox(height: 12),
              _buildActionButtons(credit, listType),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    String label;

    // Obtener el brightness del tema actual
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    switch (status) {
      case 'pending_approval':
        backgroundColor = isDarkMode
            ? Colors.orange.withOpacity(0.2)
            : Colors.orange.withOpacity(0.1);
        borderColor = isDarkMode
            ? Colors.orange.shade300
            : Colors.orange.shade600;
        textColor = isDarkMode
            ? Colors.orange.shade300
            : Colors.orange.shade700;
        label = 'Pendiente';
        break;
      case 'waiting_delivery':
        backgroundColor = isDarkMode
            ? Colors.blue.withOpacity(0.2)
            : Colors.blue.withOpacity(0.1);
        borderColor = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600;
        textColor = isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700;
        label = 'En Espera';
        break;
      case 'active':
        backgroundColor = isDarkMode
            ? Colors.green.withOpacity(0.2)
            : Colors.green.withOpacity(0.1);
        borderColor = isDarkMode
            ? Colors.green.shade300
            : Colors.green.shade600;
        textColor = isDarkMode ? Colors.green.shade300 : Colors.green.shade700;
        label = 'Activo';
        break;
      case 'rejected':
        backgroundColor = isDarkMode
            ? Colors.red.withOpacity(0.2)
            : Colors.red.withOpacity(0.1);
        borderColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade600;
        textColor = isDarkMode ? Colors.red.shade300 : Colors.red.shade700;
        label = 'Rechazado';
        break;
      default:
        backgroundColor = isDarkMode
            ? Colors.grey.withOpacity(0.2)
            : Colors.grey.withOpacity(0.1);
        borderColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
        textColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Credito credit, String listType) {
    final authState = ref.watch(authProvider);
    final canApprove = authState.isManager || authState.isAdmin;
    final canDeliver =
        authState.isCobrador || authState.isManager || authState.isAdmin;

    List<Widget> buttons = [];

    if (listType == 'pending_approval' && canApprove) {
      buttons.addAll([
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showQuickApprovalDialog(credit),
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Aprobar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showQuickRejectionDialog(credit),
            icon: const Icon(Icons.cancel, size: 16),
            label: const Text('Rechazar', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      ]);
    } else if ((listType == 'ready_for_delivery' ||
            (listType == 'waiting_delivery' && credit.isReadyForDelivery)) &&
        canDeliver) {
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showQuickDeliveryDialog(credit),
            icon: const Icon(Icons.local_shipping, size: 16),
            label: const Text('Entregar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      );
    } else if (listType == 'active' && credit.isActive) {
      // Botón para pagos desde la lista de créditos activos
      buttons.add(
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showPaymentDialogFromList(credit),
            icon: const Icon(Icons.payment, size: 16),
            label: const Text('Pagar', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              minimumSize: const Size(0, 32),
            ),
          ),
        ),
      );
    }

    if (buttons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: buttons);
  }

  Color _getDeliveryDateColor(Credito credit) {
    if (credit.scheduledDeliveryDate == null) return Colors.grey;
    if (credit.isOverdueForDelivery) {
      return Colors.red;
    } else if (credit.isReadyForDelivery) {
      return Colors.green;
    } else {
      return Colors.blue;
    }
  }

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
    final result = await PaymentDialog.show(
      context,
      ref,
      credit,
      onPaymentSuccess: () {
        // Al registrar pago, refrescar la lista
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado. Actualizando créditos...'),
          ),
        );
        ref.read(creditProvider.notifier).loadCredits();
        _loadInitialData();
      },
    );

    // Si no se concretó pago, no es necesario hacer nada
    if (result != true) {
      // No-op
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
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
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
                          scheduledDeliveryDate: selectedDate,
                          approvalNotes:
                              'Aprobación rápida con entrega inmediata',
                          deliveryNotes: 'Entrega inmediata desde aprobación',
                        );
                  } else {
                    result = await ref
                        .read(creditProvider.notifier)
                        .approveCreditForDelivery(
                          creditId: credit.id,
                          scheduledDeliveryDate: selectedDate,
                          notes: 'Aprobación rápida para entrega',
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
