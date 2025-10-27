import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import 'base_report_view.dart';

/// Vista para mostrar reportes estadísticos
class StatisticalReportView extends BaseReportView {
  const StatisticalReportView({
    required rp.ReportRequest request,
    required dynamic payload,
    Key? key,
  }) : super(request: request, payload: payload, key: key);

  @override
  String getReportTitle() => 'Reporte Estadístico';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    final payloadMap = payload is Map ? payload : {};
    final projections = payloadMap['projections'] as List? ?? [];
    final frequency = payloadMap['frequency'] as Map? ?? {};

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
                  'Distribución de Frecuencia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (frequency.isEmpty)
                  const Text('No hay datos de frecuencia')
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: frequency.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = frequency.entries.elementAt(index);
                      return ListTile(
                        title: Text(entry.key.toString()),
                        trailing: Text(entry.value.toString()),
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
                  'Proyecciones (${projections.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (projections.isEmpty)
                  const Text('No hay proyecciones disponibles')
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projections.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(projections[index].toString()),
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
