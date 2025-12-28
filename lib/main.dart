import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';
import 'services/supabase_service.dart';
import 'services/notification_service.dart'; // Importar
import 'screens/auth/auth_screen.dart';
import 'screens/cliente/home_cliente.dart';
import 'screens/admin/admin_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://gaoifvxiaehrixsqilxc.supabase.co', 
    anonKey: 'sb_publishable_3GbCGUgtFYz6RpEya570vQ_KUVAE23M',
  );

  // Inicializar notificaciones locales
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
      ),
      home: const RaizNavegacion(),
      routes: {
        '/auth': (context) => const AuthScreen(),
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data == 'barbero' ? const AdminHomeScreen() : const HomeCliente();
      },
    );
  }
}