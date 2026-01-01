import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../negocio/providers/auth_provider.dart';
import '../../datos/api_services/storage_service.dart';
import '../superadmin/admin_dashboard_screen.dart';
import '../manager/manager_dashboard_screen.dart';
import '../cobrador/cobrador_dashboard_screen.dart';
import '../creditos/credit_type_screen.dart';

// Importación explícita del AuthState si no está disponible
// ignore_for_file: unused_import

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  final bool _rememberMe = false;
  String? _lastShownError;
  String? _savedIdentifier;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Devuelve el widget destino (dashboard) según los roles del usuario.
  // Asume que el primer rol relevante determina la pantalla.
  Widget _getDestinationForRoles(List<String> roles) {
    if (roles.contains('admin')) {
      return const AdminDashboardScreen();
    }
    if (roles.contains('manager')) {
      return const ManagerDashboardScreen();
    }
    if (roles.contains('cobrador') || roles.contains('collector')) {
      // 'cobrador' o 'collector' -> pantalla de cobrador
      return const CobradorDashboardScreen();
    }
    // Por defecto, usar la pantalla de tipos de crédito para roles no reconocidos
    return const CreditTypeScreen();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // Inicializar animaciones
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Iniciar animaciones
    _fadeController.forward();
    _slideController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final storage = StorageService();
      final saved = await storage.getSavedIdentifier();
      if (mounted) {
        setState(() {
          _savedIdentifier = saved;
          if (saved != null) {
            _emailOrPhoneController.text = saved;
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Capturar referencias antes del async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Escuchar cambios en AuthState para actualizar errores y el estado de savedIdentifier
    ref.listen<AuthState>(authProvider, (previous, next) async {
      // Si el usuario se autenticó, navegar al dashboard correspondiente según su rol
      if (mounted &&
          next.isAuthenticated &&
          next.usuario != null &&
          (previous == null || !previous.isAuthenticated)) {
        final roles = next.usuario!.roles;
        final destination = _getDestinationForRoles(roles);
        // Reemplazar la pila para evitar volver al login
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => destination),
          (route) => false,
        );
        return;
      }
      // Si el usuario ya no está autenticado y el estado está inicializado,
      // recargamos el identificador guardado para decidir si mostramos el campo email
      if (mounted && next.usuario == null && next.isInitialized) {
        final storage = StorageService();
        final saved = await storage.getSavedIdentifier();
        if (_savedIdentifier != saved) {
          setState(() {
            _savedIdentifier = saved;
            if (saved == null) {
              _emailOrPhoneController.clear();
            } else {
              _emailOrPhoneController.text = saved;
            }
          });
        }
      }

      if (next.error != null && next.error != _lastShownError && mounted) {
        _lastShownError = next.error;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              next.error!,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Cerrar',
              textColor: Colors.white,
              onPressed: () {
                scaffoldMessenger.hideCurrentSnackBar();
                if (mounted) {
                  ref.read(authProvider.notifier).clearError();
                  _lastShownError = null;
                }
              },
            ),
          ),
        );

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted && ref.read(authProvider).error == next.error) {
            ref.read(authProvider.notifier).clearError();
            _lastShownError = null;
          }
        });
      } else if (next.error == null) {
        _lastShownError = null;
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    colorScheme.surface,
                    colorScheme.surface.withValues(alpha: 0.95),
                  ]
                : [
                    colorScheme.primary.withValues(alpha: 0.05),
                    colorScheme.surface,
                  ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Card(
                      elevation: isDark ? 2 : 1,
                      shadowColor: colorScheme.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo animado
                            Hero(
                              tag: 'app_logo',
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.secondary,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 40,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Título
                            Text(
                              'CeF Pro',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bienvenido de nuevo',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),

                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  if (_savedIdentifier == null) ...[
                                    _buildTextField(
                                      controller: _emailOrPhoneController,
                                      label: 'Email o teléfono',
                                      icon: Icons.person_outline_rounded,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (_savedIdentifier != null) return null;
                                        if (value == null || value.isEmpty) {
                                          return 'Por favor ingresa tu email o teléfono';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                  ] else ...[
                                    // Usuario guardado
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: colorScheme.secondary,
                                            child: Icon(
                                              Icons.person,
                                              color: colorScheme.onSecondary,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Continuar como',
                                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                    color: colorScheme.onSecondaryContainer.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                                Text(
                                                  _savedIdentifier!,
                                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: colorScheme.onSecondaryContainer,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.edit_outlined),
                                            onPressed: () async {
                                              final storage = StorageService();
                                              await storage.clearSavedIdentifier();
                                              if (mounted) {
                                                setState(() {
                                                  _savedIdentifier = null;
                                                  _emailOrPhoneController.clear();
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],

                                  _buildTextField(
                                    controller: _passwordController,
                                    label: 'Contraseña',
                                    icon: Icons.lock_outline_rounded,
                                    obscureText: _obscurePassword,
                                    autofocus: _savedIdentifier != null,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor ingresa tu contraseña';
                                      }
                                      if (value.length < 6) {
                                        return 'La contraseña debe tener al menos 6 caracteres';
                                      }
                                      return null;
                                    },
                                    onFieldSubmitted: (_) => _handleLogin(),
                                  ),
                                  const SizedBox(height: 32),

                                  // Botón de login
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final authState = ref.watch(authProvider);
                                        return FilledButton(
                                          onPressed: authState.isLoading ? null : _handleLogin,
                                          style: FilledButton.styleFrom(
                                            backgroundColor: colorScheme.primary,
                                            foregroundColor: colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            elevation: 2,
                                          ),
                                          child: authState.isLoading
                                              ? SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      colorScheme.onPrimary,
                                                    ),
                                                  ),
                                                )
                                              : Text(
                                                  _savedIdentifier != null ? 'Continuar' : 'Iniciar sesión',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    letterSpacing: 0.5,
                                                  ),
                                                ),
                                        );
                                      },
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool autofocus = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofocus: autofocus,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  void _handleLogin() async {
    if (_savedIdentifier == null &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu contraseña'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailOrPhone =
        _savedIdentifier ?? _emailOrPhoneController.text.trim();
    final password = _passwordController.text;

    await ref
        .read(authProvider.notifier)
        .login(emailOrPhone, password, rememberMe: _rememberMe);
  }
}
