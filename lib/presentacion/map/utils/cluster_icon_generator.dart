import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Generador de iconos personalizados para marcadores de clusters
class ClusterIconGenerator {
  // Cache para evitar regenerar el mismo icono múltiples veces
  static final Map<String, BitmapDescriptor> _iconCache = {};

  /// Genera un icono de marcador personalizado con texto y color
  static Future<BitmapDescriptor> generateMarkerIcon(
    String line1,
    Color color, {
    String? line2,
  }) async {
    final cacheKey = '$line1|$line2|${color.value}';
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    final icon = await _createMarkerBitmap(line1, color, line2: line2);
    _iconCache[cacheKey] = icon;
    return icon;
  }

  /// Genera un icono simple basado en estado
  static Future<BitmapDescriptor> generateStatusIcon(
    String status,
    Color color,
  ) async {
    final statusText = status == 'paid'
        ? 'Pagó hoy'
        : status == 'pending'
            ? 'No pagó hoy'
            : 'Sin datos';

    return generateMarkerIcon(statusText, color);
  }

  /// Genera un icono para cluster con múltiples personas
  static Future<BitmapDescriptor> generateClusterIcon(
    int peopleCount,
    String clusterStatus,
    Color color,
  ) async {
    final cacheKey = 'cluster_$peopleCount|$clusterStatus|${color.value}';
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    final icon = await _createClusterMarkerBitmap(
      peopleCount,
      clusterStatus,
      color,
    );
    _iconCache[cacheKey] = icon;
    return icon;
  }

  // ===== Privado =====

  static Future<BitmapDescriptor> _createClusterMarkerBitmap(
    int peopleCount,
    String clusterStatus,
    Color color,
  ) async {
    const pr = 1.0;

    final darkColor = Color.lerp(color, Colors.black, 0.2)!;
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;

    // Texto principal: número de personas
    final tpPeople = TextPainter(
      text: TextSpan(
        text: '$peopleCount',
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Color.fromARGB(76, 0, 0, 0),
              offset: Offset(1.5, 1.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    // Texto secundario: "personas" o "persona"
    final tpLabel = TextPainter(
      text: TextSpan(
        text: peopleCount == 1 ? 'persona' : 'personas',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: darkColor,
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.9),
              offset: const Offset(0.5, 0.5),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    const paddingH = 20.0;
    const paddingV = 16.0;
    const spacing = 16.0;
    const pinRadius = 70.0;
    const pointerH = 34.0;
    const shadowOffset = 14.0;

    final labelW = tpPeople.width + paddingH * 2;
    final labelH = tpPeople.height + tpLabel.height + paddingV * 2 + 6;

    final width = labelW + 30.0;
    final w = width < 150.0 ? 150.0 : width;
    final height = labelH + spacing + pinRadius * 2 + pointerH + shadowOffset;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Sombra de la etiqueta
    final labelLeft = (w - labelW) / 2;
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft + 3, 3, labelW, labelH),
      const Radius.circular(12),
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(shadowRect, shadowPaint);

    // Gradiente para la etiqueta
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft, 0, labelW, labelH),
      const Radius.circular(12),
    );

    final gradient = ui.Gradient.linear(
      Offset(labelLeft, 0),
      Offset(labelLeft, labelH),
      [Colors.white, lightColor.withOpacity(0.15)],
    );

    final fill = Paint()..shader = gradient;
    canvas.drawRRect(rrect, fill);

    // Borde
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    canvas.drawRRect(rrect, border);

    // Dibujar textos
    tpPeople.paint(canvas, Offset(labelLeft + paddingH, paddingV));
    tpLabel.paint(
      canvas,
      Offset(labelLeft + paddingH, paddingV + tpPeople.height + 6),
    );

    // Sombra del círculo
    final circleCenter = Offset(w / 2, labelH + spacing + pinRadius);
    final shadowCircle = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(circleCenter.dx + 2, circleCenter.dy + 2),
      pinRadius,
      shadowCircle,
    );

    // Gradiente del círculo
    final circleGradient = ui.Gradient.radial(
      circleCenter,
      pinRadius,
      [lightColor, color, darkColor],
      [0.0, 0.5, 1.0],
    );
    final pinPaint = Paint()..shader = circleGradient;
    canvas.drawCircle(circleCenter, pinRadius, pinPaint);

    // Bordes del círculo
    final pinBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5;
    canvas.drawCircle(circleCenter, pinRadius, pinBorder);

    final pinBorder2 = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(circleCenter, pinRadius + 2.0, pinBorder2);

    // Triángulo
    final tipY = labelH + spacing + pinRadius * 2 + pointerH;
    final topY = labelH + spacing + pinRadius * 2;

    final shadowPath = Path()
      ..moveTo(w / 2 + 2, tipY + 2)
      ..lineTo(w / 2 - 12 + 2, topY + 2)
      ..lineTo(w / 2 + 12 + 2, topY + 2)
      ..close();
    canvas.drawPath(shadowPath, shadowCircle);

    final path = Path()
      ..moveTo(w / 2, tipY)
      ..lineTo(w / 2 - 12, topY)
      ..lineTo(w / 2 + 12, topY)
      ..close();
    canvas.drawPath(path, pinPaint);

    final pathBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(path, pathBorder);

    final picture = recorder.endRecording();
    final img = await picture.toImage((w * pr).ceil(), (height * pr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Limpia el cache de iconos
  static void clearCache() {
    _iconCache.clear();
  }

  // ===== Privado =====

  static Future<BitmapDescriptor> _createMarkerBitmap(
    String line1,
    Color color, {
    String? line2,
  }) async {
    const pr = 1.0; // Device pixel ratio

    // 🎨 DISEÑO MODERNO: Colores más vibrantes y gradientes
    final darkColor = Color.lerp(color, Colors.black, 0.2)!;
    final lightColor = Color.lerp(color, Colors.white, 0.3)!;

    // Determinar icono según el estado
    String statusIcon = '●';
    if (line1.contains('Pagó')) {
      statusIcon = '✓'; // Check mark para pagado
    } else if (line1.contains('No pagó')) {
      statusIcon = '✗'; // X para no pagado
    } else {
      statusIcon = '?'; // Interrogación para sin datos
    }

    // Medir los textos con estilos mejorados (AUMENTADOS PARA MEJOR VISIBILIDAD)
    final tpIcon = TextPainter(
      text: TextSpan(
        text: statusIcon,
        style: TextStyle(
          fontSize: 38, // Aumentado de 26
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.4),
              offset: const Offset(1.5, 1.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    final tp1 = TextPainter(
      text: TextSpan(
        text: line1,
        style: TextStyle(
          fontSize: 16, // Aumentado de 14
          fontWeight: FontWeight.bold,
          color: darkColor,
          shadows: [
            Shadow(
              color: Colors.white.withOpacity(0.9),
              offset: const Offset(0.5, 0.5),
              blurRadius: 2,
            ),
          ],
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    TextPainter? tp2;
    if (line2 != null && line2.trim().isNotEmpty) {
      tp2 = TextPainter(
        text: TextSpan(
          text: line2,
          style: TextStyle(
            fontSize: 15, // Aumentado de 13
            fontWeight: FontWeight.bold, // Cambio de w600 a bold
            color: Colors.grey.shade900, // Más oscuro para mejor contraste
            shadows: [
              Shadow(
                color: Colors.white.withOpacity(0.7),
                offset: const Offset(0.5, 0.5),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
    }

    const paddingH = 28.0; // Aumentado de 24 (+16%)
    const paddingV = 20.0; // Aumentado de 18 (+11%)
    const spacing = 18.0; // Aumentado de 16 (+12%)
    const lineGap = 14.0; // Aumentado de 12 (+16%)
    const pinRadius = 70.0; // Aumentado de 56 (+25%)
    const pointerH = 34.0; // Aumentado de 28 (+21%)
    const shadowOffset = 14.0; // Aumentado de 12 (+16%)

    final contentW = tp2 == null
        ? tp1.width
        : (tp1.width > tp2.width ? tp1.width : tp2.width);
    final labelW = contentW + paddingH * 2;
    final contentH = tp2 == null
        ? tp1.height
        : (tp1.height + lineGap + tp2.height);
    final labelH = contentH + paddingV * 2;

    final width = labelW + 32.0; // Aumentado de 24
    final w = width < 150.0 ? 150.0 : width; // Aumentado de 120
    final height = labelH + spacing + pinRadius * 2 + pointerH + shadowOffset;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // 🎨 SOMBRA para la etiqueta (efecto depth)
    final labelLeft = (w - labelW) / 2;
    final shadowRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft + 3, 3, labelW, labelH),
      const Radius.circular(12),
    );
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(shadowRect, shadowPaint);

    // 🎨 GRADIENTE para la etiqueta (moderno)
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(labelLeft, 0, labelW, labelH),
      const Radius.circular(12),
    );

    final gradient = ui.Gradient.linear(
      Offset(labelLeft, 0),
      Offset(labelLeft, labelH),
      [Colors.white, lightColor.withOpacity(0.15)],
    );

    final fill = Paint()..shader = gradient;
    canvas.drawRRect(rrect, fill);

    // Borde más grueso y llamativo
    final border = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5; // Aumentado de 3.5
    canvas.drawRRect(rrect, border);

    // Texto línea 1
    tp1.paint(canvas, Offset(labelLeft + paddingH, paddingV));

    // Texto línea 2 (opcional)
    if (tp2 != null) {
      final y2 = paddingV + tp1.height + lineGap;
      tp2.paint(canvas, Offset(labelLeft + paddingH, y2));
    }

    // 🎨 SOMBRA para el círculo del pin
    final circleCenter = Offset(w / 2, labelH + spacing + pinRadius);
    final shadowCircle = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      Offset(circleCenter.dx + 2, circleCenter.dy + 2),
      pinRadius,
      shadowCircle,
    );

    // 🎨 GRADIENTE para el círculo del pin
    final circleGradient = ui.Gradient.radial(
      circleCenter,
      pinRadius,
      [lightColor, color, darkColor],
      [0.0, 0.5, 1.0],
    );
    final pinPaint = Paint()..shader = circleGradient;
    canvas.drawCircle(circleCenter, pinRadius, pinPaint);

    // Borde blanco alrededor del pin
    final pinBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5; // Aumentado de 4.0
    canvas.drawCircle(circleCenter, pinRadius, pinBorder);

    // Borde de color alrededor del borde blanco
    final pinBorder2 = Paint()
      ..color = darkColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5; // Aumentado de 2.0
    canvas.drawCircle(
      circleCenter,
      pinRadius + 2.0,
      pinBorder2,
    );

    // 🎨 ICONO de estado en el centro del pin
    final iconX = circleCenter.dx - tpIcon.width / 2;
    final iconY = circleCenter.dy - tpIcon.height / 2;
    tpIcon.paint(canvas, Offset(iconX, iconY));

    // 🎨 SOMBRA para el triángulo
    final tipY = labelH + spacing + pinRadius * 2 + pointerH;
    final topY = labelH + spacing + pinRadius * 2;
    final shadowPath = Path()
      ..moveTo(w / 2 + 2, tipY + 2)
      ..lineTo(w / 2 - 10 + 2, topY + 2)
      ..lineTo(w / 2 + 10 + 2, topY + 2)
      ..close();
    canvas.drawPath(shadowPath, shadowCircle);

    // Triángulo del pin con gradiente (más ancho)
    final path = Path()
      ..moveTo(w / 2, tipY)
      ..lineTo(w / 2 - 12, topY)
      ..lineTo(w / 2 + 12, topY)
      ..close();
    canvas.drawPath(path, pinPaint);

    // Borde del triángulo (más grueso)
    final pathBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5; // Aumentado de 2.5
    canvas.drawPath(path, pathBorder);

    final picture = recorder.endRecording();
    final img = await picture.toImage((w * pr).ceil(), (height * pr).ceil());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}
