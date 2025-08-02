# Arquitectura del Sistema de Autenticación

## Diagrama de Arquitectura General

```mermaid
graph TB
    subgraph "Capa de Presentación"
        A[LoginScreen]
        B[SplashScreen]
        C[HomeScreen]
        D[PerfilScreen]
    end
    
    subgraph "Capa de Negocio"
        E[AuthProvider]
        F[AuthState]
    end
    
    subgraph "Capa de Datos"
        G[ApiService]
        H[StorageService]
    end
    
    subgraph "Almacenamiento Local"
        I[SharedPreferences]
    end
    
    subgraph "Backend"
        J[API REST]
        K[Base de Datos]
    end
    
    A --> E
    B --> E
    C --> E
    D --> E
    
    E --> G
    E --> H
    
    G --> J
    H --> I
    
    J --> K
```

## Flujo de Datos Detallado

### 1. Inicialización de la App

```mermaid
flowchart TD
    A[App inicia] --> B[ProviderScope]
    B --> C[MyApp]
    C --> D[initialize()]
    D --> E[StorageService.hasValidSession()]
    E --> F{¿Hay sesión?}
    F -->|Sí| G[restoreSession()]
    F -->|No| H[ir a LoginScreen]
    G --> I[getToken() + getUser()]
    I --> J[setState(usuario)]
    J --> K[ir a HomeScreen]
```

### 2. Proceso de Login

```mermaid
flowchart TD
    A[Usuario ingresa datos] --> B[Validar formulario]
    B --> C[AuthProvider.login()]
    C --> D[ApiService.login()]
    D --> E[POST /api/login]
    E --> F{¿Respuesta exitosa?}
    F -->|Sí| G[saveToken()]
    F -->|No| H[Mostrar error]
    G --> I[saveUser()]
    I --> J[setRememberMe()]
    J --> K[setLastLogin()]
    K --> L[setState(usuario)]
    L --> M[Navegar a Home]
```

### 3. Gestión de Estado

```mermaid
stateDiagram-v2
    [*] --> Inicializando: App inicia
    Inicializando --> Autenticado: Sesión válida encontrada
    Inicializando --> NoAutenticado: Sin sesión
    NoAutenticado --> Login: Usuario ingresa credenciales
    Login --> Autenticado: Login exitoso
    Login --> NoAutenticado: Login fallido
    Autenticado --> NoAutenticado: Logout
    Autenticado --> Refreshing: Actualizar datos
    Refreshing --> Autenticado: Actualización exitosa
    Refreshing --> NoAutenticado: Error en actualización
```

## Estructura de Componentes

### StorageService - Gestión de Datos Locales

```mermaid
classDiagram
    class StorageService {
        -String _tokenKey
        -String _userKey
        -String _rememberMeKey
        -String _lastLoginKey
        +saveToken(String token)
        +getToken() String?
        +removeToken()
        +saveUser(Usuario usuario)
        +getUser() Usuario?
        +removeUser()
        +setRememberMe(bool remember)
        +getRememberMe() bool
        +setLastLogin(DateTime dateTime)
        +getLastLogin() DateTime?
        +hasValidSession() bool
        +clearSession()
        +getSessionInfo() Map
    }
```

### ApiService - Comunicación con Backend

```mermaid
classDiagram
    class ApiService {
        -String baseUrl
        -Dio _dio
        -StorageService _storageService
        -String? _token
        +login(String emailOrPhone, String password)
        +logout()
        +getMe()
        +checkExists(String emailOrPhone)
        +getLocalUser() Usuario?
        +hasValidSession() bool
        +restoreSession() bool
        -_loadToken()
        -_saveToken(String token)
        -_logout()
    }
```

### AuthProvider - Gestión de Estado

```mermaid
classDiagram
    class AuthState {
        +Usuario? usuario
        +bool isLoading
        +String? error
        +bool isInitialized
        +bool isAuthenticated
        +bool isCobrador
        +bool isJefe
        +bool isCliente
    }
    
    class AuthNotifier {
        -ApiService _apiService
        -StorageService _storageService
        +initialize()
        +login(String emailOrPhone, String password, bool rememberMe)
        +logout()
        +refreshUser()
        +clearError()
        +checkExists(String emailOrPhone)
        +getSessionInfo()
    }
    
    AuthNotifier --> AuthState
```

## Flujo de Datos en Memoria

```mermaid
sequenceDiagram
    participant UI as Pantalla
    participant State as AuthState
    participant Notifier as AuthNotifier
    participant API as ApiService
    participant Storage as StorageService

    Note over UI,Storage: Flujo de actualización de estado
    
    UI->>Notifier: login(credentials)
    Notifier->>State: copyWith(isLoading: true)
    Notifier->>API: login(credentials)
    API->>Storage: saveToken(token)
    API->>Storage: saveUser(user)
    API-->>Notifier: response
    Notifier->>State: copyWith(usuario: user, isLoading: false)
    State-->>UI: Rebuild con nuevo estado
```

## Manejo de Errores

```mermaid
flowchart TD
    A[Operación] --> B{¿Éxito?}
    B -->|Sí| C[Continuar]
    B -->|No| D[Capturar error]
    D --> E{¿Tipo de error?}
    E -->|Conexión| F[Mostrar error de red]
    E -->|Autenticación| G[Limpiar sesión]
    E -->|Datos corruptos| H[Eliminar datos locales]
    E -->|Otro| I[Mostrar error genérico]
    F --> J[Reintentar]
    G --> K[Ir a login]
    H --> L[Reinicializar]
    I --> M[Mostrar mensaje]
```

## Seguridad y Validación

```mermaid
graph LR
    A[Entrada de Usuario] --> B[Validación Frontend]
    B --> C[Enviar a Backend]
    C --> D[Validación Backend]
    D --> E[Generar Token]
    E --> F[Guardar Localmente]
    F --> G[Encriptar Datos]
    G --> H[Verificar en Uso]
```

## Optimizaciones Implementadas

### 1. Carga Lazy
```mermaid
flowchart TD
    A[App inicia] --> B[Cargar datos básicos]
    B --> C[Mostrar splash]
    C --> D[Verificar sesión]
    D --> E{Cargar pantalla completa}
    E -->|Sí| F[Cargar HomeScreen]
    E -->|No| G[Cargar LoginScreen]
```

### 2. Cache de Datos
```mermaid
flowchart TD
    A[Solicitud de datos] --> B{¿En cache?}
    B -->|Sí| C[Usar datos locales]
    B -->|No| D[Llamar API]
    D --> E[Guardar en cache]
    E --> C
    C --> F[Actualizar UI]
```

### 3. Manejo Offline
```mermaid
flowchart TD
    A[Operación] --> B{¿Conexión?}
    B -->|Sí| C[Ejecutar normalmente]
    B -->|No| D[Usar datos locales]
    D --> E[Mostrar indicador offline]
    E --> F[Reintentar cuando conecte]
```

## Métricas y Monitoreo

```mermaid
graph TD
    A[Eventos de Usuario] --> B[Login Exitoso]
    A --> C[Login Fallido]
    A --> D[Logout]
    A --> E[Tiempo de Sesión]
    
    B --> F[Analytics]
    C --> F
    D --> F
    E --> F
    
    F --> G[Dashboard]
    F --> H[Alertas]
```

## Consideraciones de Performance

1. **Inicialización rápida**: Verificación de sesión en paralelo
2. **Carga progresiva**: Datos críticos primero
3. **Cache inteligente**: Datos de usuario en memoria
4. **Limpieza automática**: Datos obsoletos se eliminan
5. **Optimización de red**: Requests agrupados

## Escalabilidad

```mermaid
graph LR
    A[Usuario Único] --> B[Múltiples Usuarios]
    B --> C[Roles Diferentes]
    C --> D[Permisos Granulares]
    D --> E[Sincronización Multi-dispositivo]
```

Esta arquitectura proporciona una base sólida para el sistema de autenticación, con separación clara de responsabilidades, manejo robusto de errores y optimizaciones para una mejor experiencia de usuario. 