import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. AUTENTICACIÓN Y ROLES
  // ==========================================

  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
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
          'rol': 'cliente',
        });
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<void> iniciarSesion(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> cerrarSesion() async {
    await _supabase.auth.signOut();
  }

  Future<String> getRolUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'cliente';
    final data = await _supabase
        .from('perfiles')
        .select('rol')
        .eq('id', user.id)
        .single();
    return data['rol'] ?? 'cliente';
  }

  // ==========================================
  // 2. GESTIÓN DE CITAS (CLIENTE)
  // ==========================================

  Future<List<Map<String, dynamic>>> getServicios() async {
    final data = await _supabase
        .from('servicios')
        .select()
        .eq('negocio_id', AppConfig.negocioId);
    return List<Map<String, dynamic>>.from(data);
  }

  // CREAR CITA CON LIMPIEZA DE LISTA DE ESPERA AUTOMÁTICA
  Future<void> crearCita({
    required String servicioId,
    required DateTime fechaHora,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Inicia sesión para reservar");

      // 1. Insertar la cita
      await _supabase.from('citas').insert({
        'negocio_id': AppConfig.negocioId,
        'cliente_id': user.id,
        'servicio_id': servicioId,
        'fecha_hora': fechaHora.toIso8601String(),
        'estado': 'confirmada',
      });

      // 2. LÓGICA DE AUTONOMÍA: Eliminar al usuario de la lista de espera si existía
      await _supabase
          .from('lista_espera')
          .delete()
          .eq('cliente_id', user.id)
          .eq('negocio_id', AppConfig.negocioId);

    } catch (e) {
      throw Exception("Error al procesar la reserva: $e");
    }
  }

  Future<List<String>> getHorasOcupadas(DateTime fecha) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toIso8601String();

    final data = await _supabase
        .from('citas')
        .select('fecha_hora')
        .eq('negocio_id', AppConfig.negocioId)
        .gte('fecha_hora', inicioDia)
        .lte('fecha_hora', finDia)
        .neq('estado', 'cancelada');

    return (data as List).map((cita) {
      final dt = DateTime.parse(cita['fecha_hora']).toLocal();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }).toList();
  }

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

  Future<void> cancelarCita(String citaId) async {
    await _supabase.from('citas').update({'estado': 'cancelada'}).eq('id', citaId);
  }

  // ==========================================
  // 3. LISTA DE ESPERA E INTELIGENCIA
  // ==========================================

  Future<void> unirseAListaEspera() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("Inicia sesión");
      await _supabase.from('lista_espera').insert({
        'negocio_id': AppConfig.negocioId,
        'cliente_id': user.id,
        'prioridad': 1,
      });
    } catch (e) {
      throw Exception("Ya estás en la lista o hubo un error: $e");
    }
  }

  // ==========================================
  // 4. PANEL DE ADMINISTRADOR (BARBERO)
  // ==========================================

  Future<List<Map<String, dynamic>>> getCitasDelDia(DateTime fecha) async {
    final inicioDia = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final finDia = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59).toIso8601String();

    final data = await _supabase
        .from('citas')
        .select('*, servicios(nombre), perfiles(nombre)')
        .eq('negocio_id', AppConfig.negocioId)
        .gte('fecha_hora', inicioDia)
        .lte('fecha_hora', finDia)
        .order('fecha_hora', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> actualizarEstadoCita(String citaId, String nuevoEstado) async {
    await _supabase.from('citas').update({'estado': nuevoEstado}).eq('id', citaId);
  }

  Future<List<Map<String, dynamic>>> getListaEsperaDetallada() async {
    final data = await _supabase
        .from('lista_espera')
        .select('*, perfiles(nombre)')
        .eq('negocio_id', AppConfig.negocioId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }
}