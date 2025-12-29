import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/cliente/home_cliente.dart';
import 'screens/cliente/mis_citas_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'widgets/conexion_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseKey,
  );

  await NotificationService.inicializar();

  runApp(ConexionWrapper(child: const TuturnoApp()));
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
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppConfig.colorPrimario)),
        ),
      ),
      home: const RaizNavegacion(),
      routes: {
        '/auth': (context) => const AuthScreen(),
        '/home_cliente': (context) => const HomeCliente(),
        '/home_admin': (context) => const AdminHomeScreen(),
        '/mis_citas': (context) => const MisCitasScreen(),
      },
    );
  }
}

class RaizNavegacion extends StatelessWidget {
  const RaizNavegacion({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) return const AuthScreen();

    return FutureBuilder<String>(
      future: SupabaseService().getRolUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == 'barbero') {
          return const AdminHomeScreen();
        } else {
          return const HomeCliente();
        }
      },
    );
  }
}