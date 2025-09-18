import 'dart:async';
import 'dart:io' as io;
import 'package:dart_mcp/server.dart';
import 'package:dart_mcp/stdio.dart';

void main() {
  // Crear el servidor MCP para la aplicación cobrador
  CobradorMCPServer(stdioChannel(input: io.stdin, output: io.stdout));
}

/// Servidor MCP para la aplicación cobrador Flutter
base class CobradorMCPServer extends MCPServer with ToolsSupport {
  CobradorMCPServer(super.channel)
      : super.fromStreamChannel(
          implementation: Implementation(
            name: 'Cobrador App MCP Server',
            version: '1.0.0',
          ),
          instructions: 'Servidor MCP para gestionar funcionalidades de la aplicación cobrador',
        ) {
    // Registrar herramientas disponibles
    registerTool(getClientsTool, _getClients);
    registerTool(createPaymentTool, _createPayment);
    registerTool(getPaymentStatusTool, _getPaymentStatus);
  }

  /// Herramienta para obtener lista de clientes
  final getClientsTool = Tool(
    name: 'get_clients',
    description: 'Obtiene la lista de clientes disponibles',
    inputSchema: Schema.object(
      properties: {
        'filter': Schema.string(description: 'Filtro opcional para buscar clientes'),
      },
    ),
  );

  /// Herramienta para crear un pago
  final createPaymentTool = Tool(
    name: 'create_payment',
    description: 'Crea un nuevo registro de pago',
    inputSchema: Schema.object(
      properties: {
        'client_id': Schema.string(description: 'ID del cliente'),
        'amount': Schema.string(description: 'Monto del pago en bolivianos'),
        'description': Schema.string(description: 'Descripción del pago'),
      },
      required: ['client_id', 'amount'],
    ),
  );

  /// Herramienta para obtener estado de pagos
  final getPaymentStatusTool = Tool(
    name: 'get_payment_status',
    description: 'Obtiene el estado de los pagos de un cliente',
    inputSchema: Schema.object(
      properties: {
        'client_id': Schema.string(description: 'ID del cliente'),
      },
      required: ['client_id'],
    ),
  );

  /// Implementación de la herramienta get_clients
  FutureOr<CallToolResult> _getClients(CallToolRequest request) async {
    final filter = request.arguments?['filter'] as String?;
    
    // Simulación de datos - en una app real esto vendría de tu base de datos
    final clients = [
      {'id': '1', 'name': 'Juan Pérez', 'phone': '+591 123456789'},
      {'id': '2', 'name': 'María García', 'phone': '+591 987654321'},
      {'id': '3', 'name': 'Carlos López', 'phone': '+591 456789123'},
    ];
    
    final filteredClients = filter != null
        ? clients.where((c) => c['name']!.toLowerCase().contains(filter.toLowerCase())).toList()
        : clients;
    
    return CallToolResult(
      content: [
        TextContent(
          text: 'Clientes encontrados: ${filteredClients.length}\n' +
                filteredClients.map((c) => '- ${c['name']} (${c['phone']})').join('\n'),
        ),
      ],
    );
  }

  /// Implementación de la herramienta create_payment
  FutureOr<CallToolResult> _createPayment(CallToolRequest request) async {
    final clientId = request.arguments!['client_id'] as String;
    final amount = request.arguments!['amount'] as String;
    final description = request.arguments?['description'] as String? ?? 'Pago registrado';
    
    // Simulación de creación de pago
    final paymentId = DateTime.now().millisecondsSinceEpoch.toString();
    
    return CallToolResult(
      content: [
        TextContent(
          text: 'Pago creado exitosamente:\n' +
                'ID: $paymentId\n' +
                'Cliente: $clientId\n' +
                'Monto: Bs. $amount\n' +
                'Descripción: $description',
        ),
      ],
    );
  }

  /// Implementación de la herramienta get_payment_status
  FutureOr<CallToolResult> _getPaymentStatus(CallToolRequest request) async {
    final clientId = request.arguments!['client_id'] as String;
    
    // Simulación de estado de pagos
    return CallToolResult(
      content: [
        TextContent(
          text: 'Estado de pagos para cliente $clientId:\n' +
                '- Pagos pendientes: 2\n' +
                '- Último pago: Bs. 150.00 (hace 3 días)\n' +
                '- Total adeudado: Bs. 300.00',
        ),
      ],
    );
  }
}
