import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config.dart';

void main() async {
  // Asegura la inicialización de los servicios de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // CONEXIÓN OFICIAL A TU PROYECTO SUPABASE
  await Supabase.initialize(
    url: 'https://gaoifvxiaehrixsqilxc.supabase.co', 
    anonKey: 'sb_publishable_3GbCGUgtFYz6RpEya570vQ_KUVAE23M',
  );

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
        colorScheme: const ColorScheme.dark().copyWith(
          primary: AppConfig.colorPrimario,
          secondary: AppConfig.colorAcento,
        ),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppConfig.colorFondo, Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado o estático de barbería
            const Icon(Icons.content_cut, size: 100, color: AppConfig.colorPrimario),
            const SizedBox(height: 30),
            const Text(
              AppConfig.nombreApp,
              style: TextStyle(
                fontSize: 45, 
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
                color: AppConfig.colorAcento
              ),
            ),
            const Text(
              "TU AGENDA DIGITAL",
              style: TextStyle(
                fontSize: 12, 
                letterSpacing: 2,
                color: AppConfig.colorPrimario
              ),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppConfig.colorPrimario),
            ),
            const SizedBox(height: 20),
            const Text(
              "Sincronizando con el servidor...",
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}