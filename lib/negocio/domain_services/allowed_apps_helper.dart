import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auto_logout_service.dart';

/// Servicio auxiliar para manejar el acceso a aplicaciones permitidas
/// y marcar el contexto apropiado en el AutoLogoutService
class AllowedAppsHelper {
  static AutoLogoutService? _autoLogoutService;

  /// Inicializa el helper con referencia al AutoLogoutService
  static void init(AutoLogoutService autoLogoutService) {
    _autoLogoutService = autoLogoutService;
  }

  /// Marca el inicio de uso de la cámara
  static void markCameraUsage() {
    _autoLogoutService?.markAllowedContext('camera_access_active');
    debugPrint('📷 Marcado uso de cámara - logout pausado');
  }

  /// Marca el inicio de uso de la galería
  static void markGalleryUsage() {
    _autoLogoutService?.markAllowedContext('gallery_access_active');
    debugPrint('🖼️ Marcado uso de galería - logout pausado');
  }

  /// Marca el inicio de navegación con Google Maps
  static void markMapsUsage() {
    _autoLogoutService?.markAllowedContext('maps_navigation_active');
    debugPrint('🗺️ Marcado uso de mapas - logout pausado');
  }

  /// Marca el inicio de una llamada telefónica
  static void markPhoneCallUsage() {
    _autoLogoutService?.markAllowedContext('phone_call_active');
    debugPrint('📞 Marcado llamada telefónica - logout pausado');
  }

  /// Marca el uso de WhatsApp (cuando se abre desde la app)
  static void markWhatsAppUsage() {
    _autoLogoutService?.markAllowedContext('whatsapp_usage_active');
    debugPrint('💬 Marcado uso de WhatsApp - logout pausado');
  }

  /// Limpia todos los contextos permitidos
  static void clearAllContexts() {
    _autoLogoutService?.clearAllowedContext();
    debugPrint('🧹 Limpiados todos los contextos permitidos');
  }

  /// Función auxiliar para abrir la cámara con contexto de seguridad
  static Future<XFile?> openCameraSecurely({
    ImageSource source = ImageSource.camera,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    try {
      // Marcar que vamos a usar la cámara
      if (source == ImageSource.camera) {
        markCameraUsage();
      } else {
        markGalleryUsage();
      }

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        preferredCameraDevice: preferredCameraDevice,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      // Mantener el contexto activo por un poco más de tiempo
      await Future.delayed(const Duration(seconds: 2));
      clearAllContexts();

      return image;
    } catch (e) {
      debugPrint('❌ Error abriendo cámara/galería: $e');
      clearAllContexts();
      rethrow;
    }
  }

  /// Función auxiliar para abrir múltiples imágenes de galería
  static Future<List<XFile>> openGalleryMultipleSecurely({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      markGalleryUsage();

      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        limit: limit,
      );

      // Mantener el contexto activo
      await Future.delayed(const Duration(seconds: 2));
      clearAllContexts();

      return images;
    } catch (e) {
      debugPrint('❌ Error abriendo galería múltiple: $e');
      clearAllContexts();
      rethrow;
    }
  }

  /// Función auxiliar para abrir Google Maps con ubicación
  static Future<bool> openMapsSecurely({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    try {
      markMapsUsage();

      final String googleMapsUrl = label != null
          ? 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude&query_place_id=$label'
          : 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

      final Uri uri = Uri.parse(googleMapsUrl);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint('🗺️ Google Maps abierto exitosamente');
        // Mantener contexto activo por más tiempo para navegación
        Future.delayed(const Duration(minutes: 2), () {
          clearAllContexts();
        });
      } else {
        clearAllContexts();
      }

      return launched;
    } catch (e) {
      debugPrint('❌ Error abriendo Google Maps: $e');
      clearAllContexts();
      return false;
    }
  }

  /// Función auxiliar para realizar llamada telefónica
  static Future<bool> makePhoneCallSecurely(String phoneNumber) async {
    try {
      markPhoneCallUsage();

      // Limpiar el número de teléfono
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      final Uri uri = Uri.parse('tel:$cleanNumber');

      final bool launched = await launchUrl(uri);

      if (launched) {
        debugPrint('📞 Llamada iniciada exitosamente a $cleanNumber');
        // Mantener contexto activo durante la llamada (tiempo extendido)
        Future.delayed(const Duration(minutes: 5), () {
          clearAllContexts();
        });
      } else {
        clearAllContexts();
      }

      return launched;
    } catch (e) {
      debugPrint('❌ Error realizando llamada: $e');
      clearAllContexts();
      return false;
    }
  }

  /// Función auxiliar para abrir WhatsApp con mensaje
  static Future<bool> openWhatsAppSecurely({
    required String phoneNumber,
    String? message,
  }) async {
    try {
      markWhatsAppUsage();

      // Limpiar número de teléfono para WhatsApp
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
      final encodedMessage = message != null
          ? Uri.encodeComponent(message)
          : '';

      final String whatsappUrl = message != null
          ? 'https://wa.me/$cleanNumber?text=$encodedMessage'
          : 'https://wa.me/$cleanNumber';

      final Uri uri = Uri.parse(whatsappUrl);
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (launched) {
        debugPrint('💬 WhatsApp abierto exitosamente');
        // Mantener contexto activo para conversación
        Future.delayed(const Duration(minutes: 3), () {
          clearAllContexts();
        });
      } else {
        clearAllContexts();
      }

      return launched;
    } catch (e) {
      debugPrint('❌ Error abriendo WhatsApp: $e');
      clearAllContexts();
      return false;
    }
  }

  /// Función para verificar permisos antes de usar aplicaciones
  static Future<bool> checkAndRequestPermission(Permission permission) async {
    try {
      final status = await permission.status;

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await permission.request();
        return result.isGranted;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error verificando permisos: $e');
      return false;
    }
  }

  /// Función auxiliar para usar cámara con verificación de permisos
  static Future<XFile?> openCameraWithPermissions({
    ImageSource source = ImageSource.camera,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    // Verificar permisos según la fuente
    final Permission requiredPermission = source == ImageSource.camera
        ? Permission.camera
        : Permission.photos;

    final bool hasPermission = await checkAndRequestPermission(requiredPermission);

    if (!hasPermission) {
      debugPrint('❌ Permisos no concedidos para ${source.name}');
      return null;
    }

    return await openCameraSecurely(
      source: source,
      preferredCameraDevice: preferredCameraDevice,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );
  }

  /// Función auxiliar para hacer llamada con verificación de permisos
  static Future<bool> makePhoneCallWithPermissions(String phoneNumber) async {
    final bool hasPermission = await checkAndRequestPermission(Permission.phone);

    if (!hasPermission) {
      debugPrint('❌ Permisos no concedidos para realizar llamadas');
      return false;
    }

    return await makePhoneCallSecurely(phoneNumber);
  }
}
