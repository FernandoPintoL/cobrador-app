import 'package:cobrador_app/presentacion/cliente/cliente_form_screen.dart';
import 'package:cobrador_app/presentacion/pantallas/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'negocio/providers/auth_provider.dart';
import 'datos/servicios/websocket_service.dart';
import 'datos/servicios/notification_service.dart';
import 'presentacion/pantallas/splash_screen.dart';
import 'presentacion/pantallas/login_screen.dart';
import 'presentacion/superadmin/admin_dashboard_screen.dart';
import 'presentacion/manager/manager_dashboard_screen.dart';
import 'presentacion/cobrador/cobrador_dashboard_screen.dart';

Future<void> main() async {
  // Asegurarse de que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno con manejo de errores
  try {
    await dotenv.load(fileName: ".env");
    print("✅ Variables de entorno cargadas correctamente");
  } catch (e) {
    print("Error cargando .env: $e");
    // Continuar sin variables de entorno
  }

  // Configurar WebSocket con la URL del .env
  try {
    final websocketUrl = dotenv.env['WEBSOCKET_URL'];
    if (websocketUrl != null && websocketUrl.isNotEmpty) {
      final wsService = WebSocketService();
      // Determinar si es producción basándose en la URL
      final isProduction = websocketUrl.contains('railway.app') ||
                          websocketUrl.startsWith('wss://');

      wsService.configureServer(
        url: websocketUrl,
        isProduction: isProduction,
        enableSSL: websocketUrl.startsWith('wss://'),
      );

      print("🔧 WebSocket configurado con URL: $websocketUrl");
      print("🏭 Modo: ${isProduction ? 'Producción' : 'Desarrollo'}");
    } else {
      print("⚠️ WEBSOCKET_URL no encontrada en .env");
    }
  } catch (e) {
    print("❌ Error configurando WebSocket: $e");
  }

  // Inicializar el servicio de notificaciones
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    print("🔔 Servicio de notificaciones inicializado");
  } catch (e) {
    print("⚠️ Error inicializando notificaciones: $e");
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Solo inicializar la autenticación aquí
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Inicializar WebSocket solo una vez y escuchar cambios de autenticación
    if (!_initialized) {
      _initialized = true;
    }

    // Escuchar cambios en el estado de autenticación
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated &&
          next.usuario != null &&
          (previous == null || !previous.isAuthenticated)) {
        // Usuario se autenticó, WebSocket se conecta automáticamente
        print(
          '🔌 Usuario autenticado, WebSocket se conectará automáticamente...',
        );
      } else if (previous?.isAuthenticated == true && !next.isAuthenticated) {
        // Usuario cerró sesión, WebSocket se desconecta automáticamente
        print(
          '🔌 Usuario cerró sesión, WebSocket se desconectará automáticamente...',
        );
        print('🚪 Usuario ha cerrado sesión - Redirigiendo a LoginScreen');
      }
    });

    return MaterialApp(
      title: 'Cobrador App',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: ThemeMode.system, // Respeta la configuración del sistema
      home: _buildInitialScreen(authState),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/crear-cliente': (context) => const ClienteFormScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF667eea),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        primary: const Color(0xFF667eea),
        secondary: const Color(0xFF764ba2),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      useMaterial3: true,
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: const Color(0xFF667eea),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF667eea),
        primary: const Color(0xFF667eea),
        secondary: const Color(0xFF764ba2),
        brightness: Brightness.dark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1a1a1a),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF667eea), width: 2),
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 4,
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
      print('✅ Usuario es MANAGER - Redirigiendo a ManagerDashboardScreen');
      print('  - Roles del usuario: ${authState.usuario!.roles}');
      return const ManagerDashboardScreen();
    } else if (authState.isCobrador) {
      print('✅ Usuario es COBRADOR - Redirigiendo a CobradorDashboardScreen');
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
