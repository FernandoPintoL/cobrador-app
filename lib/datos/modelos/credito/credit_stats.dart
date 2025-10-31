import 'package:flutter/foundation.dart';

class CreditStats {
  final int totalCredits;
  final int activeCredits;
  final int completedCredits;
  final int defaultedCredits;
  final double totalAmount;
  final double totalBalance;

  CreditStats({
    required this.totalCredits,
    required this.activeCredits,
    required this.completedCredits,
    required this.defaultedCredits,
    required this.totalAmount,
    required this.totalBalance,
  });

  factory CreditStats.fromJson(Map<String, dynamic> json) {
    return CreditStats(
      totalCredits: json['total_credits'] ?? 0,
      activeCredits: json['active_credits'] ?? 0,
      completedCredits: json['completed_credits'] ?? 0,
      defaultedCredits: json['defaulted_credits'] ?? 0,
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      totalBalance: double.tryParse(json['total_balance'].toString()) ?? 0.0,
    );
  }

  /// Crea CreditStats desde la estructura de estadísticas del login
  /// Estructura esperada:
  /// - Anidada: {summary: {total_clientes, creditos_activos, saldo_total_cartera}, ...}
  /// - Plana: {total_clientes, creditos_activos, saldo_total_cartera, ...}
  factory CreditStats.fromDashboardStatistics(Map<String, dynamic> json) {
    debugPrint('Creando CreditStats desde estadísticas del dashboard...');
    debugPrint('INPUT JSON: $json');

    // Intentar obtener de 'summary' (estructura anidada) o del nivel raíz (plano)
    final summary = json['summary'] as Map<String, dynamic>? ?? {};

    final totalClientesValue =
        summary['total_clientes'] ?? json['total_clientes'];
    final creditosActivosValue =
        summary['creditos_activos'] ?? json['creditos_activos'];
    final saldoValue =
        summary['saldo_total_cartera'] ?? json['saldo_total_cartera'];

    debugPrint('✅ totalClientesValue: $totalClientesValue');
    debugPrint('✅ creditosActivosValue: $creditosActivosValue');
    debugPrint('✅ saldoValue: $saldoValue');

    // Convertir a int y double de manera segura
    int totalInt = 0;
    int activeInt = 0;
    double saldoDouble = 0.0;

    if (totalClientesValue is num) {
      totalInt = totalClientesValue.toInt();
    } else if (totalClientesValue is String) {
      totalInt = int.tryParse(totalClientesValue) ?? 0;
    }

    if (creditosActivosValue is num) {
      activeInt = creditosActivosValue.toInt();
    } else if (creditosActivosValue is String) {
      activeInt = int.tryParse(creditosActivosValue) ?? 0;
    }

    if (saldoValue is num) {
      saldoDouble = saldoValue.toDouble();
    } else if (saldoValue is String) {
      saldoDouble = double.tryParse(saldoValue) ?? 0.0;
    }

    return CreditStats(
      totalCredits: totalInt,
      activeCredits: activeInt,
      completedCredits: 0,
      defaultedCredits: 0,
      totalAmount: saldoDouble,
      totalBalance: saldoDouble,
    );
  }

  double get collectionRate {
    if (totalAmount == 0) return 0.0;
    return ((totalAmount - totalBalance) / totalAmount) * 100;
  }

  double get defaultRate {
    if (totalCredits == 0) return 0.0;
    return (defaultedCredits / totalCredits) * 100;
  }
}
