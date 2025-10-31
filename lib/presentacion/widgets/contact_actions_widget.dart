import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

/// Widget helper para acciones de contacto (llamadas y WhatsApp)
class ContactActionsWidget {
  /// Verifica si WhatsApp está instalado en el dispositivo
  /// Maneja múltiples instalaciones de WhatsApp
  static Future<bool> isWhatsAppInstalled() async {
    try {
      // Lista de esquemas de WhatsApp para verificar
      final List<String> whatsappSchemes = [
        'whatsapp://', // WhatsApp normal
        'whatsapp4b://', // WhatsApp Business alternativo
        'intent://send/#Intent;scheme=whatsapp;package=com.whatsapp;end', // Intent específico
      ];

      print('🔍 Verificando instalaciones de WhatsApp...');

      for (String scheme in whatsappSchemes) {
        try {
          final Uri uri = Uri.parse(scheme);
          final bool canLaunch = await canLaunchUrl(uri);
          print(
            '📱 Esquema "$scheme": ${canLaunch ? "✅ Disponible" : "❌ No disponible"}',
          );

          if (canLaunch) {
            print('✅ WhatsApp detectado con esquema: $scheme');
            return true;
          }
        } catch (e) {
          print('❌ Error con esquema "$scheme": $e');
          continue;
        }
      }

      print('❌ Ningún WhatsApp detectado');
      return false;
    } catch (e) {
      print('❌ Error verificando WhatsApp: $e');
      return false;
    }
  }

  /// Copia el número al portapapeles como alternativa
  static Future<void> copyToClipboard(String text, BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Número copiado: $text'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error copiando al portapapeles: $e');
    }
  }

  /// Realiza una llamada telefónica al número proporcionado
  static Future<void> makePhoneCall(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      throw Exception('Número de teléfono no disponible');
    }

    print('📞 Número original para llamada: "$phoneNumber"');

    // Limpiar el número de espacios y caracteres especiales
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    print('📞 Número limpio para llamada: "$cleanNumber"');

    final Uri phoneUri = Uri(scheme: 'tel', path: cleanNumber);
    print('📞 URI de llamada: $phoneUri');

    try {
      // Preferir abrir en aplicación externa (teléfono)
      final launched = await launchUrl(
        phoneUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        print('❌ launchUrl retornó false para llamada');
        throw Exception('No se puede realizar la llamada');
      }
      print('✅ Realizando llamada...');
    } catch (e) {
      print('❌ Error al intentar realizar la llamada: $e');
      throw Exception('Error al intentar realizar la llamada: $e');
    }
  }

  /// Abre WhatsApp con el número proporcionado
  static Future<void> openWhatsApp(
    String phoneNumber, {
    String? message,
    BuildContext? context,
  }) async {
    if (phoneNumber.isEmpty) {
      throw Exception('Número de teléfono no disponible');
    }

    print('📱 Número original: "$phoneNumber"');

    // Limpiar el número y asegurar formato internacional
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    print('📱 Número limpio: "$cleanNumber"');

    // Si no empieza con +, asumir que es un número boliviano (+591)
    if (!cleanNumber.startsWith('+')) {
      // Si empieza con 591, agregar solo el +
      if (cleanNumber.startsWith('591')) {
        cleanNumber = '+$cleanNumber';
      } else {
        // Si es un número local, agregar +591
        cleanNumber = '+591$cleanNumber';
      }
    }

    print('📱 Número con código país: "$cleanNumber"');

    // Para WhatsApp, necesitamos el número SIN el símbolo +
    String whatsappNumber = cleanNumber.replaceFirst('+', '');
    print('📱 Número para WhatsApp: "$whatsappNumber"');

    // Lista de URLs para intentar (optimizada por plataforma)
    final List<String> urlsToTry = Platform.isAndroid
        ? [
            // Android: usar esquema directo primero
            'whatsapp://send?phone=$whatsappNumber${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}',
            // Intent normal
            'intent://send?phone=$whatsappNumber${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}#Intent;scheme=whatsapp;package=com.whatsapp;end',
            // Intent Business
            'intent://send?phone=$whatsappNumber${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}#Intent;scheme=whatsapp;package=com.whatsapp.w4b;end',
            // Fallback web (abre navegador o app)
            'https://wa.me/$whatsappNumber${message != null && message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
            'https://api.whatsapp.com/send?phone=$whatsappNumber${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}',
            // Últimos recursos
            'whatsapp://send?phone=$whatsappNumber',
            'whatsapp://',
          ]
        : [
            // iOS: esquema directo y fallback web (no usar intent://)
            'whatsapp://send?phone=$whatsappNumber${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}',
            'https://wa.me/$whatsappNumber${message != null && message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
            'https://api.whatsapp.com/send?phone=$whatsappNumber${message != null && message.isNotEmpty ? '&text=${Uri.encodeComponent(message)}' : ''}',
          ];

    for (int i = 0; i < urlsToTry.length; i++) {
      final url = urlsToTry[i];
      print('📱 Intentando URL ${i + 1}/${urlsToTry.length}: $url');

      try {
        final Uri uri = Uri.parse(url);

        // Para Intent URIs, usar modo externo siempre
        final LaunchMode mode = url.startsWith('intent://')
            ? LaunchMode.externalApplication
            : LaunchMode.externalApplication;

        if (await canLaunchUrl(uri)) {
          print('✅ URL ${i + 1} disponible, intentando abrir...');
          await launchUrl(uri, mode: mode);
          print('✅ WhatsApp abierto exitosamente con URL ${i + 1}');
          return;
        } else {
          print('❌ URL ${i + 1} no disponible según canLaunchUrl');
        }
      } catch (e) {
        print('❌ Error con URL ${i + 1}: $e');

        // Si es un Intent URI y falla, intentar el siguiente
        if (url.startsWith('intent://')) {
          print('⚠️ Intent URI falló, probando siguiente método...');
          continue;
        }

        continue;
      }
    }

    // Si todos los métodos fallan
    print('❌ Todos los métodos de WhatsApp fallaron');

    // Verificar instalación para mostrar mejor diagnóstico
    bool installed = false;
    try {
      installed = await isWhatsAppInstalled();
    } catch (_) {}

    if (installed && context != null && context.mounted) {
      print('⚠️ Posible conflicto con múltiples WhatsApp instalados');
      _showMultipleWhatsAppDialog(context, whatsappNumber, message);
    } else if (context != null && context.mounted) {
      _showWhatsAppFailedDialog(context, whatsappNumber, message);
    }

    throw Exception(
      'No se pudo abrir WhatsApp con ningún método disponible.' +
          (installed ? ' Es posible que tengas múltiples WhatsApp instalados.' : ''),
    );
  }

  /// Muestra diálogo específico para múltiples instalaciones de WhatsApp
  static void _showMultipleWhatsAppDialog(
    BuildContext context,
    String phoneNumber,
    String? message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.apps, color: Colors.blue),
            SizedBox(width: 8),
            Text('Múltiples WhatsApp detectados'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se detectaron múltiples instalaciones de WhatsApp en tu dispositivo.',
            ),
            const SizedBox(height: 12),
            const Text('• WhatsApp normal\n• WhatsApp Business\n'),
            const SizedBox(height: 12),
            const Text('Puedes:'),
            const SizedBox(height: 8),
            Text('📱 Copiar el número: +$phoneNumber'),
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📝 Mensaje: $message'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ContactActionsWidget.copyToClipboard('+$phoneNumber', context);
            },
            child: const Text('Copiar número'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Intentar abrir directamente el selector de apps
              try {
                final Uri webUri = Uri.parse(
                  'https://wa.me/$phoneNumber${message != null && message.isNotEmpty ? '?text=${Uri.encodeComponent(message)}' : ''}',
                );
                await launchUrl(webUri, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (context.mounted) {
                  ContactActionsWidget.copyToClipboard(
                    '+$phoneNumber',
                    context,
                  );
                }
              }
            },
            child: const Text('Abrir en navegador'),
          ),
        ],
      ),
    );
  }

  /// Muestra diálogo cuando WhatsApp falla al abrir
  static void _showWhatsAppFailedDialog(
    BuildContext context,
    String phoneNumber,
    String? message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error con WhatsApp'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No se pudo abrir WhatsApp. Puedes copiar el número para contactar manualmente.',
            ),
            const SizedBox(height: 16),
            Text('Número: +$phoneNumber'),
            if (message != null && message.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Mensaje: $message'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ContactActionsWidget.copyToClipboard('+$phoneNumber', context);
            },
            child: const Text('Copiar número'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo con opciones de contacto
  static void showContactDialog({
    required BuildContext context,
    required String userName,
    required String phoneNumber,
    String? userRole,
    String? customMessage,
  }) {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este usuario no tiene número de teléfono registrado'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Contactar a $userName',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Número: $phoneNumber',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // Información de depuración
            Text(
              'Formato limpio: ${phoneNumber.replaceAll(RegExp(r'[^\d+]'), '')}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (userRole != null) ...[
              const SizedBox(height: 4),
              Text('Rol: $userRole', style: TextStyle(color: Colors.grey[600])),
            ],
            const SizedBox(height: 16),
            const Text('Selecciona una opción de contacto:'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ContactActionsWidget.makePhoneCall(phoneNumber);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.phone, color: Colors.green),
            label: const Text('Llamar'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final defaultMessage =
                    customMessage ??
                    'Hola $userName, me comunico desde la aplicación de cobradores.';
                await ContactActionsWidget.openWhatsApp(
                  phoneNumber,
                  message: defaultMessage,
                  context: context,
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            icon: const Icon(Icons.message, color: Colors.green),
            label: const Text('WhatsApp'),
          ),
        ],
      ),
    );
  }

  /// Widget de botón de contacto compacto
  static Widget buildContactButton({
    required BuildContext context,
    required String userName,
    required String phoneNumber,
    String? userRole,
    String? customMessage,
    IconData icon = Icons.phone,
    Color? color,
    String tooltip = 'Contactar',
  }) {
    return IconButton(
      icon: Icon(icon, color: color ?? Colors.blue),
      tooltip: tooltip,
      onPressed: phoneNumber.isEmpty
          ? null
          : () => showContactDialog(
              context: context,
              userName: userName,
              phoneNumber: phoneNumber,
              userRole: userRole,
              customMessage: customMessage,
            ),
    );
  }

  /// Widget de acción de contacto para menús contextuales
  static PopupMenuItem<String> buildContactMenuItem({
    required String phoneNumber,
    String value = 'contactar',
    IconData icon = Icons.phone,
    Color iconColor = Colors.blue,
    String label = 'Contactar',
  }) {
    return PopupMenuItem(
      value: value,
      enabled: phoneNumber.isNotEmpty,
      child: ListTile(
        leading: Icon(
          icon,
          color: phoneNumber.isEmpty ? Colors.grey : iconColor,
        ),
        title: Text(
          label,
          style: TextStyle(color: phoneNumber.isEmpty ? Colors.grey : null),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  /// Widget que muestra el número de teléfono con botón de contacto integrado
  static Widget buildPhoneDisplay({
    required BuildContext context,
    required String userName,
    required String phoneNumber,
    String? userRole,
    String? customMessage,
    TextStyle? textStyle,
  }) {
    if (phoneNumber.isEmpty) {
      return Text(
        'Sin teléfono',
        style:
            textStyle?.copyWith(color: Colors.grey) ??
            TextStyle(color: Colors.grey[600]),
      );
    }

    return InkWell(
      onTap: () => showContactDialog(
        context: context,
        userName: userName,
        phoneNumber: phoneNumber,
        userRole: userRole,
        customMessage: customMessage,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phone, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Text(
            phoneNumber,
            style:
                textStyle?.copyWith(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ) ??
                TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
          ),
        ],
      ),
    );
  }

  /// Mensajes predeterminados según el rol
  static String getDefaultMessage(String userRole, String userName) {
    switch (userRole.toLowerCase()) {
      case 'client':
      case 'cliente':
        return 'Hola $userName, me comunico desde la aplicación de cobradores para consultar sobre su cuenta.';
      case 'cobrador':
        return 'Hola $userName, me comunico desde la aplicación para coordinar actividades de cobranza.';
      case 'manager':
        return 'Hola $userName, me comunico desde la aplicación para temas de gestión.';
      case 'admin':
        return 'Hola $userName, me comunico desde la aplicación para temas administrativos.';
      default:
        return 'Hola $userName, me comunico desde la aplicación de cobradores.';
    }
  }
}
