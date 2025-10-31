# 📱 Vista Previa Visual - Reporte de Actividad Diaria

## Flujo de Navegación

```
┌──────────────────────────────────────────────────┐
│  📋 Generador de Reportes                        │
├──────────────────────────────────────────────────┤
│                                                  │
│  🔽 Filtros de búsqueda                   ⇧     │
│                                                  │
│  Tipo de reporte: [Dropdown ▼]                  │
│    - payments                                    │
│    - credits                                     │
│    - daily-activity  ← SELECCIONAR ESTO        │
│    - portfolio                                   │
│    - ...                                         │
│                                                  │
│  [Limpiar] Formato: [JSON ▼]  [🎬 Generar]     │
│                                                  │
├──────────────────────────────────────────────────┤
│                                                  │
│  ⌛ Cargando...                                  │
│                                                  │
│  (Esperar a que se carguen los datos)          │
│                                                  │
└──────────────────────────────────────────────────┘

              ⬇️ (después de cargar)

┌──────────────────────────────────────────────────┐
│            REPORTE DE ACTIVIDAD DIARIA           │
├──────────────────────────────────────────────────┤
│                                                  │
│ ┌──────────────────────────────────────────────┐ │
│ │ 📊 RESUMEN DEL DÍA                          │ │
│ │ (Gradiente azul)                            │ │
│ │                                              │ │
│ │     📋 2              💰 Bs 325.00          │ │
│ │   Total Pagos        Monto Recaudado       │ │
│ └──────────────────────────────────────────────┘ │
│                                                  │
│ 👥 Resumen por Cobrador                        │
│                                                  │
│ ┌──────────────────────────────────────────────┐ │
│ │ A │ APP COBRADOR                            │ │
│ │   │ ID: 43                                  │ │
│ │───────────────────────────────────────────  │ │
│ │  Pagos: 2        │        Monto: Bs 325.00 │ │
│ └──────────────────────────────────────────────┘ │
│                                                  │
│ 💰 Detalle de Pagos                            │
│                                                  │
│ ┌──────────────────────────────────────────────┐ │
│ │ Pago #15              [✅ Completado]       │ │
│ │ Cuota 4 • APP COBRADOR                      │ │
│ │                                              │ │
│ │ Cliente: CLIENTE TEST 3                      │ │
│ │ Monto: Bs 300.00 🟢                         │ │
│ │                                              │ │
│ │ [💵 Efectivo]  28/10/2025 01:13             │ │
│ └──────────────────────────────────────────────┘ │
│                                                  │
│ ┌──────────────────────────────────────────────┐ │
│ │ Pago #21              [✅ Completado]       │ │
│ │ Cuota 2 • APP COBRADOR                      │ │
│ │                                              │
│ │ Cliente: FERNANDO PINTO LINO                │ │
│ │ Monto: Bs 25.00 🟢                          │ │
│ │                                              │
│ │ [💵 Efectivo]  27/10/2025 07:44             │ │
│ └──────────────────────────────────────────────┘ │
│                                                  │
└──────────────────────────────────────────────────┘
```

---

## Vista Detallada de Componentes

### 1️⃣ Card de Resumen

```
┌────────────────────────────────────────────┐
│ 📊 RESUMEN DEL DÍA                         │
│ ════════════════════════════════════════   │
│ (Gradiente: Azul primario → Transparente) │
│                                            │
│    📋           💰                        │
│    2            Bs 325.00                │
│  Total Pagos   Monto Recaudado           │
│                                            │
└────────────────────────────────────────────┘
```

**Características:**
- Gradiente azul de arriba hacia abajo
- Iconos grandes y claros
- Números prominentes en blanco
- Etiquetas descriptivas en blanco
- Sombra (elevation: 4)

---

### 2️⃣ Card por Cobrador

```
┌──────────────────────────────────────────────┐
│ [A] │ APP COBRADOR                          │
│ [🟦]│ ID: 43                                │
│     │                                        │
├──────────────────────────────────────────────┤
│                                              │
│    2 Pagos          │        Bs 325.00     │
│    (azul primario)  │        (verde)       │
│                                              │
└──────────────────────────────────────────────┘
```

**Características:**
- Avatar circular con inicial
- Nombre del cobrador en negrita
- ID pequeño debajo
- Separador visual (divider)
- Estadísticas en dos columnas
- Números en colores: azul (cantidad), verde (monto)

---

### 3️⃣ Card de Pago (Lista)

```
┌────────────────────────────────────────────────┐
│ Pago #15                 [✅ Completado]      │
│ Cuota 4 • APP COBRADOR                        │
│                                                │
│ Cliente: CLIENTE TEST 3       Bs 300.00 🟢   │
│                                                │
│ [💵 Efectivo]   28/10/2025 01:13             │
└────────────────────────────────────────────────┘
```

**Características:**
- Header con ID y chip de estado
- Información del cliente y monto
- Método de pago con icono y color
- Fecha y hora de transacción
- Elevación/sombra
- Border radius redondeado

---

### 4️⃣ Chips de Método de Pago

```
Método: [💵 Efectivo]  [💳 Tarjeta]  [🏦 Transferencia]

Estilos:
• Efectivo     → Verde (#4CAF50), icono dinero
• Tarjeta      → Azul (#2196F3), icono tarjeta
• Transferencia→ Púrpura (#9C27B0), icono banco
• Otros        → Gris (#9E9E9E), icono pago
```

---

### 5️⃣ Chips de Estado

```
Estado: [✅ Completado]  [⏱️ Pendiente]  [❌ Fallido]

Estilos:
• Completado → Verde (#4CAF50)
• Pendiente  → Naranja (#FF9800)
• Fallido    → Rojo (#F44336)
```

---

## Modal de Detalles (Bottom Sheet)

```
┌────────────────────────────────────────────┐
│ Detalles del Pago    [✅ Completado]      │
│ Pago #15                                   │
│                                            │
├────────────────────────────────────────────┤
│ 👤 CLIENTE                                │
│ ├─ Nombre: CLIENTE TEST 3                 │
│ └─ Crédito ID: #24                        │
│                                            │
│ 💰 INFORMACIÓN DEL PAGO                   │
│ ├─ Monto: Bs 300.00 🟢                    │
│ ├─ Método: Efectivo                       │
│ └─ Cuota: 4                               │
│                                            │
│ 👨‍💼 COBRADOR                               │
│ ├─ Nombre: APP COBRADOR                   │
│ └─ ID: 43                                 │
│                                            │
│ 📅 FECHAS                                 │
│ ├─ Fecha de Pago: 28/10/2025 01:13       │
│ └─ Creado: 27/10/2025 01:13              │
│                                            │
│ 📍 UBICACIÓN (si está disponible)        │
│ ├─ Latitud: -19.34796900                 │
│ └─ Longitud: -165.12177000               │
│                                            │
│ ┌────────────────────────────────────────┐ │
│ │         [Cerrar]                       │ │
│ └────────────────────────────────────────┘ │
└────────────────────────────────────────────┘
```

**Características:**
- Bottom sheet con redondeado en la parte superior
- Secciones claramente divididas
- Layout tipo formulario (etiqueta: valor)
- Valores en negrita
- Montos en verde
- Botón de cierre al final
- Scrolleable si es necesario

---

## Vista de Tabla (Alternativa)

Cuando se presiona el ícono de tabla:

```
┌──────────┬───────────────┬────────┬────────┬──────────┬───────────┐
│ Pago ID  │ Cliente       │ Monto  │ Método │ Fecha    │ Estado    │
├──────────┼───────────────┼────────┼────────┼──────────┼───────────┤
│ #15      │ CLIENTE TEST  │ 300.00 │[💵]   │28/10/25  │[✅]       │
├──────────┼───────────────┼────────┼────────┼──────────┼───────────┤
│ #21      │ FERNANDO P.   │ 25.00  │[💵]   │27/10/25  │[✅]       │
└──────────┴───────────────┴────────┴────────┴──────────┴───────────┘
```

**Características:**
- Scroll horizontal
- Header con fondo de color primario
- Montos formateados
- Chips en columnas
- Compacta pero legible

---

## Comportamiento Interactivo

### 1. Al Abrir Reports Screen
```
1. Muestra dropdown de tipos de reporte
2. Usuario selecciona "daily-activity"
3. Se habilita botón "Generar"
```

### 2. Al Presionar "Generar"
```
1. Muestra spinner de carga
2. Se hace llamada a: GET /reports/daily-activity
3. Se parsean los datos
4. Se mostrarán los widgets modernos
```

### 3. Al Hacer Tap en un Pago
```
1. Se abre modal de detalles (bottom sheet)
2. Se anima desde abajo
3. Muestra información completa
4. Usuario puede scroll para ver más
5. Presiona "Cerrar" para volver
```

### 4. Al Cambiar Vista (Tabla/Lista)
```
1. Presiona ícono en la parte superior
2. La vista cambia sin recargar datos
3. Los mismos datos pero en diferente formato
```

---

## Paleta de Colores

```
Primario:   #5E81F4 (Índigo suave) o configurado en Theme
Éxito:      #4CAF50 (Verde)
Advertencia:#FF9800 (Naranja)
Error:      #F44336 (Rojo)
Dinero:     #2E7D32 (Verde oscuro)
Fondo:      Blanco o Gris claro (Light mode)
            Gris oscuro o Negro (Dark mode)
```

---

## Animaciones

- ✨ **Fade in** al cargar los datos
- 📱 **Slide up** del modal de detalles
- 🔄 **Rotación** del ícono de filtros colapsables
- ⚡ **Transición** suave entre vista tabla y lista

---

## Responsive Behavior

```
📱 Móvil (< 600px)
├─ Una columna
├─ Cards a ancho completo
├─ Lista vertical
└─ Tabla scroll horizontal

📊 Tablet (600px - 1200px)
├─ Cards más grandes
├─ Dos columnas si es posible
└─ Tabla con más columnas visibles

🖥️ Desktop (> 1200px)
├─ Layout múltiples columnas
├─ Tabla completamente visible
└─ Modal de detalles en popup
```

---

## Dark Mode

Todos los componentes están optimizados para dark mode:

```
Dark Mode:
├─ Fondo: #121212 (Gris muy oscuro)
├─ Cards: #1E1E1E (Gris oscuro)
├─ Texto: #FFFFFF (Blanco)
├─ Secundario: #E0E0E0 (Gris claro)
├─ Colores de estado: Mismos (muy visibles)
└─ Gradientes: Adaptados automáticamente
```

---

## Ejemplos de Datos Reales

### Ejemplo 1: Pago Completado - Efectivo
```json
{
  "id": 15,
  "clientName": "CLIENTE TEST 3",
  "amount": 300.00,
  "paymentMethod": "cash",
  "status": "completed",
  "installmentNumber": 4,
  "cobradorName": "APP COBRADOR",
  "paymentDate": "2025-10-28T01:13:19Z"
}

Mostrado como:
┌──────────────────────────────────────┐
│ Pago #15              [✅ Completado]│
│ Cuota 4 • APP COBRADOR              │
│ Cliente: CLIENTE TEST 3              │
│ Monto: Bs 300.00 🟢                 │
│ [💵 Efectivo]  28/10/2025 01:13     │
└──────────────────────────────────────┘
```

### Ejemplo 2: Pago Completado - Tarjeta
```
┌──────────────────────────────────────┐
│ Pago #25              [✅ Completado]│
│ Cuota 3 • JUAN PÉREZ                │
│ Cliente: COMERCIAL STORE             │
│ Monto: Bs 500.00 🟢                 │
│ [💳 Tarjeta]  28/10/2025 15:45      │
└──────────────────────────────────────┘
```

### Ejemplo 3: Resumen por Día Activo
```
Card de Resumen:
┌───────────────────────────────────┐
│ 📊 RESUMEN DEL DÍA                │
│                                   │
│  📋 8 Pagos    💰 Bs 2,450.00   │
│  (cuatro pagos completados)       │
└───────────────────────────────────┘

Cards de Cobradores:
┌──────────────────────────┐
│ AC│ ANTONIO CORTÉS      │
│   │ ID: 45             │
├───────────────────────────┤
│ 4 Pagos │ Bs 1,200.00   │
└──────────────────────────┘

┌──────────────────────────┐
│ ML│ MARÍA López         │
│   │ ID: 46             │
├───────────────────────────┤
│ 4 Pagos │ Bs 1,250.00   │
└──────────────────────────┘
```

---

## Casos Especiales

### Sin Datos
```
┌─────────────────────────────┐
│  📬 Sin actividad           │
│                             │
│ No hay registros de pagos  │
│ para mostrar               │
└─────────────────────────────┘
```

### Cargando
```
┌─────────────────────────────┐
│      ⌛ Cargando...         │
│                             │
│    (Spinner giratorio)      │
└─────────────────────────────┘
```

### Error
```
┌─────────────────────────────┐
│  ⚠️ Error al cargar         │
│                             │
│ Connection refused          │
│ Verifica tu conexión       │
└─────────────────────────────┘
```

---

## Resumen Visual

La implementación proporciona una **interfaz moderna, intuitiva y responsive** que:

- ✨ Se adapta a cualquier tamaño de pantalla
- 🌙 Funciona en light y dark mode
- 💫 Tiene animaciones suaves
- 📱 Es completamente táctil amigable
- ♿ Sigue Material Design 3
- 🌍 Está localizada en español
- 💱 Muestra montos en Bolivianos
- 📊 Organiza datos de forma clara

---

**Versión:** 1.0
**Última actualización:** 2025-10-27
