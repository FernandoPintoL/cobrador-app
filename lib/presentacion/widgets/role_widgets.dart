import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/role_colors.dart';
import '../../datos/api_services/api_service.dart';

/// Widget que muestra información del rol de manera consistente
class RoleDisplayWidget extends StatelessWidget {
  final String role;
  final double? fontSize;
  final bool showIcon;
  final bool useGradient;
  final EdgeInsets padding;

  const RoleDisplayWidget({
    super.key,
    required this.role,
    this.fontSize = 12,
    this.showIcon = true,
    this.useGradient = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final displayName = RoleColors.getRoleDisplayName(role);
    final icon = RoleColors.getRoleIcon(role);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          Icon(icon, size: (fontSize ?? 12) + 4, color: Colors.white),
          const SizedBox(width: 4),
        ],
        Text(
          displayName,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: useGradient ? RoleColors.getGradient(role) : null,
        color: useGradient ? null : RoleColors.getPrimaryColor(role),
        borderRadius: BorderRadius.circular(12),
      ),
      child: content,
    );
  }
}

/// Avatar circular con colores del rol
class RoleAvatarWidget extends StatelessWidget {
  final String role;
  final String userName;
  final double radius;
  final bool useGradient;

  const RoleAvatarWidget({
    super.key,
    required this.role,
    required this.userName,
    this.radius = 20,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    if (useGradient) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          gradient: RoleColors.getGradient(role),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: RoleColors.getPrimaryColor(role),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// AppBar con colores del rol
class RoleAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String role;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final double elevation;

  const RoleAppBar({
    super.key,
    required this.title,
    required this.role,
    this.actions,
    this.leading,
    this.bottom,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: RoleColors.getPrimaryColor(role),
      foregroundColor: Colors.white,
      elevation: elevation,
      actions: actions,
      leading: leading,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0.0));
}

/// Card con header gradiente del rol
class RoleHeaderCard extends StatelessWidget {
  final String role;
  final String userName;
  final String? userEmail;
  final Widget? trailing;
  final VoidCallback? onTap;

  const RoleHeaderCard({
    super.key,
    required this.role,
    required this.userName,
    this.userEmail,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: Container(
        decoration: BoxDecoration(
          gradient: RoleColors.getGradient(role),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                RoleAvatarWidget(role: role, userName: userName, radius: 30),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (userEmail != null && userEmail!.isNotEmpty)
                        Text(
                          userEmail!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 8),
                      RoleDisplayWidget(
                        role: role,
                        useGradient: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// FloatingActionButton con colores del rol
class RoleFloatingActionButton extends StatelessWidget {
  final String role;
  final VoidCallback onPressed;
  final Widget child;
  final String? tooltip;

  const RoleFloatingActionButton({
    super.key,
    required this.role,
    required this.onPressed,
    required this.child,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: RoleColors.getPrimaryColor(role),
      foregroundColor: Colors.white,
      tooltip: tooltip,
      child: child,
    );
  }
}

/// Avatar con imagen de perfil real o iniciales del rol como fallback
class ProfileAvatarWidget extends StatelessWidget {
  final String role;
  final String userName;
  final String? profileImagePath;
  final double radius;
  final bool useGradient;

  const ProfileAvatarWidget({
    super.key,
    required this.role,
    required this.userName,
    this.profileImagePath,
    this.radius = 20,
    this.useGradient = false,
  });

  @override
  Widget build(BuildContext context) {
    // Si hay imagen de perfil, mostrarla
    if (profileImagePath != null && profileImagePath!.isNotEmpty) {
      final apiService = ApiService();
      final imageUrl = apiService.getProfileImageUrl(profileImagePath);

      return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) => CircleAvatar(
          radius: radius,
          backgroundImage: imageProvider,
        ),
        placeholder: (context, url) => _buildFallbackAvatar(),
        errorWidget: (context, url, error) => _buildFallbackAvatar(),
        memCacheWidth: (radius * 4).toInt(),
        memCacheHeight: (radius * 4).toInt(),
      );
    }

    // Si no hay imagen, mostrar avatar del rol
    return _buildFallbackAvatar();
  }

  Widget _buildFallbackAvatar() {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    if (useGradient) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          gradient: RoleColors.getGradient(role),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initial,
            style: TextStyle(
              fontSize: radius * 0.6,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: RoleColors.getPrimaryColor(role),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
