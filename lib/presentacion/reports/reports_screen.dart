import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../negocio/providers/reports_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  final String userRole; // 'manager' o 'cobrador'

  const ReportsScreen({super.key, required this.userRole});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _selectedReport;
  Map<String, dynamic> _filters = {};
  String _format = 'json';

  @override
  Widget build(BuildContext context) {
    final reportTypesAsync = ref.watch(reportTypesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Generador de Reportes')),
      body: reportTypesAsync.when(
        data: (types) {
          final entries = types.entries.toList();
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tipo de reporte',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedReport,
                  items: entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value['name'] ?? e.key),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedReport = v),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                if (_selectedReport != null)
                  ..._buildFiltersFor(types[_selectedReport!]),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Formato: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _format,
                      items:
                          ((types[_selectedReport]?['formats']
                                      as List<dynamic>?) ??
                                  ['json'])
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f as String,
                                  child: Text(f.toString().toUpperCase()),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _format = v ?? 'json'),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _selectedReport == null
                          ? null
                          : _generateReport,
                      child: const Text('Generar'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _ReportResultView(
                    selectedReport: _selectedReport,
                    filters: _filters,
                    format: _format,
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) =>
            Center(child: Text('Error cargando tipos de reportes: $e')),
      ),
    );
  }

  List<Widget> _buildFiltersFor(dynamic typeDef) {
    final List<Widget> widgets = [];
    final filters = (typeDef?['filters'] as List<dynamic>?) ?? [];

    for (final f in filters) {
      final key = f as String;
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: key.replaceAll('_', ' ').toUpperCase(),
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => _filters[key] = v,
          ),
        ),
      );
    }

    return widgets;
  }

  void _generateReport() {
    setState(() {});
    // El resultado se maneja por _ReportResultView que observa generateReportProvider manualmente
  }
}

class _ReportResultView extends ConsumerWidget {
  final String? selectedReport;
  final Map<String, dynamic> filters;
  final String format;

  const _ReportResultView({
    required this.selectedReport,
    required this.filters,
    required this.format,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedReport == null) {
      return const Center(
        child: Text('Seleccione un reporte y presione Generar'),
      );
    }

    final params = {
      'type': selectedReport!,
      'filters': filters,
      'format': format,
    };
    final asyncVal = ref.watch(generateReportProvider(params));

    return asyncVal.when(
      data: (value) {
        if (format == 'json') {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(8.0),
            child: Text(value.toString()),
          );
        }

        // Para binarios ofrecer descarga
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Reporte binario listo.'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text('Descargar'),
                onPressed: () async {
                  try {
                    if (value is List<int>) {
                      final dir = await getApplicationDocumentsDirectory();
                      final fileName = 'reporte-${selectedReport}.${format}';
                      final filePath = '${dir.path}/$fileName';
                      final file = File(filePath);
                      await file.writeAsBytes(value);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reporte guardado en: $filePath'),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Respuesta inesperada: no son bytes'),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error guardando archivo: $e')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('Error generando reporte: $e')),
    );
  }
}
