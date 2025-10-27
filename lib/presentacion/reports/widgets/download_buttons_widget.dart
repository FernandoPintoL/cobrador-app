import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;
import '../utils/report_formatters.dart';

/// Construye botones de descarga para Excel y PDF con gestión de archivos
Widget buildDownloadButtons(
  BuildContext context,
  WidgetRef ref,
  rp.ReportRequest req,
  Map payload,
) {
  return Row(
    children: [
      ElevatedButton.icon(
        onPressed: () async {
          try {
            final bytes = await ref
                .read(rp.reportsApiProvider)
                .generateReport(
                  req.type,
                  filters: req.filters,
                  format: 'excel',
                );
            if (bytes is List<int>) {
              final dir = await getApplicationDocumentsDirectory();
              final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
              final fileName = 'reporte_${req.type}_$ts.xlsx';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reporte guardado: $fileName'),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () {
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
              );
              try {
                await OpenFilex.open(file.path);
              } catch (_) {}
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al descargar Excel: $e')),
            );
          }
        },
        icon: const Icon(Icons.grid_on),
        label: const Text('Excel'),
      ),
      const SizedBox(width: 8),
      ElevatedButton.icon(
        onPressed: () async {
          try {
            final bytes = await ref
                .read(rp.reportsApiProvider)
                .generateReport(req.type, filters: req.filters, format: 'pdf');
            if (bytes is List<int>) {
              final dir = await getApplicationDocumentsDirectory();
              final ts = DateTime.now().toIso8601String().replaceAll(':', '-');
              final fileName = 'reporte_${req.type}_$ts.pdf';
              final file = File('${dir.path}/$fileName');
              await file.writeAsBytes(bytes);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Reporte guardado: $fileName'),
                  action: SnackBarAction(
                    label: 'Abrir',
                    onPressed: () {
                      OpenFilex.open(file.path);
                    },
                  ),
                ),
              );
              try {
                await OpenFilex.open(file.path);
              } catch (_) {}
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al descargar PDF: $e')),
            );
          }
        },
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('PDF'),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Align(
          alignment: Alignment.centerRight,
          child:
              (payload['generated_by'] != null ||
                  payload['generated_at'] != null)
              ? Text(
                  'Generado' +
                      (payload['generated_by'] != null
                          ? ' por ${payload['generated_by']}'
                          : '') +
                      (payload['generated_at'] != null
                          ? ' • ${ReportFormatters.formatDate(payload['generated_at'])}'
                          : ''),
                  style: Theme.of(context).textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : const SizedBox.shrink(),
        ),
      ),
    ],
  );
}
