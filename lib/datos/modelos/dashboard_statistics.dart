/// Modelo para las estadísticas del dashboard que se devuelven en el login
/// Contiene estadísticas específicas según el rol del usuario
class DashboardStatistics {
  // Estadísticas para Manager
  final int? totalCobradores;
  final int? totalClientes;
  final int? totalCreditos;
  final double? cobrosMes;

  // Estadísticas para Admin
  final int? totalManagers;
  final int? totalCobradoresAdmin;
  final int? totalClientesAdmin;

  // Estadísticas para Cobrador
  final int? clientesAsignados;
  final int? creditosActivos;
  final double? totalCobradoHoy;
  final double? metaDiaria;

  // Summary extra
  final double? saldoTotalCartera;

  // Hoy
  final int? cobrosRealizadosHoy;
  final int? pendientesHoy;
  final double? efectivoEnCaja;

  // Alertas
  final int? pagosAtrasados;
  final int? clientesSinUbicacion;
  final int? creditosPorVencer7Dias;

  // Metas
  final double? cobrosMesActual;
  final double? metaMes;
  final double? porcentajeCumplimiento;

  DashboardStatistics({
    // Manager stats
    this.totalCobradores,
    this.totalClientes,
    this.totalCreditos,
    this.cobrosMes,
    // Admin stats
    this.totalManagers,
    this.totalCobradoresAdmin,
    this.totalClientesAdmin,
    // Cobrador stats
    this.clientesAsignados,
    this.creditosActivos,
    this.totalCobradoHoy,
    this.metaDiaria,
    // Summary extra
    this.saldoTotalCartera,
    // Hoy
    this.cobrosRealizadosHoy,
    this.pendientesHoy,
    this.efectivoEnCaja,
    // Alertas
    this.pagosAtrasados,
    this.clientesSinUbicacion,
    this.creditosPorVencer7Dias,
    // Metas
    this.cobrosMesActual,
    this.metaMes,
    this.porcentajeCumplimiento,
  });

  factory DashboardStatistics.fromJson(Map<String, dynamic> json) {
    // ✅ Soporta múltiples estructuras según el rol:
    // 1. Cobrador (/api/me): { summary: {...}, hoy: {...}, alertas: {...}, metas: {...} }
    // 2. Manager (/api/me): { resumen_equipo: {...}, rendimiento_hoy: {...}, alertas_criticas: {...} }
    // 3. Plano (/login): { total_clientes, creditos_activos, ... }

    // Extraer estructuras anidadas para Cobrador
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final hoy = json['hoy'] as Map<String, dynamic>? ?? {};
    final metas = json['metas'] as Map<String, dynamic>? ?? {};
    final alertas = json['alertas'] as Map<String, dynamic>? ?? {};

    // Extraer estructuras anidadas para Manager
    final resumenEquipo = json['resumen_equipo'] as Map<String, dynamic>? ?? {};
    final rendimientoHoy =
        json['rendimiento_hoy'] as Map<String, dynamic>? ?? {};
    final alertasCriticas =
        json['alertas_criticas'] as Map<String, dynamic>? ?? {};

    // Intentar obtener valores de estructuras anidadas primero, luego del nivel raíz
    final totalClientesValue =
        resumenEquipo['total_clientes'] ??
        summary['total_clientes'] ??
        json['total_clientes'];
    final creditosActivosValue =
        resumenEquipo['creditos_activos'] ??
        summary['creditos_activos'] ??
        json['creditos_activos'];
    final montoCobradoValue =
        rendimientoHoy['total_cobrado_hoy'] ??
        hoy['monto_cobrado'] ??
        json['total_cobrado_hoy'];
    final totalCobradoresValue =
        resumenEquipo['total_cobradores'] ?? json['total_cobradores'];
    final saldoTotalValue =
        resumenEquipo['saldo_total_cartera'] ??
        summary['saldo_total_cartera'] ??
        json['saldo_total_cartera'];

    final metaMesValue = metas['meta_mes'] ?? json['meta_diaria'];
    final cobrosRealizadosValue =
        hoy['cobros_realizados'] ?? json['cobros_realizados'];
    final pendientesHoyValue = hoy['pendientes_hoy'] ?? json['pendientes_hoy'];
    final efectivoEnCajaValue =
        hoy['efectivo_en_caja'] ?? json['efectivo_en_caja'];

    final pagosAtrasadosValue =
        alertasCriticas['total_pagos_atrasados'] ??
        alertas['pagos_atrasados'] ??
        json['pagos_atrasados'];
    final clientesSinUbicacionValue =
        alertas['clientes_sin_ubicacion'] ?? json['clientes_sin_ubicacion'];
    final creditosPorVencer7DiasValue =
        alertas['creditos_por_vencer_7dias'] ??
        json['creditos_por_vencer_7dias'];

    final cobrosMesActualValue =
        metas['cobros_mes_actual'] ?? json['cobros_mes_actual'];
    final porcentajeCumplimientoValue =
        metas['porcentaje_cumplimiento'] ?? json['porcentaje_cumplimiento'];

    return DashboardStatistics(
      // Manager stats
      totalCobradores: _parseInt(totalCobradoresValue),
      totalClientes: _parseInt(totalClientesValue),
      totalCreditos: _parseInt(creditosActivosValue),
      cobrosMes: _parseDouble(montoCobradoValue),
      // Admin stats
      totalManagers: _parseInt(json['total_managers']),
      totalCobradoresAdmin: _parseInt(json['total_cobradores_admin']),
      totalClientesAdmin: _parseInt(json['total_clientes_admin']),
      // Cobrador stats
      clientesAsignados: _parseInt(json['clientes_asignados']),
      creditosActivos: _parseInt(creditosActivosValue),
      totalCobradoHoy: _parseDouble(montoCobradoValue),
      metaDiaria: _parseDouble(metaMesValue),
      // Summary extra
      saldoTotalCartera: _parseDouble(saldoTotalValue),
      // Hoy
      cobrosRealizadosHoy: _parseInt(cobrosRealizadosValue),
      pendientesHoy: _parseInt(pendientesHoyValue),
      efectivoEnCaja: _parseDouble(efectivoEnCajaValue),
      // Alertas
      pagosAtrasados: _parseInt(pagosAtrasadosValue),
      clientesSinUbicacion: _parseInt(clientesSinUbicacionValue),
      creditosPorVencer7Dias: _parseInt(creditosPorVencer7DiasValue),
      // Metas
      cobrosMesActual: _parseDouble(cobrosMesActualValue),
      metaMes: _parseDouble(metaMesValue),
      porcentajeCumplimiento: _parseDouble(porcentajeCumplimientoValue),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // Manager stats
      'total_cobradores': totalCobradores,
      'total_clientes': totalClientes,
      'total_creditos': totalCreditos,
      'cobros_mes': cobrosMes,
      // Admin stats
      'total_managers': totalManagers,
      'total_cobradores_admin': totalCobradoresAdmin,
      'total_clientes_admin': totalClientesAdmin,
      // Cobrador stats
      'clientes_asignados': clientesAsignados,
      'creditos_activos': creditosActivos,
      'total_cobrado_hoy': totalCobradoHoy,
      'meta_diaria': metaDiaria,
      // Summary extra
      'saldo_total_cartera': saldoTotalCartera,
      // Hoy
      'cobros_realizados': cobrosRealizadosHoy,
      'pendientes_hoy': pendientesHoy,
      'efectivo_en_caja': efectivoEnCaja,
      // Alertas
      'pagos_atrasados': pagosAtrasados,
      'clientes_sin_ubicacion': clientesSinUbicacion,
      'creditos_por_vencer_7dias': creditosPorVencer7Dias,
      // Metas
      'cobros_mes_actual': cobrosMesActual,
      'meta_mes': metaMes,
      'porcentaje_cumplimiento': porcentajeCumplimiento,
    };
  }

  /// Convierte las estadísticas a formato Map compatible con otros providers.
  ///
  /// Este método es útil para convertir las estadísticas en un formato
  /// compatible con el ManagerProvider y otros providers existentes.
  Map<String, dynamic> toCompatibleMap() {
    final map = <String, dynamic>{};

    // Manager stats
    if (totalCobradores != null) map['total_cobradores'] = totalCobradores;
    if (totalClientes != null) map['total_clientes'] = totalClientes;
    // Para manager: totalCreditos es creditos_activos, pero creditosActivos también puede existir para cobrador
    if (totalCreditos != null) map['creditos_activos'] = totalCreditos;
    if (creditosActivos != null) map['creditos_activos'] = creditosActivos;
    // Para manager: saldoTotalCartera es la cartera total (no cobrosMes)
    if (saldoTotalCartera != null)
      map['saldo_total_cartera'] = saldoTotalCartera;

    // Admin stats
    if (totalManagers != null) map['total_managers'] = totalManagers;
    if (totalCobradoresAdmin != null)
      map['total_cobradores_admin'] = totalCobradoresAdmin;
    if (totalClientesAdmin != null)
      map['total_clientes_admin'] = totalClientesAdmin;

    // Cobrador stats
    if (clientesAsignados != null)
      map['clientes_asignados'] = clientesAsignados;
    if (totalCobradoHoy != null) map['total_cobrado_hoy'] = totalCobradoHoy;
    if (metaDiaria != null) map['meta_diaria'] = metaDiaria;

    // Extra fields
    if (cobrosRealizadosHoy != null)
      map['cobros_realizados_hoy'] = cobrosRealizadosHoy;
    if (pendientesHoy != null) map['pendientes_hoy'] = pendientesHoy;
    if (efectivoEnCaja != null) map['efectivo_en_caja'] = efectivoEnCaja;
    if (pagosAtrasados != null) map['pagos_atrasados'] = pagosAtrasados;
    if (clientesSinUbicacion != null)
      map['clientes_sin_ubicacion'] = clientesSinUbicacion;
    if (creditosPorVencer7Dias != null)
      map['creditos_por_vencer_7dias'] = creditosPorVencer7Dias;

    // Metas
    if (cobrosMesActual != null) map['cobros_mes_actual'] = cobrosMesActual;
    if (metaMes != null) map['meta_mes'] = metaMes;
    if (porcentajeCumplimiento != null)
      map['porcentaje_cumplimiento'] = porcentajeCumplimiento;

    return map;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'DashboardStatistics('
        'totalCobradores: $totalCobradores, '
        'totalClientes: $totalClientes, '
        'totalCreditos: $totalCreditos, '
        'cobrosMes: $cobrosMes, '
        'totalManagers: $totalManagers, '
        'totalCobradoresAdmin: $totalCobradoresAdmin, '
        'totalClientesAdmin: $totalClientesAdmin, '
        'clientesAsignados: $clientesAsignados, '
        'creditosActivos: $creditosActivos, '
        'totalCobradoHoy: $totalCobradoHoy, '
        'metaDiaria: $metaDiaria, '
        'saldoTotalCartera: $saldoTotalCartera, '
        'cobrosRealizadosHoy: $cobrosRealizadosHoy, '
        'pendientesHoy: $pendientesHoy, '
        'efectivoEnCaja: $efectivoEnCaja, '
        'pagosAtrasados: $pagosAtrasados, '
        'clientesSinUbicacion: $clientesSinUbicacion, '
        'creditosPorVencer7Dias: $creditosPorVencer7Dias, '
        'cobrosMesActual: $cobrosMesActual, '
        'metaMes: $metaMes, '
        'porcentajeCumplimiento: $porcentajeCumplimiento'
        ')';
  }
}
