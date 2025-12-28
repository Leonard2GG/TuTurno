import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart'; // Importante

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
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargando = true);
    try {
      final citasData = await _supabaseService.getCitasDelDia(DateTime.now());
      final esperaData = await _supabaseService.getListaEsperaDetallada();
      setState(() {
        _citas = citasData;
        _espera = esperaData;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cambiarEstado(String id, String estado) async {
    try {
      await _supabaseService.actualizarEstadoCita(id, estado);
      
      // LÓGICA DE NOTIFICACIÓN AUTOMÁTICA
      if (estado == 'cancelada' && _espera.isNotEmpty) {
        await NotificationService.mostrarNotificacion(
          id: 2,
          titulo: "¡Turno Disponible!",
          cuerpo: "Se ha liberado un hueco. ¡Entra rápido para reservar!",
        );
      }

      _cargarDatos();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al actualizar estado")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("PANEL BARBERO"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "CITAS HOY", icon: Icon(Icons.calendar_today)),
              Tab(text: "ESPERA", icon: Icon(Icons.people_outline)),
            ],
            indicatorColor: AppConfig.colorPrimario,
          ),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _cargarDatos),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _supabaseService.cerrarSesion();
                if (mounted) Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
          ],
        ),
        body: _cargando 
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : TabBarView(
              children: [
                _buildTabCitas(),
                _buildTabEspera(),
              ],
            ),
      ),
    );
  }

  Widget _buildTabCitas() {
    if (_citas.isEmpty) return const Center(child: Text("No hay turnos hoy"));
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _citas.length,
      itemBuilder: (context, index) {
        final cita = _citas[index];
        final hora = DateFormat('hh:mm a').format(DateTime.parse(cita['fecha_hora']).toLocal());
        final estado = cita['estado'];

        return Card(
          color: estado == 'completada' ? Colors.green.withAlpha(30) : Colors.white.withAlpha(10),
          child: ListTile(
            leading: Text(hora, style: const TextStyle(color: AppConfig.colorPrimario, fontWeight: FontWeight.bold)),
            title: Text(cita['perfiles']['nombre'] ?? 'Cliente'),
            subtitle: Text(cita['servicios']['nombre'] ?? 'Servicio'),
            trailing: estado == 'confirmada' 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _cambiarEstado(cita['id'], 'completada'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: () => _cambiarEstado(cita['id'], 'cancelada'),
                    ),
                  ],
                )
              : Text(estado.toString().toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
        );
      },
    );
  }

  Widget _buildTabEspera() {
    if (_espera.isEmpty) return const Center(child: Text("Lista de espera vacía"));
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _espera.length,
      itemBuilder: (context, index) {
        final item = _espera[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppConfig.colorPrimario,
              child: Text("${index + 1}", style: const TextStyle(color: Colors.black)),
            ),
            title: Text(item['perfiles']['nombre'] ?? 'Anónimo'),
            subtitle: const Text("Esperando turno libre"),
            trailing: const Icon(Icons.notifications_active, color: Colors.amber),
          ),
        );
      },
    );
  }
}