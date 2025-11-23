import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'face_overlay_painter.dart';

/// Pantalla de cámara con detección de rostros en tiempo real
///
/// Utiliza Google ML Kit para detectar rostros y guiar al usuario
/// a centrar su rostro correctamente antes de capturar.
class CameraWithFaceDetectionScreen extends StatefulWidget {
  final String title;
  final String? helpText;
  final ResolutionPreset resolution;
  final bool autoCapture; // Captura automática cuando detecta el rostro

  const CameraWithFaceDetectionScreen({
    super.key,
    this.title = 'Capturar Rostro',
    this.helpText,
    this.resolution = ResolutionPreset.high,
    this.autoCapture = false,
  });

  @override
  State<CameraWithFaceDetectionScreen> createState() =>
      _CameraWithFaceDetectionScreenState();
}

class _CameraWithFaceDetectionScreenState
    extends State<CameraWithFaceDetectionScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  bool _isProcessing = false;
  int _selectedCameraIndex = 1; // Empezar con cámara frontal
  String? _errorMessage;

  // Face detection
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  Face? _detectedFace;
  Size _imageSize = Size.zero;

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
    _faceDetector.close();
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

      // Preferir cámara frontal para rostros
      _selectedCameraIndex = _cameras!.length > 1 ? 1 : 0;

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

      final faces = await _faceDetector.processImage(inputImage);

      if (mounted) {
        setState(() {
          _detectedFace = faces.isNotEmpty ? faces.first : null;
          _imageSize = Size(
            image.width.toDouble(),
            image.height.toDouble(),
          );
        });

        // Auto-captura si está habilitada y se detecta un rostro bien centrado
        if (widget.autoCapture && _detectedFace != null && !_isTakingPicture) {
          // Esperar un momento para que el usuario se estabilice
          await Future.delayed(const Duration(milliseconds: 1500));
          if (_detectedFace != null && mounted) {
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

        rotationCompensation = (rotationCompensation - (orientations[DeviceOrientation.portraitUp] ?? 0) + 360) % 360;
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

        // Face Detection Overlay
        FaceCaptureOverlay(
          detectedFace: _detectedFace,
          imageSize: _imageSize,
          helpText: widget.helpText,
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
                // Spacer
                const SizedBox(width: 60),

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
                color: _detectedFace != null ? Colors.green : Colors.white,
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
