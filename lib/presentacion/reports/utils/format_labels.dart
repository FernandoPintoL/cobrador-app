import 'package:flutter/material.dart';

/// Utilidad para obtener etiquetas, íconos y descripciones amigables
/// para los formatos de exportación de reportes.
///
/// Convierte términos técnicos (HTML, JSON, PDF, Excel) en lenguaje
/// claro para usuarios no técnicos.
class FormatLabels {
  /// Obtiene la etiqueta amigable para un formato de exportación
  ///
  /// Ejemplos:
  /// - 'html' → 'Ver en navegador'
  /// - 'json' → 'Vista previa'
  /// - 'pdf' → 'Descargar PDF'
  /// - 'excel' → 'Descargar Excel'
  static String getLabel(String format) {
    switch (format.toLowerCase()) {
      case 'html':
        return 'Ver en navegador';
      case 'json':
        return 'Vista previa';
      case 'pdf':
        return 'Descargar PDF';
      case 'excel':
        return 'Descargar Excel';
      default:
        return format.toUpperCase();
    }
  }

  /// Obtiene el ícono Material correspondiente a un formato
  ///
  /// Íconos visuales que comunican rápidamente la acción
  static IconData getIcon(String format) {
    switch (format.toLowerCase()) {
      case 'html':
        return Icons.web;
      case 'json':
        return Icons.phone_android;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'excel':
        return Icons.grid_on;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Obtiene una descripción técnica detallada para mostrar en tooltip
  ///
  /// Proporciona contexto adicional sobre qué hace cada formato
  static String getTechnicalHint(String format) {
    switch (format.toLowerCase()) {
      case 'html':
        return 'Se abrirá en Chrome, Safari u otro navegador instalado';
      case 'json':
        return 'Visualización rápida dentro de la app sin descargar archivo';
      case 'pdf':
        return 'Descarga archivo PDF para compartir, imprimir o guardar';
      case 'excel':
        return 'Descarga archivo Excel para editar en Excel, Sheets u otra app';
      default:
        return 'Formato: ${format.toUpperCase()}';
    }
  }

  /// Obtiene una descripción corta alternativa (sin tooltip)
  ///
  /// Útil para mostrar como subtítulo o descripción secundaria
  static String getShortDescription(String format) {
    switch (format.toLowerCase()) {
      case 'html':
        return 'Abre en navegador externo';
      case 'json':
        return 'Muestra en la app';
      case 'pdf':
        return 'Guarda como PDF';
      case 'excel':
        return 'Guarda como Excel';
      default:
        return '';
    }
  }
}
