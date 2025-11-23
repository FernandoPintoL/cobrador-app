import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pantalla de cámara in-app personalizable
///
/// Esta pantalla permite capturar fotos sin salir de la aplicación,
/// evitando el cierre de sesión por cambio de app.
///
/// Características:
/// - Vista previa en tiempo real
/// - Cambio entre cámara frontal y trasera
/// - Control de flash
/// - Captura en alta resolución
/// - Confirmación de foto antes de usar
class InAppCameraScreen extends StatefulWidget {
  final String title;
  final String? helpText;
  final ResolutionPreset resolution;

  const InAppCameraScreen({
    super.key,
    this.title = 'Tomar Foto',
    this.helpText,
    this.resolution = ResolutionPreset.high,
  });

  @override
  State<InAppCameraScreen> createState() => _InAppCameraScreenState();
}

class _InAppCameraScreenState extends State<InAppCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isTakingPicture = false;
  int _selectedCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    // Lock orientation to portrait for better UX
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    // Restore all orientations
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

    // App state changed before we got the chance to initialize
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

      // Prefer back camera (index 0 is usually back camera)
      _selectedCameraIndex = 0;

      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        widget.resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

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
        // User cancelled, continue taking photos
        setState(() {
          _isTakingPicture = false;
        });
      }
    } catch (e) {
      if (mounted) {
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

    await _controller?.dispose();

    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras!.length;

    try {
      _controller = CameraController(
        _cameras![_selectedCameraIndex],
        widget.resolution,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(_currentFlashMode);

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
              color: Colors.black.withOpacity(0.5),
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
        _buildCameraPreview(),

        // Help text overlay (if provided)
        if (widget.helpText != null) _buildHelpText(),

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

  Widget _buildCameraPreview() {
    if (_controller == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: CameraPreview(_controller!),
    );
  }

  Widget _buildHelpText() {
    return Positioned(
      top: 100,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.helpText!,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    return Column(
      children: [
        const Spacer(),
        // Bottom controls
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.3),
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
                  onPressed:
                      _cameras != null && _cameras!.length > 1
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
            color: Colors.black.withOpacity(0.5),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
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
                color: Colors.white,
                width: 4,
              ),
              color: _isTakingPicture
                  ? Colors.grey.withOpacity(0.5)
                  : Colors.white.withOpacity(0.3),
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
        title: Text(
          'Vista Previa',
          style: const TextStyle(color: Colors.white),
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
              color: Colors.black.withOpacity(0.8),
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
