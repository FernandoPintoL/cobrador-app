import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../../../negocio/providers/reports_provider.dart' as rp;

/// Helper centralizado para descargar reportes en Excel y PDF
/// Evita la duplicación de lógica de descarga en múltiples lugares
class ReportDownloadHelper {
  /// Descarga un reporte en formato especificado (excel o pdf)
  static Future<void> downloadReport(
    BuildContext context,
    WidgetRef ref,
    rp.ReportRequest request,
    String format, // 'excel' o 'pdf'
  ) async {
    try {
      // Determinar extensión
      final isExcel = format.toLowerCase() == 'excel';
      final extension = isExcel ? 'xlsx' : 'pdf';
      final mimeType = isExcel ? 'application/vnd.ms-excel' : 'application/pdf';

      // Generar reporte
      final bytes = await ref
          .read(rp.reportsApiProvider)
          .generateReport(
            request.type,
            filters: request.filters,
            format: format.toLowerCase(),
          );

      // Validar que la respuesta sea bytes válidos
      if (bytes is! List<int>) {
        _showError(context, 'Error: respuesta inválida del servidor');
        return;
      }

      // Validar que los bytes no estén vacíos
      final bytesList = bytes as List<int>;
      if (bytesList.isEmpty) {
        _showError(context, 'Error: el archivo generado está vacío');
        return;
      }

      // Guardar archivo
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'reporte_${request.type}_$timestamp.$extension';
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(bytesList);

      // Mostrar éxito
      _showSuccess(context, fileName, file);

      // Intentar abrir
      try {
        await OpenFilex.open(filePath);
      } catch (_) {
        // Silenciar error si no puede abrir
      }
    } catch (e) {
      _showError(context, 'Error al descargar $format: $e');
    }
  }

  /// Muestra un SnackBar de éxito con opción de abrir
  static void _showSuccess(BuildContext context, String fileName, File file) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reporte guardado: $fileName'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Abrir',
          onPressed: () {
            try {
              OpenFilex.open(file.path);
            } catch (_) {}
          },
        ),
      ),
    );
  }

  /// Muestra un SnackBar de error
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Obtiene el icono para un formato de descarga
  static IconData getIconForFormat(String format) {
    switch (format.toLowerCase()) {
      case 'excel':
      case 'xlsx':
        return Icons.grid_on;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'csv':
        return Icons.table_chart;
      case 'json':
        return Icons.code;
      default:
        return Icons.download;
    }
  }

  /// Obtiene el nombre legible de un formato
  static String getFormatLabel(String format) {
    switch (format.toLowerCase()) {
      case 'excel':
      case 'xlsx':
        return 'Excel';
      case 'pdf':
        return 'PDF';
      case 'csv':
        return 'CSV';
      case 'json':
        return 'JSON';
      default:
        return format.toUpperCase();
    }
  }
}
