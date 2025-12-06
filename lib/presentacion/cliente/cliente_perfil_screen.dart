import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../datos/modelos/usuario.dart';
import '../../config/role_colors.dart';
import '../widgets/role_widgets.dart';
import '../widgets/contact_actions_widget.dart';
import '../../negocio/providers/user_management_provider.dart';
import '../../negocio/providers/credit_provider.dart';
import '../../ui/widgets/response_viewer_dialog.dart';
import '../widgets/profile_image_widget.dart';
import 'cliente_creditos_screen.dart';
import 'location_picker_screen.dart';
import '../../datos/api_services/base_api_service.dart';
import '../../datos/api_services/user_api_service.dart';

class ClientePerfilScreen extends ConsumerStatefulWidget {
  final Usuario cliente;

  const ClientePerfilScreen({super.key, required this.cliente});

  @override
  ConsumerState<ClientePerfilScreen> createState() => _ClientePerfilScreenState();
}

class _ClientePerfilScreenState extends ConsumerState<ClientePerfilScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar créditos del cliente para mostrar estadísticas
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(creditProvider.notifier).loadClientCredits(widget.cliente.id.toInt());
    });
  }

  // Obtener color según categoría del cliente
  Color _getCategoryColor() {
    final category = (widget.cliente.clientCategory ?? 'B').toUpperCase();
    switch (category) {
      case 'A':
        return Colors.amber; // VIP - Dorado
      case 'C':
        return Colors.deepOrange; // En riesgo - Naranja/Rojo
      case 'B':
      default:
        return RoleColors.clientePrimary; // Normal - Azul
    }
  }

  // Obtener icono según categoría
  IconData _getCategoryIcon() {
    final category = (widget.cliente.clientCategory ?? 'B').toUpperCase();
    switch (category) {
      case 'A':
        return Icons.star; // VIP
      case 'C':
        return Icons.warning_amber_rounded; // En riesgo
      case 'B':
      default:
        return Icons.person; // Normal
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final creditState = ref.watch(creditProvider);

    return Scaffold(
      appBar: RoleAppBar(
        title: 'Perfil del Cliente',
        role: 'manager',
        actions: [
          if (widget.cliente.telefono.isNotEmpty)
            ContactActionsWidget.buildContactButton(
              context: context,
              userName: widget.cliente.nombre,
              phoneNumber: widget.cliente.telefono,
              userRole: 'cliente',
              customMessage: ContactActionsWidget.getDefaultMessage(
                'cliente',
                widget.cliente.nombre,
              ),
              color: RoleColors.clientePrimary,
              tooltip: 'Contactar cliente',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header moderno con foto y estadísticas
            _buildModernHeader(theme, isDark, creditState),

            const SizedBox(height: 16),

            // Grid de Acciones Rápidas (2x2)
            _buildActionsGrid(theme, isDark),

            const SizedBox(height: 16),

            // Información de Contacto
            _buildContactInfoCard(theme, isDark),

            const SizedBox(height: 16),

            // Mapa de ubicación
            if (widget.cliente.latitud != null && widget.cliente.longitud != null)
              _buildMapPreview(theme, isDark),

            if (widget.cliente.latitud != null && widget.cliente.longitud != null)
              const SizedBox(height: 16),

            // Fotos de CI registradas
            _ClientIdPhotosSection(cliente: widget.cliente),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme, bool isDark, dynamic creditState) {
    // Calcular estadísticas de créditos
    final credits = creditState.credits ?? [];
    final activeCredits = credits.where((c) => c.status == 'active').length;
    final totalCredits = credits.length;
    final categoryColor = _getCategoryColor();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  categoryColor.withValues(alpha: 0.3),
                  categoryColor.withValues(alpha: 0.1),
                ]
              : [
                  categoryColor.withValues(alpha: 0.15),
                  categoryColor.withValues(alpha: 0.05),
                ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto de perfil - grande y destacada
            ProfileImageWidget(
              profileImage: widget.cliente.profileImage,
              size: 100,
            ),
            const SizedBox(height: 16),

            // Nombre del cliente
            Text(
              widget.cliente.nombre,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Categoría del cliente - chip único
            _buildCategoryChip(theme, isDark),

            const SizedBox(height: 20),

            // Estadísticas rápidas
            _buildQuickStats(theme, isDark, activeCredits, totalCredits),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(ThemeData theme, bool isDark) {
    final categoryColor = _getCategoryColor();
    final categoryIcon = _getCategoryIcon();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: isDark ? 0.35 : 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            categoryIcon,
            color: categoryColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '${widget.cliente.clientCategory ?? 'B'} - ${widget.cliente.clientCategoryName}',
            style: TextStyle(
              color: categoryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme, bool isDark, int activeCredits, int totalCredits) {
    return Wrap(
      spacing: 20,
      runSpacing: 16,
      alignment: WrapAlignment.center,
      children: [
        _buildStatBadge(
          theme,
          isDark,
          icon: Icons.account_balance_wallet,
          label: 'Créditos Activos',
          value: '$activeCredits',
          color: Colors.green,
        ),
        _buildStatBadge(
          theme,
          isDark,
          icon: Icons.history,
          label: 'Total Créditos',
          value: '$totalCredits',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatBadge(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsGrid(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flash_on,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Acciones Rápidas',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Grid responsive de acciones
          LayoutBuilder(
            builder: (context, constraints) {
              // Determinar número de columnas según el ancho disponible
              final crossAxisCount = constraints.maxWidth > 400 ? 2 : 2;
              final childAspectRatio = constraints.maxWidth > 400 ? 1.6 : 1.3;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildActionCard(
                    theme,
                    isDark,
                    icon: Icons.account_balance_wallet,
                    title: 'Créditos',
                    subtitle: 'Ver historial',
                    color: Colors.green,
                    onTap: () => _navigateToCredits(context),
                  ),
                  _buildActionCard(
                    theme,
                    isDark,
                    icon: Icons.map,
                    title: 'Ubicación',
                    subtitle: 'Ver en mapa',
                    color: Colors.blue,
                    onTap: () => _showOnMap(context),
                  ),
                  _buildActionCard(
                    theme,
                    isDark,
                    icon: Icons.phone,
                    title: 'Contactar',
                    subtitle: 'Llamar/WhatsApp',
                    color: Colors.orange,
                    onTap: () => _contactClient(context),
                  ),
                  _buildActionCard(
                    theme,
                    isDark,
                    icon: Icons.category,
                    title: 'Categoría',
                    subtitle: 'Cambiar A/B/C',
                    color: Colors.purple,
                    onTap: () => _changeCategory(context, ref),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.1 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.3 : 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Flexible(
                child: Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfoCard(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contact_mail,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Información de Contacto',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Email
              _buildInfoRow(
                theme,
                isDark,
                icon: Icons.email_outlined,
                label: 'Email',
                value: widget.cliente.email,
                color: Colors.blue,
              ),

              // Teléfono
              if (widget.cliente.telefono.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme,
                  isDark,
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: widget.cliente.telefono,
                  color: Colors.green,
                ),
              ],

              // Dirección
              if (widget.cliente.direccion.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInfoRow(
                  theme,
                  isDark,
                  icon: Icons.location_on_outlined,
                  label: 'Dirección',
                  value: widget.cliente.direccion,
                  color: Colors.orange,
                  maxLines: 2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapPreview(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ubicación del Cliente',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Botón para abrir mapa completo
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.open_in_full,
                        color: Colors.blue,
                        size: 20,
                      ),
                      onPressed: () => _showOnMap(context),
                      tooltip: 'Ver en pantalla completa',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mapa
            InkWell(
              onTap: () => _showOnMap(context),
              child: SizedBox(
                height: 200,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      widget.cliente.latitud!,
                      widget.cliente.longitud!,
                    ),
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: MarkerId('cliente_${widget.cliente.id}'),
                      position: LatLng(
                        widget.cliente.latitud!,
                        widget.cliente.longitud!,
                      ),
                      infoWindow: InfoWindow(
                        title: widget.cliente.nombre,
                        snippet: 'Cliente ${widget.cliente.clientCategory ?? 'B'}',
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  myLocationButtonEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  liteModeEnabled: true, // Modo lite para preview
                ),
              ),
            ),

            // Footer con dirección
            if (widget.cliente.direccion.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? theme.colorScheme.surfaceContainerHighest
                      : Colors.grey.withValues(alpha: 0.1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.place,
                      color: theme.colorScheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.cliente.direccion,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _changeCategory(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final current = (widget.cliente.clientCategory ?? 'B').toUpperCase();
    String? selected;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.category, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text('Cambiar Categoría'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCategoryOption(
              theme,
              value: 'A',
              groupValue: current,
              title: 'Cliente VIP',
              description: 'Excelente historial de pagos',
              icon: Icons.star,
              color: Colors.amber,
              onChanged: (v) {
                selected = v;
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            _buildCategoryOption(
              theme,
              value: 'B',
              groupValue: current,
              title: 'Cliente Normal',
              description: 'Historial de pagos estable',
              icon: Icons.person,
              color: Colors.blue,
              onChanged: (v) {
                selected = v;
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 8),
            _buildCategoryOption(
              theme,
              value: 'C',
              groupValue: current,
              title: 'Cliente en Riesgo',
              description: 'Requiere seguimiento',
              icon: Icons.warning,
              color: Colors.red,
              onChanged: (v) {
                selected = v;
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (selected != null && selected != current) {
      final resp = await ref.read(userManagementProvider.notifier).updateClientCategoryApi(
            clientId: widget.cliente.id,
            category: selected!,
          );
      if (context.mounted) {
        ResponseViewerDialog.show(
          context,
          Map<String, dynamic>.from(resp),
          title: 'Categoría Actualizada',
        );
      }
    }
  }

  Widget _buildCategoryOption(
    ThemeData theme, {
    required String value,
    required String groupValue,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required Function(String?) onChanged,
  }) {
    final isSelected = value == groupValue;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: isDark ? 0.3 : 0.15)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value - $title',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : null,
                    ),
                  ),
                  Text(
                    description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  void _navigateToCredits(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClienteCreditosScreen(cliente: widget.cliente),
      ),
    );
  }

  void _showOnMap(BuildContext context) {
    if (widget.cliente.latitud != null && widget.cliente.longitud != null) {
      final clienteMarker = Marker(
        markerId: MarkerId('cliente_${widget.cliente.id}'),
        position: LatLng(widget.cliente.latitud!, widget.cliente.longitud!),
        infoWindow: InfoWindow(
          title: widget.cliente.nombre,
          snippet: 'Cliente ${widget.cliente.clientCategory ?? 'B'} - ${widget.cliente.telefono}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationPickerScreen(
            allowSelection: false,
            extraMarkers: {clienteMarker},
            customTitle: 'Ubicación de ${widget.cliente.nombre}',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene ubicación GPS registrada'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _contactClient(BuildContext context) {
    if (widget.cliente.telefono.isNotEmpty) {
      ContactActionsWidget.showContactDialog(
        context: context,
        userName: widget.cliente.nombre,
        phoneNumber: widget.cliente.telefono,
        userRole: 'cliente',
        customMessage: ContactActionsWidget.getDefaultMessage(
          'cliente',
          widget.cliente.nombre,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este cliente no tiene teléfono registrado'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

// ============================================
// Sección de Fotos de CI - Mejorada
// ============================================

class _ClientIdPhotosSection extends StatelessWidget {
  final Usuario cliente;
  const _ClientIdPhotosSection({required this.cliente});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: UserApiService().listUserPhotos(cliente.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Cargando fotos de CI...',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'No se pudieron cargar las fotos de CI',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final photos = (snapshot.data ?? []);
        List<Map<String, dynamic>> ciPhotos = photos.where((p) {
          final type = (p['type'] ?? p['category'] ?? p['tag'] ?? '').toString().toLowerCase();
          return type.contains('id') || type.contains('ci') || type.contains('carnet');
        }).map((e) => Map<String, dynamic>.from(e)).toList();

        if (ciPhotos.isEmpty && photos.isNotEmpty) {
          ciPhotos = photos.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }

        if (ciPhotos.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.badge, color: Colors.teal, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Documentos de Identidad',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid responsive de fotos
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = constraints.maxWidth > 400 ? 3 : 2;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: ciPhotos.length,
                        itemBuilder: (context, index) {
                          final item = ciPhotos[index];
                          final url = _resolvePhotoUrl(item);
                          final label = (item['type'] ?? '').toString().toLowerCase();
                          final pretty = label.contains('front') || label.contains('anverso')
                              ? 'Anverso'
                              : (label.contains('back') || label.contains('reverso'))
                                  ? 'Reverso'
                                  : 'Documento';

                          return _IdPhotoTile(url: url, label: pretty, theme: theme);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _resolvePhotoUrl(Map<String, dynamic> item) {
    final dynamic directUrl = item['url'] ?? item['image_url'];
    if (directUrl is String && directUrl.startsWith('http')) {
      return directUrl;
    }
    final String? path = (item['path'] ?? item['file_path'] ?? item['image'])?.toString();
    if (path == null || path.isEmpty) return UserApiService().getProfileImageUrl('');

    final serverUrl = BaseApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');
    if (path.startsWith('http')) return path;
    if (path.startsWith('/')) {
      return '$serverUrl$path';
    }
    final full = path.startsWith('storage/') ? path : 'storage/$path';
    return '$serverUrl/$full';
  }
}

class _IdPhotoTile extends StatelessWidget {
  final String url;
  final String label;
  final ThemeData theme;

  const _IdPhotoTile({
    required this.url,
    required this.label,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _openViewer(context, url, label),
      borderRadius: BorderRadius.circular(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: theme.colorScheme.errorContainer,
                child: Icon(Icons.error_outline, color: theme.colorScheme.error),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.zoom_in, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context, String url, String label) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
