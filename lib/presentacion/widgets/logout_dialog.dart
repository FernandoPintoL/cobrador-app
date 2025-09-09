import 'dart:io' show Platform, exit;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cobrador_app/main.dart';
import '../../negocio/providers/auth_provider.dart';

/// Muestra opciones para cerrar sesión o salir de la app.
///
/// Opciones:
/// - Cancelar: cierra el diálogo.
/// - Salir: cierra la aplicación sin cerrar sesión en el servidor.
/// - Cerrar sesión completa: hace logout y navega a la pantalla de login.
Future<void> showLogoutOptions({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿Qué deseas hacer?'),
      content: const Text(
        'Selecciona una opción para continuar:',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('cancel'),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('exit'),
          child: const Text('Salir'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop('logout'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cerrar sesión completa'),
        ),
      ],
    ),
  );

  switch (result) {
    case 'logout':
      // Cerrar sesión completa: limpiar identificador guardado para forzar email en el próximo inicio
      await ref.read(authProvider.notifier).logoutFull();
      // Navegar a login y limpiar la pila de navegación de forma segura usando navigatorKey global
      // Evita usar el context del diálogo que podría no tener un Navigator válido
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final nav = MyApp.navigatorKey.currentState;
        if (nav != null) {
          nav.pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
      break;
    case 'exit':
      // Salir de la app de forma segura dependiendo de la plataforma
      if (kIsWeb) {
        // En web, no se puede cerrar la pestaña; solo cerrar diálogo.
        return;
      }
      try {
        await SystemNavigator.pop();
      } catch (_) {
        // Fallbacks por plataforma
        if (!kIsWeb) {
          try {
            if (Platform.isAndroid) {
              await SystemNavigator.pop();
            } else if (Platform.isIOS) {
              // iOS no permite cerrar la app programáticamente; intentamos
              // navegar atrás hasta salir.
              Navigator.of(context).popUntil((route) => route.isFirst);
            } else {
              exit(0);
            }
          } catch (_) {
            // Último recurso
            exit(0);
          }
        }
      }
      break;
    case 'cancel':
    default:
      // No hacer nada
      break;
  }
}
