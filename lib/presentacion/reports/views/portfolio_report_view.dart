import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import 'base_report_view.dart';

/// Vista para mostrar reportes de portafolio
class PortfolioReportView extends BaseReportView {
  const PortfolioReportView({
    required rp.ReportRequest request,
    required dynamic payload,
    Key? key,
  }) : super(request: request, payload: payload, key: key);

  @override
  String getReportTitle() => 'Reporte de Portafolio';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Distribución de Portafolio',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Total Portafolio'),
              trailing: Text(
                '\$${_getTotalPortfolio()}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            Text(
              'Por Cobradores',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildPortfolioList(context),
          ],
        ),
      ),
    );
  }

  String _getTotalPortfolio() {
    final payloadMap = payload is Map ? payload : {};
    return (payloadMap['totalPortfolio'] ?? 0).toString();
  }

  Widget _buildPortfolioList(BuildContext context) {
    final payloadMap = payload is Map ? payload : {};
    final byCobradores = payloadMap['byCobradores'] as Map? ?? {};

    if (byCobradores.isEmpty) {
      return const Text('No hay datos de portafolio');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: byCobradores.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = byCobradores.entries.elementAt(index);
        return ListTile(
          title: Text(entry.key.toString()),
          trailing: Text(entry.value.toString()),
        );
      },
    );
  }
}
