# Referencia Rápida - Módulo de Reportes

## 📁 Estructura de carpetas

```
lib/presentacion/reports/
├── reports_screen.dart           ← Pantalla principal
├── ARCHITECTURE.md               ← Documentación completa
├── DIAGRAMS.md                   ← Diagramas de flujo
├── QUICK_REFERENCE.md            ← Este archivo
├── views/                         ← Vistas por tipo de reporte
├── widgets/                       ← Componentes reutilizables
└── utils/                         ← Utilidades sin estado
```

---

## ⚡ Tareas comunes

### Agregar nuevo tipo de reporte

**1. Crear la vista:**
```dart
// lib/presentacion/reports/views/my_new_report_view.dart
import 'base_report_view.dart';

class MyNewReportView extends BaseReportView {
  const MyNewReportView({
    required super.request,
    required super.payload,
    Key? key,
  }) : super(key: key);

  @override
  String getReportTitle() => 'Mi Nuevo Reporte';

  @override
  IconData getReportIcon() => Icons.my_icon;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    // Tu implementación aquí
    return Container(
      // Contenido del reporte
    );
  }
}
```

**2. Registrar en ReportViewFactory:**
```dart
// En report_view_factory.dart
if (payload.containsKey('my_new_data')) {
  return MyNewReportView(request: request, payload: payload);
}
```

---

### Formatear un valor

**Usa `ReportFormatters`:**
```dart
// Fechas
ReportFormatters.formatDate(date)          // "25/12/2023"
ReportFormatters.formatTime(time)          // "14:30"

// Moneda
ReportFormatters.formatCurrency(1234.56)   // "$1,234.56"

// Conversiones
ReportFormatters.toDouble(value)           // Convierte a double
ReportFormatters.toNumericValue(value)     // Igual que toDouble

// Colores según valores
ReportFormatters.colorForStatus(status)
ReportFormatters.colorForPaymentMethod(method)
ReportFormatters.colorForDifference(diff)

// Iconos
ReportFormatters.iconForPaymentMethod(method)
```

---

### Extraer datos anidados

**Usa `ReportFormatters`:**
```dart
// Extraer nombres
final clientName = ReportFormatters.extractPaymentClientName(payment);
final cobradorName = ReportFormatters.extractPaymentCobradorName(payment);

// Genérico
final nombre = ReportFormatters.extractClientName(data);
final cobrador = ReportFormatters.extractCobradorName(data);

// Método genérico para valores anidados
// ReportFormatters._getNestedValue(data, ['ruta.anidada', 'alternativa'])
```

---

### Traducir etiqueta de filtro

**Usa `FilterLabelTranslator`:**
```dart
final label = FilterLabelTranslator.translate('client_id');
// → "ID Cliente"

final label = FilterLabelTranslator.translate('unknown_field');
// → "Unknown Field" (humanizado automáticamente)
```

---

### Construir filtros dinámicamente

**Usa `FilterBuilder`:**
```dart
final filters = FilterBuilder.buildFiltersForReportType(
  reportTypeDefinition: types['payments'],
  currentFilters: _filters,
  isManualDateRange: _quickRangeIndex == 5,
  onFilterChanged: (key, value) {
    setState(() { /* actualizar */ });
  },
);
```

---

### Aplicar rango de fecha rápido

**Usa `ReportStateHelper`:**
```dart
// Rangos: 0=Hoy, 1=Ayer, 2=Últ 7 días, 3=Este mes, 4=Mes pasado, 5=Manual
ReportStateHelper.applyQuickDateRange(0, _filters);  // Hoy
ReportStateHelper.applyQuickDateRange(2, _filters);  // Últimos 7 días

// Limpiar filtros de fecha
ReportStateHelper.clearDateFilters(_filters);

// Verificar si está en modo manual
if (ReportStateHelper.isManualDateRange(_quickRangeIndex)) {
  // El usuario puede configurar fechas manualmente
}
```

---

### Crear request de reporte

**Usa `ReportStateHelper`:**
```dart
final request = ReportStateHelper.createReportRequest(
  reportType: 'payments',
  filters: {'client_id': '123', 'status': 'pending'},
  format: 'json',
);
```

---

### Construir tarjetas de resumen

**Usa `SummaryCardsBuilder`:**
```dart
SummaryCardsBuilder(
  payload: payload,
  cards: [
    SummaryCardConfig(
      title: 'Total',
      summaryKey: 'total_amount',
      icon: Icons.attach_money,
      color: Colors.green,
      formatter: ReportFormatters.formatCurrency,
    ),
    SummaryCardConfig(
      title: 'Cantidad',
      summaryKey: 'total_items',
      icon: Icons.inventory,
      color: Colors.blue,
      formatter: (val) => '$val',
    ),
  ],
)
```

---

### Renderizar datos genéricos

**Usa `GenericReportBuilder`:**
```dart
// Automático (detecta tipo)
GenericReportBuilder.buildAutomatic(payload)

// Específico para Map
GenericReportBuilder.buildMapReport(payload, title: 'Datos')

// Específico para List
GenericReportBuilder.buildListReport(payload, title: 'Elementos')
```

---

### Detectar tipo de filtro

**Usa `FilterBuilder`:**
```dart
final type = FilterBuilder.detectFilterType('client_id');
// → FilterType.cliente

final type = FilterBuilder.detectFilterType('start_date');
// → FilterType.date

final type = FilterBuilder.detectFilterType('cobrador_name');
// → FilterType.cobrador
```

---

## 🔍 Búsqueda de clases

### Formateo y transformación
- `ReportFormatters` - Todas las conversiones, formateo, cálculos
- `DateRangeHelper` - Rangos de fecha rápidos
- `FilterLabelTranslator` - Traducción de labels

### UI y construcción
- `FilterBuilder` - Construcción de filtros
- `SummaryCardsBuilder` - Tarjetas de resumen
- `GenericReportBuilder` - Renderizado genérico
- `ReportTable` - Tabla genérica

### Vistas y reportes
- `BaseReportView` - Clase base abstracta
- `ReportViewFactory` - Factory para crear vistas
- `PaymentsReportView` - Reporte de pagos
- `CreditsReportView` - Reporte de créditos
- `BalancesReportView` - Reporte de balances

### Estado y lógica
- `ReportStateHelper` - Gestión de estado
- `ReportsScreen` - Pantalla principal

### Widgets
- `DateFilterField` - Selector de fecha
- `SearchSelectField` - Búsqueda y selección
- `MiniStatCard` - Tarjeta estadística
- `PaymentsListWidget` - Lista de pagos
- `CreditsListWidget` - Lista de créditos
- `BalancesListWidget` - Lista de balances

---

## 📊 Dónde poner código nuevo

| Necesidad | Dónde poner | Archivo |
|-----------|-----------|---------|
| Formatear fecha/moneda | Clase estática | `report_formatters.dart` |
| Extraer dato anidado | Método extractor | `report_formatters.dart` |
| Traducir label | Diccionario | `filter_helpers.dart` |
| Nuevo tipo de filtro | Enum + builder | `filter_builder.dart` |
| Rango de fecha | Helper | `date_range_helper.dart` |
| Vista especializada | Heredar BaseReportView | `views/` |
| Componente UI | StatelessWidget/StatefulWidget | `widgets/` |
| Lógica de estado | Método estático | `report_state_helper.dart` |

---

## 🎨 Patrones utilizados

| Patrón | Ubicación | Beneficio |
|--------|-----------|-----------|
| Factory | `ReportViewFactory` | Crear vistas sin acoplamiento |
| Strategy | `BaseReportView` subclasses | Diferentes algoritmos intercambiables |
| Template Method | `BaseReportView` | Estructura común, detalles específicos |
| Builder | `FilterBuilder`, `SummaryCardsBuilder` | Construcción paso a paso |
| DRY | `ReportFormatters`, `FilterLabelTranslator` | Una fuente de verdad |

---

## ⚠️ Errores comunes

### ❌ Crear función de formateo local
```dart
// MAL
String _formatCurrency(double val) {
  return '\$${val.toStringAsFixed(2)}';
}
```
**✅ Correcto:**
```dart
final str = ReportFormatters.formatCurrency(value);
```

---

### ❌ Traducir label inline
```dart
// MAL
label: 'Monto Total'  // Qué pasa si cambia?
```
**✅ Correcto:**
```dart
label: FilterLabelTranslator.translate('total_amount')
```

---

### ❌ Extraer cliente sin usar helper
```dart
// MAL
final name = payment['client']?['name'] ?? 'Unknown';
```
**✅ Correcto:**
```dart
final name = ReportFormatters.extractPaymentClientName(payment);
```

---

### ❌ Crear vista sin heredar BaseReportView
```dart
// MAL
class MyReportView extends StatelessWidget { }
```
**✅ Correcto:**
```dart
class MyReportView extends BaseReportView { }
```

---

### ❌ Mezclar lógica con UI en ReportsScreen
```dart
// MAL
setState(() {
  _currentRequest = rp.ReportRequest(
    type: _selectedReport ?? '',
    filters: Map<String, dynamic>.from(_filters),
    format: _format,
  );
});
```
**✅ Correcto:**
```dart
setState(() {
  _currentRequest = ReportStateHelper.createReportRequest(
    reportType: _selectedReport ?? '',
    filters: _filters,
    format: _format,
  );
});
```

---

## 🔗 Dependencias comunes

```
ReportsScreen
  → FilterBuilder (crear filtros)
  → ReportStateHelper (crear requests)
  → ReportViewFactory (crear vistas)

BaseReportView
  → ReportFormatters (formateo)
  → Widgets especializados (UI)

Todos los widgets
  → ReportFormatters (formateo consistente)
  → FilterLabelTranslator (traducciones)
```

---

## 🚀 Importes más comunes

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Utils
import 'utils/report_formatters.dart';
import 'utils/filter_builder.dart';
import 'utils/report_state_helper.dart';
import 'utils/filter_helpers.dart';
import 'utils/generic_report_builder.dart';

// Views
import 'views/base_report_view.dart';
import 'views/report_view_factory.dart';

// Widgets
import 'widgets/report_table.dart';
import 'widgets/summary_cards_builder.dart';

// Provider
import '../../negocio/providers/reports_provider.dart' as rp;
```

---

## 📞 Dónde conseguir ayuda

1. **Entender la arquitectura** → `ARCHITECTURE.md`
2. **Ver diagramas** → `DIAGRAMS.md`
3. **Encontrar rápidamente** → Este archivo (QUICK_REFERENCE.md)
4. **Leer comentarios en código** → Clases principales tienen doc comments
5. **Explorar ejemplos** → Ver vistas existentes (PaymentsReportView, CreditsReportView)

---

## ✅ Checklist para nueva vista

- [ ] Hereda de `BaseReportView`
- [ ] Implementa `buildReportContent()`
- [ ] Implementa `getReportTitle()`
- [ ] Implementa `getReportIcon()`
- [ ] Registrada en `ReportViewFactory`
- [ ] Usa `ReportFormatters` para todo formateo
- [ ] Usa `FilterLabelTranslator` para labels
- [ ] Archivos organizados en `views/`
- [ ] Doc comments en la clase
- [ ] Ejemplo en los comentarios

---

## ✅ Checklist para nuevo helper

- [ ] Es una función estática sin estado
- [ ] Puesto en la carpeta `utils/`
- [ ] Nombrado significativamente
- [ ] Usa nombres de métodos claros
- [ ] Tiene doc comments
- [ ] Centraliza lógica duplicada
- [ ] Fácil de testear

---

## Resumen de mejora

**Antes de refactorización:**
- ❌ ~600 líneas de código duplicado
- ❌ 9 vistas placeholder sin implementación
- ❌ Helpers locales en múltiples widgets
- ❌ Responsabilidades mezcladas

**Después de refactorización:**
- ✅ DRY (Don't Repeat Yourself)
- ✅ 12+ vistas funcionales
- ✅ Helpers centralizados
- ✅ Separación clara de responsabilidades
- ✅ Arquitectura documentada y comprensible

---

**Última actualización:** 2024
**Versión:** 1.0
**Mantenedor:** El equipo de desarrollo
