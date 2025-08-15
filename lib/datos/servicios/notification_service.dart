import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servicio para gestionar notificaciones locales
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Inicializa el servicio de notificaciones
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Configuración para Android - usar el icono de notificación personalizado
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('notification'); // Cambiado a notification.png (sin extensión)

      // Configuración para iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuración general
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      // Inicializar el plugin
      final bool? initialized = await _flutterLocalNotificationsPlugin
          .initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = initialized ?? false;

      if (_isInitialized) {
        // Solicitar permisos
        await _requestPermissions();
        print('✅ Servicio de notificaciones inicializado correctamente');
      } else {
        print('❌ Error al inicializar servicio de notificaciones');
      }

      return _isInitialized;
    } catch (e) {
      print('❌ Error inicializando notificaciones: $e');
      return false;
    }
  }

  /// Solicita permisos de notificación
  Future<bool> _requestPermissions() async {
    try {
      // Solicitar permisos en Android 13+
      if (await Permission.notification.isDenied) {
        final status = await Permission.notification.request();
        if (status.isPermanentlyDenied) {
          print('⚠️ Permisos de notificación denegados permanentemente');
          return false;
        }
      }

      // Para iOS, solicitar permisos adicionales
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }

      print('✅ Permisos de notificación concedidos');
      return true;
    } catch (e) {
      print('❌ Error solicitando permisos: $e');
      return false;
    }
  }

  /// Maneja cuando se toca una notificación
  void _onNotificationTapped(NotificationResponse notificationResponse) {
    final String? payload = notificationResponse.payload;
    print('📱 Notificación tocada con payload: $payload');

    // Aquí puedes agregar navegación específica según el tipo de notificación
    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Maneja el payload de la notificación
  void _handleNotificationPayload(String payload) {
    try {
      // El payload puede contener información sobre qué hacer cuando se toca la notificación
      // Por ejemplo: "credit:123", "payment:456", "message:789"
      final parts = payload.split(':');
      if (parts.length >= 2) {
        final type = parts[0];
        final id = parts[1];

        switch (type) {
          case 'credit':
            print('🏦 Abrir detalles del crédito: $id');
            // Aquí puedes agregar navegación al detalle del crédito
            break;
          case 'payment':
            print('💰 Abrir detalles del pago: $id');
            // Aquí puedes agregar navegación al detalle del pago
            break;
          case 'message':
            print('💬 Abrir chat/mensaje: $id');
            // Aquí puedes agregar navegación al chat
            break;
          default:
            print('🔔 Tipo de notificación desconocido: $type');
        }
      }
    } catch (e) {
      print('❌ Error procesando payload de notificación: $e');
    }
  }

  /// Muestra una notificación de crédito
  Future<void> showCreditNotification({
    required String title,
    required String body,
    String? creditId,
    String? action,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Servicio de notificaciones no inicializado');
      return;
    }

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final String payload = creditId != null ? 'credit:$creditId' : 'credit:general';

    // Configurar el canal de notificación para Android
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'credits_channel',
      'Notificaciones de Créditos',
      channelDescription: 'Notificaciones relacionadas con créditos',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification', // Usar el icono personalizado creado
      color: Color(0xFF667eea),
      enableVibration: true,
      playSound: true,
    );

    // Configuración para iOS
    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    print('🏦 Notificación de crédito mostrada: $title');
  }

  /// Muestra una notificación de pago
  Future<void> showPaymentNotification({
    required String title,
    required String body,
    String? paymentId,
    double? amount,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Servicio de notificaciones no inicializado');
      return;
    }

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final String payload = paymentId != null ? 'payment:$paymentId' : 'payment:general';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'payments_channel',
      'Notificaciones de Pagos',
      channelDescription: 'Notificaciones relacionadas con pagos',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_notification', // Usar el icono personalizado creado
      color: Color(0xFF4CAF50),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    print('💰 Notificación de pago mostrada: $title');
  }

  /// Muestra una notificación de mensaje
  Future<void> showMessageNotification({
    required String title,
    required String body,
    String? messageId,
    String? senderId,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Servicio de notificaciones no inicializado');
      return;
    }

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    final String payload = messageId != null ? 'message:$messageId' : 'message:general';

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'messages_channel',
      'Notificaciones de Mensajes',
      channelDescription: 'Notificaciones relacionadas con mensajes',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher', // Usar el icono por defecto
      color: Color(0xFF2196F3),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );

    print('💬 Notificación de mensaje mostrada: $title');
  }

  /// Muestra una notificación general
  Future<void> showGeneralNotification({
    required String title,
    required String body,
    String? type,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('⚠️ Servicio de notificaciones no inicializado');
      return;
    }

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'general_channel',
      'Notificaciones Generales',
      channelDescription: 'Notificaciones generales de la aplicación',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher', // Usar el icono por defecto
      color: Color(0xFF667eea),
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: payload ?? 'general:$type',
    );

    print('🔔 Notificación general mostrada: $title');
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
    print('🗑️ Todas las notificaciones canceladas');
  }

  /// Cancela una notificación específica
  Future<void> cancelNotification(int notificationId) async {
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    print('🗑️ Notificación $notificationId cancelada');
  }

  /// Obtiene las notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  /// Verifica si las notificaciones están habilitadas
  Future<bool> areNotificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    }
    return true; // En iOS asumimos que están habilitadas si llegamos hasta aquí
  }

  /// Abre la configuración de notificaciones del sistema
  Future<void> openNotificationSettings() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await openAppSettings();
    }
  }
}
