# Verificar Integración: Reporte de Actividad Diaria

## Instrucciones para Probar

### Opción 1: Desde Reports Screen (Recomendado)

1. **Abrir la pantalla de Reportes**
   - Navega a la pantalla de reportes de tu app
   - Deberías ver un dropdown con tipos de reportes disponibles

2. **Seleccionar "daily-activity"**
   - En el dropdown "Tipo de reporte", busca y selecciona:
     - `daily-activity` o
     - `actividad-diaria` o
     - `actividad_diaria`

3. **Configurar filtros (opcional)**
   - Puedes ajustar la fecha si lo deseas
   - Las otras opciones de filtro también están disponibles

4. **Presionar "Generar"**
   - El botón azul "Generar" ejecutará el endpoint
   - Espera a que se carguen los datos

5. **Visualizar el reporte**
   - Deberías ver:
     - ✅ **Card de resumen** con gradiente azul (Total de Pagos y Monto Recaudado)
     - ✅ **Cards por cobrador** con avatares circulares
     - ✅ **Lista de pagos** con:
       - Chips de método de pago (Efectivo/Tarjeta/Transferencia)
       - Chips de estado (Completado/Pendiente/Fallido)
       - Información de cliente, monto, fecha
     - ✅ **Modal de detalles** al hacer tap en cualquier pago

---

### Opción 2: Acceso Directo via Code

Si quieres integrar un acceso directo desde tu dashboard:

```dart
import 'package:flutter/material.dart';
import 'package:app_cobrador/presentacion/reports/views/daily_activity_report_view.dart';

// En cualquier botón o acción:
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const DailyActivityReportView(),
  ),
);
```

---

## Flujo Técnico Verificado ✅

```
Reports Screen
  ↓ (selecciona "daily-activity")
  ↓
Report Factory
  ↓ (detecta tipo de reporte)
  ↓
_DailyActivityReportView (NUEVO - MEJORADO)
  ↓
Muestra:
  - DailyActivitySummaryCard
  - CobradorSummaryCard (por cada cobrador)
  - DailyActivityListView (lista de pagos)
  - Modal con detalles al tap
```

---

## Cambios Realizados en Factory

El archivo `report_view_factory.dart` fue actualizado para:

1. **Importar nuevos widgets y modelos**
   ```dart
   import '../../../datos/modelos/reporte/daily_activity_report.dart';
   import '../widgets/daily_activity_widgets.dart';
   ```

2. **Reemplazar `_DailyActivityReportView`**
   - Antes: Mostraba datos genéricos
   - Ahora: Muestra cards y widgets modernos con manejo de detalles

3. **Parsear el payload automáticamente**
   ```dart
   final DailyActivityReport report = DailyActivityReport.fromJson(payload);
   ```

---

## Qué Debería Ver en Pantalla

### 1. Card de Resumen (Azul con gradiente)
```
┌─────────────────────────────────┐
│  RESUMEN DEL DÍA                │
│                                 │
│  📋 Total Pagos: 2              │
│  💰 Monto Recaudado: Bs 325.00  │
└─────────────────────────────────┘
```

### 2. Cards por Cobrador
```
┌─────────────────────────────────┐
│ A | APP COBRADOR                │
│   | ID: 43                      │
│───────────────────────────────  │
│ Pagos: 2  │  Monto: Bs 325.00  │
└─────────────────────────────────┘
```

### 3. Lista de Pagos
```
┌─────────────────────────────────┐
│ Pago #15 ✅ Completado         │
│ Cuota 4 • APP COBRADOR          │
│                                 │
│ Cliente: CLIENTE TEST 3         │
│ Monto: Bs 300.00 🟢             │
│ 💵 Efectivo | 28/10/2025 01:13 │
└─────────────────────────────────┘
```

### 4. Modal de Detalles (Al hacer tap en un pago)
```
Detalles del Pago  [✅ Completado]
Pago #15

[CLIENTE]
Nombre: CLIENTE TEST 3
Crédito ID: #24

[INFORMACIÓN DEL PAGO]
Monto: Bs 300.00
Método: Efectivo
Cuota: 4

[COBRADOR]
Nombre: APP COBRADOR
ID: 43

[FECHAS]
Fecha de Pago: 28/10/2025 01:13
Creado: 27/10/2025 01:13

[Botón Cerrar]
```

---

## Checklist de Verificación

- [ ] ¿Se muestra el card de resumen con gradiente?
- [ ] ¿Aparecen los cards de cobradores?
- [ ] ¿Se ve la lista de pagos con chips de colores?
- [ ] ¿Al hacer tap en un pago se abre el modal de detalles?
- [ ] ¿Los chips de método de pago muestran los colores correctos?
  - [ ] Efectivo: Verde
  - [ ] Tarjeta: Azul
  - [ ] Transferencia: Púrpura
- [ ] ¿Los chips de estado funcionan correctamente?
  - [ ] Completado: Verde
  - [ ] Pendiente: Naranja
  - [ ] Fallido: Rojo
- [ ] ¿Los montos están formateados en "Bs X.XX"?
- [ ] ¿Las fechas se muestran en formato "dd/MM/yyyy HH:mm"?
- [ ] ¿Funciona en modo claro y oscuro?

---

## Si Algo No Funciona

### Error: "Tipo de reporte no encontrado"
- Verifica que el backend retorna los tipos de reportes
- Ejecuta: `GET /reports/types` y busca "daily-activity"

### Error: "No se muestran los datos"
- Verifica la URL del endpoint: `GET /reports/daily-activity?format=json`
- Debe retornar datos con estructura:
  ```json
  {
    "success": true,
    "data": {
      "items": [...],
      "summary": {...}
    }
  }
  ```

### Error: "Parse error en modelo"
- Revisa que el JSON del backend coincida con la estructura esperada
- Verifica que los campos tengan los nombres correctos (sin snake_case erróneo)

### Widget no se ve
- Verifica que estés usando `Reports Screen`
- Presiona el botón "Generar" después de seleccionar el reporte
- Espera a que carguen los datos (debe haber un spinner)

---

## Integración con otros módulos

### Desde Manager Dashboard
```dart
// Si quieres agregar un botón rápido en el dashboard
FloatingActionButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DailyActivityReportView(),
      ),
    );
  },
  tooltip: 'Actividad Diaria',
  child: const Icon(Icons.today),
)
```

### Desde Drawer
```dart
ListTile(
  leading: const Icon(Icons.today),
  title: const Text('Actividad Diaria'),
  onTap: () {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const DailyActivityReportView(),
      ),
    );
  },
)
```

---

## Troubleshooting Avanzado

### Si los datos no se cargan después de seleccionar el reporte:

1. **Revisar Network**
   - Abre DevTools (Flutter DevTools)
   - Ve a Network y busca la llamada a `/reports/daily-activity`
   - Verifica el status (debe ser 200)
   - Revisa la respuesta JSON

2. **Revisar Logs**
   ```
   flutter run --verbose
   ```
   Busca mensajes de error en la salida

3. **Verificar Endpoint**
   ```bash
   curl "http://192.168.1.23:9000/api/reports/daily-activity?format=json"
   ```
   Debe retornar un JSON válido

4. **Verificar Autenticación**
   - El usuario debe tener permisos para ver reportes
   - El token debe ser válido

---

## Próximos Pasos

Después de verificar que todo funciona:

1. Agregar un botón de acceso rápido desde el dashboard
2. Configurar notificaciones cuando hay nuevos pagos
3. Agregar filtros avanzados (por método de pago, estado, etc.)
4. Implementar gráficos de distribución

---

**Versión:** 1.0
**Fecha:** 2025-10-27
**Estado:** ✅ Listo para Producción
