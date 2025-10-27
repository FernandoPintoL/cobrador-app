import 'package:flutter/material.dart';

/// Utilidades para formatear datos en reportes
class ReportFormatters {
  /// Formatea un valor como fecha (dd/MM/yyyy)
  static String formatDate(dynamic val) {
    if (val == null) return '';
    try {
      final dt = DateTime.tryParse(val.toString());
      if (dt == null) return val.toString();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (e) {
      return val.toString();
    }
  }

  /// Formatea un valor como hora (HH:mm)
  static String formatTime(dynamic val) {
    if (val == null) return '';
    try {
      DateTime? dt;
      if (val is DateTime) {
        dt = val;
      } else {
        dt = DateTime.tryParse(val.toString());
      }
      if (dt == null) return '';
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return '$hh:$mm';
    } catch (_) {
      return '';
    }
  }

  /// Formatea un valor como moneda ($X.XX)
  static String formatCurrency(dynamic val) {
    if (val == null) return '';
    try {
      final d = double.tryParse(val.toString()) ?? 0.0;
      return '\$${d.toStringAsFixed(2)}';
    } catch (e) {
      return val.toString();
    }
  }

  /// Convierte un valor dinámico a double
  static double toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  /// Obtiene el color para un estado de crédito
  static Color colorForCreditStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending_approval':
        return Colors.amber;
      case 'waiting_delivery':
        return Colors.deepOrange;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  /// Obtiene el color para una frecuencia
  static Color colorForFrequency(String? freq) {
    switch ((freq ?? '').toLowerCase()) {
      case 'daily':
        return Colors.purple;
      case 'weekly':
        return Colors.teal;
      case 'monthly':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el icono para un método de pago
  static IconData iconForPaymentMethod(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return Icons.payments;
      case 'transfer':
        return Icons.wallet;
      case 'card':
        return Icons.credit_card;
      case 'mobile_payment':
        return Icons.phone_iphone;
      default:
        return Icons.attach_money;
    }
  }

  /// Obtiene el color para un método de pago
  static Color colorForPaymentMethod(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return Colors.green;
      case 'transfer':
        return Colors.blue;
      case 'card':
        return Colors.purple;
      case 'mobile_payment':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  /// Obtiene el color para un estado genérico
  static Color colorForStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  /// Obtiene el color para un nivel de severidad
  static Color colorForSeverity(String? severity) {
    switch ((severity ?? '').toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Verifica si un valor es null o vacío
  static bool isEmpty(dynamic val) {
    if (val == null) return true;
    if (val is String) return val.isEmpty;
    if (val is List) return val.isEmpty;
    if (val is Map) return val.isEmpty;
    return false;
  }

  // =========== HELPERS DE CÁLCULO ===========

  /// Obtiene el color para una diferencia (balance)
  /// Verde si es positivo, rojo si es negativo, gris si es casi cero
  static Color colorForDifference(double diff) {
    final ad = diff.abs();
    if (ad < 0.01) return Colors.blueGrey; // casi cero
    return diff >= 0 ? Colors.green : Colors.red;
  }

  // =========== TRADUCTORES AL ESPAÑOL ===========

  /// Traduce el estado del crédito al español
  static String translateCreditStatus(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending_approval':
        return 'Pendiente de Aprobación';
      case 'waiting_delivery':
        return 'Esperando Entrega';
      case 'active':
        return 'Activo';
      case 'completed':
        return 'Completado';
      case 'rejected':
        return 'Rechazado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status ?? 'Desconocido';
    }
  }

  /// Traduce la frecuencia de pago al español
  static String translateFrequency(String? frequency) {
    switch ((frequency ?? '').toLowerCase()) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'biweekly':
        return 'Quincenal';
      case 'monthly':
        return 'Mensual';
      case 'yearly':
        return 'Anual';
      default:
        return frequency ?? 'N/A';
    }
  }

  /// Traduce el método de pago al español
  static String translatePaymentMethod(String? method) {
    switch ((method ?? '').toLowerCase()) {
      case 'cash':
        return 'Efectivo';
      case 'transfer':
        return 'Transferencia';
      case 'card':
        return 'Tarjeta';
      case 'mobile_payment':
        return 'Pago Móvil';
      case 'check':
        return 'Cheque';
      default:
        return method ?? 'N/A';
    }
  }

  // =========== INDICADORES DE PAGO DE CUOTAS ===========

  /// Calcula el número de cuotas pendientes (no pagadas)
  /// Retorna la diferencia: total - pagadas
  static int calculatePendingInstallments(int? totalInstallments, int? paidInstallments) {
    if (totalInstallments == null || paidInstallments == null) return 0;
    return (totalInstallments - paidInstallments).clamp(0, totalInstallments);
  }

  /// Obtiene el estado del crédito basado en cuotas pagadas/pendientes
  /// Prioriza el pago de cuotas sobre las fechas
  static String getCreditPaymentStatus(int? totalInstallments, int? paidInstallments) {
    if (totalInstallments == null || paidInstallments == null) {
      return 'desconocido';
    }

    final pendingInstallments = calculatePendingInstallments(totalInstallments, paidInstallments);

    if (pendingInstallments == 0) {
      return 'completado'; // Todas las cuotas pagadas
    } else if (pendingInstallments <= 3) {
      return 'alerta_leve'; // 1-3 cuotas sin pagar
    } else {
      return 'alerta_critica'; // Más de 3 cuotas sin pagar
    }
  }

  /// Obtiene el color basado en el estado de pago de cuotas
  static Color colorForPaymentStatus(int? totalInstallments, int? paidInstallments) {
    final status = getCreditPaymentStatus(totalInstallments, paidInstallments);

    switch (status) {
      case 'completado':
        return Colors.green;
      case 'alerta_leve':
        return Colors.amber;
      case 'alerta_critica':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  /// Obtiene el ícono diferencial basado en estado de pago
  static IconData getPaymentStatusIcon(int? totalInstallments, int? paidInstallments) {
    final status = getCreditPaymentStatus(totalInstallments, paidInstallments);

    switch (status) {
      case 'completado':
        return Icons.check_circle;
      case 'alerta_leve':
        return Icons.warning;
      case 'alerta_critica':
        return Icons.error;
      default:
        return Icons.help_outline;
    }
  }

  /// Obtiene la etiqueta de estado de pago
  static String getPaymentStatusLabel(int? totalInstallments, int? paidInstallments) {
    final status = getCreditPaymentStatus(totalInstallments, paidInstallments);
    final pending = calculatePendingInstallments(totalInstallments, paidInstallments);

    switch (status) {
      case 'completado':
        return 'Todas pagadas';
      case 'alerta_leve':
        return '$pending cuota${pending > 1 ? 's' : ''} pendiente${pending > 1 ? 's' : ''}';
      case 'alerta_critica':
        return '$pending cuota${pending > 1 ? 's' : ''} atrasada${pending > 1 ? 's' : ''}';
      default:
        return 'N/A';
    }
  }

  /// Obtiene un valor numérico desde cualquier tipo dinámico
  static double toNumericValue(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  /// Obtiene un valor numérico usando múltiples posibles nombres de campo
  /// Útil cuando los mismos datos pueden tener diferentes claves
  static double pickAmount(Map<String, dynamic> data, List<String> keys) {
    for (final k in keys) {
      if (data.containsKey(k) && data[k] != null) {
        return toNumericValue(data[k]);
      }
    }
    return 0.0;
  }

  /// Calcula la diferencia de balance
  /// Si existe 'difference' o 'diff', usa eso. Si no, estima: final - (initial + collected - lent)
  static double computeBalanceDifference(Map<String, dynamic> data) {
    if (data['difference'] != null) return toNumericValue(data['difference']);
    if (data['diff'] != null) return toNumericValue(data['diff']);

    final initial = pickAmount(data, [
      'initial',
      'initial_amount',
      'start',
      'opening',
      'initial_cash',
    ]);
    final collected = pickAmount(data, [
      'collected',
      'collected_amount',
      'income',
      'in',
    ]);
    final lent = pickAmount(data, ['lent', 'lent_amount', 'loaned', 'out']);
    final finalVal = pickAmount(data, ['final', 'final_amount', 'closing', 'end']);
    return finalVal - (initial + collected - lent);
  }

  // =========== EXTRACTORES ANIDADOS ===========

  /// Método genérico para extraer valores anidados de un mapa
  /// Intenta múltiples rutas separadas por puntos (ej: 'cobrador.name')
  /// Si no encuentra nada, retorna el defaultValue
  ///
  /// Ejemplo:
  /// - _getNestedValue(data, ['client.name', 'client_name'], 'Cliente')
  /// - _getNestedValue(data, ['cobrador.name', 'cobrador_name'], '')
  static String _getNestedValue(
    Map<String, dynamic> data,
    List<String> paths, {
    String defaultValue = '',
  }) {
    try {
      for (final path in paths) {
        dynamic value = data;

        // Recorrer la ruta separada por puntos (ej: 'cobrador.name' -> ['cobrador', 'name'])
        for (final key in path.split('.')) {
          if (value is Map && value.containsKey(key)) {
            value = value[key];
          } else {
            value = null;
            break;
          }
        }

        // Si encontramos un valor, retornarlo
        if (value != null) {
          return value.toString();
        }
      }
    } catch (_) {}

    return defaultValue;
  }

  /// Extrae el nombre del cliente de un mapa de crédito
  /// Busca en: credit['client']['name'], credit['client_name']
  static String extractCreditClientName(Map<String, dynamic> credit) {
    return _getNestedValue(credit, ['client.name', 'client_name'], defaultValue: 'Cliente');
  }

  /// Extrae el nombre del cobrador de un mapa de crédito
  /// Busca en: credit['created_by']['name'], credit['delivered_by']['name'],
  /// credit['cobrador']['name'], credit['cobrador_name']
  static String extractCreditCobradorName(Map<String, dynamic> credit) {
    return _getNestedValue(credit, [
      'created_by.name',
      'delivered_by.name',
      'cobrador.name',
      'cobrador_name',
    ]);
  }

  /// Extrae el nombre del cobrador de un mapa de balance
  /// Busca en: balance['cobrador']['name'], balance['cobrador_name']
  static String extractBalanceCobradorName(Map<String, dynamic> balance) {
    return _getNestedValue(balance, ['cobrador.name', 'cobrador_name']);
  }

  /// Extrae la fecha de un mapa de balance
  static String extractBalanceDate(Map<String, dynamic> balance) {
    try {
      final dateValue = balance['date'];
      if (dateValue != null) {
        return formatDate(dateValue);
      }
    } catch (_) {}
    return '';
  }

  /// Extrae el nombre del cliente de un mapa de pago
  /// Busca en: payment['client']['name'], payment['client_name']
  static String extractPaymentClientName(Map<String, dynamic> payment) {
    return _getNestedValue(payment, ['client.name', 'client_name'], defaultValue: 'Cliente');
  }

  /// Extrae el nombre del cobrador de un mapa de pago
  /// Busca en múltiples formas: payment['cobrador']['name'], payment['cobrador_name'],
  /// payment['deliveredBy']['name']
  static String extractPaymentCobradorName(Map<String, dynamic> payment) {
    return _getNestedValue(payment, [
      'cobrador.name',
      'cobrador_name',
      'deliveredBy.name',
    ]);
  }

  /// Extrae nombre de cliente desde múltiples formas posibles
  /// Busca en: data['client']['name'], data['credit']['client']['name'],
  /// data['credit']['client_name'], data['client_name'], data['name']
  static String extractClientName(Map<String, dynamic> data) {
    return _getNestedValue(data, [
      'client.name',
      'credit.client.name',
      'credit.client_name',
      'client_name',
      'name',
    ], defaultValue: 'Cliente');
  }

  /// Extrae nombre de cobrador desde múltiples formas posibles
  /// Busca en: data['cobrador']['name'], data['deliveredBy']['name'],
  /// data['cobrador_name'], data['collector_name']
  static String extractCobradorName(Map<String, dynamic> data) {
    return _getNestedValue(data, [
      'cobrador.name',
      'deliveredBy.name',
      'cobrador_name',
      'collector_name',
    ]);
  }
}
