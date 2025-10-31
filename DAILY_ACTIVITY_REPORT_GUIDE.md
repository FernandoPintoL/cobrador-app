# Guía: Reporte de Actividad Diaria

## Descripción

Se ha implementado un sistema moderno y completo para mostrar el reporte de actividad diaria con:

- **Cards modernas** con resumen visual
- **Tablas interactivas** con datos detallados
- **Chips de estado** para métodos de pago y estados
- **Vista de lista** responsive para dispositivos móviles
- **Filtros por fecha** y vista alternativa (tabla/lista)
- **Modal de detalles** para cada pago individual

## Archivos Creados

### 1. Modelo de Datos
**Ubicación:** `lib/datos/modelos/reporte/daily_activity_report.dart`

Clases principales:
- `DailyActivityReport`: Contenedor principal del reporte
- `DailyActivityItem`: Representa un pago individual
- `DailyActivitySummary`: Resumen general del día
- `CobradorSummary`: Resumen por cobrador

### 2. API Service
**Ubicación:** `lib/datos/api_services/reports_api_service.dart`

Método agregado:
```dart
Future<DailyActivityReport> getDailyActivityReport({
  DateTime? startDate,
  DateTime? endDate,
  int? cobradorId,
  String? paymentMethod,
})
```

Endpoint: `GET /reports/daily-activity?format=json`

### 3. Provider Riverpod
**Ubicación:** `lib/negocio/providers/reports_provider.dart`

Clases y providers:
- `DailyActivityFilters`: Clase inmutable para filtros
- `dailyActivityReportProvider`: FutureProvider.family para obtener datos

```dart
final dailyActivityReportProvider =
  FutureProvider.family<DailyActivityReport, DailyActivityFilters>
```

### 4. Widgets Reutilizables
**Ubicación:** `lib/presentacion/reports/widgets/daily_activity_widgets.dart`

Widgets disponibles:
- `DailyActivitySummaryCard`: Card de resumen con gradiente
- `CobradorSummaryCard`: Card individual por cobrador
- `PaymentMethodChip`: Chip para método de pago (Efectivo/Tarjeta/Transferencia)
- `PaymentStatusChip`: Chip para estado (Completado/Pendiente/Fallido)
- `DailyActivityTable`: Tabla de datos con scroll horizontal
- `DailyActivityCard`: Card para vista de lista
- `DailyActivityListView`: ListView con manejo de vacío

### 5. Vista Principal
**Ubicación:** `lib/presentacion/reports/views/daily_activity_report_view.dart`

`DailyActivityReportView`: ConsumerStatefulWidget con:
- Selector de fecha con DatePicker
- Toggle entre vista de tabla y lista
- Panel de filtros colapsable
- Modal de detalles de cada pago

## Cómo Usar

### Opción 1: Usar la Vista Directamente

```dart
import 'package:app_cobrador/presentacion/reports/views/daily_activity_report_view.dart';

// En tu navegación:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const DailyActivityReportView(),
  ),
);
```

### Opción 2: Integrar con Sistema de Reportes Existente

La vista ya está disponible en `report_view_factory.dart` cuando se selecciona el tipo de reporte `daily-activity`:

```dart
// En reports_screen.dart, seleccionar "daily-activity" como tipo de reporte
// La vista se mostrará automáticamente con soporte para descargas
```

### Opción 3: Usar Widgets Individuales

```dart
import 'package:app_cobrador/presentacion/reports/widgets/daily_activity_widgets.dart';
import 'package:app_cobrador/negocio/providers/reports_provider.dart';

class MiPantalla extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = DailyActivityFilters(
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );

    return ref.watch(dailyActivityReportProvider(filters)).when(
      loading: () => Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('Error: $error'),
      data: (report) {
        return Column(
          children: [
            DailyActivitySummaryCard(summary: report.summary),
            DailyActivityListView(
              items: report.items,
              onItemTap: (item) {
                // Manejar tap en item
              },
            ),
          ],
        );
      },
    );
  }
}
```

## Características Principales

### 1. Card de Resumen (DailyActivitySummaryCard)
- Gradiente con color primario
- Muestra total de pagos y monto recaudado
- Íconos visuales para datos
- Responsive

### 2. Cards por Cobrador (CobradorSummaryCard)
- Avatar circular con inicial
- Información del cobrador (ID, nombre)
- Estadísticas (cantidad de pagos, monto)
- Separador visual

### 3. Chips de Métodos de Pago
- **Efectivo** (verde, icono de dinero)
- **Tarjeta** (azul, icono de tarjeta)
- **Transferencia** (púrpura, icono de banco)
- Estilos personalizados con fondo semitransparente

### 4. Chips de Estado
- **Completado** (verde)
- **Pendiente** (naranja)
- **Fallido** (rojo)
- Compatibles con modo claro y oscuro

### 5. Tabla de Datos (DailyActivityTable)
- Columnas: ID, Cliente, Monto, Método, Fecha, Estado
- Scroll horizontal para pantallas pequeñas
- Header con color de fondo
- Montos formateados en Bs

### 6. Vista de Lista (DailyActivityListView)
- Cards individuales para cada pago
- Información: ID, Cliente, Monto, Método, Fecha, Cobrador
- Tap para ver detalles completos
- Mensaje vacío cuando no hay datos

### 7. Modal de Detalles
- Bottom sheet con scroll
- Secciones: Cliente, Pago, Cobrador, Fechas, Ubicación
- Montos en formato de moneda
- Botón de cierre

## Formato de Datos (JSON)

La API retorna datos en este formato:

```json
{
  "success": true,
  "data": {
    "items": [
      {
        "id": 15,
        "client_id": 47,
        "cobrador_id": 43,
        "credit_id": 24,
        "amount": "300.00",
        "payment_date": "2025-10-28T01:13:19.000000Z",
        "payment_method": "cash",
        "latitude": "-19.34796900",
        "longitude": "-165.12177000",
        "status": "completed",
        "installment_number": 4,
        "cobrador": { ... },
        "credit": { ... }
      }
    ],
    "summary": {
      "total_payments": 2,
      "total_amount": 325,
      "total_amount_formatted": "Bs 325.00",
      "by_cobrador": {
        "43": {
          "count": 2,
          "amount": 325
        }
      }
    }
  }
}
```

## Filtros Disponibles

```dart
final filters = DailyActivityFilters(
  startDate: DateTime(2025, 10, 27),           // Fecha inicial
  endDate: DateTime(2025, 10, 27, 23, 59),    // Fecha final
  cobradorId: 43,                              // Filtrar por cobrador
  paymentMethod: 'cash',                       // Filtrar por método ('cash', 'card', 'transfer')
);
```

## Styling y Temas

- **Colores**: Usa `Theme.of(context).primaryColor` para consistencia
- **Tipografía**: Sigue Material 3 guidelines
- **Dark Mode**: Totalmente compatible
- **Locale**: Formatos de fecha/moneda en `es_BO` (español - Bolivia)

## Localización Monetaria

- Locale: `es_BO`
- Símbolo: `Bs ` (Bolivianos)
- Decimales: 2
- Ejemplos: `Bs 325.00`, `Bs 1,200.50`

## Integración con Navegación

### Opción A: Navigator

```dart
Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => const DailyActivityReportView(),
  ),
);
```

### Opción B: Named Routes

```dart
// En tu configuración de rutas:
GoRoute(
  path: '/reports/daily-activity',
  builder: (context, state) => const DailyActivityReportView(),
)
```

### Opción C: Desde ReportsScreen

Seleccionar "daily-activity" como tipo de reporte en la pantalla de reportes.

## Dependencias Utilizadas

- `flutter_riverpod`: State management
- `intl`: Formatos de fecha y moneda
- `material`: Widgets y temas

Todas ya están incluidas en `pubspec.yaml`.

## Testing

Para probar con datos de ejemplo:

```dart
final sampleFilters = DailyActivityFilters(
  startDate: DateTime.now(),
  endDate: DateTime.now(),
);

// En un widget:
ref.watch(dailyActivityReportProvider(sampleFilters))
```

## Troubleshooting

### "No activity found"
- Verificar que el endpoint retorna datos para la fecha seleccionada
- Revisar que el usuario tiene permisos para ver el reporte

### Widgets no se muestran
- Verificar que `DailyActivityReport` se parseó correctamente
- Revisar logs de la API

### Formato de moneda incorrecto
- Verificar que el locale en `intl` es `es_BO`
- En algunos dispositivos puede necesitar configuración de locale adicional

## Próximas Mejoras Sugeridas

1. Agregar gráficos (charts) de distribución de pagos
2. Exportar a PDF/Excel con formato personalizado
3. Filtros avanzados (rango de montos, estado, etc.)
4. Búsqueda de clientes
5. Sincronización en tiempo real con WebSocket
6. Cache local para offline
7. Análisis predictivo de pagos
8. Integración con mapas de ubicación

## Soporte

Para preguntas o problemas:
1. Revisar la estructura de carpetas en el documento anterior
2. Verificar que todos los archivos están en su ubicación correcta
3. Ejecutar `flutter pub get` para actualizar dependencias
4. Revisar los logs de compilación

---

**Versión:** 1.0
**Última actualización:** 2025-10-27
