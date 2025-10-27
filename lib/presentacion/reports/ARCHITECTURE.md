# Arquitectura del Módulo de Reportes

## 📋 Tabla de contenidos

1. [Visión general](#visión-general)
2. [Estructura de directorios](#estructura-de-directorios)
3. [Componentes principales](#componentes-principales)
4. [Flujo de datos](#flujo-de-datos)
5. [Patrones de diseño](#patrones-de-diseño)
6. [Guía de extensión](#guía-de-extensión)

---

## 🎯 Visión general

El módulo de reportes es responsable de:
- Generar reportes de diferentes tipos (pagos, créditos, balances, etc.)
- Mostrar datos de forma clara y legible
- Permitir filtrado y búsqueda de datos
- Exportar reportes en múltiples formatos

**Arquitectura**: Presentación > Vistas > Widgets + Utilidades

**Patrón principal**: Factory + Strategy + Template Method

---

## 📁 Estructura de directorios

```
lib/presentacion/reports/
├── reports_screen.dart                 # Pantalla principal (UI + estado)
├── ARCHITECTURE.md                     # Este archivo
│
├── views/                              # Vistas especializadas por tipo
│   ├── base_report_view.dart           # Clase base abstracta
│   ├── payments_report_view.dart       # Reporte de pagos
│   ├── credits_report_view.dart        # Reporte de créditos
│   ├── balances_report_view.dart       # Reporte de balances
│   ├── portfolio_report_view.dart      # Reporte de cartera
│   ├── performance_report_view.dart    # Reporte de desempeño
│   ├── commission_report_view.dart     # Reporte de comisiones
│   ├── analysis_report_view.dart       # Reporte de análisis
│   ├── statistical_report_view.dart    # Reporte estadístico
│   ├── report_view_factory.dart        # Factory para crear vistas
│   └── views.dart                      # Barrel file
│
├── widgets/                            # Componentes reutilizables
│   ├── mini_stat_card.dart             # Tarjeta de estadística
│   ├── report_table.dart               # Tabla genérica
│   ├── date_filter_field.dart          # Campo de fecha
│   ├── search_select_field.dart        # Campo de búsqueda
│   ├── download_buttons_widget.dart    # Botones de descarga
│   ├── summary_cards_builder.dart      # Constructor genérico de tarjetas
│   ├── payments_list_widget.dart       # Lista de pagos
│   ├── credits_list_widget.dart        # Lista de créditos
│   ├── balances_list_widget.dart       # Lista de balances
│   ├── [otros widgets especializados]
│   ├── widgets.dart                    # Barrel file
│   └── commission_widgets.dart
│
└── utils/                              # Utilidades sin estado
    ├── report_formatters.dart          # Formateo de datos
    ├── date_range_helper.dart          # Rangos de fecha rápidos
    ├── filter_helpers.dart             # Traducción de filtros
    ├── report_download_helper.dart     # Descarga de reportes
    ├── filter_builder.dart             # Constructor de filtros
    ├── report_state_helper.dart        # Gestión de estado
    ├── generic_report_builder.dart     # Renderizado genérico
    └── [otros helpers]
```

---

## 🔧 Componentes principales

### 1. **ReportsScreen** (`reports_screen.dart`)
**Responsabilidad**: UI principal + gestión de estado

**Características**:
- Selector de tipo de reporte
- Panel colapsable de filtros
- Rango rápido de fechas
- Generación de reportes

**Estado**:
```dart
String? _selectedReport;              // Tipo de reporte seleccionado
Map<String, dynamic> _filters;        // Filtros aplicados
String _format;                       // Formato (json/excel/pdf)
int? _quickRangeIndex;                // Índice de rango rápido
bool _showFilters;                    // Panel de filtros visible
rp.ReportRequest? _currentRequest;    // Request actual para generar
```

**Dependencias**:
- `FilterBuilder`: Construye widgets de filtros
- `ReportStateHelper`: Gestiona estado y lógica
- `ReportViewFactory`: Crea vistas apropiadas

---

### 2. **BaseReportView** (`base_report_view.dart`)
**Patrón**: Template Method

**Responsabilidad**: Clase abstracta que define estructura común para todas las vistas

**Métodos abstractos**:
- `buildReportContent()`: Contenido específico del reporte

**Métodos concretos**:
- `build()`: Estructura general (header + contenido + footer)
- `buildReportHeader()`: Header con información básica
- `buildPayloadInfo()`: Info del payload (tipo, tamaño)
- `buildReportSummary()`: Resumen opcional (sobrescribible)

**Ejemplo**:
```dart
class PaymentsReportView extends BaseReportView {
  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    // Implementar contenido específico
  }
}
```

---

### 3. **ReportViewFactory** (`report_view_factory.dart`)
**Patrón**: Factory + Strategy

**Responsabilidad**: Detectar tipo de reporte y crear vista apropiada

**Flujo**:
1. Analiza el payload (keys del Map)
2. Determina el tipo de reporte
3. Retorna la vista correspondiente

**Ejemplo de detección**:
```dart
if (payload.containsKey('payments')) {
  return PaymentsReportView(...);
} else if (payload.containsKey('credits')) {
  // Detectar si es mora o lista de espera
  return CreditsReportView(...);
}
```

**Vistas especializadas**:
- `PaymentsReportView`: Pagos con tablas y estadísticas
- `CreditsReportView`: Créditos con barras de progreso
- `BalancesReportView`: Balances con cálculo de diferencias
- Vistas genéricas fallback para reportes no específicos

---

### 4. **FilterBuilder** (`filter_builder.dart`)
**Responsabilidad**: Construir widgets de filtros dinámicamente

**Flujo**:
1. `detectFilterType()`: Identifica tipo de filtro (date/cobrador/text)
2. `buildFilterWidget()`: Crea widget apropiado
3. `buildFiltersForReportType()`: Construye lista completa

**Tipos de filtro**:
- `FilterType.date`: DateFilterField
- `FilterType.cobrador`: SearchSelectField (cobrador)
- `FilterType.cliente`: SearchSelectField (cliente)
- `FilterType.categoria`: SearchSelectField (categoría)
- `FilterType.text`: TextFormField

---

### 5. **ReportStateHelper** (`report_state_helper.dart`)
**Responsabilidad**: Gestionar estado y lógica de reportes

**Funciones clave**:
- `createReportRequest()`: Crea ReportRequest
- `applyQuickDateRange()`: Aplica rango de fecha rápido
- `clearDateFilters()`: Limpia filtros de fecha
- `buildQuickRangeChips()`: Construye chips de rango rápido
- `isManualDateRange()`: Verifica si está en modo manual

---

### 6. **ReportFormatters** (`report_formatters.dart`)
**Responsabilidad**: Formatear y extraer datos

**Categorías**:

**Formateadores**:
- `formatDate()`: dd/MM/yyyy
- `formatTime()`: HH:mm
- `formatCurrency()`: $X.XX

**Extractores de datos**:
- `extractPaymentClientName()`: Extrae nombre del cliente desde pago
- `extractPaymentCobradorName()`: Extrae cobrador desde pago
- `_getNestedValue()`: Método genérico para valores anidados

**Calculadores**:
- `toDouble()`: Convierte a double
- `pickAmount()`: Extrae monto con múltiples claves posibles
- `computeBalanceDifference()`: Calcula diferencia de balance

**Mapeo de colores**:
- `colorForStatus()`: Color según estado
- `colorForPaymentMethod()`: Color según método
- `colorForFrequency()`: Color según frecuencia
- `colorForDifference()`: Color según si es positivo/negativo

**Mapeo de iconos**:
- `iconForPaymentMethod()`: Icono según método

---

### 7. **GenericReportBuilder** (`generic_report_builder.dart`)
**Responsabilidad**: Renderizar datos sin estructura específica

**Métodos**:
- `buildMapReport()`: Renderiza Map como tabla
- `buildListReport()`: Renderiza List como tabla o chips
- `buildAutomatic()`: Detecta tipo y renderiza automáticamente

**Ventajas**:
- Sin necesidad de vistas especializadas para cada tipo
- Renderizado consistente
- Estados vacío/error manejados

---

### 8. **SummaryCardsBuilder** (`summary_cards_builder.dart`)
**Responsabilidad**: Construir tarjetas de resumen reutilizables

**Configuración**:
```dart
SummaryCardConfig(
  title: 'Total Pagos',
  summaryKey: 'total_payments',
  icon: Icons.payments,
  color: Colors.green,
  formatter: (value) => '$value',
)
```

**Ventajas**:
- Elimina duplicación de tarjetas
- Configuración limpia y reutilizable
- Soporta formatters personalizados

---

## 📊 Flujo de datos

```
┌─────────────────────────────────────────────────────────────────┐
│ ReportsScreen (UI + Estado)                                     │
│ • Selector de reporte                                           │
│ • Panel de filtros (colapsable)                                │
│ • Rango de fecha rápido                                        │
└────────────────────┬────────────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ▼                       ▼
    FilterBuilder        ReportStateHelper
    • Detecta tipo      • Crea request
    • Crea widgets      • Aplica rango fecha
                        • Valida estado

                     │
         ┌───────────┴───────────┐
         ▼                       ▼
   generateReport()        Provider
   • Crea request           • Ejecuta backend
   • Actualiza estado       • Retorna payload

                     │
         ┌───────────┴───────────┐
         ▼                       ▼
  ReportViewFactory      _ReportResultView
  • Detecta tipo         • Muestra resultado
  • Crea vista           • Maneja errores

                     │
         ┌───────────┴──────────────────┐
         ▼                              ▼
  BaseReportView          GenericReportBuilder
  (especializada)         (fallback genérico)
  • PaymentsReportView    • buildMapReport()
  • CreditsReportView     • buildListReport()
  • BalancesReportView    • buildAutomatic()

                     │
         ┌───────────┴──────────────────┐
         ▼                              ▼
   SummaryCardsBuilder        ReportTable
   • Tarjetas de resumen      • Tabla genérica
   • Estadísticas             • Renderizado flexible

                     │
         ┌───────────┴──────────────────┐
         ▼                              ▼
  ReportFormatters          [Widgets especializados]
  • Formateo                • PaymentsListWidget
  • Extracción              • CreditsListWidget
  • Colores/Iconos          • BalancesListWidget
```

---

## 🎨 Patrones de diseño

### 1. **Factory Pattern**
**Ubicación**: `ReportViewFactory`

**Propósito**: Crear vistas apropiadas sin acoplamiento

```dart
// Cliente no necesita saber qué vista crear
final view = ReportViewFactory.createView(
  request: request,
  payload: payload,
);
```

---

### 2. **Strategy Pattern**
**Ubicación**: Diferentes `BaseReportView` subclasses

**Propósito**: Diferentes algoritmos (vistas) intercambiables

```dart
// Cada vista es una estrategia diferente
PaymentsReportView vs CreditsReportView
→ Mismo interfaz, diferente implementación
```

---

### 3. **Template Method Pattern**
**Ubicación**: `BaseReportView`

**Propósito**: Define estructura, deja detalles a subclases

```dart
// BaseReportView.build()
1. buildReportHeader()       // Implementado
2. buildReportSummary()      // Sobrescribible
3. buildReportContent()      // Abstracto
4. buildReportFooter()       // Implementado
```

---

### 4. **Builder Pattern**
**Ubicación**: `FilterBuilder`, `SummaryCardsBuilder`, `GenericReportBuilder`

**Propósito**: Construir estructuras complejas paso a paso

```dart
// Construcción paso a paso
FilterBuilder.buildFiltersForReportType(
  reportTypeDefinition: ...,
  currentFilters: ...,
  isManualDateRange: ...,
  onFilterChanged: ...,
)
```

---

### 5. **DRY (Don't Repeat Yourself)**
**Implementado en**:
- `ReportFormatters`: Centraliza todo formateo
- `FilterLabelTranslator`: Una fuente de verdad para traducciones
- `GenericReportBuilder`: Renderizado genérico reutilizable

---

## 🚀 Guía de extensión

### Caso 1: Agregar nuevo tipo de reporte

**1. Crear vista especializada**:
```dart
// lib/presentacion/reports/views/my_report_view.dart
class MyReportView extends BaseReportView {
  @override
  String getReportTitle() => 'Mi Reporte';

  @override
  IconData getReportIcon() => Icons.my_icon;

  @override
  Widget buildReportContent(BuildContext context, WidgetRef ref) {
    // Implementar contenido
    return MyCustomWidget(payload: payload);
  }
}
```

**2. Registrar en Factory**:
```dart
// report_view_factory.dart
if (payload.containsKey('my_data')) {
  return MyReportView(request: request, payload: payload);
}
```

---

### Caso 2: Agregar nuevo tipo de filtro

**1. Actualizar `FilterBuilder`**:
```dart
static FilterType detectFilterType(String filterKey) {
  if (filterKey.contains('my_filter')) {
    return FilterType.myFilter;  // Agregar enum
  }
  // ...
}

static Widget buildFilterWidget({
  required FilterType type,
  // ...
}) {
  switch (type) {
    case FilterType.myFilter:
      return MyCustomFilterWidget(...);
    // ...
  }
}
```

**2. Actualizar `FilterLabelTranslator`** (si es necesario):
```dart
static const Map<String, String> _translations = {
  'my_filter': 'Mi Filtro',
  // ...
};
```

---

### Caso 3: Agregar nuevo formateador

```dart
// report_formatters.dart
class ReportFormatters {
  // ...

  /// Formatea valor como porcentaje
  static String formatPercentage(dynamic val) {
    final d = toDouble(val);
    return '${(d * 100).toStringAsFixed(1)}%';
  }
}

// Usar en widget
final percentStr = ReportFormatters.formatPercentage(0.85);
// → "85.0%"
```

---

## 📚 Mejores prácticas

### ✅ Hacer

1. **Usar `ReportFormatters`** para todo formateo
   - Centraliza lógica
   - Consistencia garantizada

2. **Heredad de `BaseReportView`** para nuevas vistas
   - Estructura uniforme
   - Menor código duplicado

3. **Usar `FilterBuilder`** para construir filtros
   - Detección automática
   - Widgets apropiados

4. **Documentar cambios** en ARCHITECTURE.md
   - Mantiene documentación actualizada

### ❌ No hacer

1. **No crear funciones de formateo locales**
   - Usa `ReportFormatters`
   - Evita duplicación

2. **No crear vistas sin heredar de `BaseReportView`**
   - Pierdes estructura común
   - Código inconsistente

3. **No mezclar lógica de estado con UI**
   - Usa helpers como `ReportStateHelper`
   - Mantén separación de responsabilidades

4. **No crear nuevas traducciones locales**
   - Usa `FilterLabelTranslator`
   - Una fuente de verdad

---

## 🔗 Dependencias entre módulos

```
ReportsScreen
  ├→ FilterBuilder (construye filtros)
  ├→ ReportStateHelper (gestiona estado)
  ├→ ReportViewFactory (crea vistas)
  │   ├→ BaseReportView (clase base)
  │   │   ├→ PaymentsReportView
  │   │   ├→ CreditsReportView
  │   │   ├→ BalancesReportView
  │   │   └→ [otras vistas especializadas]
  │   └→ GenericReportBuilder (vistas genéricas)
  │       └→ ReportTable
  │
  └→ ReportFormatters (formateo de datos)
      ├→ ReportFormatters.formatCurrency()
      ├→ ReportFormatters.formatDate()
      ├→ ReportFormatters.extractPaymentClientName()
      └→ [otros métodos]

Widgets
  ├→ SummaryCardsBuilder
  │   └→ ReportFormatters
  ├→ PaymentsListWidget
  │   └→ ReportFormatters
  └→ [otros widgets]
      └→ ReportFormatters

Utils
  ├→ ReportFormatters (base)
  ├→ FilterLabelTranslator (traducciones)
  ├→ DateRangeHelper (rangos fecha)
  └→ ReportDownloadHelper (descargas)
```

---

## 📈 Métricas de calidad

### Antes de refactorización:
- Líneas de código duplicado: ~600+
- Número de helpers locales: 15+
- Vistas placeholder: 9
- Violación SRP: Múltiples

### Después de refactorización:
- Líneas de código duplicado: Eliminadas
- Helpers centralizados: 1 (`ReportFormatters`)
- Vistas funcionales: 12+
- Separación clara: Por responsabilidad

---

## 🎯 Conclusión

La arquitectura de reportes está diseñada para ser:
- **Extensible**: Agregar nuevos tipos fácilmente
- **Mantenible**: DRY y separación de responsabilidades
- **Testeable**: Componentes desacoplados
- **Consistente**: Patrones comunes en todas partes

Para más detalles, revisar comentarios en código fuente.
