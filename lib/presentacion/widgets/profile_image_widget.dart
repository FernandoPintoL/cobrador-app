import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import '../../negocio/domain_services/allowed_apps_helper.dart';
import 'dart:io';
import '../../datos/api_services/api_service.dart';

class ProfileImageWidget extends StatelessWidget {
  final String? profileImage;
  final double size;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;
  final Widget? placeholder;
  final Widget? errorWidget;

  const ProfileImageWidget({
    super.key,
    required this.profileImage,
    this.size = 60,
    this.borderRadius,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final imageUrl = apiService.getProfileImageUrl(profileImage);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: showBorder
              ? Border.all(
                  color: borderColor ?? Theme.of(context).primaryColor,
                  width: borderWidth,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius ?? size / 2),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => _buildPlaceholder(context, isDark),
            errorWidget: (context, url, error) =>
                _buildErrorWidget(context, isDark),
            memCacheWidth: (size * 2).toInt(),
            memCacheHeight: (size * 2).toInt(),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
      ),
    );
  }
}

class ProfileImageWithUpload extends StatefulWidget {
  final String? profileImage;
  final double size;
  final double? borderRadius;
  final Function(File)? onImageSelected;
  final bool showUploadButton;
  final bool isUploading;
  final String? uploadError;

  const ProfileImageWithUpload({
    super.key,
    required this.profileImage,
    this.size = 80,
    this.borderRadius,
    this.onImageSelected,
    this.showUploadButton = true,
    this.isUploading = false,
    this.uploadError,
  });

  @override
  State<ProfileImageWithUpload> createState() => _ProfileImageWithUploadState();
}

class _ProfileImageWithUploadState extends State<ProfileImageWithUpload> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProfileImageWidget(
          profileImage: widget.profileImage,
          size: widget.size,
          borderRadius: widget.borderRadius,
          onTap: widget.showUploadButton ? _showImagePickerDialog : null,
        ),
        if (widget.showUploadButton)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28, // Tamaño fijo para evitar overflow
              height: 28, // Tamaño fijo para evitar overflow
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: IconButton(
                onPressed: widget.isUploading ? null : _showImagePickerDialog,
                icon: widget.isUploading
                    ? SizedBox(
                        width: 12, // Reducido de 16 a 12
                        height: 12, // Reducido de 16 a 12
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(Icons.camera_alt, color: Colors.white, size: 14), // Reducido de 16 a 14
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28), // Ajustado para el nuevo tamaño
              ),
            ),
          ),
        if (widget.uploadError != null)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error, color: Colors.white, size: 12),
            ),
          ),
      ],
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          _ImagePickerBottomSheet(onImageSelected: widget.onImageSelected),
    );
  }
}

class _ImagePickerBottomSheet extends StatelessWidget {
  final Function(File)? onImageSelected;

  const _ImagePickerBottomSheet({this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Seleccionar imagen de perfil',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ImagePickerOption(
                icon: Icons.camera_alt,
                label: 'Cámara',
                onTap: () => _pickImage(context, ImageSource.camera),
              ),
              _ImagePickerOption(
                icon: Icons.photo_library,
                label: 'Galería',
                onTap: () => _pickImage(context, ImageSource.gallery),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _pickImage(BuildContext context, ImageSource source) async {
    Navigator.pop(context);

    try {
      final XFile? image = await AllowedAppsHelper.openCameraSecurely(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        onImageSelected?.call(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ImagePickerOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImagePickerOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
