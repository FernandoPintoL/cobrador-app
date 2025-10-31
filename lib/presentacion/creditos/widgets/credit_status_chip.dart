import 'package:flutter/material.dart';

/// Widget que muestra el estado de un crédito como un chip con colores
/// según el estado (pending, active, rejected, etc.)
class CreditStatusChip extends StatelessWidget {
  final String status;

  const CreditStatusChip({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final statusInfo = _getStatusInfo(isDarkMode);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusInfo.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusInfo.borderColor),
      ),
      child: Text(
        statusInfo.label,
        style: TextStyle(
          color: statusInfo.textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  _StatusInfo _getStatusInfo(bool isDarkMode) {
    switch (status) {
      case 'pending_approval':
        return _StatusInfo(
          backgroundColor: isDarkMode
              ? Colors.orange.withOpacity(0.2)
              : Colors.orange.withOpacity(0.1),
          borderColor: isDarkMode
              ? Colors.orange.shade300
              : Colors.orange.shade600,
          textColor: isDarkMode
              ? Colors.orange.shade300
              : Colors.orange.shade700,
          label: 'Pendiente',
        );
      case 'waiting_delivery':
        return _StatusInfo(
          backgroundColor: isDarkMode
              ? Colors.blue.withOpacity(0.2)
              : Colors.blue.withOpacity(0.1),
          borderColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
          textColor: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
          label: 'En Espera',
        );
      case 'active':
        return _StatusInfo(
          backgroundColor: isDarkMode
              ? Colors.green.withOpacity(0.2)
              : Colors.green.withOpacity(0.1),
          borderColor: isDarkMode
              ? Colors.green.shade300
              : Colors.green.shade600,
          textColor: isDarkMode ? Colors.green.shade300 : Colors.green.shade700,
          label: 'Activo',
        );
      case 'rejected':
        return _StatusInfo(
          backgroundColor: isDarkMode
              ? Colors.red.withOpacity(0.2)
              : Colors.red.withOpacity(0.1),
          borderColor: isDarkMode ? Colors.red.shade300 : Colors.red.shade600,
          textColor: isDarkMode ? Colors.red.shade300 : Colors.red.shade700,
          label: 'Rechazado',
        );
      case 'completed':
        return _StatusInfo(
          backgroundColor: isDarkMode
              ? Colors.teal.withOpacity(0.2)
              : Colors.teal.withOpacity(0.1),
          borderColor: isDarkMode ? Colors.teal.shade300 : Colors.teal.shade600,
          textColor: isDarkMode ? Colors.teal.shade300 : Colors.teal.shade700,
          label: 'Completado',
        );
      default:
        return _StatusInfo(
          backgroundColor: isDarkMode
              ? Colors.grey.withOpacity(0.2)
              : Colors.grey.withOpacity(0.1),
          borderColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
          textColor: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700,
          label: status,
        );
    }
  }
}

/// Clase helper para almacenar información de estilo del estado
class _StatusInfo {
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final String label;

  _StatusInfo({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.label,
  });
}
