import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'negocio/providers/auth_provider.dart';
import 'presentacion/pantallas/splash_screen.dart';
import 'presentacion/pantallas/login_screen.dart';
import 'presentacion/pantallas/home_screen.dart';
import 'presentacion/pantallas/admin_dashboard_screen.dart';
import 'presentacion/pantallas/manager_dashboard_screen.dart';
import 'presentacion/pantallas/cobrador_dashboard_screen.dart';

Future<void> main() async {
  // Cargar variables de entorno con manejo de errores
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Error cargando .env: $e");
    // Continuar sin variables de entorno
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Inicializar la aplicación verificando sesión guardada
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Cobrador App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF667eea),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          primary: const Color(0xFF667eea),
          secondary: const Color(0xFF764ba2),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
      ),
      home: _buildInitialScreen(authState),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
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
    // Determinar qué dashboard mostrar según el rol del usuario
    if (authState.isAdmin) {
      return const AdminDashboardScreen();
    } else if (authState.isManager) {
      return const ManagerDashboardScreen();
    } else if (authState.isCobrador) {
      return const CobradorDashboardScreen();
    } else {
      // Por defecto, mostrar el dashboard del cobrador
      return const CobradorDashboardScreen();
    }
  }
}
