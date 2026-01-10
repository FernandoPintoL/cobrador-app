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

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String? _lastShownError;
  String? _savedIdentifier;

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
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
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
    // ✅ FIX: Capturar referencias antes del async gap para evitar errores de widget desmontado
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    // ignore: unused_local_variable
    final borderColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;

    return Scaffold(
      body: Container(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 0,
                margin: const EdgeInsets.symmetric(horizontal: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24.0,
                    horizontal: 16.0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /*Text(
                        'facebook',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: const Color(0xFF1877F2),
                          fontSize: 44,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                      ),*/
                      TextButton(
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
                        child: const Text(
                          'facebook',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            color: const Color(0xFF1877F2),
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Text(
                        'Iniciar sesión Facebook',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? onSurface.withValues(alpha: 0.9)
                              : const Color(0xFF1C1E21),
                        ),
                      ),
                      const SizedBox(height: 16),

                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            if (_savedIdentifier == null) ...[
                              TextFormField(
                                controller: _emailOrPhoneController,
                                decoration: const InputDecoration(
                                  hintText: 'Email or phone number',
                                  border: OutlineInputBorder(),
                                ),
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
                            ],

                            /*if (_savedIdentifier != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.grey.shade50,
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.person, color: isDark ? Colors.grey.shade400 : Colors.grey),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Continuar como:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            _savedIdentifier ?? 'Usuario',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
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
                                      child: const Text('Cambiar'),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],*/
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              obscureText: _obscurePassword,
                              autofocus: _savedIdentifier != null,
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

                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final authState = ref.watch(authProvider);
                                  return ElevatedButton(
                                    onPressed: authState.isLoading
                                        ? null
                                        : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1877F2),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: authState.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            _savedIdentifier != null
                                                ? 'Continuar'
                                                : 'Iniciar sesión',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
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
    );
  }

  void _handleLogin() async {
    // ✅ FIX: Limpiar error anterior antes de intentar nuevo login
    if (mounted) {
      ref.read(authProvider.notifier).clearError();
      _lastShownError = null;
    }

    if (_savedIdentifier == null &&
        !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa tu contraseña'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
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
