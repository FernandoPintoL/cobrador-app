# 📊 Modelos Tipados de Reportes - Guía de Uso

## 🎯 Objetivo

Esta guía documenta el uso de modelos tipados para reportes, garantizando **type safety** completo en toda la aplicación.

---

## ✅ Beneficios

1. **Type Safety**: El compilador detecta errores en tiempo de compilación
2. **Autocompletado**: El IDE sugiere propiedades y métodos disponibles
3. **Documentación**: Los modelos documentan la estructura de datos
4. **Refactoring seguro**: Cambios en modelos se propagan automáticamente
5. **Menos bugs**: No más errores de `null` o campos incorrectos

---

## 📚 Modelos Disponibles

| Reporte | Modelo | Ubicación |
|---------|--------|-----------|
| Créditos | `CreditsReport` | `credits_report_model.dart` |
| Pagos | `PaymentsReport` | `payments_report_model.dart` |
| Balances | `BalancesReport` | `balances_report_model.dart` |
| Mora | `OverdueReport` | `overdue_report_model.dart` |
| Actividad Diaria | `DailyActivityReport` | `daily_activity_report.dart` |

---

## 🚀 Cómo Usar

### **1. Importar el modelo**

```dart
import 'package:cobrador_app/datos/modelos/reporte/reporte_models.dart';
```

### **2. Usar en el servicio API**

```dart
// ✅ ANTES (sin tipo)
final response = await service.generateReport('credits', filters: {...});
final items = response['data']['items']; // ❌ Dynamic, sin type safety

// ✅ AHORA (tipado)
final report = await service.getCreditsReport(
  status: 'active',
  cobradorId: 123,
  startDate: DateTime(2024, 1, 1),
);
final items = report.items; // ✅ List<CreditReportItem>, type safe!
```

### **3. Usar en un Provider**

```dart
// ✅ Provider tipado
final creditsReportProvider = FutureProvider.family<CreditsReport, CreditsReportFilters>(
  (ref, filters) async {
    final service = ref.read(reportsApiProvider);
    return await service.getCreditsReport(
      status: filters.status,
      cobradorId: filters.cobradorId,
      // ... más filtros
    );
  },
);
```

### **4. Usar en una Vista**

```dart
class MyReportView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = CreditsReportFilters(status: 'active');
    final reportAsync = ref.watch(creditsReportProvider(filters));

    return reportAsync.when(
      data: (report) {
        // ✅ Type safe! El IDE conoce todas las propiedades
        return Column(
          children: [
            Text('Total: ${report.summary.totalCredits}'),
            Text('Monto: ${report.summary.totalAmountFormatted}'),
            ListView.builder(
              itemCount: report.items.length,
              itemBuilder: (context, index) {
                final credit = report.items[index];
                // ✅ Autocompletado completo
                return ListTile(
                  title: Text(credit.clientName),
                  subtitle: Text(credit.amountFormatted),
                  trailing: Text(credit.status),
                );
              },
            ),
          ],
        );
      },
      loading: () => CircularProgressIndicator(),
      error: (err, stack) => Text('Error: $err'),
    );
  }
}
```

---

## 🔍 Ejemplos Prácticos

### **Ejemplo 1: Reporte de Créditos Activos**

```dart
final report = await service.getCreditsReport(status: 'active');

// ✅ Type safe - El IDE sabe que es int
final totalCredits = report.summary.totalCredits;

// ✅ Type safe - El IDE sabe que es double
final totalAmount = report.summary.totalAmount;

// ✅ Type safe - Iterar con tipo conocido
for (final credit in report.items) {
  print('${credit.clientName}: ${credit.amountFormatted}');
  print('Estado: ${credit.status}');
  print('Progreso: ${credit.completedInstallments}/${credit.totalInstallments}');
}
```

### **Ejemplo 2: Reporte de Pagos del Día**

```dart
final today = DateTime.now();
final report = await service.getPaymentsReport(
  startDate: today,
  endDate: today,
);

// ✅ Acceso tipado al resumen
print('Total pagos: ${report.summary.totalPayments}');
print('Monto total: ${report.summary.totalAmountFormatted}');

// ✅ Agrupar por método de pago (type safe)
final cashPayments = report.items
    .where((p) => p.paymentMethod == 'cash')
    .toList();
```

### **Ejemplo 3: Reporte de Mora con Severidad**

```dart
final report = await service.getOverdueReport(minDaysOverdue: 1);

// ✅ Filtrar por nivel de severidad
final critical = report.items
    .where((item) => item.severityLevel == 3)
    .toList();

final high = report.items
    .where((item) => item.severityLevel == 2)
    .toList();

// ✅ Usar propiedades calculadas
for (final item in critical) {
  print('${item.clientName} - ${item.severityLabel}');
  print('Días de atraso: ${item.daysOverdue}');
  print('Cuotas vencidas: ${item.installmentsOverdue}');
}
```

---

## 🎨 Propiedades Calculadas

Los modelos incluyen propiedades calculadas útiles:

### **OverdueReportItem**
- `severityLevel`: Nivel de severidad (0-3)
- `severityLabel`: Etiqueta legible ("Bajo", "Medio", "Alto", "Crítico")

### **BalanceReportItem**
- `hasDiscrepancy`: Booleano si hay discrepancia
- `isClosed`: Booleano si el balance está cerrado

### **CreditReportItem**
- `paymentPercentage`: Porcentaje de cuotas pagadas
- `statusColor`: Color sugerido para el estado

---

## 🔧 Migración de Código Existente

### **ANTES (dynamic)**
```dart
final data = response['data'];
final items = data['items'] as List?;
final summary = data['summary'] as Map?;

if (items != null) {
  for (final item in items) {
    final name = item['client_name']; // ❌ Dynamic, propenso a errores
    final amount = item['amount'] ?? 0; // ❌ Puede fallar si es String
  }
}
```

### **DESPUÉS (tipado)**
```dart
final report = CreditsReport.fromJson(response['data']);

for (final item in report.items) {
  final name = item.clientName; // ✅ String garantizado
  final amount = item.amount; // ✅ double garantizado
}
```

---

## 📝 Buenas Prácticas

1. **Siempre usar modelos tipados** en lugar de `Map<String, dynamic>`
2. **Crear clases de filtros** inmutables con equality para providers
3. **Aprovechar propiedades calculadas** en los modelos
4. **Usar métodos tipados** del servicio API
5. **Confiar en el compilador** - si compila, probablemente funciona

---

## 🚨 Errores Comunes

### ❌ **Error: Acceso directo a Map**
```dart
final items = payload['items']; // ❌ Dynamic, sin type safety
```

### ✅ **Correcto: Usar modelo**
```dart
final report = CreditsReport.fromJson(payload);
final items = report.items; // ✅ List<CreditReportItem>
```

### ❌ **Error: Casting manual**
```dart
final amount = (item['amount'] as num).toDouble(); // ❌ Puede fallar
```

### ✅ **Correcto: Usar propiedad tipada**
```dart
final amount = item.amount; // ✅ Ya es double
```

---

## 📊 Estructura de Respuesta del Backend

Todos los reportes siguen esta estructura:

```json
{
  "success": true,
  "data": {
    "items": [...],           // Array de elementos del reporte
    "summary": {...},         // Resumen agregado
    "generated_at": "...",    // Timestamp de generación
    "generated_by": "..."     // Nombre del usuario
  },
  "message": "..."
}
```

Los modelos mapean directamente `data`:

```dart
final report = ReportType.fromJson(response['data']);
```

---

## 🎯 Conclusión

El uso de modelos tipados **elimina una categoría completa de bugs** y mejora significativamente la experiencia de desarrollo.

**El compilador es tu amigo** - úsalo para detectar errores antes de ejecutar el código.
