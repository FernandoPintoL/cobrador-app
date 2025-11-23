import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

/// Overlay personalizado para guiar al usuario al capturar rostros
///
/// Muestra un óvalo que indica dónde debe posicionarse el rostro
/// y puede mostrar la posición detectada en tiempo real.
class FaceOverlayPainter extends CustomPainter {
  final Color frameColor;
  final Color backgroundColor;
  final double frameThickness;
  final Face? detectedFace;
  final Size imageSize;
  final InputImageRotation rotation;

  FaceOverlayPainter({
    this.frameColor = Colors.white,
    this.backgroundColor = Colors.black54,
    this.frameThickness = 3.0,
    this.detectedFace,
    this.imageSize = Size.zero,
    this.rotation = InputImageRotation.rotation0deg,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Dimensiones del área de captura del rostro (óvalo)
    final double frameWidth = size.width * 0.7;
    final double frameHeight = frameWidth * 1.3; // Proporción vertical
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;

    // Área de captura
    final captureRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    // Dibujar overlay oscuro alrededor del área de captura
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()..addOval(captureRect);

    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      paint,
    );

    // Determinar si hay un rostro bien posicionado
    final bool isFaceDetected = detectedFace != null && _isFaceInFrame(captureRect, size);

    // Dibujar marco del área de captura
    final framePaint = Paint()
      ..color = isFaceDetected ? Colors.green : frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameThickness;

    canvas.drawOval(captureRect, framePaint);

    // Si hay un rostro detectado, dibujarlo
    if (detectedFace != null) {
      _drawFaceBounds(canvas, size);
    }
  }

  bool _isFaceInFrame(Rect frameRect, Size canvasSize) {
    if (detectedFace == null) return false;

    final faceRect = _scaleRect(
      rect: detectedFace!.boundingBox,
      imageSize: imageSize,
      widgetSize: canvasSize,
    );

    // Verificar si el rostro está dentro del marco (con cierto margen)
    final centerX = faceRect.left + faceRect.width / 2;
    final centerY = faceRect.top + faceRect.height / 2;

    final frameCenterX = frameRect.left + frameRect.width / 2;
    final frameCenterY = frameRect.top + frameRect.height / 2;

    final distanceX = (centerX - frameCenterX).abs();
    final distanceY = (centerY - frameCenterY).abs();

    return distanceX < frameRect.width * 0.3 && distanceY < frameRect.height * 0.3;
  }

  void _drawFaceBounds(Canvas canvas, Size size) {
    final rect = _scaleRect(
      rect: detectedFace!.boundingBox,
      imageSize: imageSize,
      widgetSize: size,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.greenAccent.withValues(alpha: 0.7);

    canvas.drawRect(rect, paint);
  }

  Rect _scaleRect({
    required Rect rect,
    required Size imageSize,
    required Size widgetSize,
  }) {
    final double scaleX = widgetSize.width / imageSize.width;
    final double scaleY = widgetSize.height / imageSize.height;

    return Rect.fromLTRB(
      rect.left * scaleX,
      rect.top * scaleY,
      rect.right * scaleX,
      rect.bottom * scaleY,
    );
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.detectedFace != detectedFace ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Widget que muestra el overlay para captura de rostros
class FaceCaptureOverlay extends StatelessWidget {
  final Face? detectedFace;
  final Size imageSize;
  final InputImageRotation rotation;
  final String? helpText;

  const FaceCaptureOverlay({
    super.key,
    this.detectedFace,
    this.imageSize = Size.zero,
    this.rotation = InputImageRotation.rotation0deg,
    this.helpText,
  });

  bool get isFaceDetected => detectedFace != null;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay con el marco
        CustomPaint(
          painter: FaceOverlayPainter(
            detectedFace: detectedFace,
            imageSize: imageSize,
            rotation: rotation,
          ),
          child: Container(),
        ),

        // Texto de ayuda
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isFaceDetected
                  ? Colors.green.withValues(alpha: 0.8)
                  : Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isFaceDetected
                  ? 'Rostro detectado - Mantén la posición'
                  : helpText ?? 'Centra tu rostro en el óvalo',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
