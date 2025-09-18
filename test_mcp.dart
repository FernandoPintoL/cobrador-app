import 'dart:async';
import 'dart:io' as io;
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

void main() {
  // Crear el servidor y conectarlo a stdio
  MCPTestServer(stdioChannel(input: io.stdin, output: io.stdout));
}

/// Servidor MCP de prueba que implementa herramientas básicas
base class MCPTestServer extends MCPServer with ToolsSupport {
  MCPTestServer(super.channel)
    : super.fromStreamChannel(
        implementation: Implementation(
          name: 'Flutter App Cobrador MCP Server',
          version: '1.0.0',
        ),
        instructions: 'Servidor MCP para la aplicación cobrador Flutter',
      ) {
    registerTool(helloTool, _hello);
  }

  /// Herramienta simple de saludo
  final helloTool = Tool(
    name: 'hello',
    description: 'Saluda con un mensaje personalizado',
    inputSchema: Schema.object(
      properties: {'name': Schema.string(description: 'Nombre para saludar')},
      required: ['name'],
    ),
  );

  /// Implementación de la herramienta hello
  FutureOr<CallToolResult> _hello(CallToolRequest request) => CallToolResult(
    content: [
      TextContent(
        text:
            'Hola ${request.arguments!['name']}! Bienvenido a la app cobrador.',
      ),
    ],
  );
}
