import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';

class GlassmorphicHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final Color roleColor;
  final String? profileImage;
  final bool isUploading;
  final String? uploadError;
  final Function(File) onImageSelected;

  const GlassmorphicHeaderCard({
    super.key,
    required this.name,
    required this.email,
    required this.role,
    required this.roleColor,
    this.profileImage,
    this.isUploading = false,
    this.uploadError,
    required this.onImageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  roleColor.withValues(alpha: 0.15),
                  roleColor.withValues(alpha: 0.05),
                ]
              : [
                  roleColor.withValues(alpha: 0.1),
                  roleColor.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // Profile Image with glow effect
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _buildProfileImage(),
                ),

                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              roleColor.withValues(alpha: 0.3),
                              roleColor.withValues(alpha: 0.2),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: roleColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRoleIcon(),
                              color: roleColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              role,
                              style: TextStyle(
                                color: roleColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    // This will be replaced with actual profile image widget
    // For now, using a placeholder
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor.withValues(alpha: 0.3),
            roleColor.withValues(alpha: 0.1),
          ],
        ),
        border: Border.all(
          color: roleColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person,
        color: roleColor,
        size: 35,
      ),
    );
  }

  IconData _getRoleIcon() {
    switch (role.toLowerCase()) {
      case 'manager':
        return Icons.manage_accounts;
      case 'cobrador':
        return Icons.account_balance_wallet;
      case 'superadmin':
        return Icons.admin_panel_settings;
      default:
        return Icons.person;
    }
  }
}
