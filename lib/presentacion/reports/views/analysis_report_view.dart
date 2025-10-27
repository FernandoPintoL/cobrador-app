import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import 'base_report_view.dart';

/// Vista para mostrar reportes de análisis
class AnalysisReportView extends BaseReportView {
  const AnalysisReportView({
    required rp.ReportRequest request,
    required dynamic payload,
    Key? key,
  }) : super(request: request, payload: payload, key: key);

  @override
  String getReportTitle() => 'Reporte de Análisis';

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
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
                  'Análisis de Cobradores',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _buildAnalysisContent(context),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisContent(BuildContext context) {
    final payloadMap = payload is Map ? payload : {};
    final cobradores = payloadMap['cobradores'] as Map?;

    if (cobradores == null || cobradores.isEmpty) {
      return const Text('No hay datos de análisis disponibles');
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cobradores.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final entry = cobradores.entries.elementAt(index);
        return ListTile(
          title: Text(entry.key.toString()),
          subtitle: Text('${entry.value}'),
        );
      },
    );
  }
}
