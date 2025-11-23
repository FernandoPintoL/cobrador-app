import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'document_overlay_painter.dart';

/// Pantalla de cámara con detección de documentos en tiempo real
///
/// Utiliza Google ML Kit para detectar texto en el documento y
/// guiar al usuario a posicionar el documento correctamente.
class CameraWithDocumentDetectionScreen extends StatefulWidget {
  final String title;
  final String? helpText;
  final ResolutionPreset resolution;
  final bool autoCapture; // Captura automática cuando detecta el documento

  const CameraWithDocumentDetectionScreen({
    super.key,
    this.title = 'Capturar Documento',
    this.helpText,
    this.resolution = ResolutionPreset.high,
    this.autoCapture = false,
  });

  @override
  State<CameraWithDocumentDetectionScreen> createState() =>
      _CameraWithDocumentDetectionScreenState();
}

class _CameraWithDocumentDetectionScreenState
    extends State<CameraWithDocumentDetectionScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _isProcessing = false;
  int _selectedCameraIndex = 0; // Empezar con cámara trasera
  FlashMode _currentFlashMode = FlashMode.off;
  String? _errorMessage;

  // Text recognition for document detection
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  bool _isDocumentDetected = false;
  int _textBlocksCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _textRecognizer.close();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _errorMessage = null;
      });

      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _errorMessage = 'No se encontraron cámaras en este dispositivo';
        });
        return;
      }

      // Preferir cámara trasera para documentos
      _selectedCameraIndex = 0;

      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        widget.resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();

      // Iniciar streaming de imágenes para detección
      _controller!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al inicializar cámara: ${e.toString()}';
      });
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || _isTakingPicture) return;

    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        // Detectar documento basado en cantidad de texto encontrado
        final hasEnoughText = recognizedText.blocks.length >= 3;

        setState(() {
          _isDocumentDetected = hasEnoughText;
          _textBlocksCount = recognizedText.blocks.length;
        });

        // Auto-captura si está habilitada y se detecta un documento
        if (widget.autoCapture && _isDocumentDetected && !_isTakingPicture) {
          // Esperar un momento para que el usuario estabilice el documento
          await Future.delayed(const Duration(milliseconds: 2000));
          if (_isDocumentDetected && mounted) {
            _takePicture();
          }
        }
      }
    } catch (e) {
      // Silenciar errores de procesamiento de imagen
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final camera = _cameras![_selectedCameraIndex];
      final sensorOrientation = camera.sensorOrientation;

      InputImageRotation? rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
      } else if (Platform.isAndroid) {
        var rotationCompensation = sensorOrientation;

        final orientations = {
          DeviceOrientation.portraitUp: 0,
          DeviceOrientation.landscapeLeft: 90,
          DeviceOrientation.portraitDown: 180,
          DeviceOrientation.landscapeRight: 270,
        };

        rotationCompensation =
            (rotationCompensation - (orientations[DeviceOrientation.portraitUp] ?? 0) + 360) % 360;
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }

      if (rotation == null) return null;

      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final plane = image.planes.first;

      return InputImage.fromBytes(
        bytes: plane.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: plane.bytesPerRow,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    if (_isTakingPicture) {
      return;
    }

    setState(() {
      _isTakingPicture = true;
    });

    try {
      // Detener el stream de imágenes
      await _controller!.stopImageStream();

      // Ensure flash mode is set
      await _controller!.setFlashMode(_currentFlashMode);

      final XFile photo = await _controller!.takePicture();

      if (!mounted) return;

      // Navigate to preview screen for confirmation
      final File? confirmedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (context) => _PhotoPreviewScreen(
            imagePath: photo.path,
            title: widget.title,
          ),
        ),
      );

      if (confirmedFile != null && mounted) {
        // Return the confirmed photo
        Navigator.of(context).pop(confirmedFile);
      } else {
        // User cancelled, restart streaming
        if (mounted) {
          _controller!.startImageStream(_processCameraImage);
          setState(() {
            _isTakingPicture = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _controller!.startImageStream(_processCameraImage);
        setState(() {
          _isTakingPicture = false;
        });
        _showError('Error al tomar foto: ${e.toString()}');
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) {
      _showError('No hay otra cámara disponible');
      return;
    }

    setState(() {
      _isInitialized = false;
    });

    await _controller?.stopImageStream();
    await _controller?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    try {
      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        widget.resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_currentFlashMode);
      _controller!.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cambiar cámara: ${e.toString()}';
      });
    }
  }

  Future<void> _toggleFlashMode() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }

    try {
      FlashMode newMode;
      switch (_currentFlashMode) {
        case FlashMode.off:
          newMode = FlashMode.auto;
          break;
        case FlashMode.auto:
          newMode = FlashMode.always;
          break;
        case FlashMode.always:
          newMode = FlashMode.off;
          break;
        case FlashMode.torch:
          newMode = FlashMode.off;
          break;
      }

      await _controller!.setFlashMode(newMode);

      setState(() {
        _currentFlashMode = newMode;
      });
    } catch (e) {
      _showError('Error al cambiar flash: ${e.toString()}');
    }
  }

  IconData _getFlashIcon() {
    switch (_currentFlashMode) {
      case FlashMode.off:
        return Icons.flash_off;
      case FlashMode.auto:
        return Icons.flash_auto;
      case FlashMode.always:
        return Icons.flash_on;
      case FlashMode.torch:
        return Icons.flashlight_on;
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black54,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (!_isInitialized) {
      return _buildLoadingView();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        Center(
          child: CameraPreview(_controller!),
        ),

        // Document Detection Overlay
        DocumentCaptureOverlay(
          isDocumentDetected: _isDocumentDetected,
          helpText: widget.helpText,
        ),

        // Debug info (opcional - solo en desarrollo)
        if (_textBlocksCount > 0)
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Bloques: $_textBlocksCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

        // Controls overlay
        _buildControlsOverlay(),
      ],
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'Inicializando cámara...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade300,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.only(
            bottom: 40,
            top: 40,
            left: 16,
            right: 16,
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Flash toggle button
                _buildControlButton(
                  icon: _getFlashIcon(),
                  onPressed: _toggleFlashMode,
                  label: _currentFlashMode == FlashMode.off
                      ? 'Flash Off'
                      : _currentFlashMode == FlashMode.auto
                          ? 'Flash Auto'
                          : 'Flash On',
                ),

                // Take picture button
                _buildCaptureButton(),

                // Switch camera button
                _buildControlButton(
                  icon: Icons.flip_camera_ios,
                  onPressed: _cameras != null && _cameras!.length > 1
                      ? _switchCamera
                      : null,
                  label: 'Cambiar',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: IconButton(
            icon: Icon(icon),
            color: Colors.white,
            iconSize: 28,
            onPressed: onPressed,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2.0,
                color: Colors.black87,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isTakingPicture ? null : _takePicture,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isDocumentDetected ? Colors.green : Colors.white,
                width: 4,
              ),
              color: _isTakingPicture
                  ? Colors.grey.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.3),
            ),
            child: _isTakingPicture
                ? const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Capturar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 2.0,
                color: Colors.black87,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Preview screen to confirm captured photo
class _PhotoPreviewScreen extends StatelessWidget {
  final String imagePath;
  final String title;

  const _PhotoPreviewScreen({
    required this.imagePath,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Vista Previa',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.8),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      label: const Text('Reintentar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(File(imagePath));
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Usar Foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
