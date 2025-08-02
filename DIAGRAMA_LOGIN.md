# Diagrama de Secuencia - Sistema de Login

## Flujo de Autenticación Completo

### 1. Inicialización de la Aplicación

```mermaid
sequenceDiagram
    participant App as Aplicación
    participant Auth as AuthProvider
    participant Storage as StorageService
    participant API as ApiService
    participant UI as Pantalla

    App->>Auth: initialize()
    Auth->>Storage: hasValidSession()
    Storage-->>Auth: true/false
    
    alt Sesión válida existe
        Auth->>API: restoreSession()
        API->>Storage: getToken()
        Storage-->>API: token
        API->>Storage: getUser()
        Storage-->>API: user
        Auth->>UI: setState(usuario)
        UI->>UI: Navegar a HomeScreen
    else No hay sesión válida
        Auth->>UI: setState(no autenticado)
        UI->>UI: Navegar a LoginScreen
    end
```

### 2. Proceso de Login

```mermaid
sequenceDiagram
    participant User as Usuario
    participant UI as LoginScreen
    participant Auth as AuthProvider
    participant API as ApiService
    participant Storage as StorageService
    participant Backend as Backend API

    User->>UI: Ingresa email/teléfono + password
    User->>UI: Marca "Recordarme"
    User->>UI: Presiona "Iniciar Sesión"
    
    UI->>Auth: login(emailOrPhone, password, rememberMe)
    Auth->>API: login(emailOrPhone, password)
    API->>Backend: POST /api/login
    Note over API,Backend: {email_or_phone, password}
    
    Backend-->>API: {token, user}
    API->>Storage: saveToken(token)
    API->>Storage: saveUser(user)
    API-->>Auth: response
    
    Auth->>Storage: setRememberMe(rememberMe)
    Auth->>Storage: setLastLogin(DateTime.now())
    Auth->>UI: setState(usuario)
    
    UI->>UI: Navegar a HomeScreen
```

### 3. Verificación de Sesión en Inicio

```mermaid
sequenceDiagram
    participant App as Aplicación
    participant Auth as AuthProvider
    participant Storage as StorageService
    participant API as ApiService
    participant UI as Pantalla

    App->>Auth: initialize()
    Auth->>Storage: hasValidSession()
    Storage->>Storage: getToken() && getUser()
    Storage-->>Auth: true/false
    
    alt Sesión válida
        Auth->>API: restoreSession()
        API->>Storage: getToken()
        Storage-->>API: token
        API->>API: _token = token
        API-->>Auth: true
        Auth->>Storage: getUser()
        Storage-->>Auth: usuario
        Auth->>UI: setState(usuario, isInitialized: true)
        UI->>UI: Mostrar HomeScreen
    else No hay sesión
        Auth->>UI: setState(isInitialized: true)
        UI->>UI: Mostrar LoginScreen
    end
```

### 4. Logout

```mermaid
sequenceDiagram
    participant User as Usuario
    participant UI as PerfilScreen
    participant Auth as AuthProvider
    participant API as ApiService
    participant Storage as StorageService
    participant Backend as Backend API

    User->>UI: Presiona botón logout
    UI->>UI: Mostrar diálogo de confirmación
    User->>UI: Confirma logout
    
    UI->>Auth: logout()
    Auth->>API: logout()
    API->>Backend: POST /api/logout
    
    alt Conexión disponible
        Backend-->>API: 200 OK
    else Sin conexión
        API->>API: Manejar error
    end
    
    API->>Storage: clearSession()
    Storage->>Storage: removeToken()
    Storage->>Storage: removeUser()
    Storage->>Storage: removeLastLogin()
    
    Auth->>UI: setState(no autenticado)
    UI->>UI: Navegar a LoginScreen
```

### 5. Flujo de Errores

```mermaid
sequenceDiagram
    participant User as Usuario
    participant UI as LoginScreen
    participant Auth as AuthProvider
    participant API as ApiService
    participant Backend as Backend API

    User->>UI: Ingresa credenciales incorrectas
    UI->>Auth: login(emailOrPhone, password)
    Auth->>API: login(emailOrPhone, password)
    API->>Backend: POST /api/login
    
    Backend-->>API: 401 Unauthorized
    API-->>Auth: Exception('Error de conexión')
    Auth->>UI: setState(error: 'Error de conexión')
    UI->>UI: Mostrar SnackBar con error
```

## Componentes del Sistema

### StorageService
- **saveToken()**: Guarda el token JWT
- **getToken()**: Obtiene el token guardado
- **saveUser()**: Guarda datos del usuario
- **getUser()**: Obtiene datos del usuario
- **setRememberMe()**: Guarda preferencia "Recordarme"
- **hasValidSession()**: Verifica si hay sesión válida
- **clearSession()**: Limpia todos los datos de sesión

### ApiService
- **login()**: Realiza login con email/teléfono
- **logout()**: Realiza logout
- **restoreSession()**: Restaura sesión desde almacenamiento
- **getMe()**: Obtiene datos del usuario actual

### AuthProvider
- **initialize()**: Inicializa la aplicación
- **login()**: Maneja el proceso de login
- **logout()**: Maneja el proceso de logout
- **refreshUser()**: Actualiza datos del usuario

## Estados de la Aplicación

```mermaid
stateDiagram-v2
    [*] --> Inicializando
    Inicializando --> Autenticado: Sesión válida
    Inicializando --> NoAutenticado: Sin sesión
    NoAutenticado --> Login: Usuario ingresa credenciales
    Login --> Autenticado: Login exitoso
    Login --> NoAutenticado: Login fallido
    Autenticado --> NoAutenticado: Logout
    Autenticado --> [*]
    NoAutenticado --> [*]
```

## Datos Almacenados

```mermaid
graph TD
    A[SharedPreferences] --> B[auth_token]
    A --> C[user_data]
    A --> D[remember_me]
    A --> E[last_login]
    
    B --> F[JWT Token]
    C --> G[Datos del Usuario]
    D --> H[Boolean]
    E --> I[DateTime]
```

## Consideraciones de Seguridad

1. **Almacenamiento seguro**: SharedPreferences encriptado
2. **Limpieza automática**: Datos se eliminan al logout
3. **Manejo de errores**: Datos corruptos se eliminan
4. **Validación**: Verificación de token y usuario
5. **Confirmación**: Diálogo antes de logout

## Flujo de Navegación

```mermaid
graph TD
    A[SplashScreen] --> B{¿Sesión válida?}
    B -->|Sí| C[HomeScreen]
    B -->|No| D[LoginScreen]
    D --> E{¿Login exitoso?}
    E -->|Sí| C
    E -->|No| D
    C --> F[PerfilScreen]
    F --> G{¿Logout?}
    G -->|Sí| D
    G -->|No| C
```

Este diagrama muestra el flujo completo del sistema de autenticación implementado, incluyendo la persistencia de sesión, manejo de errores y navegación entre pantallas. 