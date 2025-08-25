import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Utilidades para manejo y compresión de imágenes
class ImageUtils {
  /// Comprime una imagen JPEG/PNG para que pese menos de [maxBytes] (por defecto 1MB)
  /// Retorna un nuevo File si se comprime; si ya cumple, retorna el original.
  static Future<File> compressToUnder(
    File inputFile, {
    int maxBytes = 1024 * 1024, // 1MB
    int minQuality = 35,
  }) async {
    try {
      final originalBytes = await inputFile.length();
      if (originalBytes <= maxBytes) return inputFile;

      final ext = p.extension(inputFile.path).toLowerCase();
      final isPng = ext == '.png';

      // Definir calidades decrecientes
      final qualities = <int>[85, 75, 65, 55, 45, 40, 35];

      Uint8List? lastResult;
      for (final q in qualities) {
        final result = await FlutterImageCompress.compressWithFile(
          inputFile.path,
          format: isPng ? CompressFormat.png : CompressFormat.jpeg,
          quality: q,
          keepExif: true,
        );
        if (result == null) continue;
        lastResult = result;
        if (result.lengthInBytes <= maxBytes) {
          return _persistTempFile(result, inputFile.path);
        }
      }

      // Si no se logró, intentar reducir tamaño (resize) manteniendo calidad media
      if (lastResult != null) {
        int width = 1920;
        while (width >= 720) {
          final result = await FlutterImageCompress.compressWithFile(
            inputFile.path,
            format: isPng ? CompressFormat.png : CompressFormat.jpeg,
            quality: 60,
            minWidth: width,
            minHeight: (width * 0.6).toInt(),
            keepExif: true,
          );
          if (result != null && result.lengthInBytes <= maxBytes) {
            return _persistTempFile(result, inputFile.path);
          }
          width = (width * 0.8).toInt();
        }
      }

      // Si aún supera el tamaño, retornamos la mejor versión conseguida
      if (lastResult != null) {
        return _persistTempFile(lastResult, inputFile.path);
      }

      return inputFile; // fallback
    } catch (_) {
      return inputFile;
    }
  }

  static Future<File> _persistTempFile(Uint8List bytes, String originalPath) async {
    final tmpDir = await getTemporaryDirectory();
    final fileName = 'compressed_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalPath)}';
    final outPath = p.join(tmpDir.path, fileName);
    final outFile = File(outPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }
}
