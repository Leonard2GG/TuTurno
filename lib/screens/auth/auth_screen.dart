import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  bool _esLogin = true;
  bool _cargando = false;
  final _supabaseService = SupabaseService();

  Future<void> _procesar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);
    try {
      if (_esLogin) {
        await _supabaseService.iniciarSesion(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
      } else {
        // Logica para Cuba: +53 + 8 digitos
        String telefonoFinal = "+53${_telefonoController.text.trim()}";
        
        await _supabaseService.registrarUsuario(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          nombre: _nombreController.text.trim(),
          telefono: telefonoFinal,
        );
      }
      
      if (mounted) {
        final rol = await _supabaseService.getRolUsuario();
        Navigator.pushReplacementNamed(context, rol == 'barbero' ? '/home_admin' : '/home_cliente');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Text(_esLogin ? "Bienvenido" : "Crea tu Cuenta",
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppConfig.colorPrimario)),
                const SizedBox(height: 30),
                if (!_esLogin) ...[
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: "Nombre Completo", prefixIcon: Icon(Icons.person)),
                    validator: (v) => v!.isEmpty ? "Obligatorio" : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.number,
                    maxLength: 8,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    decoration: const InputDecoration(
                      labelText: "Teléfono (8 dígitos)",
                      prefixText: "+53 ",
                      prefixIcon: Icon(Icons.phone_android),
                      counterText: "",
                    ),
                    validator: (v) => v!.length != 8 ? "Deben ser 8 números" : null,
                  ),
                ],
                const SizedBox(height: 15),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email)),
                  validator: (v) => !v!.contains('@') ? "Email inválido" : null,
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock)),
                  validator: (v) => v!.length < 6 ? "Mínimo 6 caracteres" : null,
                ),
                const SizedBox(height: 30),
                _cargando 
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.colorPrimario,
                        minimumSize: const Size(double.infinity, 50)),
                      onPressed: _procesar,
                      child: Text(_esLogin ? "ENTRAR" : "REGISTRARME", style: const TextStyle(color: Colors.black)),
                    ),
                TextButton(
                  onPressed: () => setState(() => _esLogin = !_esLogin),
                  child: Text(_esLogin ? "¿No tienes cuenta? Regístrate" : "¿Ya tienes cuenta? Inicia Sesión"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}