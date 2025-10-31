# 📊 Diagramas - Sistema de Estadísticas en Tiempo Real

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                         BACKEND (Laravel)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐     │
│  │ Crear Pago   │    │ Crear Crédito│    │ Aprobar      │     │
│  │              │───▶│              │───▶│ Crédito      │     │
│  └──────────────┘    └──────────────┘    └──────────────┘     │
│         │                    │                    │             │
│         └────────────────────┼────────────────────┘             │
│                              ▼                                  │
│                     ┌──────────────────┐                        │
│                     │   Laravel Job    │                        │
│                     │ CalculateStats   │                        │
│                     └──────────────────┘                        │
│                              │                                  │
│         ┌────────────────────┼────────────────────┐             │
│         ▼                    ▼                    ▼             │
│  ┌─────────────┐     ┌─────────────┐     ┌─────────────┐      │
│  │   Emit:     │     │   Emit:     │     │   Emit:     │      │
│  │ stats.      │     │ stats.      │     │ stats.      │      │
│  │ global.     │     │ cobrador.   │     │ manager.    │      │
│  │ updated     │     │ updated     │     │ updated     │      │
│  └─────────────┘     └─────────────┘     └─────────────┘      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  WebSocket Node  │
                    │   Socket.IO      │
                    └──────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│   FLUTTER     │    │   FLUTTER     │    │   FLUTTER     │
│   (Admin)     │    │  (Manager)    │    │  (Cobrador)   │
├───────────────┤    ├───────────────┤    ├───────────────┤
│               │    │               │    │               │
│ WebSocket     │    │ WebSocket     │    │ WebSocket     │
│ Service       │    │ Service       │    │ Service       │
│      │        │    │      │        │    │      │        │
│      ▼        │    │      ▼        │    │      ▼        │
│ WebSocket     │    │ WebSocket     │    │ WebSocket     │
│ Provider      │    │ Provider      │    │ Provider      │
│      │        │    │      │        │    │      │        │
│      ▼        │    │      ▼        │    │      ▼        │
│ Riverpod      │    │ Riverpod      │    │ Riverpod      │
│ Providers     │    │ Providers     │    │ Providers     │
│      │        │    │      │        │    │      │        │
│      ▼        │    │      ▼        │    │      ▼        │
│ Dashboard UI  │    │ Dashboard UI  │    │ Dashboard UI  │
│               │    │               │    │               │
└───────────────┘    └───────────────┘    └───────────────┘
```

## 🔄 Flujo de Datos

```
┌──────────────────────────────────────────────────────────────────┐
│                     FLUJO DE ACTUALIZACIÓN                        │
└──────────────────────────────────────────────────────────────────┘

1️⃣  Usuario Realiza Acción
    ├─ Crear pago
    ├─ Crear crédito
    ├─ Aprobar crédito
    ├─ Entregar crédito
    └─ Rechazar crédito
                │
                ▼
2️⃣  Backend Procesa (Laravel)
    ├─ Valida datos
    ├─ Guarda en DB
    └─ Dispara Job
                │
                ▼
3️⃣  Job Calcula Estadísticas
    ├─ Consulta DB
    ├─ Calcula totales
    ├─ Calcula métricas
    └─ Prepara payload JSON
                │
                ▼
4️⃣  Job Emite Eventos WebSocket
    ├─ stats.global.updated → 🌍 Todos
    ├─ stats.cobrador.updated → 👤 Cobrador específico
    └─ stats.manager.updated → 👥 Manager específico
                │
                ▼
5️⃣  WebSocket Server (Node.js)
    ├─ Recibe eventos
    ├─ Filtra por usuario/sala
    └─ Broadcast a clientes
                │
                ▼
6️⃣  Flutter App Recibe
    ├─ WebSocketService escucha
    ├─ Parsea JSON a Map
    └─ Emite en Stream
                │
                ▼
7️⃣  WebSocketProvider Procesa
    ├─ Recibe de Stream
    ├─ Parsea a Modelo (GlobalStats/etc)
    └─ Actualiza State
                │
                ▼
8️⃣  Riverpod Notifica
    ├─ notifyListeners()
    └─ Widgets escuchando se rebuildan
                │
                ▼
9️⃣  UI se Actualiza Automáticamente ✨
    └─ Usuario ve datos actualizados
```

## 📡 Canales y Receptores

```
┌──────────────────────────────────────────────────────────────────┐
│                     CANALES WEBSOCKET                             │
└──────────────────────────────────────────────────────────────────┘

stats.global.updated
  │
  ├─🌍 Admin       (Puede ver todo)
  ├─👥 Manager     (Puede ver su equipo + global)
  └─👤 Cobrador    (Puede ver sus stats + global)

  Estructura:
  {
    "type": "global",
    "stats": {
      "total_clients": 150,
      "today_collections": 1200.00,
      "month_collections": 18500.75,
      ...
    },
    "timestamp": "2025-10-31T14:30:45.000Z"
  }

─────────────────────────────────────────────────────────────────

stats.cobrador.updated
  │
  ├─👤 Cobrador (ID=42)  ✅ Recibe (solo sus datos)
  ├─👤 Cobrador (ID=43)  ❌ NO recibe
  └─👥 Manager           ✅ Recibe (si el cobrador está en su equipo)

  Estructura:
  {
    "type": "cobrador",
    "user_id": 42,
    "stats": {
      "cobrador_id": 42,
      "total_clients": 25,
      "today_collections": 250.00,
      ...
    },
    "timestamp": "2025-10-31T14:30:45.000Z"
  }

─────────────────────────────────────────────────────────────────

stats.manager.updated
  │
  ├─👥 Manager (ID=15)   ✅ Recibe (solo sus datos)
  ├─👥 Manager (ID=16)   ❌ NO recibe
  └─🌍 Admin             ✅ Recibe (puede ver todos)

  Estructura:
  {
    "type": "manager",
    "user_id": 15,
    "stats": {
      "manager_id": 15,
      "total_cobradores": 5,
      "today_collections": 1000.00,
      ...
    },
    "timestamp": "2025-10-31T14:30:45.000Z"
  }
```

## 🎯 Qué Escucha Cada Rol

```
┌──────────────────────────────────────────────────────────────────┐
│                    EVENTOS POR ROL                                │
└──────────────────────────────────────────────────────────────────┘

🌍 ADMIN
  ├─ ✅ stats.global.updated     (Ve todo el sistema)
  ├─ ✅ credit-notification      (Ve todos los créditos)
  └─ ✅ payment-notification     (Ve todos los pagos)

─────────────────────────────────────────────────────────────────

👥 MANAGER
  ├─ ✅ stats.global.updated     (Ve estadísticas globales)
  ├─ ✅ stats.manager.updated    (Ve estadísticas de su equipo)
  ├─ ✅ credit-notification      (Créditos de su equipo)
  └─ ✅ payment-notification     (Pagos de su equipo)

─────────────────────────────────────────────────────────────────

👤 COBRADOR
  ├─ ✅ stats.global.updated     (Ve estadísticas globales)
  ├─ ✅ stats.cobrador.updated   (Ve sus propias estadísticas)
  ├─ ✅ credit-notification      (Sus créditos)
  └─ ✅ payment-notification     (Sus pagos)
```

## 🏛️ Arquitectura de Flutter

```
┌──────────────────────────────────────────────────────────────────┐
│                  ARQUITECTURA FLUTTER                             │
└──────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                         UI LAYER                                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │   Dashboard  │  │   Cobrador   │  │   Manager    │         │
│  │   Global     │  │   Dashboard  │  │   Dashboard  │         │
│  └──────────────┘  └──────────────┘  └──────────────┘         │
│         │                 │                  │                  │
│         └─────────────────┼──────────────────┘                  │
│                           │                                     │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            │ ref.watch()
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                     PROVIDER LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │          webSocketProvider (Riverpod)                   │    │
│  │                                                          │    │
│  │  State:                                                  │    │
│  │    - isConnected                                         │    │
│  │    - globalStats: GlobalStats?                           │    │
│  │    - cobradorStats: CobradorStats?                       │    │
│  │    - managerStats: ManagerStats?                         │    │
│  │    - notifications: List<AppNotification>                │    │
│  └────────────────────────────────────────────────────────┘    │
│                           │                                     │
│  Providers Derivados:     │                                     │
│  ┌───────────────────┐   │   ┌───────────────────┐           │
│  │ globalStats       │◄──┼──▶│ cobradorStats     │           │
│  │ Provider          │   │   │ Provider          │           │
│  └───────────────────┘   │   └───────────────────┘           │
│                           │                                     │
│  ┌───────────────────┐   │   ┌───────────────────┐           │
│  │ managerStats      │◄──┼──▶│ isWebSocket       │           │
│  │ Provider          │   │   │ ConnectedProvider │           │
│  └───────────────────┘   │   └───────────────────┘           │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            │ StreamSubscription
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      SERVICE LAYER                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │          WebSocketService (Singleton)                   │    │
│  │                                                          │    │
│  │  Streams:                                                │    │
│  │    - globalStatsStream                                   │    │
│  │    - cobradorStatsStream                                 │    │
│  │    - managerStatsStream                                  │    │
│  │    - notificationStream                                  │    │
│  │    - paymentStream                                       │    │
│  │                                                          │    │
│  │  Methods:                                                │    │
│  │    - connect()                                           │    │
│  │    - disconnect()                                        │    │
│  │    - authenticate()                                      │    │
│  └────────────────────────────────────────────────────────┘    │
│                           │                                     │
└───────────────────────────┼─────────────────────────────────────┘
                            │
                            │ Socket.IO
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WEBSOCKET SERVER                              │
│                      (Node.js)                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 📦 Modelos de Datos

```
┌──────────────────────────────────────────────────────────────────┐
│                       MODELOS DART                                │
└──────────────────────────────────────────────────────────────────┘

GlobalStats
├─ int totalClients
├─ int totalCobradores
├─ int totalManagers
├─ int totalCredits
├─ int totalPayments
├─ int overduePayments
├─ int pendingPayments
├─ double totalBalance
├─ double todayCollections
├─ double monthCollections
└─ DateTime updatedAt

CobradorStats
├─ int cobradorId
├─ int totalClients
├─ int totalCredits
├─ int totalPayments
├─ int overduePayments
├─ int pendingPayments
├─ double totalBalance
├─ double todayCollections
├─ double monthCollections
└─ DateTime updatedAt

ManagerStats
├─ int managerId
├─ int totalCobradores
├─ int totalCredits
├─ int totalPayments
├─ int overduePayments
├─ int pendingPayments
├─ double totalBalance
├─ double todayCollections
├─ double monthCollections
└─ DateTime updatedAt
```

## ⚡ Performance

```
┌──────────────────────────────────────────────────────────────────┐
│                    OPTIMIZACIONES                                 │
└──────────────────────────────────────────────────────────────────┘

✅ Sin Polling
   └─ No hace peticiones HTTP repetidas
   └─ Solo actualiza cuando hay cambios reales

✅ Broadcast Eficiente
   └─ stats.global.updated se envía una sola vez
   └─ Todos los clientes conectados lo reciben

✅ Filtrado en Servidor
   └─ Backend decide quién recibe qué eventos
   └─ Flutter no filtra, solo escucha

✅ Streams de Dart
   └─ broadcast() permite múltiples listeners
   └─ No duplica datos en memoria

✅ Riverpod
   └─ Solo rebuilda widgets que escuchan
   └─ Caché automático de providers

✅ Modelos Inmutables
   └─ copyWith() para actualizaciones
   └─ No muta estado directamente
```

---

**Última Actualización**: 2025-10-31
**Versión**: 1.0.0
