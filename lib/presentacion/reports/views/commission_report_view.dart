import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import 'base_report_view.dart';

/// Vista para mostrar reportes de comisiones
class CommissionReportView extends BaseReportView {
  const CommissionReportView({
    required rp.ReportRequest request,
    required dynamic payload,
    Key? key,
  }) : super(request: request, payload: payload, key: key);

  @override
  String getReportTitle() => 'Reporte de Comisiones';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    final payloadMap = payload is Map ? payload : {};
    final topEarners = payloadMap['topEarners'] as List? ?? [];
    final commissions = payloadMap['commissions'] as List? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Comisión Total',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '\$${payloadMap['totalCommission'] ?? 0}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Top Ganadores',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (topEarners.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No hay datos disponibles'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: topEarners.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text(topEarners[index].toString()),
                ),
              );
            },
          ),
      ],
    );
  }
}
