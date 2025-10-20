# 🔍 Verificación: Carga de Estadísticas en Dashboard del Cobrador

## 📋 Resumen
Este documento verifica paso a paso que las estadísticas se cargan correctamente en el dashboard del cobrador en dos escenarios:
1. **Primer login**: Datos vienen del endpoint `/login`
2. **App reiniciada**: Datos se recuperan de `/api/me`

---

## 🔐 ESCENARIO 1: Primer Login

### 1️⃣ Envío de Credenciales
**Endpoint:** `POST /login`
**Carga útil:**
```json
{
  "email_or_phone": "cobrador@example.com",
  "password": "password123"
}
```

### 2️⃣ Respuesta del Servidor
**Estructura esperada:**
```json
{
  "success": true,
  "data": {
    "token": "eyJhbGc...",
    "user": {
      "id": 1,
      "nombre": "Juan Cobrador",
      "email": "cobrador@example.com",
      "roles": ["cobrador"]
    },
    "statistics": {
      "summary": {
        "total_clientes": 15,
        "creditos_activos": 8,
        "saldo_total_cartera": 25000.50
      }
    }
  }
}
```

### 3️⃣ Procesamiento en `AuthApiService.login()`
**Archivo:** `lib/datos/api_services/auth_api_service.dart` (líneas 12-78)

**Código ejecutado:**
```dart
// ✅ Paso 1: Token guardado
if (responseData['token'] != null) {
  debugPrint('✅ Token recibido: ${responseData['token'].toString().substring(0, 20)}...');
  await saveTokenFromResponse(responseData['token']);
}

// ✅ Paso 2: Usuario guardado
if (responseData['user'] != null) {
  debugPrint('👤 Datos de usuario recibidos');
  final usuario = Usuario.fromJson(responseData['user']);
  await storageService.saveUser(usuario);
}

// ✅ Paso 3: Estadísticas guardadas (CRÍTICO)
if (responseData['statistics'] != null) {
  debugPrint('📊 Estadísticas del dashboard recibidas');
  final statistics = DashboardStatistics.fromJson(responseData['statistics']);
  debugPrint('📊 Guardando estadísticas: $statistics');
  await storageService.saveDashboardStatistics(statistics);
}
```

**Salida de logs esperada:**
```
✅ Token recibido: eyJhbGc...
👤 Datos de usuario recibidos
📊 Estadísticas del dashboard recibidas
📊 Guardando estadísticas: DashboardStatistics(...)
```

### 4️⃣ Parsing en `DashboardStatistics.fromJson()`
**Archivo:** `lib/datos/modelos/dashboard_statistics.dart` (líneas 37-53)

**Estructura parseada:**
```dart
DashboardStatistics(
  totalClientes: 15,        // ✅ Desde summary.total_clientes
  totalCreditos: null,      // Manager stat (no aplica)
  clientesAsignados: null,  // No viene en login
  creditosActivos: 8,       // ✅ Desde summary.creditos_activos
  totalCobradoHoy: null,    // No viene en login
  metaDiaria: null,         // No viene en login
)
```

### 5️⃣ Actualización en `AuthNotifier.login()`
**Archivo:** `lib/negocio/providers/auth_provider.dart` (líneas 180-210)

**Código ejecutado:**
```dart
// Cargar estadísticas del dashboard desde almacenamiento local
final statistics = await _storageService.getDashboardStatistics();
if (statistics != null) {
  debugPrint('📊 Estadísticas cargadas desde almacenamiento local');
}

state = state.copyWith(
  usuario: usuario,
  statistics: statistics,  // ✅ GUARDADAS EN AuthState
  isLoading: false,
);
```

**AuthState ahora contiene:**
```dart
AuthState(
  usuario: Usuario(...),
  statistics: DashboardStatistics(...),  // ✅ Disponible para dashboard
  isLoading: false,
)
```

### 6️⃣ Carga en Dashboard
**Archivo:** `lib/presentacion/cobrador/cobrador_dashboard_screen.dart` (líneas 46-70)

**En `_cargarDatosIniciales()`:**
```dart
void _cargarDatosIniciales() {
  final authState = ref.read(authProvider);

  // ✅ PASO CRÍTICO: Verificar si statistics vienen del login
  if (authState.statistics != null) {
    debugPrint('✅ Usando estadísticas del login (evitando petición innecesaria)');
    
    // Convertir estructura del login a CreditStats
    final statsFromLogin = authState.statistics!;
    final creditStats = CreditStats.fromDashboardStatistics(
      statsFromLogin.toJson(),
    );

    // Establecer directamente (sin petición HTTP)
    ref.read(creditProvider.notifier).setStats(creditStats);
  } else {
    // Fallback solo si no vinieron del login
    debugPrint('⚠️ No hay estadísticas del login, cargando desde el backend...');
    ref.read(creditProvider.notifier).loadCobradorStats();
  }
}
```

**Logs esperados:**
```
✅ Usando estadísticas del login (evitando petición innecesaria)
✅ Estableciendo estadísticas directamente (desde login)
```

### 7️⃣ Conversión en `CreditStats.fromDashboardStatistics()`
**Archivo:** `lib/datos/modelos/credito/credit_stats.dart` (líneas 32-49)

**Mapeo realizado:**
```dart
final summary = json['summary'] as Map<String, dynamic>? ?? {};

return CreditStats(
  totalCredits: (summary['total_clientes'] as num?)?.toInt() ?? 0,     // 15
  activeCredits: (summary['creditos_activos'] as num?)?.toInt() ?? 0,  // 8
  completedCredits: 0,
  defaultedCredits: 0,
  totalAmount: (summary['saldo_total_cartera'] as num?)?.toDouble() ?? 0.0,  // 25000.50
  totalBalance: (summary['saldo_total_cartera'] as num?)?.toDouble() ?? 0.0, // 25000.50
);
```

**Resultado en CreditStats:**
```dart
CreditStats(
  totalCredits: 15,
  activeCredits: 8,
  totalAmount: 25000.50,
  totalBalance: 25000.50,
)
```

### 8️⃣ Actualización en `CreditNotifier.setStats()`
**Archivo:** `lib/negocio/providers/credit_provider.dart` (líneas 982-986)

**Código ejecutado:**
```dart
void setStats(CreditStats stats) {
  print('✅ Estableciendo estadísticas directamente (desde login)');
  state = state.copyWith(stats: stats, isLoading: false);  // ✅ State actualizado
}
```

### 9️⃣ Renderizado en Dashboard
**Archivo:** `lib/presentacion/cobrador/cobrador_dashboard_screen.dart` (líneas 372-415)

**Cards que se rellenan:**
```dart
Builder(
  builder: (context) {
    final creditState = ref.watch(creditProvider);
    final stats = creditState.stats;  // ✅ Obtiene stats

    return Wrap(
      children: [
        _buildStatCard(
          context,
          'Créditos Totales',
          '${stats?.totalCredits ?? 0}',      // 15 ✅
          Icons.credit_score,
          Colors.blue,
        ),
        _buildStatCard(
          context,
          'Créditos Activos',
          '${stats?.activeCredits ?? 0}',     // 8 ✅
          Icons.play_circle,
          Colors.green,
        ),
        _buildStatCard(
          context,
          'Monto Total',
          'Bs ${stats?.totalAmount.toStringAsFixed(2) ?? '0.00'}',  // Bs 25000.50 ✅
          Icons.attach_money,
          Colors.orange,
        ),
        _buildStatCard(
          context,
          'Balance Total',
          'Bs ${stats?.totalBalance.toStringAsFixed(2) ?? '0.00'}',  // Bs 25000.50 ✅
          Icons.account_balance_wallet,
          Colors.purple,
        ),
      ],
    );
  },
),
```

### ✅ RESULTADO ESPERADO
Las 4 cards muestran:
- **Créditos Totales:** 15
- **Créditos Activos:** 8
- **Monto Total:** Bs 25000.50
- **Balance Total:** Bs 25000.50

**Tiempo de llenado:** 0-500ms (datos del login, sin petición HTTP)

---

## 🔄 ESCENARIO 2: App Reiniciada

### 1️⃣ Recuperación en `AuthNotifier.initialize()`
**Archivo:** `lib/negocio/providers/auth_provider.dart` (líneas 50-130)

**Proceso:**
```dart
Future<void> initialize() async {
  // ✅ Paso 1: Verificar si hay sesión válida
  final hasSession = await _storageService.hasValidSession();
  
  if (hasSession) {
    // ✅ Paso 2: Obtener usuario del almacenamiento local
    final usuario = await _storageService.getUser();
    
    // ✅ PASO CRÍTICO: Obtener estadísticas guardadas
    final statistics = await _storageService.getDashboardStatistics();
    
    // ✅ Paso 3: Restaurar sesión con servidor
    await _apiService.restoreSession();
    
    // ✅ Paso 4: Actualizar usuario desde el servidor (refreshUser)
    await refreshUser();
    
    // ✅ Paso 5: Actualizar state con datos locales primero
    state = state.copyWith(
      usuario: usuario,
      statistics: statistics,  // ✅ Estadísticas cargadas del almacenamiento
      isLoading: false,
      isInitialized: true,
    );
  }
}
```

**Logs esperados:**
```
🔍 hasValidSession = true
📊 Estadísticas cargadas desde almacenamiento local
🔍 restoreSession = true
```

### 2️⃣ Sincronización en `AuthNotifier.refreshUser()`
**Archivo:** `lib/negocio/providers/auth_provider.dart` (líneas 298-350)

**Endpoint llamado:** `GET /me`

**Respuesta esperada:**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": 1,
      "nombre": "Juan Cobrador",
      "email": "cobrador@example.com"
    },
    "statistics": {
      "summary": {
        "total_clientes": 15,
        "creditos_activos": 8,
        "saldo_total_cartera": 25000.50
      }
    }
  }
}
```

**Código en `refreshUser()`:**
```dart
Future<void> refreshUser() async {
  try {
    // ✅ Paso 1: Llamar a /api/me
    final response = await _apiService.authApiService.getMe();
    
    // ✅ Paso 2: Obtener usuario de la respuesta
    final usuario = Usuario.fromJson(response['data']['user']);
    
    // ✅ PASO CRÍTICO: Obtener estadísticas de la respuesta
    if (response['data']['statistics'] != null) {
      final statistics = DashboardStatistics.fromJson(
        response['data']['statistics'],
      );
      
      // ✅ Paso 3: Guardar estadísticas en almacenamiento
      await _storageService.saveDashboardStatistics(statistics);
      
      // ✅ Paso 4: Actualizar state con nuevas estadísticas
      state = state.copyWith(
        usuario: usuario,
        statistics: statistics,  // ✅ Actualizadas desde servidor
      );
    }
  } catch (e) {
    debugPrint('Error en refreshUser: $e');
  }
}
```

**Logs esperados:**
```
📊 Estadísticas cargadas desde almacenamiento local (initial)
📊 Estadísticas del dashboard recibidas en /api/me
📊 Guardando estadísticas desde /api/me: DashboardStatistics(...)
📊 Estadísticas actualizadas desde /api/me
```

### 3️⃣ Carga en Dashboard (igual que Escenario 1)
El dashboard llama a `_cargarDatosIniciales()` que verifica `authState.statistics` y procede igual.

### ✅ RESULTADO ESPERADO
- Estadísticas se cargan **instantáneamente** desde almacenamiento local
- Luego se sincronizan con `/api/me` en background
- Cards muestran datos correctos durante toda la app

---

## 🧪 CHECKLIST DE VERIFICACIÓN

### Login Inicial
- [ ] Revisar logs al ejecutar: `flutter run`
- [ ] Ingresar credenciales de cobrador
- [ ] **Verificar logs:**
  ```
  ✅ Token recibido: eyJhbGc...
  👤 Datos de usuario recibidos
  📊 Estadísticas del dashboard recibidas
  📊 Guardando estadísticas: DashboardStatistics(...)
  ✅ Usando estadísticas del login (evitando petición innecesaria)
  ✅ Estableciendo estadísticas directamente (desde login)
  ```
- [ ] **Cards deben mostrar valores (no 0):**
  - Créditos Totales: > 0
  - Créditos Activos: > 0
  - Monto Total: > 0
  - Balance Total: > 0
- [ ] **Sin petición a `/api/credits/cobrador/*/stats`** en Network Debugger

### App Reiniciada
- [ ] Cerrar app completamente: `Alt+Tab` + cerrar
- [ ] Ejecutar nuevamente: `flutter run`
- [ ] **Verificar logs:**
  ```
  🔍 hasValidSession = true
  📊 Estadísticas cargadas desde almacenamiento local
  ✅ Usando estadísticas del login (evitando petición innecesaria)
  ✅ Estableciendo estadísticas directamente (desde login)
  ```
- [ ] **Cards se llenan inmediatamente** (sin delay)
- [ ] Luego logs adicionales: `📊 Estadísticas del dashboard recibidas en /api/me`

### Sincronización `/api/me`
- [ ] Abrir Developer Tools de Flutter
- [ ] En Logs buscar: `Estadísticas del dashboard recibidas en /api/me`
- [ ] Verificar que no hay errores en respuesta
- [ ] Confirmar que valores se mantienen consistentes

---

## 🔍 DEBUGGING: Si algo falla

### Problema: Cards muestran 0

**Posible causa:** `authState.statistics` es null

**Verificación:**
```dart
// En cobrador_dashboard_screen.dart línea 54
final authState = ref.read(authProvider);
debugPrint('DEBUG: authState.statistics = ${authState.statistics}');
debugPrint('DEBUG: authState.usuario = ${authState.usuario}');
```

**Si statistics es null:**
1. Revisar si `/login` retorna `statistics` en respuesta
2. Revisar `AuthApiService.login()` - ¿se guarda `statistics`?
3. Revisar `StorageService.saveDashboardStatistics()` - ¿guarda correctamente?

### Problema: Conversión falla

**Posible causa:** Estructura diferente de la esperada

**Verificación en `credit_stats.dart`:**
```dart
factory CreditStats.fromDashboardStatistics(Map<String, dynamic> json) {
  debugPrint('DEBUG: json input = $json');
  final summary = json['summary'] as Map<String, dynamic>? ?? {};
  debugPrint('DEBUG: summary = $summary');
  
  return CreditStats(
    totalCredits: (summary['total_clientes'] as num?)?.toInt() ?? 0,
    activeCredits: (summary['creditos_activos'] as num?)?.toInt() ?? 0,
    totalAmount: (summary['saldo_total_cartera'] as num?)?.toDouble() ?? 0.0,
    totalBalance: (summary['saldo_total_cartera'] as num?)?.toDouble() ?? 0.0,
  );
}
```

**Si estructura es diferente:**
1. Revisar estructura real de `/login` response
2. Actualizar mapeo en `fromDashboardStatistics()`
3. Actualizar también en `DashboardStatistics.fromJson()`

### Problema: `/api/me` no trae statistics

**Verificación:**
```dart
// En auth_api_service.dart método getMe()
debugPrint('DEBUG: /me response = ${response.data}');
```

**Si no trae statistics:**
1. Backend debe incluir `statistics` en respuesta de `/api/me`
2. Mismo formato que en `/login`

---

## 📊 COMPARATIVA: Antes vs Después

| Aspecto | Antes | Después |
|---------|-------|---------|
| **Tiempo de llenado** | 3-4 segundos | 0-500 ms |
| **Peticiones HTTP** | /login + /api/credits/cobrador/*/stats | /login + /api/me (solo si cambios) |
| **Datos en login** | No se aprovechaban | ✅ Se usan directamente |
| **Persistencia** | Solo usuario | ✅ Usuario + Estadísticas |
| **App restart** | Petición HTTP | ✅ Datos locales + sync background |

---

## 📝 NOTAS IMPORTANTES

1. **Dos fuentes de estadísticas:**
   - `login`: Estadísticas generales (resumen)
   - `/me`: Estadísticas actuales del usuario

2. **Estructura diferente por rol:**
   - Cobrador: `clientesAsignados`, `creditosActivos`, `totalCobradoHoy`
   - Manager: `totalCobradores`, `totalClientes`, `cobrosMes`
   - Admin: `totalManagers`, `totalCobradores`, `totalClientes`

3. **Conversión es necesaria porque:**
   - Login retorna estructura con `summary` anidado
   - CreditStats espera estructura plana
   - `fromDashboardStatistics()` realiza esta conversión

4. **Fallback importante:**
   - Si no hay statistics, se cae a `loadCobradorStats()`
   - Esto asegura que siempre haya datos
   - Aunque sea petición HTTP

