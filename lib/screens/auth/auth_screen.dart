import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import '../cliente/home_cliente.dart';
import '../admin/admin_home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController(); // Nuevo
  final _supabaseService = SupabaseService();
  bool _esRegistro = false;
  bool _cargando = false;

  Future<void> _procesar() async {
    setState(() => _cargando = true);
    try {
      if (_esRegistro) {
        await _supabaseService.registrarUsuario(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombre: _nombreController.text.trim(),
          telefono: _telefonoController.text.trim(),
        );
        setState(() => _esRegistro = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Registrado! Ahora inicia sesión")));
      } else {
        await _supabaseService.iniciarSesion(_emailController.text.trim(), _passwordController.text.trim());
        final rol = await _supabaseService.getRolUsuario();
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => rol == 'barbero' ? const AdminHomeScreen() : const HomeCliente()
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Icon(Icons.content_cut, size: 80, color: AppConfig.colorPrimario),
                const SizedBox(height: 30),
                if (_esRegistro) ...[
                  TextField(controller: _nombreController, decoration: const InputDecoration(labelText: "Nombre")),
                  const SizedBox(height: 10),
                  TextField(controller: _telefonoController, decoration: const InputDecoration(labelText: "WhatsApp (Ej: +549...)"), keyboardType: TextInputType.phone),
                  const SizedBox(height: 10),
                ],
                TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
                const SizedBox(height: 10),
                TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Contraseña"), obscureText: true),
                const SizedBox(height: 25),
                _cargando ? const CircularProgressIndicator() : ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario, minimumSize: const Size(double.infinity, 50)),
                  onPressed: _procesar,
                  child: Text(_esRegistro ? "CREAR CUENTA" : "ENTRAR", style: const TextStyle(color: Colors.black)),
                ),
                TextButton(onPressed: () => setState(() => _esRegistro = !_esRegistro), child: Text(_esRegistro ? "¿Ya tienes cuenta?" : "Crear cuenta nueva"))
              ],
            ),
          ),
        ),
      ),
    );
  }
}