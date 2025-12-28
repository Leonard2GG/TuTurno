import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. AUTENTICACIÓN Y PERFILES
  // ==========================================

  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    try {
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      final User? user = res.user;
      if (user != null) {
        await _supabase.from('perfiles').insert({
          'id': user.id,
          'negocio_id': AppConfig.negocioId,
          'nombre': nombre,
          'telefono': telefono,
          'rol': 'cliente',
        });
      }
    } catch (e) {
      throw Exception("Error en registro: $e");
    }
  }

  Future<void> iniciarSesion(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> cerrarSesion() async => await _supabase.auth.signOut();

  Future<String> getRolUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'cliente';
    final data = await _supabase.from('perfiles').select('rol').eq('id', user.id).single();
    return data['rol'] ?? 'cliente';
  }

  // ==========================================
  // 2. GESTIÓN DE CITAS (CLIENTE)
  // ==========================================

  Future<List<Map<String, dynamic>>> getServicios() async {
    final data = await _supabase.from('servicios').select().eq('negocio_id', AppConfig.negocioId);
    return List<Map<String, dynamic>>.from(data);
  }

  // Obtener citas del cliente logueado (CORRIGE EL ERROR)
  Future<List<Map<String, dynamic>>> getMisCitas() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final data = await _supabase
        .from('citas')
        .select('*, servicios(nombre, precio)')
        .eq('cliente_id', user.id)
        .order('fecha_hora', ascending: true);
    
    return List<Map<String, dynamic>>.from(data);
  }

  // Cancelar cita (CORRIGE EL ERROR)
  Future<void> cancelarCita(String citaId) async {
    await _supabase
        .from('citas')
        .update({'estado': 'cancelada'})
        .eq('id', citaId);
  }

  Future<void> crearCita({required String servicioId, required DateTime fechaHora}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Inicia sesión");

    await _supabase.from('citas').insert({
      'negocio_id': AppConfig.negocioId,
      'cliente_id': user.id,
      'servicio_id': servicioId,
      'fecha_hora': fechaHora.toIso8601String(),
      'estado': 'confirmada',
    });

    await _supabase.from('lista_espera').delete().eq('cliente_id', user.id);
  }

  Future<List<String>> getHorasOcupadas(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59).toIso8601String();

    final data = await _supabase.from('citas')
        .select('fecha_hora')
        .eq('negocio_id', AppConfig.negocioId)
        .gte('fecha_hora', inicio)
        .lte('fecha_hora', fin)
        .neq('estado', 'cancelada');

    return (data as List).map((c) {
      final dt = DateTime.parse(c['fecha_hora']).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }).toList();
  }

  // ==========================================
  // 3. PANEL DE ADMINISTRADOR Y LISTA ESPERA
  // ==========================================

  Future<List<Map<String, dynamic>>> getCitasDelDia(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59).toIso8601String();

    final data = await _supabase.from('citas')
        .select('*, servicios(nombre), perfiles(nombre, telefono)')
        .eq('negocio_id', AppConfig.negocioId)
        .gte('fecha_hora', inicio)
        .lte('fecha_hora', fin)
        .order('fecha_hora', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<List<Map<String, dynamic>>> getListaEsperaDetallada() async {
    final data = await _supabase.from('lista_espera')
        .select('*, perfiles(nombre, telefono)')
        .eq('negocio_id', AppConfig.negocioId)
        .order('creado_en', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> actualizarEstadoCita(String id, String nuevoEstado) async {
    await _supabase.from('citas').update({'estado': nuevoEstado}).eq('id', id);
  }

  Future<void> unirseAListaEspera() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('lista_espera').insert({
      'negocio_id': AppConfig.negocioId,
      'cliente_id': user.id,
    });
  }
}