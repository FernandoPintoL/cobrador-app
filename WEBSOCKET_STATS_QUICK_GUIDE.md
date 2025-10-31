# 📊 Guía Rápida - Estadísticas en Tiempo Real

## 🚀 Inicio Rápido

### 1. Importar
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/websocket_provider.dart';
```

### 2. Usar en Widget
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalStats = ref.watch(globalStatsProvider);

    return Text('Clientes: ${globalStats?.totalClients ?? 0}');
  }
}
```

## 📡 Providers Disponibles

| Provider | Tipo | Para qué |
|----------|------|----------|
| `globalStatsProvider` | `GlobalStats?` | Estadísticas globales (todos) |
| `cobradorStatsProvider` | `CobradorStats?` | Estadísticas del cobrador |
| `managerStatsProvider` | `ManagerStats?` | Estadísticas del equipo |
| `isWebSocketConnectedProvider` | `bool` | Estado de conexión |

## 📊 Campos Disponibles

### GlobalStats
```dart
stats.totalClients          // Total de clientes
stats.totalCobradores       // Total de cobradores
stats.totalManagers         // Total de managers
stats.totalCredits          // Créditos activos
stats.totalPayments         // Total de pagos
stats.overduePayments       // Pagos atrasados
stats.pendingPayments       // Pagos pendientes
stats.totalBalance          // Balance pendiente
stats.todayCollections      // Cobros de hoy
stats.monthCollections      // Cobros del mes
stats.updatedAt             // Última actualización
```

### CobradorStats
```dart
stats.cobradorId            // ID del cobrador
stats.totalClients          // Clientes del cobrador
stats.totalCredits          // Créditos activos
stats.totalPayments         // Total de pagos
stats.overduePayments       // Pagos atrasados
stats.pendingPayments       // Pagos pendientes
stats.totalBalance          // Balance pendiente
stats.todayCollections      // Cobros de hoy
stats.monthCollections      // Cobros del mes
stats.updatedAt             // Última actualización
```

### ManagerStats
```dart
stats.managerId             // ID del manager
stats.totalCobradores       // Cobradores en el equipo
stats.totalCredits          // Créditos del equipo
stats.totalPayments         // Total de pagos
stats.overduePayments       // Pagos atrasados
stats.pendingPayments       // Pagos pendientes
stats.totalBalance          // Balance del equipo
stats.todayCollections      // Cobros de hoy
stats.monthCollections      // Cobros del mes
stats.updatedAt             // Última actualización
```

## 💡 Ejemplos Rápidos

### Dashboard Simple
```dart
class Dashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(globalStatsProvider);

    if (stats == null) {
      return CircularProgressIndicator();
    }

    return Column(
      children: [
        Text('Clientes: ${stats.totalClients}'),
        Text('Cobros Hoy: ${stats.todayCollections.toStringAsFixed(2)} Bs'),
        Text('Balance: ${stats.totalBalance.toStringAsFixed(2)} Bs'),
        Text('Atrasados: ${stats.overduePayments}'),
      ],
    );
  }
}
```

### Dashboard del Cobrador
```dart
class CobradorDash extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(cobradorStatsProvider);

    return Column(
      children: [
        Text('Mis Clientes: ${stats?.totalClients ?? 0}'),
        Text('Cobré Hoy: ${stats?.todayCollections.toStringAsFixed(2) ?? '0'} Bs'),
        Text('Del Mes: ${stats?.monthCollections.toStringAsFixed(2) ?? '0'} Bs'),
      ],
    );
  }
}
```

### Dashboard del Manager
```dart
class ManagerDash extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(managerStatsProvider);

    return Column(
      children: [
        Text('Cobradores: ${stats?.totalCobradores ?? 0}'),
        Text('Equipo Cobró Hoy: ${stats?.todayCollections.toStringAsFixed(2) ?? '0'} Bs'),
        Text('Del Mes: ${stats?.monthCollections.toStringAsFixed(2) ?? '0'} Bs'),
      ],
    );
  }
}
```

### Verificar Conexión
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(isWebSocketConnectedProvider);

    return Row(
      children: [
        Icon(
          isConnected ? Icons.cloud_done : Icons.cloud_off,
          color: isConnected ? Colors.green : Colors.red,
        ),
        Text(isConnected ? 'Conectado' : 'Desconectado'),
      ],
    );
  }
}
```

## 🔄 Actualización Automática

**¡No necesitas hacer nada!** Los datos se actualizan automáticamente cuando:
- Se crea un pago
- Se crea un crédito
- Se aprueba un crédito
- Se entrega un crédito
- Se rechaza un crédito

## 🐛 Debug

### Ver datos en consola
```dart
final stats = ref.watch(globalStatsProvider);
print('Stats: $stats');
```

### Logs automáticos
```
📊 Estadísticas globales actualizadas: 150 clientes, 1200.0 Bs hoy
📊 Estadísticas del cobrador actualizadas: 25 clientes, 250.0 Bs hoy
```

## ⚠️ Importante

1. **Siempre verificar null**: `stats?.campo ?? 0`
2. **No hacer polling**: Los datos se actualizan solos
3. **No usar RefreshIndicator**: Es innecesario
4. **Verificar conexión**: Mostrar estado offline si es necesario

## 📚 Más Info

- **Documentación Completa**: `lib/datos/modelos/WEBSOCKET_STATS_README.md`
- **Ejemplos Completos**: `lib/datos/modelos/WEBSOCKET_STATS_EXAMPLES.dart`
- **Implementación**: `IMPLEMENTACION_WEBSOCKET_STATS.md`

---

¡Listo para usar! 🎉
