import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../datos/modelos/reporte/daily_activity_report.dart';
import '../../../negocio/providers/reports_provider.dart';
import '../../../negocio/providers/auth_provider.dart';
import '../../../config/role_colors.dart';
import '../widgets/daily_activity_widgets.dart';

class DailyActivityReportView extends ConsumerStatefulWidget {
  const DailyActivityReportView({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyActivityReportView> createState() =>
      _DailyActivityReportViewState();
}

class _DailyActivityReportViewState
    extends ConsumerState<DailyActivityReportView> {
  late DateTime selectedDate;
  bool _useTableView = false;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener el usuario actual desde authProvider
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    // Validar que el usuario tenga acceso a este reporte
    if (usuario == null || usuario.roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reporte de Actividad Diaria'),
        ),
        body: _buildAccessDeniedWidget(context),
      );
    }

    // Determinar el rol del usuario (prioridad: admin > manager > cobrador)
    final String userRole;
    if (usuario.esAdmin()) {
      userRole = 'admin';
    } else if (usuario.esManager()) {
      userRole = 'manager';
    } else if (usuario.esCobrador()) {
      userRole = 'cobrador';
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reporte de Actividad Diaria'),
        ),
        body: _buildAccessDeniedWidget(context),
      );
    }

    // Crear filtros basados en la fecha seleccionada
    final filters = DailyActivityFilters(
      startDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
      endDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59),
    );

    final reportProvider = dailyActivityReportProvider(filters);

    // Obtener color del tema según el rol
    final themeColor = RoleColors.getPrimaryColor(userRole);
    final roleName = RoleColors.getRoleDisplayName(userRole);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reporte de Actividad Diaria'),
            Text(
              'Rol: $roleName',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: themeColor,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                DateFormat('dd/MM/yyyy').format(selectedDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Panel de filtros
            _buildFilterPanel(context, userRole),
            // Contenido del reporte
            Padding(
              padding: const EdgeInsets.all(16),
              child: ref.watch(reportProvider).when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => _buildErrorWidget(error.toString()),
                    data: (report) => _buildReportContent(
                      context,
                      report,
                      userRole,
                      usuario.id.toString(),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar cuando el acceso es denegado
  Widget _buildAccessDeniedWidget(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.red.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Acceso Denegado',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tienes permisos para ver este reporte',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterPanel(BuildContext context, String userRole) {
    return Container(
      color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 20,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Filtros',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(selectedDate),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(_useTableView ? Icons.view_list : Icons.table_chart),
                onPressed: () {
                  setState(() {
                    _useTableView = !_useTableView;
                  });
                },
                tooltip: _useTableView ? 'Vista de lista' : 'Vista de tabla',
              ),
            ],
          ),
          // Mostrar información contextual según el rol
          const SizedBox(height: 12),
          if (userRole == 'cobrador')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoleColors.cobradorSecondary.withValues(alpha: 0.1),
                border: Border.all(color: RoleColors.cobradorSecondary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: RoleColors.cobradorPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Visualizando solo tus pagos del día',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: RoleColors.cobradorPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            )
          else if (userRole == 'manager')
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoleColors.managerSecondary.withValues(alpha: 0.1),
                border: Border.all(color: RoleColors.managerSecondary.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: RoleColors.managerPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Visualizando pagos de tus cobradores',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: RoleColors.managerPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    DailyActivityReport report,
    String userRole,
    String userId,
  ) {
    // Filtrar items según el rol del usuario
    final filteredItems = _filterReportItemsByRole(
      report.items,
      userRole,
      userId,
    );

    if (filteredItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Sin actividad',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                userRole == 'cobrador'
                    ? 'No hay registros de tus pagos para esta fecha'
                    : 'No hay registros de pagos para esta fecha',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Calcular resumen para los items filtrados
    final filteredSummary = _calculateSummary(filteredItems);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card de resumen
        DailyActivitySummaryCard(summary: filteredSummary),
        const SizedBox(height: 24),

        // Resumen por cobrador - Solo mostrar si no es cobrador y hay datos
        if (userRole != 'cobrador' && filteredSummary.byCobradores.isNotEmpty) ...[
          Text(
            'Resumen por Cobrador',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredSummary.byCobradores.entries.length,
            itemBuilder: (context, index) {
              final entry = filteredSummary.byCobradores.entries.elementAt(index);
              final cobradorId = entry.key;
              final cobradorSummary = entry.value;

              // Encontrar el nombre del cobrador desde los items
              final cobradorName = filteredItems
                  .where((item) => item.cobradorId.toString() == cobradorId)
                  .firstOrNull
                  ?.cobradorName;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CobradorSummaryCard(
                  cobradorId: cobradorId,
                  summary: cobradorSummary,
                  cobradorName: cobradorName,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        // Detalle de actividades
        Text(
          'Detalle de Pagos',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),

        // Vista de tabla o lista
        if (_useTableView) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DailyActivityTable(items: filteredItems),
          ),
        ] else ...[
          DailyActivityListView(
            items: filteredItems,
            onItemTap: (item) => _showPaymentDetails(context, item),
          ),
        ],
      ],
    );
  }

  /// Filtra los items del reporte según el rol del usuario
  List<DailyActivityItem> _filterReportItemsByRole(
    List<DailyActivityItem> items,
    String userRole,
    String userId,
  ) {
    if (userRole == 'cobrador') {
      // El cobrador solo ve sus propios pagos
      return items.where((item) => item.cobradorId.toString() == userId).toList();
    } else if (userRole == 'manager') {
      // El manager vería aquí los pagos de sus cobradores asignados
      // Por ahora, mostramos todos (el backend debería filtrar según la asignación)
      return items;
    } else {
      // Admin ve todo
      return items;
    }
  }

  /// Calcula el resumen para un conjunto filtrado de items
  DailyActivitySummary _calculateSummary(List<DailyActivityItem> items) {
    if (items.isEmpty) {
      return DailyActivitySummary(
        totalPayments: 0,
        totalAmount: 0,
        totalAmountFormatted: 'Bs 0.00',
        byCobradores: {},
      );
    }

    double totalAmount = 0;
    final byCobradores = <String, CobradorSummary>{};

    for (final item in items) {
      totalAmount += item.amount;

      // Agrupar por cobrador
      final cobradorKey = item.cobradorId.toString();
      if (!byCobradores.containsKey(cobradorKey)) {
        byCobradores[cobradorKey] = CobradorSummary(count: 0, amount: 0.0);
      }

      final existing = byCobradores[cobradorKey]!;
      byCobradores[cobradorKey] = CobradorSummary(
        count: existing.count + 1,
        amount: existing.amount + item.amount,
      );
    }

    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return DailyActivitySummary(
      totalPayments: items.length,
      totalAmount: totalAmount,
      totalAmountFormatted: currencyFormat.format(totalAmount),
      byCobradores: byCobradores,
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Error al cargar el reporte',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red.withValues(alpha: 0.8),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void _showPaymentDetails(BuildContext context, DailyActivityItem item) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Detalles del Pago',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Pago #${item.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),
                  PaymentStatusChip(status: item.status),
                ],
              ),
              const SizedBox(height: 24),

              // Información del cliente
              _buildDetailSection(
                context,
                'Cliente',
                [
                  _buildDetailRow(context, 'Nombre', item.clientName),
                  _buildDetailRow(context, 'Crédito ID', '#${item.creditId}'),
                ],
              ),
              const SizedBox(height: 16),

              // Información del pago
              _buildDetailSection(
                context,
                'Información del Pago',
                [
                  _buildDetailRow(
                    context,
                    'Monto',
                    currencyFormat.format(item.amount),
                    isHighlight: true,
                  ),
                  _buildDetailRow(
                    context,
                    'Método',
                    item.paymentMethodDisplay,
                  ),
                  _buildDetailRow(
                    context,
                    'Cuota',
                    '${item.installmentNumber}',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Información del cobrador
              _buildDetailSection(
                context,
                'Cobrador',
                [
                  _buildDetailRow(context, 'Nombre', item.cobradorName),
                  _buildDetailRow(context, 'ID', item.cobradorId.toString()),
                ],
              ),
              const SizedBox(height: 16),

              // Fechas
              _buildDetailSection(
                context,
                'Fechas',
                [
                  _buildDetailRow(
                    context,
                    'Fecha de Pago',
                    DateFormat('dd/MM/yyyy HH:mm').format(item.paymentDate),
                  ),
                  _buildDetailRow(
                    context,
                    'Creado',
                    DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                  ),
                ],
              ),

              // Ubicación si está disponible
              if (item.latitude != null && item.longitude != null) ...[
                const SizedBox(height: 16),
                _buildDetailSection(
                  context,
                  'Ubicación',
                  [
                    _buildDetailRow(
                      context,
                      'Latitud',
                      item.latitude.toString(),
                    ),
                    _buildDetailRow(
                      context,
                      'Longitud',
                      item.longitude.toString(),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                  color: isHighlight ? Colors.green.shade700 : null,
                ),
          ),
        ],
      ),
    );
  }
}
