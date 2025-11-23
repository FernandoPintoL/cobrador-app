import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_with_face_detection_screen.dart';
import 'camera_with_document_detection_screen.dart';

/// Pantalla de prueba rápida para las cámaras con ML
///
/// Para probar, agrega esta ruta a tu router o navega directamente:
/// Navigator.push(context, MaterialPageRoute(builder: (_) => TestCameraMLScreen()));
class TestCameraMLScreen extends StatefulWidget {
  const TestCameraMLScreen({super.key});

  @override
  State<TestCameraMLScreen> createState() => _TestCameraMLScreenState();
}

class _TestCameraMLScreenState extends State<TestCameraMLScreen> {
  File? _lastPhoto;
  String _lastPhotoType = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Cámaras ML'),
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Vista previa de la última foto capturada
            if (_lastPhoto != null) ...[
              Container(
                width: double.infinity,
                height: 300,
                color: Colors.black,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      _lastPhoto!,
                      fit: BoxFit.contain,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _lastPhotoType,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Última foto: ${_lastPhoto!.path.split('/').last}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[200],
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      'No hay fotos capturadas',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Botones de prueba
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🎭 Detección de Rostros',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Test 1: Face Detection Manual
                  _buildTestButton(
                    icon: Icons.face,
                    label: 'Rostro - Captura Manual',
                    color: Colors.blue,
                    onPressed: () => _testFaceDetectionManual(),
                  ),
                  const SizedBox(height: 8),

                  // Test 2: Face Detection Auto
                  _buildTestButton(
                    icon: Icons.face_retouching_natural,
                    label: 'Rostro - Auto Captura ⚡',
                    color: Colors.green,
                    onPressed: () => _testFaceDetectionAuto(),
                  ),

                  const SizedBox(height: 32),
                  const Text(
                    '📄 Detección de Documentos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Test 3: Document Detection Manual
                  _buildTestButton(
                    icon: Icons.badge,
                    label: 'Documento - Captura Manual',
                    color: Colors.orange,
                    onPressed: () => _testDocumentDetectionManual(),
                  ),
                  const SizedBox(height: 8),

                  // Test 4: Document Detection Auto
                  _buildTestButton(
                    icon: Icons.credit_card,
                    label: 'Documento - Auto Captura ⚡',
                    color: Colors.deepOrange,
                    onPressed: () => _testDocumentDetectionAuto(),
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Información
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Información de Prueba',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          '✓ Auto Captura: Se toma la foto automáticamente cuando detecta',
                        ),
                        _buildInfoItem(
                          '✓ Detección de Rostros: Funciona solo en dispositivos reales',
                        ),
                        _buildInfoItem(
                          '✓ Detección de Documentos: Detecta texto usando OCR',
                        ),
                        _buildInfoItem(
                          '✓ Borde verde = Detección exitosa',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  // Test 1: Detección de rostros - Manual
  Future<void> _testFaceDetectionManual() async {
    final photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithFaceDetectionScreen(
          title: 'Test: Rostro Manual',
          helpText: 'Centra tu rostro y presiona capturar',
          autoCapture: false,
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _lastPhoto = photo;
        _lastPhotoType = 'ROSTRO MANUAL';
      });
      _showSuccess('Rostro capturado manualmente');
    }
  }

  // Test 2: Detección de rostros - Auto
  Future<void> _testFaceDetectionAuto() async {
    final photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithFaceDetectionScreen(
          title: 'Test: Rostro Auto',
          helpText: 'Centra tu rostro - Se capturará automáticamente',
          autoCapture: true,
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _lastPhoto = photo;
        _lastPhotoType = 'ROSTRO AUTO ⚡';
      });
      _showSuccess('Rostro capturado automáticamente!', isAuto: true);
    }
  }

  // Test 3: Detección de documentos - Manual
  Future<void> _testDocumentDetectionManual() async {
    final photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithDocumentDetectionScreen(
          title: 'Test: Documento Manual',
          helpText: 'Coloca el documento en el marco',
          autoCapture: false,
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _lastPhoto = photo;
        _lastPhotoType = 'DOCUMENTO MANUAL';
      });
      _showSuccess('Documento capturado manualmente');
    }
  }

  // Test 4: Detección de documentos - Auto
  Future<void> _testDocumentDetectionAuto() async {
    final photo = await Navigator.push<File>(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithDocumentDetectionScreen(
          title: 'Test: Documento Auto',
          helpText: 'Coloca el documento - Se capturará automáticamente',
          autoCapture: true,
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _lastPhoto = photo;
        _lastPhotoType = 'DOCUMENTO AUTO ⚡';
      });
      _showSuccess('Documento capturado automáticamente!', isAuto: true);
    }
  }

  void _showSuccess(String message, {bool isAuto = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isAuto ? Icons.bolt : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isAuto ? Colors.green : Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
