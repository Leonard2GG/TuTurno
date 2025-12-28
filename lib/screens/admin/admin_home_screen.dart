import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});
  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _espera = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _activarRealtime();
  }

  // Carga inicial de datos
  Future<void> _cargarTodo() async {
    try {
      final citasData = await _supabaseService.getCitasDelDia(DateTime.now());
      final esperaData = await _supabaseService.getListaEsperaDetallada();
      if (mounted) {
        setState(() {
          _citas = citasData;
          _espera = esperaData;
          _cargando = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  // SUSCRIPCIÓN REALTIME: Escucha cambios en las tablas y refresca la UI
  void _activarRealtime() {
    Supabase.instance.client
        .channel('admin_updates')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'citas',
            callback: (payload) => _cargarTodo())
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lista_espera',
            callback: (payload) => _cargarTodo())
        .subscribe();
  }

  Future<void> _cambiarEstado(String id, String estado) async {
    await _supabaseService.actualizarEstadoCita(id, estado);
    // No hace falta llamar a _cargarTodo aquí porque Realtime lo detectará
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("PANEL BARBERO"),
          bottom: const TabBar(
            indicatorColor: AppConfig.colorPrimario,
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "CITAS"),
              Tab(icon: Icon(Icons.people), text: "ESPERA"),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _supabaseService.cerrarSesion();
                if (mounted) Navigator.pushReplacementNamed(context, '/auth');
              },
            )
          ],
        ),
        body: _cargando 
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : TabBarView(
              children: [
                _buildListaCitas(),
                _buildListaEspera(),
              ],
            ),
      ),
    );
  }

  Widget _buildListaCitas() {
    if (_citas.isEmpty) return const Center(child: Text("No hay turnos para hoy"));
    return ListView.builder(
      itemCount: _citas.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, i) {
        final cita = _citas[i];
        final hora = DateFormat('hh:mm a').format(DateTime.parse(cita['fecha_hora']).toLocal());
        
        return Card(
          child: ListTile(
            leading: Text(hora, style: const TextStyle(color: AppConfig.colorPrimario, fontWeight: FontWeight.bold)),
            title: Text(cita['perfiles']['nombre'] ?? 'Cliente'),
            subtitle: Text("${cita['servicios']['nombre']} - ${cita['perfiles']['telefono']}"),
            trailing: cita['estado'] == 'confirmada' 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => _cambiarEstado(cita['id'], 'completada')),
                    IconButton(icon: const Icon(Icons.close, color: Colors.red), onPressed: () => _cambiarEstado(cita['id'], 'cancelada')),
                  ],
                )
              : Text(cita['estado'].toString().toUpperCase(), style: const TextStyle(fontSize: 10)),
          ),
        );
      },
    );
  }

  Widget _buildListaEspera() {
    if (_espera.isEmpty) return const Center(child: Text("Lista vacía"));
    return ListView.builder(
      itemCount: _espera.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, i) {
        final item = _espera[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(child: Text("${i + 1}")),
            title: Text(item['perfiles']['nombre']),
            subtitle: Text("WhatsApp: ${item['perfiles']['telefono']}"),
            trailing: const Icon(Icons.hourglass_bottom, color: Colors.amber),
          ),
        );
      },
    );
  }
}