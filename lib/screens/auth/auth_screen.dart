import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import '../cliente/home_cliente.dart';
import '../admin/admin_home_screen.dart'; // Importante para la redirección

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _supabaseService = SupabaseService();
  
  bool _esRegistro = false;
  bool _cargando = false;

  Future<void> _procesar() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _mostrarMensaje("Por favor, llena todos los campos", esError: true);
      return;
    }

    setState(() => _cargando = true);

    try {
      if (_esRegistro) {
        await _supabaseService.registrarUsuario(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombre: _nombreController.text.trim(),
        );
        _mostrarMensaje("¡Registro exitoso! Ahora puedes entrar.");
        setState(() => _esRegistro = false);
      } else {
        // 1. Iniciar Sesión
        await _supabaseService.iniciarSesion(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // 2. Consultar el Rol (Lógica Inteligente)
        final rol = await _supabaseService.getRolUsuario();

        if (mounted) {
          if (rol == 'barbero') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeCliente()),
            );
          }
        }
      }
    } catch (e) {
      _mostrarMensaje(e.toString().replaceAll('Exception:', ''), esError: true);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _mostrarMensaje(String mensaje, {bool esError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: esError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.content_cut, size: 80, color: AppConfig.colorPrimario),
                const SizedBox(height: 20),
                Text(_esRegistro ? "Crear Cuenta" : "Bienvenido", 
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),
                if (_esRegistro) ...[
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: "Nombre"),
                  ),
                  const SizedBox(height: 15),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Correo"),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña"),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario),
                    onPressed: _cargando ? null : _procesar,
                    child: _cargando 
                      ? const CircularProgressIndicator(color: Colors.black) 
                      : Text(_esRegistro ? "REGISTRARSE" : "ENTRAR", style: const TextStyle(color: Colors.black)),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _esRegistro = !_esRegistro),
                  child: Text(_esRegistro ? "¿Ya tienes cuenta? Entra" : "¿Nuevo? Regístrate"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}