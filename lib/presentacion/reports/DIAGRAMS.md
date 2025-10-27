# Diagramas de Arquitectura - Módulo de Reportes

## 1. Flujo General de Generación de Reportes

```
┌──────────────────────────────────────────────────────────────────────┐
│                          USER INTERACTION                             │
│  • Selecciona tipo de reporte                                         │
│  • Configura filtros                                                  │
│  • Selecciona rango de fecha                                          │
│  • Presiona "Generar"                                                 │
└──────────────────────────┬───────────────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────────┐
        │      ReportsScreen (StatefulWidget)   │
        │  ────────────────────────────────     │
        │  • Selector de reportes               │
        │  • Panel de filtros colapsable        │
        │  • Rango de fecha rápido              │
        │  • Estado: _filters, _selectedReport  │
        └──────────────┬───────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
   ┌────────────┐ ┌────────────┐ ┌─────────────┐
   │FilterBuilder│ │ReportState │ │ReportViewFactory
   │            │ │Helper      │ │             │
   │• Detecta   │ │            │ │• Detecta    │
   │  tipo de   │ │• Crea      │ │  tipo de    │
   │  filtro    │ │  request   │ │  reporte    │
   │• Crea      │ │• Aplica    │ │• Crea vista │
   │  widgets   │ │  rango     │ │  apropiada  │
   │  UI        │ │  fecha     │ │             │
   └────────────┘ └────────────┘ └─────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │     ReportRequest (Model)             │
        │  ────────────────────────────────    │
        │  • type: String (payments, credits)   │
        │  • filters: Map<String, dynamic>      │
        │  • format: String (json/excel/pdf)    │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │        Backend API / Provider         │
        │  generateReportProvider(request)      │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │          Payload (Response)           │
        │  Map<String, dynamic> o List          │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │    _ReportResultView (ConsumerWidget)│
        │  ────────────────────────────────    │
        │  • Muestra resultado del reporte      │
        │  • Maneja estados de carga/error      │
        └──────────────┬───────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │   ReportViewFactory.createView()     │
        │  ────────────────────────────────    │
        │  Analiza payload, retorna vista       │
        │  apropiada según contenido            │
        └──────────────┬───────────────────────┘
                       │
        ┌──────────────┼──────────────────────┐
        ▼              ▼                      ▼
   ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐
   │Specialized  │  │Fallback      │  │Generic           │
   │Views        │  │Views         │  │Report Builder    │
   │             │  │              │  │                  │
   │• Payments   │  │• Generic     │  │• buildMapReport()│
   │• Credits    │  │• GenericList │  │• buildListReport│
   │• Balances   │  │• GenericMap  │  │• buildAutomatic()
   │• Overdue    │  │              │  │                  │
   │• etc.       │  │              │  │Renderiza datos   │
   │             │  │              │  │sin vista custom  │
   │Custom UI +  │  │Placeholder   │  │                  │
   │Widgets      │  │genéricos     │  │                  │
   └─────────────┘  └──────────────┘  └──────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────────┐
        │      UI Renderizada al Usuario       │
        │  • Tablas de datos                    │
        │  • Tarjetas de resumen                │
        │  • Gráficos (si aplica)               │
        │  • Botones de descarga                │
        └──────────────────────────────────────┘
```

---

## 2. Árbol de Dependencias

```
ReportsScreen
│
├─► FilterBuilder
│   ├─► FilterType (enum)
│   ├─► FilterLabelTranslator
│   ├─► DateFilterField
│   ├─► SearchSelectField
│   └─► TextFormField
│
├─► ReportStateHelper
│   ├─► ReportRequest (model)
│   ├─► DateRangeHelper
│   ├─► ChoiceChip (UI)
│   └─► ColorScheme
│
├─► ReportViewFactory
│   ├─► BaseReportView (clase abstracta)
│   │   ├─► PaymentsReportView
│   │   ├─► CreditsReportView
│   │   ├─► BalancesReportView
│   │   ├─► OverdueReportView
│   │   ├─► PerformanceReportView
│   │   ├─► CommissionReportView
│   │   ├─► AnalysisReportView
│   │   └─► StatisticalReportView
│   │
│   └─► GenericReportBuilder
│       ├─► ReportTable
│       ├─► CircleAvatar (UI)
│       ├─► Column/Row (layout)
│       └─► Text/Chip (UI)
│
└─► ReportFormatters (utils)
    ├─► Formatters (estáticos)
    ├─► Extractors (anidados)
    ├─► ColorMappers
    ├─► IconMappers
    └─► Calculators
```

---

## 3. Vista de Capas

```
┌─────────────────────────────────────────────────────────┐
│                 PRESENTATION LAYER                       │
│  ┌────────────────────────────────────────────────────┐ │
│  │ ReportsScreen (StatefulWidget)                     │ │
│  │ • UI principal                                     │ │
│  │ • Gestión de estado local                          │ │
│  │ • Coordina componentes                             │ │
│  └────────────────────────────────────────────────────┘ │
│                                                         │
│  ┌──────────────────┬─────────────────┬───────────────┐ │
│  │ Views Layer      │ Widgets Layer   │ Utils Layer   │ │
│  ├──────────────────┼─────────────────┼───────────────┤ │
│  │ BaseReportView   │ ReportTable     │ FilterBuilder │ │
│  │ • Template base  │ • Tabla genérica│ • Detectores  │ │
│  │ • Abstract       │ • Renderizado   │ • Builders    │ │
│  │                  │   flexible      │               │ │
│  │ Specialized:     │                 │ ReportState   │ │
│  │ • Payments       │ MiniStatCard    │ Helper        │ │
│  │ • Credits        │ • Tarjeta       │ • Lógica      │ │
│  │ • Balances       │ • Estadística   │ • Validación  │ │
│  │ • Overdue        │                 │               │ │
│  │ • Performance    │ [+5 widgets]    │ ReportFormat  │ │
│  │ • Commission     │                 │ ters          │ │
│  │ • Analysis       │ SummaryCards    │ • Formateo    │ │
│  │ • Statistical    │ Builder         │ • Extracción  │ │
│  │                  │ • Tarjetas      │ • Mapeo       │ │
│  │ Generic Views:   │   genéricas     │ • Cálculos    │ │
│  │ • GenericList    │ • Reutilizable  │               │ │
│  │ • GenericMap     │                 │ Filter        │ │
│  │ • Generic        │ GenericReport   │ Label         │ │
│  │                  │ Builder         │ Translator    │ │
│  │                  │ • Renderizado   │ • Traducciones│ │
│  │                  │   automático    │ • Una fuente  │ │
│  │                  │ • Fallback      │   de verdad   │ │
│  └──────────────────┴─────────────────┴───────────────┘ │
│                                                         │
│  ReportViewFactory (Strategy Pattern)                   │
│  • Detecta tipo de reporte                              │
│  • Crea vista apropiada                                 │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  BUSINESS LAYER                          │
│  ReportsProvider (Riverpod)                              │
│  • Genera reportes                                       │
│  • Cachea resultados                                     │
│  • Maneja errores                                        │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────┐
│                  DATA LAYER                              │
│  Backend API / Repository                                │
│  • Consulta base de datos                                │
│  • Aplica filtros                                        │
│  • Retorna payload                                       │
└─────────────────────────────────────────────────────────┘
```

---

## 4. Detección de Tipo de Reporte

```
ReportViewFactory.createView(payload)
│
├─► Analiza payload (Map keys)
│
├─ "payments" → PaymentsReportView
│   └─ Tabla de pagos + Estadísticas
│
├─ "credits" → Detectar subtipo
│   ├─ "total_overdue_credits" → OverdueReportView
│   ├─ "total_in_waiting_list" → WaitingListReportView
│   └─ (default) → CreditsReportView
│
├─ "balances" → BalancesReportView
│   └─ Tabla de balances + Cálculo diferencias
│
├─ "performance" → PerformanceReportView
│   └─ Datos de desempeño (genérico)
│
├─ "activities" → DailyActivityReportView
│   └─ Actividades diarias (genérico)
│
├─ "projections" → CashFlowForecastReportView
│   └─ Proyecciones de flujo (genérico)
│
├─ "portfolio_by_cobrador" → PortfolioReportView
│   └─ Cartera por cobrador (genérico)
│
├─ "commissions" → CommissionsReportView
│   └─ Comisiones (genérico)
│
├─ "users" → UsersReportView
│   └─ Usuarios (genérico)
│
├─ (Es List) → GenericListReportView
│   └─ Tabla genérica desde lista
│
├─ (Es Map) → GenericMapReportView
│   └─ Tabla genérica desde mapa
│
└─ (default) → GenericReportView
    └─ Renderizado automático
```

---

## 5. Flujo de Filtros

```
ReportsScreen._buildFiltersFor(typeDef)
│
├─► Obtiene lista de filtros desde definición
│
└─► Para cada filtro:
    │
    ├─► FilterBuilder.detectFilterType(filterKey)
    │   ├─ "date" → FilterType.date
    │   ├─ "cobrador" → FilterType.cobrador
    │   ├─ "cliente" → FilterType.cliente
    │   ├─ "categoria" → FilterType.categoria
    │   └─ (default) → FilterType.text
    │
    ├─► FilterBuilder.buildFilterWidget(type)
    │   ├─ FilterType.date
    │   │   └─► DateFilterField
    │   │       ├─ Solo si isManualDateRange
    │   │       └─ onChanged → _filters[key] = value
    │   │
    │   ├─ FilterType.cobrador/cliente/categoria
    │   │   └─► SearchSelectField
    │   │       ├─ type: 'cobrador'/'cliente'/'categoria'
    │   │       └─ onSelected → _filters[key] = id/name
    │   │
    │   └─ FilterType.text
    │       └─► TextFormField
    │           └─ onChanged → _filters[key] = value
    │
    ├─► Traducir label
    │   └─► FilterLabelTranslator.translate(key)
    │       ├─ Búsqueda exacta en diccionario
    │       ├─ Búsqueda por palabras clave
    │       └─ Humanizar si no hay traducción
    │
    └─► Retornar Widget con Padding
        └─ Espaciado consistente
```

---

## 6. Flujo de Formateado

```
Widget → ReportFormatters (utilidad centralizada)
│
├─► Formateo de datos
│   ├─ formatDate(val) → "25/12/2023"
│   ├─ formatTime(val) → "14:30"
│   ├─ formatCurrency(val) → "$1,234.56"
│   ├─ toDouble(val) → 1234.56
│   └─ toNumericValue(val) → 1234.56
│
├─► Extracción de datos anidados
│   ├─ _getNestedValue(data, paths)
│   │   └─ Método genérico para valores anidados
│   │
│   ├─ extractPaymentClientName(payment)
│   │   ├─ payment['client']['name']
│   │   ├─ payment['credit']['client']['name']
│   │   └─ payment['client_name']
│   │
│   ├─ extractPaymentCobradorName(payment)
│   │   ├─ payment['cobrador']['name']
│   │   ├─ payment['cobrador_name']
│   │   └─ payment['deliveredBy']['name']
│   │
│   └─ [+5 extractores más]
│
├─► Cálculo de valores
│   ├─ pickAmount(data, keys)
│   │   └─ Intenta múltiples claves
│   │
│   └─ computeBalanceDifference(data)
│       └─ final - (initial + collected - lent)
│
├─► Mapeo de colores
│   ├─ colorForStatus(status)
│   ├─ colorForPaymentMethod(method)
│   ├─ colorForFrequency(freq)
│   ├─ colorForCreditStatus(status)
│   ├─ colorForDifference(diff)
│   └─ colorForSeverity(severity)
│
└─► Mapeo de iconos
    └─ iconForPaymentMethod(method)
```

---

## 7. Patrón Template Method en BaseReportView

```
BaseReportView (clase abstracta)
│
└─► build(context, ref) [método template]
    │
    ├─► buildReportHeader()
    │   ├─ Información del reporte
    │   ├─ Request info (tipo, fecha)
    │   └─ Payload info (tamaño, estructuras)
    │
    ├─► buildReportSummary()
    │   └─ Opcional (sobrescribible)
    │
    ├─► buildReportContent() ◄─── ABSTRACTO
    │   └─ Implementado por subclases
    │       ├─ PaymentsReportView
    │       ├─ CreditsReportView
    │       ├─ BalancesReportView
    │       └─ [otros]
    │
    └─► buildReportFooter()
        └─ Información adicional (opcional)

Beneficios:
✓ Estructura uniforme
✓ Menor duplicación
✓ Fácil de extender
✓ Consistencia garantizada
```

---

## 8. Estrategia de Renderizado

```
GenericReportBuilder.buildAutomatic(payload)
│
├─► ¿Es Map?
│   └─► buildMapReport(payload)
│       ├─ Convertir keys a columnas
│       ├─ Convertir values a filas
│       └─ Renderizar ReportTable
│           └─ Tabla scrollable horizontal
│
├─► ¿Es List<Map>?
│   └─► buildListReport(payload)
│       ├─ Usar primeras 10 items como ejemplo
│       ├─ Extraer keys como columnas
│       └─ Renderizar ReportTable
│           └─ Tabla scrollable
│
├─► ¿Es List<dynamic>?
│   └─► buildListReport(payload)
│       ├─ Valores simples
│       └─ Renderizar como Chips
│           ├─ Color azul uniforme
│           ├─ Wrap spacing 8
│           └─ Run spacing 8
│
└─► (Error/Vacío)
    ├─► isEmpty → _buildEmptyWidget()
    │   ├─ Icono de inbox
    │   ├─ Mensaje "No hay datos"
    │   └─ Color gris suave
    │
    └─► Error → _buildErrorWidget(message)
        ├─ Icono de error
        ├─ Mensaje de error
        └─ Color rojo suave
```

---

## 9. Decisión de Vista Especializada vs Genérica

```
¿Necesita vista especializada?
│
├─ SÍ si:
│  ├─ Tiene layout completamente diferente
│  ├─ Usa widgets muy específicos
│  ├─ Tiene interactividad compleja
│  └─ Requiere gráficos/análisis especial
│
│  → Heredar de BaseReportView
│  → Registrar en ReportViewFactory
│  → Implementar buildReportContent()
│
└─ NO si:
   ├─ Solo necesita mostrar datos
   ├─ Tabla simple es suficiente
   ├─ No hay cálculos complejos
   └─ No hay UI diferente

   → Usar GenericReportBuilder
   → GenericReportBuilder detecta tipo
   → Renderiza tabla/chips automáticamente
```

---

## 10. Ciclo de vida de generación de reporte

```
1. Usuario selecciona reporte
   └─► setState() actualiza _selectedReport

2. Usuario configura filtros
   └─► FilterBuilder crea widgets
   └─► onChanged → _filters[key] = value

3. Usuario presiona "Generar"
   └─► _generateReport()
   └─► setState() crea _currentRequest

4. Provider ejecuta
   └─► Backend consulta DB
   └─► Aplica filtros
   └─► Retorna payload

5. UI actualiza
   └─► _ReportResultView renderiza

6. Factory detecta tipo
   └─► ReportViewFactory.createView()
   └─► Analiza payload
   └─► Retorna vista apropiada

7. Vista renderiza
   └─► BaseReportView.build() o GenericReportBuilder
   └─► Construye UI final
   └─► Usuario ve reporte

8. Usuario exporta (opcional)
   └─► ReportDownloadHelper.download()
   └─► Excel/PDF
```

---

## 11. Componentes Reutilizables

```
┌─────────────────────────────────────────────────┐
│           COMPONENTES REUTILIZABLES             │
├─────────────────────────────────────────────────┤
│                                                 │
│ ReportTable                                     │
│ └─ Tabla genérica scrollable                    │
│    └─ Usado por: GenericReportBuilder           │
│                                                 │
│ MiniStatCard                                    │
│ └─ Tarjeta de estadística                       │
│    └─ Usado por: SummaryCardsBuilder            │
│       └─ Usado por: Payments/Credits/Balances   │
│                                                 │
│ SummaryCardsBuilder                             │
│ └─ Constructor de tarjetas genérico             │
│    └─ Configurable con SummaryCardConfig        │
│       └─ Usado por: 3+ vistas especializadas    │
│                                                 │
│ DateFilterField                                 │
│ └─ Selector de fecha                            │
│    └─ Usado por: FilterBuilder                  │
│       └─ Usado por: Todos los reportes          │
│                                                 │
│ SearchSelectField                               │
│ └─ Búsqueda y selección                         │
│    └─ Tipos: cobrador, cliente, categoría       │
│       └─ Usado por: FilterBuilder               │
│          └─ Usado por: Todos los reportes       │
│                                                 │
│ PaymentsListWidget                              │
│ └─ Lista de pagos con tarjetas                  │
│    └─ Usado por: PaymentsReportView             │
│                                                 │
│ CreditsListWidget                               │
│ └─ Lista de créditos con progreso               │
│    └─ Usado por: CreditsReportView              │
│                                                 │
│ BalancesListWidget                              │
│ └─ Lista de balances con diferencias            │
│    └─ Usado por: BalancesReportView             │
│                                                 │
└─────────────────────────────────────────────────┘
```

---

## Conclusión

Esta arquitectura proporciona:
- ✅ **Extensibilidad**: Fácil agregar nuevos tipos
- ✅ **Mantenibilidad**: DRY, SRP, patrones claros
- ✅ **Reusabilidad**: Componentes modulares
- ✅ **Testabilidad**: Componentes desacoplados
- ✅ **Escalabilidad**: Soporta múltiples tipos de reportes

Para preguntas o aclaraciones, revisar `ARCHITECTURE.md` o comentarios en código.
