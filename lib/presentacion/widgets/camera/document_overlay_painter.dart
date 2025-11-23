import 'package:flutter/material.dart';

/// Overlay personalizado para guiar al usuario al capturar documentos
///
/// Muestra un marco rectangular con esquinas redondeadas que indica
/// dónde debe colocarse el documento para una captura óptima.
class DocumentOverlayPainter extends CustomPainter {
  final Color frameColor;
  final Color backgroundColor;
  final double frameThickness;
  final bool isDocumentDetected;

  DocumentOverlayPainter({
    this.frameColor = Colors.white,
    this.backgroundColor = Colors.black54,
    this.frameThickness = 3.0,
    this.isDocumentDetected = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // Dimensiones del área de captura del documento
    final double frameWidth = size.width * 0.85;
    final double frameHeight = frameWidth * 0.63; // Proporción típica de una tarjeta/documento
    final double left = (size.width - frameWidth) / 2;
    final double top = (size.height - frameHeight) / 2;

    // Área de captura
    final captureRect = Rect.fromLTWH(left, top, frameWidth, frameHeight);

    // Dibujar overlay oscuro alrededor del área de captura
    final outerPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        captureRect,
        const Radius.circular(12),
      ));

    canvas.drawPath(
      Path.combine(PathOperation.difference, outerPath, innerPath),
      paint,
    );

    // Dibujar marco del área de captura
    final framePaint = Paint()
      ..color = isDocumentDetected ? Colors.green : frameColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameThickness;

    // Marco con esquinas redondeadas
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        captureRect,
        const Radius.circular(12),
      ),
      framePaint,
    );

    // Dibujar esquinas decorativas
    _drawCorners(canvas, captureRect, isDocumentDetected ? Colors.green : frameColor);
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    final cornerPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameThickness * 2
      ..strokeCap = StrokeCap.round;

    const cornerLength = 20.0;

    // Esquina superior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.top + cornerLength),
      Offset(rect.left, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left + cornerLength, rect.top),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.top),
      Offset(rect.right, rect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.top + cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      Offset(rect.left, rect.bottom - cornerLength),
      Offset(rect.left, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom),
      Offset(rect.left + cornerLength, rect.bottom),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      Offset(rect.right - cornerLength, rect.bottom),
      Offset(rect.right, rect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom),
      Offset(rect.right, rect.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant DocumentOverlayPainter oldDelegate) {
    return oldDelegate.isDocumentDetected != isDocumentDetected ||
        oldDelegate.frameColor != frameColor ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}

/// Widget que muestra el overlay para captura de documentos
class DocumentCaptureOverlay extends StatelessWidget {
  final bool isDocumentDetected;
  final String? helpText;

  const DocumentCaptureOverlay({
    super.key,
    this.isDocumentDetected = false,
    this.helpText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Overlay con el marco
        CustomPaint(
          painter: DocumentOverlayPainter(
            isDocumentDetected: isDocumentDetected,
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
              color: isDocumentDetected
                  ? Colors.green.withOpacity(0.8)
                  : Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isDocumentDetected
                  ? 'Documento detectado - Mantén firme'
                  : helpText ?? 'Coloca el documento dentro del marco',
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
