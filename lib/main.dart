import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'services/supabase_service.dart';

// Importacion de pantallas
import 'screens/auth/auth_screen.dart';
import 'screens/cliente/home_cliente.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/config_horario_screen.dart';
import 'screens/admin/gestion_servicios_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializacion de Supabase
  await Supabase.initialize(
    url: 'https://ofmblpylpwyttgltvypf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9mbWJscHlscHd5dHRnbHR2eXBmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzg0MjMzNjAsImV4cCI6MjA1NDAwMTM2MH0.2YhK9mX-o1uK_096mE9pG1_8v6x7l-o-l-o-l-o',

  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.nombreApp,
      debugShowCheckedModeBanner: false,
      
      // Configuracion de Tema Oscuro para la Barberia
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppConfig.colorPrimario,
        scaffoldBackgroundColor: AppConfig.colorFondo,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppConfig.colorPrimario, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConfig.colorPrimario,
            foregroundColor: Colors.black,
            textStyle: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),

      // Logica de inicio (Redireccion automatica)
      home: const AuthWrapper(),

      // Registro de rutas para navegacion por nombre
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home_cliente': (context) => const HomeCliente(),
        '/home_admin': (context) => const AdminHomeScreen(),
        '/config_horario': (context) => const ConfigHorarioScreen(),
        '/gestion_servicios': (context) => const GestionServiciosScreen(),
      },
    );
  }
}

// Widget para decidir que pantalla mostrar al abrir la app
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _service = SupabaseService();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      // Si no hay sesion, va al Login
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      // Si hay sesion, verificamos el rol
      final rol = await _service.getRolUsuario();
      if (mounted) {
        if (rol == 'barbero') {
          Navigator.pushReplacementNamed(context, '/home_admin');
        } else {
          Navigator.pushReplacementNamed(context, '/home_cliente');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppConfig.colorPrimario),
      ),
    );
  }
}