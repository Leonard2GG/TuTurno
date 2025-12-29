import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../config.dart';
import 'offline_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // --- AUTENTICACION ---
  Future<void> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    final res = await _supabase.auth.signUp(email: email, password: password);
    if (res.user != null) {
      await _supabase.from('perfiles').insert({
        'id': res.user!.id,
        'negocio_id': AppConfig.negocioId,
        'nombre': nombre,
        'telefono': telefono,
        'rol': 'cliente',
      });
    }
  }

  Future<void> iniciarSesion(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<String> getRolUsuario() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 'cliente';
    final data = await _supabase.from('perfiles').select('rol').eq('id', user.id).single();
    return data['rol'] ?? 'cliente';
  }

  // --- GESTION DE CITAS (CLIENTE) ---
  Future<List<Map<String, dynamic>>> getMisCitas() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    return await _supabase
        .from('citas')
        .select('*, servicios(nombre, precio)')
        .eq('cliente_id', user.id)
        .order('fecha_hora', ascending: true);
  }

  Future<void> cancelarCita(String idCita) async {
    await _supabase.from('citas').update({'estado': 'cancelada'}).eq('id', idCita);
  }

  Future<void> crearCita({required String servicioId, required DateTime fechaHora}) async {
    final user = _supabase.auth.currentUser;
    final cita = {
      'negocio_id': AppConfig.negocioId,
      'cliente_id': user!.id,
      'servicio_id': servicioId,
      'fecha_hora': fechaHora.toIso8601String(),
    };

    // Intentamos enviar directamente, si falla o no hay conexion, encolamos
    try {
      final conn = await Connectivity().checkConnectivity();
      if (conn == ConnectivityResult.none) throw Exception('Sin conexion');

      await _supabase.from('citas').insert(cita);
      await _supabase.from('lista_espera').delete().eq('cliente_id', user.id);
    } catch (e) {
      await OfflineService.enqueueCita(cita);
    }
  }

  // --- LISTA DE ESPERA ---
  Future<void> unirseAListaEspera() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('lista_espera').insert({
      'negocio_id': AppConfig.negocioId,
      'cliente_id': user.id,
    });
  }

  // --- HORARIOS Y DISPONIBILIDAD ---
  Future<Map<String, dynamic>> getHorarioConfig() async {
    return await _supabase
        .from('configuracion_horario')
        .select()
        .eq('negocio_id', AppConfig.negocioId)
        .single();
  }

  Future<List<DateTime>> getHorasOcupadas(DateTime fecha) async {
    final inicio = DateTime(fecha.year, fecha.month, fecha.day).toIso8601String();
    final fin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59).toIso8601String();
    final data = await _supabase
        .from('citas')
        .select('fecha_hora')
        .eq('negocio_id', AppConfig.negocioId)
        .gte('fecha_hora', inicio)
        .lte('fecha_hora', fin)
        .neq('estado', 'cancelada');
    return (data as List).map((c) => DateTime.parse(c['fecha_hora']).toLocal()).toList();
  }

  // --- GESTION DE SERVICIOS (BARBERO) ---
  Future<List<Map<String, dynamic>>> getServicios() async {
    return await _supabase
        .from('servicios')
        .select()
        .eq('negocio_id', AppConfig.negocioId)
        .eq('activo', true);
  }

  Future<void> crearServicio({required String nombre, required double precio, required int duracion}) async {
    await _supabase.from('servicios').insert({
      'negocio_id': AppConfig.negocioId,
      'nombre': nombre,
      'precio': precio,
      'duracion_minutos': duracion,
    });
  }

  Future<void> editarServicio({required String id, required String nombre, required double precio, required int duracion}) async {
    await _supabase.from('servicios').update({
      'nombre': nombre,
      'precio': precio,
      'duracion_minutos': duracion,
    }).eq('id', id);
  }

  Future<void> eliminarServicio(String id) async {
    await _supabase.from('servicios').update({'activo': false}).eq('id', id);
  }

  // --- CIERRE DE SESION ---
  Future<void> cerrarSesion() async {
    try {
      await Workmanager().cancelAll();
    } catch (e) {
      print("Error cancelando Workmanager: $e");
    }
    await _supabase.auth.signOut();
  }
}