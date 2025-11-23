import 'dart:io';
import 'package:flutter/material.dart';
import 'camera_with_face_detection_screen.dart';
import 'camera_with_document_detection_screen.dart';
import 'in_app_camera_screen.dart';

/// Ejemplo de cómo usar los diferentes widgets de cámara
///
/// Este archivo muestra ejemplos prácticos de integración
class EjemploUsoCamara extends StatefulWidget {
  const EjemploUsoCamara({super.key});

  @override
  State<EjemploUsoCamara> createState() => _EjemploUsoCamaraState();
}

class _EjemploUsoCamaraState extends State<EjemploUsoCamara> {
  File? _capturedPhoto;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo Cámaras con ML'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Cámaras con Detección ML',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Estas cámaras usan Google ML Kit para detectar rostros y documentos en tiempo real.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            // Vista previa de la foto capturada
            if (_capturedPhoto != null) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _capturedPhoto!,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Foto capturada: ${_capturedPhoto!.path.split('/').last}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
            ],

            // Botón 1: Cámara con detección de rostros (manual)
            ElevatedButton.icon(
              onPressed: _capturarRostroManual,
              icon: const Icon(Icons.face),
              label: const Text('Capturar Rostro (Manual)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Muestra un óvalo guía y detecta el rostro en tiempo real. El usuario debe presionar el botón para capturar.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Botón 2: Cámara con detección de rostros (auto-captura)
            ElevatedButton.icon(
              onPressed: _capturarRostroAuto,
              icon: const Icon(Icons.face_retouching_natural),
              label: const Text('Capturar Rostro (Auto)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Captura automáticamente cuando detecta un rostro bien posicionado (después de 1.5 segundos).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Botón 3: Cámara con detección de documentos (manual)
            ElevatedButton.icon(
              onPressed: _capturarDocumentoManual,
              icon: const Icon(Icons.badge),
              label: const Text('Capturar Documento (Manual)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Muestra un marco rectangular y detecta texto en el documento. Incluye control de flash.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Botón 4: Cámara con detección de documentos (auto-captura)
            ElevatedButton.icon(
              onPressed: _capturarDocumentoAuto,
              icon: const Icon(Icons.credit_card),
              label: const Text('Capturar Documento (Auto)'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Captura automáticamente cuando detecta suficiente texto en el documento (después de 2 segundos).',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Botón 5: Cámara simple sin detección
            OutlinedButton.icon(
              onPressed: _capturarSimple,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Cámara Simple (Sin Detección)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cámara básica sin detección ML. Útil para fotos generales.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Ejemplo 1: Capturar rostro con detección (manual)
  Future<void> _capturarRostroManual() async {
    final File? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithFaceDetectionScreen(
          title: 'Capturar Selfie',
          helpText: 'Centra tu rostro en el óvalo',
          autoCapture: false,
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rostro capturado correctamente')),
        );
      }

      // Aquí puedes procesar la foto: comprimir, subir, etc.
      _procesarFoto(photo);
    }
  }

  /// Ejemplo 2: Capturar rostro con auto-captura
  Future<void> _capturarRostroAuto() async {
    final File? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithFaceDetectionScreen(
          title: 'Verificación de Identidad',
          helpText: 'Centra tu rostro - Se capturará automáticamente',
          autoCapture: true, // ✨ Auto-captura activada
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rostro capturado automáticamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Ejemplo 3: Capturar documento con detección (manual)
  Future<void> _capturarDocumentoManual() async {
    final File? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithDocumentDetectionScreen(
          title: 'Capturar Cédula',
          helpText: 'Coloca tu cédula dentro del marco',
          autoCapture: false,
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Documento capturado correctamente')),
        );
      }

      // Aquí podrías hacer OCR adicional si necesitas extraer datos
      _procesarDocumento(photo);
    }
  }

  /// Ejemplo 4: Capturar documento con auto-captura
  Future<void> _capturarDocumentoAuto() async {
    final File? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraWithDocumentDetectionScreen(
          title: 'Capturar DNI',
          helpText: 'Coloca el documento - Se capturará automáticamente',
          autoCapture: true, // ✨ Auto-captura activada
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documento capturado automáticamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  /// Ejemplo 5: Cámara simple sin detección
  Future<void> _capturarSimple() async {
    final File? photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InAppCameraScreen(
          title: 'Tomar Foto',
          helpText: 'Captura una foto clara',
        ),
      ),
    );

    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto capturada')),
        );
      }
    }
  }

  /// Procesar foto capturada
  void _procesarFoto(File photo) {
    // Aquí puedes:
    // 1. Comprimir la imagen
    // 2. Subirla a tu servidor
    // 3. Guardarla localmente
    // 4. Aplicar filtros o ajustes

    print('📸 Procesando foto: ${photo.path}');
    print('📏 Tamaño: ${photo.lengthSync()} bytes');

    // Ejemplo: Comprimir con flutter_image_compress
    // final compressedFile = await FlutterImageCompress.compressAndGetFile(
    //   photo.path,
    //   '${photo.path}_compressed.jpg',
    //   quality: 85,
    // );
  }

  /// Procesar documento capturado
  void _procesarDocumento(File photo) {
    print('📄 Procesando documento: ${photo.path}');

    // Aquí podrías:
    // 1. Hacer OCR completo del documento
    // 2. Extraer datos específicos (nombre, número de documento, etc.)
    // 3. Validar el formato del documento
    // 4. Detectar si el documento es válido

    // Ejemplo con ML Kit Text Recognition:
    // final inputImage = InputImage.fromFilePath(photo.path);
    // final recognizedText = await textRecognizer.processImage(inputImage);
    // print('Texto encontrado: ${recognizedText.text}');
  }
}

// ════════════════════════════════════════════════════════════════════════
// Ejemplos de uso en diferentes contextos
// ════════════════════════════════════════════════════════════════════════

/// Ejemplo de uso en formulario de registro
class RegistroUsuarioForm extends StatefulWidget {
  const RegistroUsuarioForm({super.key});

  @override
  State<RegistroUsuarioForm> createState() => _RegistroUsuarioFormState();
}

class _RegistroUsuarioFormState extends State<RegistroUsuarioForm> {
  File? _fotoSelfie;
  File? _fotoCedula;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Usuario')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Paso 1: Captura tu selfie'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final photo = await Navigator.push<File>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraWithFaceDetectionScreen(
                      title: 'Tu Selfie',
                      helpText: 'Mira a la cámara',
                      autoCapture: true,
                    ),
                  ),
                );
                if (photo != null) {
                  setState(() => _fotoSelfie = photo);
                }
              },
              icon: Icon(_fotoSelfie != null ? Icons.check_circle : Icons.face),
              label: Text(_fotoSelfie != null ? 'Selfie capturada ✓' : 'Capturar Selfie'),
            ),
            const SizedBox(height: 24),
            const Text('Paso 2: Captura tu cédula'),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final photo = await Navigator.push<File>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CameraWithDocumentDetectionScreen(
                      title: 'Tu Cédula',
                      helpText: 'Asegúrate de que se vea claramente',
                      autoCapture: true,
                    ),
                  ),
                );
                if (photo != null) {
                  setState(() => _fotoCedula = photo);
                }
              },
              icon: Icon(_fotoCedula != null ? Icons.check_circle : Icons.badge),
              label: Text(_fotoCedula != null ? 'Cédula capturada ✓' : 'Capturar Cédula'),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _fotoSelfie != null && _fotoCedula != null
                  ? () {
                      // Enviar datos del formulario
                      _enviarRegistro();
                    }
                  : null,
              child: const Text('Completar Registro'),
            ),
          ],
        ),
      ),
    );
  }

  void _enviarRegistro() {
    // Implementar lógica de envío
    print('Enviando registro con selfie y cédula');
  }
}
