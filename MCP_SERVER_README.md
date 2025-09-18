# Servidor MCP para Cobrador App

Este servidor MCP proporciona herramientas para gestionar funcionalidades de la aplicación cobrador Flutter.

## Instalación

El paquete `dart_mcp` ya está instalado como dependencia del proyecto.

## Configuración

### Para VS Code con MCP

Si estás usando VS Code con soporte para MCP, agrega esta configuración a tu archivo de configuración MCP:

```json
{
  "servers": {
    "cobrador_app_mcp": {
      "command": "dart",
      "args": [
        "bin/cobrador_mcp.dart"
      ],
      "env": {},
      "cwd": "ruta/completa/al/proyecto/app-cobrador"
    }
  }
}
```

### Para otros clientes MCP

Puedes ejecutar el servidor directamente desde la terminal:

```bash
# Método 1: Ejecutar directamente
dart bin/cobrador_mcp.dart

# Método 2: Usar el script de PowerShell
./start_mcp_server.ps1

# Método 3: Usar el script de batch (Windows)
start_mcp_server.bat
```

## Herramientas Disponibles

El servidor MCP proporciona las siguientes herramientas:

### 1. `get_clients`

Obtiene la lista de clientes disponibles.

**Parámetros:**

- `filter` (opcional): Filtro para buscar clientes por nombre

**Ejemplo de uso:**

```json
{
  "name": "get_clients",
  "arguments": {
    "filter": "Juan"
  }
}
```

### 2. `create_payment`

Crea un nuevo registro de pago.

**Parámetros:**

- `client_id` (requerido): ID del cliente
- `amount` (requerido): Monto del pago en bolivianos
- `description` (opcional): Descripción del pago

**Ejemplo de uso:**

```json
{
  "name": "create_payment",
  "arguments": {
    "client_id": "1",
    "amount": "150",
    "description": "Pago mensual de septiembre"
  }
}
```

### 3. `get_payment_status`

Obtiene el estado de los pagos de un cliente.

**Parámetros:**

- `client_id` (requerido): ID del cliente

**Ejemplo de uso:**

```json
{
  "name": "get_payment_status",
  "arguments": {
    "client_id": "1"
  }
}
```

## Desarrollo

### Estructura del Proyecto

```
bin/
├── cobrador_mcp.dart          # Servidor MCP principal
├── start_mcp_server.bat       # Script de inicio para Windows
├── start_mcp_server.ps1       # Script de inicio para PowerShell
└── mcp_config.json           # Configuración de ejemplo
```

### Agregar Nuevas Herramientas

Para agregar nuevas herramientas al servidor MCP:

1. Define la herramienta en el constructor:

```dart
final myTool = Tool(
  name: 'my_tool',
  description: 'Descripción de mi herramienta',
  inputSchema: Schema.object(
    properties: {
      'param': Schema.string(description: 'Parámetro de ejemplo'),
    },
    required: ['param'],
  ),
);
```

2. Registra la herramienta:

```dart
registerTool(myTool, _myToolImplementation);
```

3. Implementa la función:

```dart
FutureOr<CallToolResult> _myToolImplementation(CallToolRequest request) async {
  // Tu implementación aquí
  return CallToolResult(
    content: [
      TextContent(text: 'Resultado de la herramienta'),
    ],
  );
}
```

## Notas

- El servidor actualmente usa datos simulados. En una implementación real, estos datos vendrían de la base de datos de la aplicación.
- El servidor se ejecuta en modo stdio, lo que significa que se comunica a través de entrada y salida estándar.
- Para debugging, puedes agregar logs usando `print()` en el servidor (aunque esto puede interferir con la comunicación MCP).
