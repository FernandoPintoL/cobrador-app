import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import '../../negocio/domain_services/allowed_apps_helper.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../config/role_colors.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/modern_action_card.dart';
import 'change_password_screen.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends ConsumerState<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final profileImageState = ref.watch(profileImageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Obtener el rol principal del usuario
    final primaryRole = usuario?.roles.isNotEmpty == true
        ? usuario!.roles.first
        : 'usuario';
    final roleColor = RoleColors.getPrimaryColor(primaryRole);

    // Escuchar cambios en el estado de la imagen de perfil
    ref.listen<ProfileImageState>(profileImageProvider, (previous, next) async {
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }

      if (previous?.successMessage != next.successMessage && next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        await ref.read(authProvider.notifier).refreshUser();
        ref.read(profileImageProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar con Hero Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: isDark ? Colors.grey[900] : roleColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          roleColor,
                          roleColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),

                  // Blur overlay
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                    ),
                  ),

                  // Pattern overlay
                  Opacity(
                    opacity: 0.1,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: const AssetImage('assets/pattern.png'),
                          repeat: ImageRepeat.repeat,
                          onError: (exception, stackTrace) {},
                        ),
                      ),
                    ),
                  ),

                  // Content
                  SafeArea(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                            const SizedBox(height: 60),

                            // Profile Image with Glow
                            Hero(
                              tag: 'profile_image',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    ProfileImageWithUpload(
                                      profileImage: usuario?.profileImage,
                                      size: 120,
                                      isUploading: profileImageState.isUploading,
                                      uploadError: profileImageState.error,
                                      onImageSelected: (File imageFile) {
                                        ref
                                            .read(profileImageProvider.notifier)
                                            .uploadProfileImage(imageFile);
                                      },
                                    ),

                                    // Edit button
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: profileImageState.isUploading
                                            ? null
                                            : () => _showImagePickerDialog(context, ref),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: roleColor,
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.camera_alt,
                                            color: roleColor,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // User Name
                            Text(
                              usuario?.nombre ?? 'Usuario',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // User Email
                            Text(
                              usuario?.email ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.9),
                                shadows: const [
                                  Shadow(
                                    color: Colors.black26,
                                    offset: Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Role Chips
                            if (usuario?.roles.isNotEmpty == true)
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: usuario!.roles
                                    .map((role) => _buildModernRoleChip(context, role))
                                    .toList(),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Personal Information Section
                    _buildSectionTitle(context, 'Información Personal', Icons.person),
                    const SizedBox(height: 12),
                    _buildModernInfoCard(context, ref, usuario, roleColor),

                    const SizedBox(height: 24),

                    // Security Section
                    // _buildSectionTitle(context, 'Seguridad', Icons.security),
                    // const SizedBox(height: 12),
                    // _buildSecurityActions(context, ref, roleColor),

                    const SizedBox(height: 24),

                    // Account Actions Section
                    _buildSectionTitle(context, 'Acciones de Cuenta', Icons.settings),
                    const SizedBox(height: 12),
                    _buildAccountActions(context, ref, roleColor),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.2),
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoCard(
    BuildContext context,
    WidgetRef ref,
    dynamic usuario,
    Color roleColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: roleColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildModernInfoField(
                context,
                ref,
                usuario,
                'Nombre',
                usuario?.nombre ?? '',
                Icons.person_outline,
                roleColor,
                fieldKey: 'name',
              ),
              const Divider(height: 32),
              _buildModernInfoField(
                context,
                ref,
                usuario,
                'Email',
                usuario?.email ?? '',
                Icons.email_outlined,
                roleColor,
                fieldKey: 'email',
              ),
              const Divider(height: 32),
              _buildModernInfoField(
                context,
                ref,
                usuario,
                'Teléfono',
                usuario?.telefono ?? '',
                Icons.phone_outlined,
                roleColor,
                fieldKey: 'phone',
              ),
              const Divider(height: 32),
              _buildModernInfoField(
                context,
                ref,
                usuario,
                'Dirección',
                usuario?.direccion ?? '',
                Icons.location_on_outlined,
                roleColor,
                fieldKey: 'address',
              ),
              const Divider(height: 32),
              _buildModernInfoField(
                context,
                ref,
                usuario,
                'CI',
                usuario?.ci ?? '',
                Icons.badge_outlined,
                roleColor,
                fieldKey: 'ci',
                isReadOnly: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoField(
    BuildContext context,
    WidgetRef ref,
    dynamic usuario,
    String label,
    String value,
    IconData icon,
    Color roleColor, {
    required String fieldKey,
    bool isReadOnly = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                roleColor.withValues(alpha: 0.15),
                roleColor.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: roleColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'No especificado' : value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
        if (!isReadOnly)
          IconButton(
            icon: Icon(
              Icons.edit_outlined,
              color: roleColor,
            ),
            onPressed: () => _showEditFieldDialog(
              context,
              ref,
              usuario,
              label,
              value,
              fieldKey,
            ),
            style: IconButton.styleFrom(
              backgroundColor: roleColor.withValues(alpha: 0.1),
            ),
          ),
      ],
    );
  }

  Widget _buildSecurityActions(BuildContext context, WidgetRef ref, Color roleColor) {
    return Column(
      children: [
        /*ModernActionCard(
          title: 'Cambiar Contraseña',
          description: 'Actualiza tu contraseña de acceso',
          icon: Icons.lock_outline,
          color: Colors.orange,
          onTap: () => _showChangePasswordDialog(context, ref),
        ),*/

      ],
    );
  }

  Widget _buildAccountActions(BuildContext context, WidgetRef ref, Color roleColor) {
    return Column(
      children: [
        ModernActionCard(
          title: 'Notificaciones',
          description: 'Ver todas tus notificaciones',
          icon: Icons.notifications_outlined,
          color: Colors.blue,
          onTap: () {
            Navigator.pushNamed(context, '/notifications');
          },
        ),
        const SizedBox(height: 12),
        ModernActionCard(
          title: 'Cambiar Contraseña',
          description: 'Actualiza la contraseña de tu cuenta',
          icon: Icons.vpn_key_outlined,
          color: Colors.purple,
          onTap: () {
            final usuario = ref.read(authProvider).usuario;
            if (usuario != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangePasswordScreen(
                    targetUser: usuario,
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),
        ModernActionCard(
          title: 'Eliminar Imagen de Perfil',
          description: 'Quitar tu foto de perfil actual',
          icon: Icons.delete_outline,
          color: Colors.red,
          onTap: () => _deleteProfileImage(ref),
        ),
      ],
    );
  }

  Widget _buildModernRoleChip(BuildContext context, String role) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            RoleColors.getRoleIcon(role),
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            RoleColors.getRoleDisplayName(role),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditFieldDialog(
    BuildContext context,
    WidgetRef ref,
    dynamic usuario,
    String label,
    String value,
    String fieldKey,
  ) async {
    final controller = TextEditingController(text: value);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.edit,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text('Editar $label'),
            ],
          ),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            ),
            keyboardType: fieldKey == 'phone'
                ? TextInputType.phone
                : fieldKey == 'email'
                    ? TextInputType.emailAddress
                    : TextInputType.text,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (newValue == null) return;
    if (newValue == value) return;
    if (usuario == null) return;

    final updatedNombre = fieldKey == 'name' ? newValue : (usuario.nombre ?? '');
    final updatedEmail = fieldKey == 'email' ? newValue : (usuario.email ?? '');
    final updatedTelefono = fieldKey == 'phone' ? newValue : (usuario.telefono ?? '');
    final updatedDireccion = fieldKey == 'address' ? newValue : (usuario.direccion ?? '');

    final ok = await ref.read(userManagementProvider.notifier).actualizarUsuario(
      id: usuario.id,
      nombre: updatedNombre.isEmpty ? (usuario.nombre ?? '') : updatedNombre,
      email: updatedEmail.isEmpty ? (usuario.email ?? '') : updatedEmail,
      ci: usuario.ci ?? '',
      telefono: updatedTelefono.isEmpty ? (usuario.telefono ?? '') : updatedTelefono,
      direccion: updatedDireccion.isEmpty ? (usuario.direccion ?? '') : updatedDireccion,
    );

    if (ok && context.mounted) {
      await ref.read(authProvider.notifier).refreshUser();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('$label actualizado correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } else {
      final umState = ref.read(userManagementProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(umState.error ?? 'Error al actualizar $label'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

void _showImagePickerDialog(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _ModernImagePickerBottomSheet(
      onImageSelected: (File imageFile) {
        ref.read(profileImageProvider.notifier).uploadProfileImage(imageFile);
      },
    ),
  );
}

void _deleteProfileImage(WidgetRef ref) {
  showDialog(
    context: ref.context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red,
            ),
            const SizedBox(width: 8),
            const Text('Eliminar imagen de perfil'),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu imagen de perfil? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profileImageProvider.notifier).deleteProfileImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
}

void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  final newPassController = TextEditingController();
  final confirmController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog<void>(
    context: context,
    builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      bool obscureNew = true;
      bool obscureConfirm = true;

      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withValues(alpha: 0.2),
                        Colors.orange.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Cambiar Contraseña'),
              ],
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa una contraseña';
                      }
                      if (value.length < 6) {
                        return 'Mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirma la contraseña';
                      }
                      if (value != newPassController.text) {
                        return 'Las contraseñas no coinciden';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final pass = newPassController.text.trim();
                  final user = ref.read(authProvider).usuario;
                  if (user == null) return;

                  final ok = await ref.read(userManagementProvider.notifier).actualizarContrasena(
                    id: user.id,
                    nuevaContrasena: pass,
                  );

                  if (context.mounted) {
                    if (ok) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              const Text('Contraseña actualizada correctamente'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } else {
                      final state = ref.read(userManagementProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(state.error ?? 'Error al actualizar contraseña'),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ModernImagePickerBottomSheet extends StatelessWidget {
  final Function(File)? onImageSelected;

  const _ModernImagePickerBottomSheet({this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Colors.grey[850]!, Colors.grey[900]!]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.add_photo_alternate,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Seleccionar imagen de perfil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _ModernImagePickerOption(
                        icon: Icons.camera_alt,
                        label: 'Cámara',
                        color: Colors.blue,
                        onTap: () => _pickImage(context, ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ModernImagePickerOption(
                        icon: Icons.photo_library,
                        label: 'Galería',
                        color: Colors.purple,
                        onTap: () => _pickImage(context, ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Error al seleccionar imagen: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}

class _ModernImagePickerOption extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModernImagePickerOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ModernImagePickerOption> createState() => _ModernImagePickerOptionState();
}

class _ModernImagePickerOptionState extends State<_ModernImagePickerOption> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color.withValues(alpha: 0.15),
                widget.color.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.color.withValues(alpha: 0.3),
                      widget.color.withValues(alpha: 0.2),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
