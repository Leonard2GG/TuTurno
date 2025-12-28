import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/cliente/home_cliente.dart';
import 'screens/cliente/mis_citas_screen.dart'; // Importante
import 'screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar Supabase
  await Supabase.initialize(
    url: 'https://gaoifvxiaehrixsqilxc.supabase.co', 
    anonKey: 'sb_publishable_3GbCGUgtFYz6RpEya570vQ_KUVAE23M',
  );

  // 2. Inicializar Notificaciones
  await NotificationService.inicializar();

  runApp(const TuturnoApp());
}

class TuturnoApp extends StatelessWidget {
  const TuturnoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.nombreApp,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppConfig.colorFondo,
        primaryColor: AppConfig.colorPrimario,
        useMaterial3: true,
        // Configuración global de inputs para que se vean bien en el Auth
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConfig.colorPrimario)),
        ),
      ),
      // Pantalla inicial: decide si va al Login o al Home
      home: const RaizNavegacion(),
      
      // REGISTRO DE RUTAS: Para usar Navigator.pushNamed
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home_cliente': (context) => const HomeCliente(),
        '/home_admin': (context) => const AdminHomeScreen(),
        '/mis_citas': (context) => const MisCitasScreen(), // Agregada
      },
    );
  }
}

class RaizNavegacion extends StatelessWidget {
  const RaizNavegacion({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificamos si hay una sesión activa en el teléfono
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const AuthScreen();
    }

    // Si hay sesión, consultamos el rol para redirigir correctamente
    return FutureBuilder<String>(
      future: SupabaseService().getRolUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario)),
          );
        }
        
        // Redirección por rol
        if (snapshot.data == 'barbero') {
          return const AdminHomeScreen();
        } else {
          return const HomeCliente();
        }
      },
    );
  }
}