import 'package:cobrador_app/presentacion/cliente/cliente_form_screen.dart';
import 'package:cobrador_app/presentacion/pantallas/notifications_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_bootstrap.dart';
import 'negocio/providers/auth_provider.dart';
import 'negocio/servicios/allowed_apps_helper.dart';
import 'negocio/servicios/auto_logout_service.dart';
import 'presentacion/pantallas/splash_screen.dart';
import 'presentacion/pantallas/login_screen.dart';
import 'presentacion/superadmin/admin_dashboard_screen.dart';
import 'presentacion/manager/manager_dashboard_screen.dart';
import 'presentacion/cobrador/cobrador_dashboard_screen.dart';

Future<void> main() async {
  // Configurar logging para debug
  if (kDebugMode) {
    debugPrint('🚀 INICIANDO APLICACIÓN COBRADOR');
    debugPrint('🔧 Modo Debug activado');
  }

  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('🔧 Flutter inicializado, iniciando AppBootstrap...');

  // Centralizar inicialización de servicios
  await AppBootstrap.init();

  debugPrint('✅ AppBootstrap completado, iniciando app...');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _initialized = false;
  bool _navigatingToLogin = false;
  AutoLogoutService? _autoLogoutService;
  AutoLogoutNavigatorObserver? _navigatorObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inicializar servicios inmediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();

      // Inicializar servicio de auto-logout inmediatamente
      _autoLogoutService = ref.read(autoLogoutServiceProvider);
      _navigatorObserver = AutoLogoutNavigatorObserver(
        (routeName) => _autoLogoutService?.onScreenChanged(routeName),
      );

      debugPrint('✅ AutoLogoutService inicializado correctamente');
      // Inicializar el helper de aplicaciones permitidas
      if (_autoLogoutService != null) {
        AllowedAppsHelper.init(_autoLogoutService!);
        debugPrint('✅ AllowedAppsHelper inicializado con AutoLogoutService');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLogoutService?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Verificar si estamos en una plataforma móvil
    if (kIsWeb) {
      return; // No hacer logout automático en Web
    }
    final isMobile =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (!isMobile) {
      return; // No hacer logout automático en escritorio
    }

    // Verificar si hay usuario autenticado
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      return; // No hay sesión activa
    }

    debugPrint('🔄 Cambio de ciclo de vida de la app: $state');

    switch (state) {
      case AppLifecycleState.paused:
        debugPrint(
          '⏸️ App pausada - verificando si requiere logout por seguridad',
        );
        // La app se pausó, delegar al AutoLogoutService para manejar el logout
        _autoLogoutService?.onScreenChanged(null);
        break;

      case AppLifecycleState.resumed:
        debugPrint('▶️ App resumida - cancelando logout programado');
        // App resumida, cancelar cualquier logout programado
        break;

      case AppLifecycleState.inactive:
        debugPrint('🔕 App inactiva - no se requiere acción');
        // App temporalmente inactiva (llamada, notificación, etc.)
        break;

      case AppLifecycleState.detached:
        debugPrint('🚪 App desconectada - ejecutando logout por seguridad');
        // App siendo cerrada/desconectada, hacer logout completo
        ref.read(authProvider.notifier).partialLogout();
        break;

      case AppLifecycleState.hidden:
        debugPrint('👁️ App oculta - verificando logout por seguridad');
        // App oculta (solo en algunas plataformas)
        _autoLogoutService?.onScreenChanged(null);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Inicializar WebSocket solo una vez y escuchar cambios de autenticación
    if (!_initialized) {
      _initialized = true;
    }

    // Escuchar cambios en el estado de autenticación.
    // Redirigimos siempre al login cuando el estado ya está inicializado y
    // el usuario no está autenticado (esto cubre auto-logout y condiciones
    // de carrera donde el build puede volver a mostrar un dashboard).
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Caso: se autenticó ahora
      if (next.isAuthenticated &&
          next.usuario != null &&
          (previous == null || !previous.isAuthenticated)) {
        debugPrint(
          '🔌 Usuario autenticado, WebSocket se conectará automáticamente...',
        );
        return;
      }

      // Si el estado ya está inicializado y NO está autenticado, forzar login
      if (!next.isAuthenticated && next.isInitialized) {
        debugPrint(
          '🔌 Estado NO autenticado detectado (isInitialized=${next.isInitialized}) - redirigiendo a Login',
        );

        final ctx = MyApp.navigatorKey.currentContext;
        final currentRoute = ctx != null
            ? ModalRoute.of(ctx)?.settings.name
            : _navigatorObserver?.lastRouteName;

        if (currentRoute != '/login' && !_navigatingToLogin) {
          _navigatingToLogin = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final nav = MyApp.navigatorKey.currentState;
            final ctx = MyApp.navigatorKey.currentContext;
            if (nav != null) {
              nav.pushNamedAndRemoveUntil('/login', (route) => false);
              if (ctx != null) {
                ScaffoldMessenger.of(ctx).clearSnackBars();
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tu sesión ha expirado. Vuelve a iniciar sesión.',
                    ),
                  ),
                );
              }
            }
            _navigatingToLogin = false;
          });
        }
      }
    });

    return MaterialApp(
      title: 'Facebook eLite',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system, // Respeta la configuración del sistema
      home: _buildInitialScreen(authState),
      navigatorKey: MyApp.navigatorKey,
      navigatorObservers: _navigatorObserver != null
          ? [_navigatorObserver!]
          : [],
      routes: {
        '/login': (context) => const LoginScreen(),
        '/crear-cliente': (context) => const ClienteFormScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    // Soft, accessible palette for light mode
    const primarySoft = Color(0xFF5E81F4); // soft indigo
    const secondarySoft = Color(0xFF56C8C8); // soft teal
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySoft,
      primary: primarySoft,
      secondary: secondarySoft,
      brightness: Brightness.light,
    );
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: colorScheme,
      primaryColor: primarySoft,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    // Soft, muted palette for dark mode
    const primarySoftDark = Color(0xFF90A4F4); // softer indigo tint for dark
    const secondarySoftDark = Color(0xFF6FD6CF); // softer teal for dark
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primarySoftDark,
      primary: primarySoftDark,
      secondary: secondarySoftDark,
      brightness: Brightness.dark,
    );
    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      primaryColor: primarySoftDark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
        contentTextStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      useMaterial3: true,
    );
  }

  Widget _buildInitialScreen(AuthState authState) {
    // Mostrar pantalla de splash mientras se inicializa
    if (!authState.isInitialized) {
      return const SplashScreen();
    }

    // Si está autenticado, mostrar pantalla principal según el rol
    if (authState.isAuthenticated) {
      return _buildDashboardByRole(authState);
    }

    // Si no está autenticado, mostrar pantalla de login
    return const LoginScreen();
  }

  Widget _buildDashboardByRole(AuthState authState) {
    // Debug: Imprimir información del usuario y sus roles
    print('🔍 DEBUG: Información del usuario:');
    print('  - Usuario: ${authState.usuario?.nombre}');
    print('  - Email: ${authState.usuario?.email}');
    print('  - Roles: ${authState.usuario?.roles}');
    print('  - isAdmin: ${authState.isAdmin}');
    print('  - isManager: ${authState.isManager}');
    print('  - isCobrador: ${authState.isCobrador}');

    // Verificar que el usuario existe
    if (authState.usuario == null) {
      print('❌ ERROR: Usuario es null');
      return const LoginScreen();
    }

    // Verificar que el usuario tiene roles
    if (authState.usuario!.roles.isEmpty) {
      print('❌ ERROR: Usuario no tiene roles asignados');
      return const LoginScreen();
    }

    // Determinar qué dashboard mostrar según el rol del usuario
    // Prioridad: Admin > Manager > Cobrador
    if (authState.isAdmin) {
      print('✅ Usuario es ADMIN - Redirigiendo a AdminDashboardScreen');
      print('  - Roles del usuario: ${authState.usuario!.roles}');
      return const AdminDashboardScreen();
    } else if (authState.isManager) {
      print(
        '✅ Usuario es MANAGER - Redirigiendo a CreditTypeScreen (reemplaza dashboard)',
      );
      print('  - Roles del usuario: ${authState.usuario!.roles}');
      return const ManagerDashboardScreen();
    } else if (authState.isCobrador) {
      print(
        '✅ Usuario es COBRADOR - Redirigiendo a CreditTypeScreen (reemplaza dashboard)',
      );
      print('  - Roles del usuario: ${authState.usuario!.roles}');
      return const CobradorDashboardScreen();
    } else {
      // Verificar roles individuales como fallback
      print(
        '⚠️ No se detectó rol específico, verificando roles individuales...',
      );
      print('⚠️ Roles disponibles: ${authState.usuario!.roles}');

      if (authState.usuario!.tieneRol("admin")) {
        print('✅ Detectado rol admin por verificación individual');
        return const AdminDashboardScreen();
      } else if (authState.usuario!.tieneRol("manager")) {
        print('✅ Detectado rol manager por verificación individual');
        return const ManagerDashboardScreen();
      } else if (authState.usuario!.tieneRol("cobrador")) {
        print('✅ Detectado rol cobrador por verificación individual');
        return const CobradorDashboardScreen();
      } else {
        print('❌ ERROR: No se pudo determinar el rol del usuario');
        print('  - Roles disponibles: ${authState.usuario!.roles}');
        print('  - Verificando roles individuales:');
        print(
          '    - tieneRol("admin"): ${authState.usuario!.tieneRol("admin")}',
        );
        print(
          '    - tieneRol("manager"): ${authState.usuario!.tieneRol("manager")}',
        );
        print(
          '    - tieneRol("cobrador"): ${authState.usuario!.tieneRol("cobrador")}',
        );

        // Por seguridad, redirigir al login si no se puede determinar el rol
        return const LoginScreen();
      }
    }
  }
}
