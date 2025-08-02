import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get googleMapsApiKey {
    try {
      // En desarrollo, usa la variable de entorno
      if (dotenv.env['GOOGLE_MAPS_API_KEY'] != null &&
          dotenv.env['GOOGLE_MAPS_API_KEY']!.isNotEmpty) {
        return dotenv.env['GOOGLE_MAPS_API_KEY']!;
      }
    } catch (e) {
      print("Error accediendo a GOOGLE_MAPS_API_KEY: $e");
    }

    // Fallback para producción (debe ser configurado en el build)
    return const String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  }

  static String get appName {
    try {
      return dotenv.env['APP_NAME'] ?? 'Cobrador';
    } catch (e) {
      return 'Cobrador';
    }
  }

  static String get appVersion {
    try {
      return dotenv.env['APP_VERSION'] ?? '1.0.0';
    } catch (e) {
      return '1.0.0';
    }
  }
}
