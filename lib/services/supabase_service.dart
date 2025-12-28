import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class SupabaseService {
  // Instancia única de conexión
  final _supabase = Supabase.instance.client;

  // Función para obtener servicios del negocio específico
  Future<List<Map<String, dynamic>>> getServicios() async {
    try {
      final data = await _supabase
          .from('servicios')
          .select()
          .eq('negocio_id', AppConfig.negocioId);
      
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error en Supabase: $e');
      throw Exception('Error al conectar con la base de datos');
    }
  }

  // Verificar si hay una sesión activa (Usuario logueado)
  User? get usuarioActual => _supabase.auth.currentUser;

  // Cerrar sesión del usuario
  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }
}