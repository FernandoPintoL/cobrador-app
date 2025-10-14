# Integración WebSocket con Flutter - Guía Completa

## 📱 Documentación para Desarrolladores Frontend

Esta guía detalla cómo integrar el sistema de notificaciones en tiempo real usando WebSocket (Socket.IO) desde Flutter.

---

## 📋 Tabla de Contenidos

1. [Configuración Inicial](#1-configuración-inicial)
2. [Estructura de Conexión](#2-estructura-de-conexión)
3. [Autenticación](#3-autenticación)
4. [Canales y Eventos](#4-canales-y-eventos)
5. [Implementación en Flutter](#5-implementación-en-flutter)
6. [Flujos de Trabajo](#6-flujos-de-trabajo)
7. [Manejo de Errores](#7-manejo-de-errores)
8. [Buenas Prácticas](#8-buenas-prácticas)

---

## 1. Configuración Inicial

### 1.1 Agregar Dependencias

Agrega `socket_io_client` a tu `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  socket_io_client: ^2.0.3+1
  # Otras dependencias útiles
  provider: ^6.1.1  # Para estado global
  flutter_local_notifications: ^16.3.0  # Para notificaciones
```

```bash
flutter pub get
```

### 1.2 Configuración del Servidor

**URL del Servidor WebSocket:**
```dart
// Desarrollo
const String WEBSOCKET_URL = 'http://192.168.1.23:3001';

// Producción (cuando despliegues)
const String WEBSOCKET_URL = 'https://websocket.tu-dominio.com';
```

**Importante:**
- En desarrollo, usa la IP de tu red local
- En producción, usa HTTPS (wss://)
- El puerto por defecto es `3001`

---

## 2. Estructura de Conexión

### 2.1 Información del Usuario

Para conectarse, necesitas estos datos del usuario autenticado:

```dart
class UserData {
  final String id;          // ID del usuario
  final String name;        // Nombre completo
  final String email;       // Email
  final String userType;    // 'cobrador', 'manager', 'admin', 'client'

  UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
  });
}
```

### 2.2 Tipos de Usuario (Roles)

Los `userType` válidos son:
- `'cobrador'` - Cobrador
- `'manager'` - Gerente/Manager
- `'admin'` - Administrador
- `'client'` - Cliente

**Importante:** El `userType` determina qué notificaciones recibirás.

---

## 3. Autenticación

### 3.1 Flujo de Autenticación

```
[Flutter] → Conexión → [WebSocket Server]
          ↓
[Flutter] → Emitir 'authenticate' con datos
          ↓
[WebSocket] → Verifica datos
          ↓
[WebSocket] → Emite 'authenticated' (éxito) o 'authentication_error' (fallo)
          ↓
[Flutter] → Se une a salas (rooms) según rol
```

### 3.2 Proceso Paso a Paso

1. **Conectar al servidor**
2. **Emitir evento `authenticate`** con datos del usuario
3. **Escuchar respuesta `authenticated`** (éxito)
4. **Escuchar `authentication_error`** (error)
5. **Una vez autenticado**, el servidor te une automáticamente a:
   - Sala personal: `user_{id}`
   - Sala de rol: `{userType}s` (ej: `cobradores`, `managers`)

---

## 4. Canales y Eventos

### 4.1 Eventos que EMITES (Flutter → Servidor)

| Evento | Descripción | Datos Requeridos |
|--------|-------------|------------------|
| `authenticate` | Autenticarte al conectar | `{ userId, userName, userType }` |
| `disconnect` | Desconectarse (automático) | - |

### 4.2 Eventos que ESCUCHAS (Servidor → Flutter)

#### 4.2.1 Eventos de Autenticación

| Evento | Cuándo se emite | Datos Recibidos |
|--------|-----------------|-----------------|
| `authenticated` | Autenticación exitosa | `{ success, message, userData }` |
| `authentication_error` | Error de autenticación | `{ success, message, error }` |

#### 4.2.2 Eventos de Créditos (Para MANAGERS)

| Evento | Descripción | Cuándo se emite |
|--------|-------------|-----------------|
| `credit_waiting_approval` | Nuevo crédito pendiente | Cobrador crea crédito |
| `credit_delivered` | Crédito entregado | Cobrador entrega crédito |

**Estructura de datos:**
```dart
{
  "action": "created" | "delivered",
  "creditId": 123,
  "credit": {
    "id": 123,
    "amount": 5000.00,
    "total_amount": 5500.00,
    "client_name": "Juan Pérez",
    "frequency": "daily",
    "status": "pending_approval"
  },
  "cobrador": {
    "id": "45",
    "name": "Carlos López",
    "email": "carlos@example.com"
  },
  "message": "El cobrador Carlos López ha creado un crédito...",
  "timestamp": "2025-10-11T14:30:00Z"
}
```

#### 4.2.3 Eventos de Créditos (Para COBRADORES)

| Evento | Descripción | Cuándo se emite |
|--------|-------------|-----------------|
| `credit_approved` | Crédito aprobado | Manager aprueba crédito |
| `credit_rejected` | Crédito rechazado | Manager rechaza crédito |

**Estructura de datos:**
```dart
{
  "title": "Crédito aprobado",
  "type": "credit_approved",
  "credit": {
    "id": 123,
    "amount": 5000.00,
    "total_amount": 5500.00,
    "status": "waiting_delivery",
    "scheduled_delivery_date": "2025-10-12",
    "entrega_inmediata": false
  },
  "manager": {
    "id": "12",
    "name": "María González",
    "email": "maria@example.com"
  },
  "message": "Tu crédito de $5000.00 ha sido aprobado por María González (Entrega inmediata: No)",
  "timestamp": "2025-10-11T14:35:00Z"
}
```

#### 4.2.4 Eventos de Pagos (Para COBRADORES)

| Evento | Descripción | Cuándo se emite |
|--------|-------------|-----------------|
| `payment_received` | Pago registrado | Se registra un pago |

**Estructura de datos:**
```dart
{
  "title": "Pago realizado",
  "type": "payment_received",
  "payment": {
    "id": 456,
    "amount": 150.00,
    "payment_date": "2025-10-11",
    "status": "completed"
  },
  "client": {
    "id": "78",
    "name": "Ana Martínez"
  },
  "message": "Has realizado un pago de $150.00 de Ana Martínez",
  "timestamp": "2025-10-11T15:00:00Z"
}
```

#### 4.2.5 Eventos de Pagos (Para MANAGERS)

| Evento | Descripción | Cuándo se emite |
|--------|-------------|-----------------|
| `cobrador_payment_received` | Pago de cobrador | Cobrador registra pago |

**Estructura de datos:**
```dart
{
  "title": "Pago de cobrador recibido",
  "type": "cobrador_payment_received",
  "payment": {
    "id": 456,
    "amount": 150.00,
    "payment_date": "2025-10-11"
  },
  "cobrador": {
    "id": "45",
    "name": "Carlos López"
  },
  "client": {
    "id": "78",
    "name": "Ana Martínez"
  },
  "message": "El cobrador Carlos López recibió un pago de $150.00 de Ana Martínez",
  "timestamp": "2025-10-11T15:00:00Z"
}
```

#### 4.2.6 Eventos de Cajas (Para COBRADORES)

| Evento | Descripción | Cuándo se emite |
|--------|-------------|-----------------|
| `cash_balance_reminder` | Recordatorio de caja | Diariamente si hay cajas sin cerrar |

**Estructura de datos:**
```dart
{
  "title": "Recordatorio de Cierre de Caja",
  "message": "Tienes 2 cajas sin cerrar de los días: 08/10/2025, 09/10/2025. Por favor, ciérralas antes de iniciar un nuevo día.",
  "pending_count": 2,
  "pending_dates": ["08/10/2025", "09/10/2025"],
  "pending_boxes": [
    {
      "id": 123,
      "date": "2025-10-08",
      "initial_amount": 1000.00,
      "collected_amount": 5000.00,
      "lent_amount": 3000.00,
      "final_amount": 3000.00
    }
  ]
}
```

#### 4.2.7 Eventos de Sistema

| Evento | Descripción | Cuándo se emite |
|--------|-------------|-----------------|
| `user_connected` | Usuario conectado | Otro usuario se conecta |
| `user_disconnected` | Usuario desconectado | Otro usuario se desconecta |
| `server_shutdown` | Servidor apagándose | Mantenimiento |

---

## 5. Implementación en Flutter

### 5.1 Servicio WebSocket Completo

Crea `lib/services/websocket_service.dart`:

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  bool _isAuthenticated = false;

  // Getters
  bool get isConnected => _isConnected;
  bool get isAuthenticated => _isAuthenticated;
  IO.Socket? get socket => _socket;

  // Callbacks
  Function(Map<String, dynamic>)? onCreditWaitingApproval;
  Function(Map<String, dynamic>)? onCreditApproved;
  Function(Map<String, dynamic>)? onCreditRejected;
  Function(Map<String, dynamic>)? onCreditDelivered;
  Function(Map<String, dynamic>)? onPaymentReceived;
  Function(Map<String, dynamic>)? onCobradorPaymentReceived;
  Function(Map<String, dynamic>)? onCashBalanceReminder;
  Function()? onAuthenticated;
  Function(String)? onAuthenticationError;
  Function()? onConnectionError;
  Function()? onDisconnected;

  /// Conectar y autenticar
  Future<void> connect({
    required String serverUrl,
    required String userId,
    required String userName,
    required String userType, // 'cobrador', 'manager', 'admin', 'client'
  }) async {
    try {
      debugPrint('🔌 Conectando a WebSocket: $serverUrl');

      _socket = IO.io(
        serverUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _setupEventListeners(
        userId: userId,
        userName: userName,
        userType: userType,
      );

      _socket!.connect();

      debugPrint('✅ Socket conectado');
    } catch (e) {
      debugPrint('❌ Error conectando WebSocket: $e');
      onConnectionError?.call();
    }
  }

  /// Configurar listeners de eventos
  void _setupEventListeners({
    required String userId,
    required String userName,
    required String userType,
  }) {
    // Evento: Conexión exitosa
    _socket!.on('connect', (_) {
      debugPrint('✅ WebSocket conectado!');
      _isConnected = true;

      // Autenticarse automáticamente
      _authenticate(
        userId: userId,
        userName: userName,
        userType: userType,
      );
    });

    // Evento: Autenticación exitosa
    _socket!.on('authenticated', (data) {
      debugPrint('✅ Autenticado exitosamente: $data');
      _isAuthenticated = true;
      onAuthenticated?.call();
    });

    // Evento: Error de autenticación
    _socket!.on('authentication_error', (data) {
      debugPrint('❌ Error de autenticación: $data');
      _isAuthenticated = false;
      final message = data['message'] ?? 'Error de autenticación';
      onAuthenticationError?.call(message);
    });

    // Evento: Desconexión
    _socket!.on('disconnect', (_) {
      debugPrint('⚠️ WebSocket desconectado');
      _isConnected = false;
      _isAuthenticated = false;
      onDisconnected?.call();
    });

    // Evento: Error de conexión
    _socket!.on('connect_error', (error) {
      debugPrint('❌ Error de conexión: $error');
      onConnectionError?.call();
    });

    // EVENTOS DE CRÉDITOS (MANAGERS)
    _socket!.on('credit_waiting_approval', (data) {
      debugPrint('📨 Crédito pendiente de aprobación: $data');
      onCreditWaitingApproval?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('credit_delivered', (data) {
      debugPrint('📨 Crédito entregado: $data');
      onCreditDelivered?.call(Map<String, dynamic>.from(data));
    });

    // EVENTOS DE CRÉDITOS (COBRADORES)
    _socket!.on('credit_approved', (data) {
      debugPrint('📨 Crédito aprobado: $data');
      onCreditApproved?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('credit_rejected', (data) {
      debugPrint('📨 Crédito rechazado: $data');
      onCreditRejected?.call(Map<String, dynamic>.from(data));
    });

    // EVENTOS DE PAGOS
    _socket!.on('payment_received', (data) {
      debugPrint('📨 Pago recibido: $data');
      onPaymentReceived?.call(Map<String, dynamic>.from(data));
    });

    _socket!.on('cobrador_payment_received', (data) {
      debugPrint('📨 Pago de cobrador: $data');
      onCobradorPaymentReceived?.call(Map<String, dynamic>.from(data));
    });

    // EVENTOS DE CAJAS
    _socket!.on('cash_balance_reminder', (data) {
      debugPrint('📨 Recordatorio de caja: $data');
      onCashBalanceReminder?.call(Map<String, dynamic>.from(data));
    });

    // EVENTOS DE SISTEMA
    _socket!.on('user_connected', (data) {
      debugPrint('👤 Usuario conectado: $data');
    });

    _socket!.on('user_disconnected', (data) {
      debugPrint('👤 Usuario desconectado: $data');
    });

    _socket!.on('server_shutdown', (data) {
      debugPrint('⚠️ Servidor apagándose: $data');
    });
  }

  /// Autenticarse con el servidor
  void _authenticate({
    required String userId,
    required String userName,
    required String userType,
  }) {
    debugPrint('🔐 Autenticando como: $userName ($userType)');

    _socket!.emit('authenticate', {
      'userId': userId,
      'userName': userName,
      'userType': userType,
    });
  }

  /// Desconectar
  void disconnect() {
    debugPrint('👋 Desconectando WebSocket...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _isAuthenticated = false;
  }

  /// Reconectar
  Future<void> reconnect({
    required String serverUrl,
    required String userId,
    required String userName,
    required String userType,
  }) async {
    disconnect();
    await Future.delayed(const Duration(seconds: 1));
    await connect(
      serverUrl: serverUrl,
      userId: userId,
      userName: userName,
      userType: userType,
    );
  }
}
```

### 5.2 Provider para Estado Global (Opcional pero recomendado)

Crea `lib/providers/websocket_provider.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';

class WebSocketProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();

  bool get isConnected => _wsService.isConnected;
  bool get isAuthenticated => _wsService.isAuthenticated;

  List<Map<String, dynamic>> notifications = [];

  void initializeWebSocket({
    required String serverUrl,
    required String userId,
    required String userName,
    required String userType,
  }) {
    // Setup callbacks
    _wsService.onAuthenticated = () {
      debugPrint('✅ Provider: Autenticado');
      notifyListeners();
    };

    _wsService.onAuthenticationError = (message) {
      debugPrint('❌ Provider: Error autenticación - $message');
      notifyListeners();
    };

    _wsService.onCreditWaitingApproval = (data) {
      _addNotification('credit_waiting_approval', data);
    };

    _wsService.onCreditApproved = (data) {
      _addNotification('credit_approved', data);
    };

    _wsService.onCreditRejected = (data) {
      _addNotification('credit_rejected', data);
    };

    _wsService.onCreditDelivered = (data) {
      _addNotification('credit_delivered', data);
    };

    _wsService.onPaymentReceived = (data) {
      _addNotification('payment_received', data);
    };

    _wsService.onCobradorPaymentReceived = (data) {
      _addNotification('cobrador_payment_received', data);
    };

    _wsService.onCashBalanceReminder = (data) {
      _addNotification('cash_balance_reminder', data);
    };

    _wsService.onDisconnected = () {
      debugPrint('⚠️ Provider: Desconectado');
      notifyListeners();
    };

    // Conectar
    _wsService.connect(
      serverUrl: serverUrl,
      userId: userId,
      userName: userName,
      userType: userType,
    );
  }

  void _addNotification(String type, Map<String, dynamic> data) {
    notifications.insert(0, {
      'type': type,
      'data': data,
      'timestamp': DateTime.now(),
    });

    // Limitar a 50 notificaciones
    if (notifications.length > 50) {
      notifications.removeLast();
    }

    notifyListeners();
  }

  void clearNotifications() {
    notifications.clear();
    notifyListeners();
  }

  void disconnect() {
    _wsService.disconnect();
    notifyListeners();
  }

  @override
  void dispose() {
    _wsService.disconnect();
    super.dispose();
  }
}
```

### 5.3 Inicialización en la App

En `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/websocket_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WebSocketProvider()),
        // Otros providers...
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cobrador App',
      home: HomeScreen(),
    );
  }
}
```

### 5.4 Conectar Después de Login

Después de que el usuario inicia sesión exitosamente:

```dart
import 'package:provider/provider.dart';
import '../providers/websocket_provider.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Future<void> _handleLogin(String email, String password) async {
    try {
      // 1. Hacer login con tu API
      final response = await _authService.login(email, password);

      // 2. Obtener datos del usuario
      final user = response.data['user'];
      final userId = user['id'].toString();
      final userName = user['name'];
      final userRole = user['roles'][0]['name']; // 'cobrador', 'manager', etc.

      // 3. Guardar token y usuario en storage local
      await _saveUserData(user, response.data['token']);

      // 4. Conectar WebSocket
      final wsProvider = Provider.of<WebSocketProvider>(context, listen: false);
      wsProvider.initializeWebSocket(
        serverUrl: 'http://192.168.1.23:3001',
        userId: userId,
        userName: userName,
        userType: userRole,
      );

      // 5. Navegar al home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen()),
      );

    } catch (e) {
      // Manejar error
      print('Error en login: $e');
    }
  }
}
```

### 5.5 Mostrar Notificaciones

Widget de ejemplo para mostrar notificaciones:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/websocket_provider.dart';

class NotificationsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, wsProvider, child) {
        if (!wsProvider.isAuthenticated) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Desconectado del servidor'),
              ],
            ),
          );
        }

        if (wsProvider.notifications.isEmpty) {
          return Center(child: Text('No hay notificaciones'));
        }

        return ListView.builder(
          itemCount: wsProvider.notifications.length,
          itemBuilder: (context, index) {
            final notification = wsProvider.notifications[index];
            return _buildNotificationCard(notification);
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'];
    final data = notification['data'];
    final timestamp = notification['timestamp'] as DateTime;

    IconData icon;
    Color color;
    String title;

    switch (type) {
      case 'credit_waiting_approval':
        icon = Icons.pending_actions;
        color = Colors.orange;
        title = 'Crédito Pendiente';
        break;
      case 'credit_approved':
        icon = Icons.check_circle;
        color = Colors.green;
        title = 'Crédito Aprobado';
        break;
      case 'credit_rejected':
        icon = Icons.cancel;
        color = Colors.red;
        title = 'Crédito Rechazado';
        break;
      case 'payment_received':
        icon = Icons.attach_money;
        color = Colors.blue;
        title = 'Pago Recibido';
        break;
      case 'cash_balance_reminder':
        icon = Icons.warning;
        color = Colors.amber;
        title = 'Recordatorio de Caja';
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
        title = 'Notificación';
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(data['message'] ?? 'Sin mensaje'),
        trailing: Text(
          _formatTimestamp(timestamp),
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        onTap: () {
          // Navegar a detalle o hacer acción
        },
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
```

---

## 6. Flujos de Trabajo

### 6.1 Flujo: Cobrador Crea Crédito

```
1. [Flutter] Cobrador completa formulario de crédito
2. [Flutter] POST /api/credits → [Laravel API]
3. [Laravel] Crea crédito con status 'pending_approval'
4. [Laravel] Dispara evento CreditCreated
5. [Laravel] Listener envía HTTP POST → [WebSocket Server]
6. [WebSocket] Emite 'credit_waiting_approval' → [Manager]
7. [Flutter Manager] Recibe notificación
8. [Flutter Manager] Muestra "Nuevo crédito de $5000 pendiente"
```

**Código Flutter (Cobrador):**
```dart
// Ya implementado en tu formulario existente
// Solo asegúrate de que el endpoint POST /api/credits funcione
```

**Código Flutter (Manager):**
```dart
// En initState o donde inicialices WebSocket
wsProvider.onCreditWaitingApproval = (data) {
  showNotification(
    title: 'Nuevo Crédito Pendiente',
    message: data['message'],
    action: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreditDetailScreen(creditId: data['creditId']),
      ),
    ),
  );
};
```

### 6.2 Flujo: Manager Aprueba Crédito

```
1. [Flutter Manager] Aprueba crédito
2. [Flutter] POST /api/credits/{id}/waiting-list/approve → [Laravel]
3. [Laravel] Cambia status a 'waiting_delivery'
4. [Laravel] Dispara evento CreditApproved
5. [WebSocket] Emite 'credit_approved' → [Cobrador]
6. [Flutter Cobrador] Recibe notificación
7. [Flutter Cobrador] Muestra "Tu crédito de $5000 fue aprobado"
```

**Código Flutter (Manager):**
```dart
Future<void> approveCredit(int creditId) async {
  try {
    final response = await http.post(
      Uri.parse('$API_URL/credits/$creditId/waiting-list/approve'),
      headers: {'Authorization': 'Bearer $token'},
      body: jsonEncode({
        'immediate_delivery': false,
        'scheduled_delivery_date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      // Éxito - el cobrador recibirá notificación automáticamente
      showSnackBar('Crédito aprobado exitosamente');
    }
  } catch (e) {
    print('Error aprobando crédito: $e');
  }
}
```

**Código Flutter (Cobrador):**
```dart
wsProvider.onCreditApproved = (data) {
  final entregaInmediata = data['credit']['entrega_inmediata'] ?? false;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('✅ Crédito Aprobado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['message']),
          SizedBox(height: 8),
          Text('Monto: \$${data['credit']['amount']}'),
          Text('Entrega inmediata: ${entregaInmediata ? 'Sí' : 'No'}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
        if (entregaInmediata)
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliverCreditScreen(creditId: data['credit']['id']),
                ),
              );
            },
            child: Text('Entregar Ahora'),
          ),
      ],
    ),
  );
};
```

### 6.3 Flujo: Cobrador Registra Pago

```
1. [Flutter Cobrador] Registra pago
2. [Flutter] POST /api/payments → [Laravel]
3. [Laravel] Crea pago
4. [Laravel] Dispara evento PaymentCreated
5. [WebSocket] Emite:
   - 'payment_received' → [Cobrador]
   - 'cobrador_payment_received' → [Manager]
6. [Flutter] Ambos reciben notificación
```

**Código Flutter (Cobrador):**
```dart
wsProvider.onPaymentReceived = (data) {
  showSnackBar('Pago de \$${data['payment']['amount']} registrado');
};
```

**Código Flutter (Manager):**
```dart
wsProvider.onCobradorPaymentReceived = (data) {
  showNotification(
    title: 'Pago de ${data['cobrador']['name']}',
    message: 'Recibió \$${data['payment']['amount']} de ${data['client']['name']}',
  );
};
```

### 6.4 Flujo: Recordatorio de Caja

```
1. [Servidor] Cron ejecuta: php artisan cashbalance:send-reminders (18:00 PM)
2. [Laravel] Encuentra cajas abiertas de días anteriores
3. [WebSocket] Emite 'cash_balance_reminder' → [Cobrador]
4. [Flutter Cobrador] Recibe notificación
5. [Flutter] Muestra alerta persistente
```

**Código Flutter (Cobrador):**
```dart
wsProvider.onCashBalanceReminder = (data) {
  final pendingCount = data['pending_count'];
  final dates = (data['pending_dates'] as List).join(', ');

  showDialog(
    context: context,
    barrierDismissible: false, // No puede cerrar tocando fuera
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning, color: Colors.amber),
          SizedBox(width: 8),
          Text('⚠️ Cajas Pendientes'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['message']),
          SizedBox(height: 16),
          Text('Fechas pendientes:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text(dates),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Más tarde'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CashBalanceScreen()),
            );
          },
          child: Text('Cerrar Cajas Ahora'),
        ),
      ],
    ),
  );
};
```

---

## 7. Manejo de Errores

### 7.1 Reconexión Automática

Socket.IO ya maneja reconexión automática, pero puedes configurarlo:

```dart
_socket = IO.io(
  serverUrl,
  IO.OptionBuilder()
    .setTransports(['websocket'])
    .setReconnection(true)               // Habilitar reconexión
    .setReconnectionAttempts(5)          // 5 intentos
    .setReconnectionDelay(2000)          // 2 segundos entre intentos
    .setReconnectionDelayMax(10000)      // Máximo 10 segundos
    .build(),
);
```

### 7.2 Indicador de Estado de Conexión

Widget para mostrar estado:

```dart
class ConnectionStatusIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<WebSocketProvider>(
      builder: (context, wsProvider, child) {
        Color color;
        String text;
        IconData icon;

        if (wsProvider.isAuthenticated) {
          color = Colors.green;
          text = 'Conectado';
          icon = Icons.wifi;
        } else if (wsProvider.isConnected) {
          color = Colors.orange;
          text = 'Autenticando...';
          icon = Icons.wifi_tethering;
        } else {
          color = Colors.red;
          text = 'Desconectado';
          icon = Icons.wifi_off;
        }

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

Úsalo en tu AppBar:

```dart
AppBar(
  title: Text('Dashboard'),
  actions: [
    Padding(
      padding: EdgeInsets.only(right: 16),
      child: ConnectionStatusIndicator(),
    ),
  ],
)
```

### 7.3 Manejar Desconexión

```dart
_wsService.onDisconnected = () {
  showSnackBar(
    'Conexión perdida. Reintentando...',
    backgroundColor: Colors.orange,
  );
};

_wsService.onConnectionError = () {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Error de Conexión'),
      content: Text('No se pudo conectar al servidor. Verifica tu conexión a internet.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Reintentar conexión
            wsProvider.reconnect(
              serverUrl: WEBSOCKET_URL,
              userId: user.id,
              userName: user.name,
              userType: user.role,
            );
          },
          child: Text('Reintentar'),
        ),
      ],
    ),
  );
};
```

---

## 8. Buenas Prácticas

### 8.1 Conectar Solo Cuando es Necesario

```dart
// ✅ BIEN: Conectar después de login exitoso
void onLoginSuccess(User user) {
  wsProvider.initializeWebSocket(/*...*/);
}

// ❌ MAL: Conectar antes de tener datos del usuario
void initState() {
  super.initState();
  wsProvider.initializeWebSocket(/*...*/); // No hay datos de usuario aún
}
```

### 8.2 Desconectar al Cerrar Sesión

```dart
Future<void> logout() async {
  // 1. Desconectar WebSocket
  Provider.of<WebSocketProvider>(context, listen: false).disconnect();

  // 2. Limpiar storage local
  await _clearUserData();

  // 3. Navegar a login
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(builder: (_) => LoginScreen()),
    (route) => false,
  );
}
```

### 8.3 Manejar Notificaciones en Background (Opcional)

Para notificaciones push reales, integra con Firebase Cloud Messaging:

```yaml
dependencies:
  firebase_messaging: ^14.7.4
  flutter_local_notifications: ^16.3.0
```

### 8.4 Limitar Notificaciones Almacenadas

```dart
void _addNotification(String type, Map<String, dynamic> data) {
  notifications.insert(0, {/*...*/});

  // Limitar a 50 notificaciones
  if (notifications.length > 50) {
    notifications.removeLast();
  }

  notifyListeners();
}
```

### 8.5 Testing

Para probar sin servidor real:

```dart
// Mock para testing
class MockWebSocketService extends WebSocketService {
  @override
  Future<void> connect({/*...*/}) async {
    _isConnected = true;
    _isAuthenticated = true;
    onAuthenticated?.call();
  }

  void simulateNotification(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'credit_approved':
        onCreditApproved?.call(data);
        break;
      // Otros casos...
    }
  }
}
```

---

## 9. Resumen de URLs y Puertos

| Ambiente | WebSocket URL | Puerto |
|----------|---------------|--------|
| Desarrollo Local | `http://192.168.1.23:3001` | 3001 |
| Producción | `https://websocket.tu-dominio.com` | 443 (HTTPS) |

---

## 10. Troubleshooting

### Problema: No recibo notificaciones

**Soluciones:**
1. Verificar que el servidor WebSocket está corriendo: `cd websocket-server && npm start`
2. Verificar conexión: `print(wsProvider.isAuthenticated);`
3. Verificar que el `userType` es correcto (`'cobrador'`, no `'Cobrador'`)
4. Revisar logs en terminal de Flutter

### Problema: Error de autenticación

**Soluciones:**
1. Verificar que `userId` es String: `userId.toString()`
2. Verificar que `userType` coincide exactamente: `'cobrador'`, `'manager'`, `'admin'`, `'client'`
3. Revisar logs del servidor WebSocket

### Problema: Reconexión fallida

**Soluciones:**
1. Verificar internet
2. Incrementar `reconnectionAttempts`
3. Implementar botón manual de reconexión

---

## 11. Ejemplo Completo Mínimo

```dart
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WebSocketDemo(),
    );
  }
}

class WebSocketDemo extends StatefulWidget {
  @override
  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  IO.Socket? socket;
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() {
    socket = IO.io('http://192.168.1.23:3001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });

    socket!.on('connect', (_) {
      print('✅ Conectado!');

      // Autenticar
      socket!.emit('authenticate', {
        'userId': '1',
        'userName': 'Juan Pérez',
        'userType': 'cobrador',
      });
    });

    socket!.on('authenticated', (data) {
      print('✅ Autenticado: $data');
      setState(() {
        messages.add('Autenticado correctamente');
      });
    });

    socket!.on('credit_approved', (data) {
      print('📨 Crédito aprobado: $data');
      setState(() {
        messages.add('Crédito aprobado: \$${data['credit']['amount']}');
      });
    });

    socket!.connect();
  }

  @override
  void dispose() {
    socket?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebSocket Demo')),
      body: ListView.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return ListTile(title: Text(messages[index]));
        },
      ),
    );
  }
}
```

---

## 📞 Contacto y Soporte

Si tienes problemas:
1. Verifica `DIAGNOSTICO_WEBSOCKET.md`
2. Ejecuta `php artisan websocket:test` en Laravel
3. Revisa logs de Flutter
4. Revisa logs del servidor WebSocket

---

**¡Listo para integrar! 🚀**
