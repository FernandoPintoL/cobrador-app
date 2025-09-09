import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../negocio/servicios/allowed_apps_helper.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../negocio/providers/profile_image_provider.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../widgets/profile_image_widget.dart';

class ProfileSettingsScreen extends ConsumerWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final usuario = authState.usuario;
    final profileImageState = ref.watch(profileImageProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Escuchar cambios en el estado de la imagen de perfil
    ref.listen<ProfileImageState>(profileImageProvider, (previous, next) async {
      // Manejar errores solo cuando cambian
      if (previous?.error != next.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
        // No llamar a clearError aquí para evitar bucles de notificación
      }

      // Manejar éxito solo cuando cambia y luego limpiar el mensaje de éxito
      if (previous?.successMessage != next.successMessage && next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        // Refrescar datos del usuario para ver la nueva imagen
        await ref.read(authProvider.notifier).refreshUser();
        ref.read(profileImageProvider.notifier).clearSuccess();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Aquí se guardarían los cambios del perfil
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cambios guardados'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de imagen de perfil
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagen de Perfil',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: ProfileImageWithUpload(
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
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: profileImageState.isUploading
                                  ? null
                                  : () => _showImagePickerDialog(context, ref),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Cambiar Foto'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: profileImageState.isUploading
                                  ? null
                                  : () => _deleteProfileImage(ref),
                              icon: const Icon(Icons.delete),
                              label: const Text('Eliminar'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección de información personal
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Información Personal',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoField(
                        context,
                        ref,
                        usuario,
                        'Nombre',
                        usuario?.nombre ?? '',
                        Icons.person,
                        fieldKey: 'name',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoField(
                        context,
                        ref,
                        usuario,
                        'Email',
                        usuario?.email ?? '',
                        Icons.email,
                        fieldKey: 'email',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoField(
                        context,
                        ref,
                        usuario,
                        'Teléfono',
                        usuario?.telefono ?? '',
                        Icons.phone,
                        fieldKey: 'phone',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoField(
                        context,
                        ref,
                        usuario,
                        'Dirección',
                        usuario?.direccion ?? '',
                        Icons.location_on,
                        fieldKey: 'address',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección de roles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Roles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            usuario?.roles
                                .map((role) => _buildRoleChip(context, role))
                                .toList() ??
                            [],
                      ),
                    ],
                  ),
                ),
              ),
              /*const SizedBox(height: 24),

              // Sección de seguridad
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seguridad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Cambiar Contraseña'),
                        subtitle: const Text('Actualizar tu contraseña'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          _showChangePasswordDialog(context, ref);
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.security),
                        title: const Text('Autenticación de Dos Factores'),
                        subtitle: const Text('Configurar 2FA'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          // Navegar a configuración de 2FA
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),*/

              // Sección de notificaciones
              /*Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notificaciones',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Notificaciones Push'),
                        subtitle: const Text(
                          'Recibir notificaciones en tiempo real',
                        ),
                        value: true, // Esto debería venir del estado
                        onChanged: (value) {
                          // Actualizar configuración de notificaciones
                        },
                      ),
                      SwitchListTile(
                        title: const Text('Notificaciones por Email'),
                        subtitle: const Text(
                          'Recibir notificaciones por correo',
                        ),
                        value: false, // Esto debería venir del estado
                        onChanged: (value) {
                          // Actualizar configuración de notificaciones
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),*/
            ],
          ),
        ),
      ),
    );
  }
}

  Widget _buildInfoField(
    BuildContext context,
    WidgetRef ref,
    dynamic usuario,
    String label,
    String value,
    IconData icon,
    {required String fieldKey}
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          icon,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
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
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () async {
            final controller = TextEditingController(text: value);
            final newValue = await showDialog<String>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text('Editar $label'),
                  content: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: label,
                      border: const OutlineInputBorder(),
                    ),
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

            if (ok) {
              // Refrescar usuario
              await ref.read(authProvider.notifier).refreshUser();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label actualizado'), backgroundColor: Colors.green),
              );
            } else {
              final umState = ref.read(userManagementProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(umState.error ?? 'Error al actualizar $label'), backgroundColor: Colors.red),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildRoleChip(BuildContext context, String role) {
    // final isDark = Theme.of(context).brightness == Brightness.dark;
    Color chipColor;

    switch (role.toLowerCase()) {
      case 'admin':
        chipColor = Colors.red;
        break;
      case 'manager':
        chipColor = Colors.orange;
        break;
      case 'cobrador':
        chipColor = Colors.green;
        break;
      case 'cliente':
        chipColor = Colors.blue;
        break;
      default:
        chipColor = Colors.grey;
    }

    return Chip(
      label: Text(
        role,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: chipColor,
    );
  }

  void _showImagePickerDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _ImagePickerBottomSheet(
        onImageSelected: (File imageFile) {
          ref.read(profileImageProvider.notifier).uploadProfileImage(imageFile);
        },
      ),
    );
  }

  void _deleteProfileImage(WidgetRef ref) {
    showDialog(
      context: ref.context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar imagen de perfil'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar tu imagen de perfil?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(profileImageProvider.notifier).deleteProfileImage();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  final newPassController = TextEditingController();
  final confirmController = TextEditingController();

  showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Cambiar Contraseña'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Nueva contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirmar contraseña',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final pass = newPassController.text.trim();
              final confirm = confirmController.text.trim();
              if (pass.isEmpty || confirm.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa ambos campos'), backgroundColor: Colors.red),
                );
                return;
              }
              if (pass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres'), backgroundColor: Colors.red),
                );
                return;
              }
              if (pass != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Las contraseñas no coinciden'), backgroundColor: Colors.red),
                );
                return;
              }

              final user = ref.read(authProvider).usuario;
              if (user == null) return;

              final ok = await ref.read(userManagementProvider.notifier).actualizarContrasena(
                id: user.id,
                nuevaContrasena: pass,
              );

              if (ok) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Contraseña actualizada'), backgroundColor: Colors.green),
                );
              } else {
                final state = ref.read(userManagementProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.error ?? 'Error al actualizar contraseña'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      );
    },
  );
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
