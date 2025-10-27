import 'package:flutter/material.dart';
import '../widgets/report_table.dart';

/// Constructor genérico para renderizar reportes sin vista especializada
///
/// Responsabilidades:
/// - Renderizar Maps como tablas
/// - Renderizar Lists como tablas o chips
/// - Detectar automáticamente el tipo de dato y renderizar apropiadamente
/// - Manejar casos especiales (datos vacíos, errores)
///
/// Patrones utilizados:
/// - Builder Pattern: construcción paso a paso
/// - Strategy Pattern: diferentes renderers según tipo
/// - Template Method: estructura común, detalles específicos
///
/// Ventajas:
/// - No necesita vistas especializadas para cada tipo de datos
/// - Renderizado consistente y profesional
/// - Manejo automático de edge cases
/// - Fácil de mantener y extender
///
/// Ejemplo de uso:
/// ```dart
/// // Renderizado automático
/// GenericReportBuilder.buildAutomatic(payload)
///
/// // Renderizado específico
/// if (payload is Map) {
///   return GenericReportBuilder.buildMapReport(payload, title: 'Datos');
/// } else if (payload is List) {
///   return GenericReportBuilder.buildListReport(payload, title: 'Elementos');
/// }
/// ```
///
/// Flujo:
/// 1. buildAutomatic() detecta el tipo
/// 2. Delega a buildMapReport() o buildListReport()
/// 3. Renderiza tabla o chips según contenido
/// 4. Maneja casos vacíos/error con widgets informativos
///
/// Ver también: ReportTable, BaseReportView, ReportViewFactory
class GenericReportBuilder {
  /// Construye una vista genérica para un Map (diccionario/objeto)
  ///
  /// **Optimización:** Usa buildTableFromMap directamente sin conversión innecesaria
  static Widget buildMapReport(dynamic payload, {String? title}) {
    if (payload is! Map) {
      return _buildErrorWidget('El payload no es un Map válido');
    }

    final map = payload as Map<String, dynamic>;
    if (map.isEmpty) {
      return _buildEmptyWidget(title ?? 'Datos');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        buildTableFromMap(map),
      ],
    );
  }

  /// Construye una vista genérica para una List
  ///
  /// **Optimización:** Evita conversiones innecesarias de tipos
  /// - Los Maps se castean directamente sin Map.from()
  /// - Los chips usan Wrap.children sin .toList() intermedio
  static Widget buildListReport(dynamic payload, {String? title}) {
    if (payload is! List || payload.isEmpty) {
      return _buildEmptyWidget(title ?? 'Lista');
    }

    final list = payload as List<dynamic>;

    // Si la lista contiene Maps, construir tabla
    if (list.first is Map) {
      final rows = List<Map<String, dynamic>>.from(
        list.whereType<Map<String, dynamic>>(),
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: buildTableFromJson(rows),
          ),
        ],
      );
    }

    // Si la lista contiene valores simples, mostrar como chips
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in list)
              Chip(
                label: Text(item?.toString() ?? 'N/A'),
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
              ),
          ],
        ),
      ],
    );
  }

  /// Construye una vista genérica desde cualquier tipo de payload
  static Widget buildAutomatic(
    dynamic payload, {
    String? title,
    bool showKeys = true,
  }) {
    if (payload is Map) {
      return buildMapReport(payload, title: title);
    } else if (payload is List) {
      return buildListReport(payload, title: title);
    } else {
      return _buildErrorWidget(
        'Tipo de payload no soportado: ${payload.runtimeType}',
      );
    }
  }

  /// Widget para mostrar cuando no hay datos
  static Widget _buildEmptyWidget(String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay datos de $label',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Widget para mostrar errores
  static Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.red[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
