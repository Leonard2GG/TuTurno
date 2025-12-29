import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';
import 'package:google_fonts/google_fonts.dart';

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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppConfig.colorFondo, AppConfig.colorFondo.withAlpha((0.95 * 255).round())],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppConfig.colorPrimario,
                  child: Text('T', style: GoogleFonts.poppins(fontSize: 36, color: Colors.black, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 18),
                Text(_esLogin ? 'Bienvenido a TuTurno' : 'Crea tu cuenta', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w600, color: AppConfig.colorAcento)),
                const SizedBox(height: 18),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 10,
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (!_esLogin) ...[
                            TextFormField(
                              controller: _nombreController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Nombre completo', prefixIcon: Icon(Icons.person)),
                              validator: (v) => v!.isEmpty ? 'Obligatorio' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _telefonoController,
                              keyboardType: TextInputType.number,
                              maxLength: 8,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Telefono (8 digitos)', prefixText: '+53 ', prefixIcon: Icon(Icons.phone_android), counterText: ''),
                              validator: (v) => v!.length != 8 ? 'Deben ser 8 numeros' : null,
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                            validator: (v) => !v!.contains('@') ? 'Email invalido' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Contrasenia', prefixIcon: Icon(Icons.lock)),
                            validator: (v) => v!.length < 6 ? 'Minimo 6 caracteres' : null,
                          ),
                          const SizedBox(height: 18),
                          _cargando ? const CircularProgressIndicator() : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              onPressed: _procesar,
                              child: Text(_esLogin ? 'ENTRAR' : 'REGISTRARME', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TextButton(onPressed: () => setState(() => _esLogin = !_esLogin), child: Text(_esLogin ? 'No tienes cuenta? Registrate' : 'Ya tienes cuenta? Inicia Sesion', style: const TextStyle(color: Colors.white70)))
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}