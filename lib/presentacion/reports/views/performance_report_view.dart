import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import 'base_report_view.dart';

/// Vista para mostrar reportes de desempeño
class PerformanceReportView extends BaseReportView {
  const PerformanceReportView({
    required rp.ReportRequest request,
    required dynamic payload,
    Key? key,
  }) : super(request: request, payload: payload, key: key);

  @override
  String getReportTitle() => 'Reporte de Desempeño';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    final payloadMap = payload is Map ? payload : {};
    final performers = payloadMap['performers'] as List? ?? [];
    final activities = payloadMap['activities'] as List? ?? [];

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
                  'Top Performers (${performers.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (performers.isEmpty)
                  const Text('No hay datos de performers')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: performers.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(performers[index].toString()),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividades Diarias (${activities.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (activities.isEmpty)
                  const Text('No hay actividades registradas')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(activities[index].toString()),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
