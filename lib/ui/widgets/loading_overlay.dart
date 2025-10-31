import 'package:flutter/material.dart';

/// Simple full-screen loading overlay used while waiting for API responses.
///
/// Usage:
/// Stack(
///   children: [
///     bodyContent,
///     LoadingOverlay(isLoading: isLoading, message: 'Cargando...'),
///   ],
/// )
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String? message;
  final Color? barrierColor;

  const LoadingOverlay({super.key, required this.isLoading, this.message, this.barrierColor});

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Container(
          color: barrierColor ?? Colors.black.withOpacity(0.35),
          child: Center(
            child: Container
              (
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scheme.outline.withOpacity(0.4)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    message ?? 'Cargando...',
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
