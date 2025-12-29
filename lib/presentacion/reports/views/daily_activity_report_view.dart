import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../datos/modelos/reporte/daily_activity_report.dart';
import '../../../negocio/providers/reports_provider.dart';
import '../../../negocio/providers/auth_provider.dart';
import '../../../config/role_colors.dart';

class DailyActivityReportView extends ConsumerStatefulWidget {
  const DailyActivityReportView({Key? key}) : super(key: key);

  @override
  ConsumerState<DailyActivityReportView> createState() =>
      _DailyActivityReportViewState();
}

class _DailyActivityReportViewState
    extends ConsumerState<DailyActivityReportView> {
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;

    if (usuario == null || usuario.roles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reporte de Actividad Diaria'),
        ),
        body: _buildAccessDeniedWidget(context),
      );
    }

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

    final filters = DailyActivityFilters(
      startDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day),
      endDate: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59),
      // Para cobradores, filtrar por su ID
      cobradorId: userRole == 'cobrador' ? usuario.id.toInt() : null,
    );

    final reportProvider = dailyActivityReportProvider(filters);
    final themeColor = RoleColors.getPrimaryColor(userRole);
    final roleName = RoleColors.getRoleDisplayName(userRole);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Reportes de Actividad Diaria'),
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
            _buildFilterPanel(context, userRole),
            Padding(
              padding: const EdgeInsets.all(12),
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
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

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
            ],
          ),
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
                      'Visualizando solo tu actividad del día',
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
                      'Visualizando actividad de todos los cobradores',
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
  ) {
    if (report.items.isEmpty) {
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
                    ? 'No hay registros de tu actividad para esta fecha'
                    : 'No hay registros de actividad para esta fecha',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Resumen general del día
        _buildDaySummaryCard(context, report.summary),
        const SizedBox(height: 24),

        // Para cobradores: mostrar su información detallada
        if (userRole == 'cobrador' && report.items.isNotEmpty) ...[
          _buildCobradorDetailCard(context, report.items.first),
        ],

        // Para managers y admins: mostrar resumen de todos los cobradores
        if (userRole != 'cobrador') ...[
          Text(
            'Actividad por Cobrador',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: report.items.length,
            itemBuilder: (context, index) {
              final cobradorItem = report.items[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCobradorSummaryCard(context, cobradorItem),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDaySummaryCard(BuildContext context, DailyActivitySummary summary) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withValues(alpha: 0.8),
              Theme.of(context).primaryColor.withValues(alpha: 0.5),
            ],
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumenes del Día',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    Text(
                      '${summary.dayName}, ${summary.date}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Grid de estadísticas
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 2,
              children: [
                _buildStatCard(
                  context,
                  'Créditos Entregados',
                  summary.totals.creditsDelivered.toString(),
                  Icons.add_card,
                ),
                _buildStatCard(
                  context,
                  'Monto Prestado',
                  currencyFormat.format(summary.totals.amountLent),
                  Icons.attach_money,
                ),
                _buildStatCard(
                  context,
                  'Pagos Cobrados',
                  summary.totals.paymentsCollected.toString(),
                  Icons.receipt,
                ),
                _buildStatCard(
                  context,
                  'Monto Cobrado',
                  currencyFormat.format(summary.totals.amountCollected),
                  Icons.money,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.white30),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCompactStat(
                  context,
                  'Pagos Esperados',
                  summary.totals.expectedPayments.toString(),
                ),
                _buildCompactStat(
                  context,
                  'Pendientes',
                  summary.totals.pendingPayments.toString(),
                ),
                _buildCompactStat(
                  context,
                  'Eficiencia',
                  summary.overallEfficiencyFormatted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }

  Widget _buildCobradorDetailCard(BuildContext context, DailyActivityCobradorItem cobrador) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tu Actividad del Día',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            // Balance de Efectivo
            _buildSectionCard(
              context,
              'Balance de Efectivo',
              Icons.account_balance_wallet,
              cobrador.cashBalance.isOpen ? Colors.green : Colors.blue,
              [
                _buildInfoRow('Estado', cobrador.cashBalance.isOpen ? 'Abierto' : 'Cerrado'),
                _buildInfoRow('Inicial', currencyFormat.format(cobrador.cashBalance.initialAmount)),
                _buildInfoRow('Cobrado', currencyFormat.format(cobrador.cashBalance.collectedAmount)),
                _buildInfoRow('Prestado', currencyFormat.format(cobrador.cashBalance.lentAmount)),
                _buildInfoRow('Final', currencyFormat.format(cobrador.cashBalance.finalAmount)),
              ],
            ),
            const SizedBox(height: 12),

            // Créditos Entregados
            _buildSectionCard(
              context,
              'Créditos Entregados',
              Icons.add_card,
              Colors.orange,
              [
                _buildInfoRow('Total', '${cobrador.creditsDelivered.count}'),
                if (cobrador.creditsDelivered.details.isNotEmpty)
                  ...cobrador.creditsDelivered.details.map((detail) =>
                    _buildDetailRow(
                      detail.clientName,
                      currencyFormat.format(detail.amount),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Pagos Cobrados
            _buildSectionCard(
              context,
              'Pagos Cobrados',
              Icons.receipt,
              Colors.purple,
              [
                _buildInfoRow('Total', '${cobrador.paymentsCollected.count}'),
                if (cobrador.paymentsCollected.details.isNotEmpty)
                  ...cobrador.paymentsCollected.details.map((detail) =>
                    _buildDetailRow(
                      detail.clientName,
                      currencyFormat.format(detail.amount),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Pagos Esperados
            _buildSectionCard(
              context,
              'Pagos Esperados',
              Icons.schedule,
              Colors.teal,
              [
                _buildInfoRow('Total Esperados', '${cobrador.expectedPayments.count}'),
                _buildInfoRow('Cobrados', '${cobrador.expectedPayments.collected}'),
                _buildInfoRow('Pendientes', '${cobrador.expectedPayments.pending}'),
                _buildInfoRow('Eficiencia', cobrador.expectedPayments.efficiencyFormatted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCobradorSummaryCard(BuildContext context, DailyActivityCobradorItem cobrador) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_BO',
      symbol: 'Bs ',
      decimalDigits: 2,
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
          child: Text(
            cobrador.cobradorName.substring(0, 1),
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          cobrador.cobradorName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('ID: ${cobrador.cobradorId}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildCompactSummaryRow(
                  context,
                  'Balance',
                  cobrador.cashBalance.isOpen ? 'Abierto' : 'Cerrado',
                  cobrador.cashBalance.isOpen ? Colors.green : Colors.blue,
                ),
                _buildCompactSummaryRow(
                  context,
                  'Créditos Entregados',
                  '${cobrador.creditsDelivered.count}',
                  Colors.orange,
                ),
                _buildCompactSummaryRow(
                  context,
                  'Pagos Cobrados',
                  '${cobrador.paymentsCollected.count}',
                  Colors.purple,
                ),
                _buildCompactSummaryRow(
                  context,
                  'Monto Cobrado',
                  currencyFormat.format(cobrador.cashBalance.collectedAmount),
                  Colors.green,
                ),
                _buildCompactSummaryRow(
                  context,
                  'Eficiencia',
                  cobrador.expectedPayments.efficiencyFormatted,
                  Colors.teal,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
  ) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '  • $label',
              style: const TextStyle(fontSize: 13, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSummaryRow(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
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
}
