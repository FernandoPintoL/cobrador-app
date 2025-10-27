/// Utilidades para traducir estados, frecuencias y formatos a español
class MapTranslations {
  /// Traduce estados de créditos al español
  static String translateCreditStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'vigente':
      case 'en_curso':
      case 'en curso':
        return 'Activo';
      case 'completed':
      case 'completado':
      case 'paid':
      case 'pagado':
        return 'Completado';
      case 'pending_approval':
      case 'pendiente_aprobacion':
        return 'Pendiente de Aprobación';
      case 'waiting_delivery':
      case 'esperando_entrega':
        return 'Esperando Entrega';
      case 'defaulted':
      case 'incumplido':
        return 'Incumplido';
      case 'rejected':
      case 'rechazado':
        return 'Rechazado';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      case 'overdue':
      case 'vencido':
        return 'Vencido';
      case 'pending':
      case 'pendiente':
        return 'Pendiente';
      default:
        return status;
    }
  }

  /// Traduce estados de persona al español
  static String translatePersonStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'al_dia':
      case 'al dia':
      case 'pagado':
        return 'Al día';
      case 'pending':
      case 'pendiente':
        return 'Pendiente';
      case 'overdue':
      case 'vencido':
      case 'atrasado':
        return 'Vencido';
      default:
        return status;
    }
  }

  /// Traduce frecuencias de pago al español
  static String translateFrequency(String frequency) {
    switch (frequency.toLowerCase()) {
      case 'daily':
      case 'diaria':
        return 'Diaria';
      case 'weekly':
      case 'semanal':
        return 'Semanal';
      case 'biweekly':
      case 'quincenal':
        return 'Quincenal';
      case 'monthly':
      case 'mensual':
        return 'Mensual';
      default:
        return frequency;
    }
  }

  /// Formatea un número como moneda en Bolivianos
  static String formatBolivianos(num value) =>
      'Bs ${value.toStringAsFixed(2)}';

  /// Formatea un número como moneda en Soles (para compatibilidad)
  static String formatSoles(num value) => 'S/ ${value.toStringAsFixed(2)}';

  /// Obtiene el nombre en español del estado de persona
  static String getPersonStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'al_dia':
      case 'al dia':
        return 'AL DÍA';
      case 'pending':
        return 'PENDIENTE';
      case 'overdue':
      case 'vencido':
        return 'VENCIDO';
      default:
        return status.toUpperCase();
    }
  }

  /// Obtiene el nombre en español del estado de crédito
  static String getCreditStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'vigente':
        return 'ACTIVO';
      case 'completed':
      case 'pagado':
        return 'COMPLETADO';
      case 'pending_approval':
        return 'PENDIENTE';
      case 'waiting_delivery':
        return 'EN ESPERA';
      case 'defaulted':
        return 'INCUMPLIDO';
      case 'rejected':
        return 'RECHAZADO';
      case 'cancelled':
        return 'CANCELADO';
      default:
        return status.toUpperCase();
    }
  }

  /// Traduce texto de "Pagó hoy/No pagó hoy"
  static String translatePaidTodayLabel(bool? paid) {
    if (paid == true) return 'Pagó hoy';
    if (paid == false) return 'No pagó hoy';
    return 'Sin datos de hoy';
  }

  /// Traduce etiquetas comunes
  static const Map<String, String> commonLabels = {
    'active': 'Activo',
    'completed': 'Completado',
    'pending': 'Pendiente',
    'overdue': 'Vencido',
    'paid': 'Pagado',
    'person': 'persona',
    'people': 'personas',
    'credit': 'crédito',
    'credits': 'créditos',
    'balance': 'Balance',
    'amount': 'Monto',
    'payment': 'Pago',
    'next_payment': 'Próximo pago',
    'location': 'Ubicación',
    'address': 'Dirección',
    'phone': 'Teléfono',
    'client_category': 'Categoría',
    'status': 'Estado',
  };
}
