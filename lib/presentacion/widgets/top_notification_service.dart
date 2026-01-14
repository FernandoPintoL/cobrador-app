import 'package:flutter/material.dart';

/// Servicio para mostrar notificaciones tipo banner en la parte superior
/// Similar a WhatsApp, Facebook, etc.
class TopNotificationService {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  /// Muestra una notificación de éxito
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  /// Muestra una notificación de error
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 6),
  }) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.red,
      icon: Icons.error,
      duration: duration,
    );
  }

  /// Muestra una notificación de advertencia
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
      duration: duration,
    );
  }

  /// Muestra una notificación de información
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _showNotification(
      context,
      message: message,
      backgroundColor: Colors.blue,
      icon: Icons.info,
      duration: duration,
    );
  }

  /// Oculta la notificación actual si existe
  static void hide() {
    if (_currentOverlay != null) {
      _currentOverlay!.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }

  /// Método interno para mostrar la notificación
  static void _showNotification(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    required Duration duration,
  }) {
    // Si ya hay una notificación mostrándose, ocultarla primero
    if (_isShowing) {
      hide();
    }

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => _TopNotificationWidget(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: hide,
      ),
    );

    _currentOverlay = overlayEntry;
    _isShowing = true;
    overlay.insert(overlayEntry);

    // Auto-ocultar después de la duración especificada
    Future.delayed(duration, () {
      if (_currentOverlay == overlayEntry) {
        hide();
      }
    });
  }
}

/// Widget de notificación animado
class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _TopNotificationWidget({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_TopNotificationWidget> createState() =>
      _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.only(
                top: topPadding + 8,
                left: 16,
                right: 16,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
