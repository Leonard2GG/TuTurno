import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

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

  // 1. CARGA INICIAL DE DATOS
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

  // 2. SUSCRIPCIÓN REALTIME (Escucha cambios y notifica)
  void _activarRealtime() {
    Supabase.instance.client
        .channel('admin_updates')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'citas',
            callback: (payload) {
              _cargarTodo();
              // Opcional: Notificar si es una nueva cita
              if (payload.eventType == PostgresChangeEvent.insert) {
                NotificationService.mostrarNotificacion(
                  id: 10,
                  titulo: "¡Nueva Reserva!",
                  cuerpo: "Un cliente ha agendado un nuevo turno.",
                );
              }
            })
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lista_espera',
            callback: (payload) {
              _cargarTodo();
              if (payload.eventType == PostgresChangeEvent.insert) {
                NotificationService.mostrarNotificacion(
                  id: 11,
                  titulo: "Lista de Espera",
                  cuerpo: "Alguien se acaba de unir a la lista de espera.",
                );
              }
            })
        .subscribe();
  }

  // 3. ACCIONES: CONTACTAR CLIENTE
  Future<void> _contactarCliente(String? telefono) async {
    if (telefono == null || telefono.isEmpty) return;
    final url = "https://wa.me/$telefono?text=Hola! Te escribo de la barbería.";
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo abrir WhatsApp")),
      );
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
            indicatorColor: AppConfig.colorPrimario,
            labelColor: AppConfig.colorPrimario,
            tabs: [
              Tab(icon: Icon(Icons.calendar_today), text: "AGENDA"),
              Tab(icon: Icon(Icons.hourglass_top), text: "ESPERA"),
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
                _buildTabCitas(),
                _buildTabEspera(),
              ],
            ),
      ),
    );
  }

  Widget _buildTabCitas() {
    if (_citas.isEmpty) return const Center(child: Text("Sin turnos hoy"));
    return ListView.builder(
      itemCount: _citas.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, i) {
        final cita = _citas[i];
        final fecha = DateTime.parse(cita['fecha_hora']).toLocal();
        final hora = DateFormat('hh:mm a').format(fecha);
        
        return Card(
          child: ListTile(
            leading: Text(hora, style: const TextStyle(color: AppConfig.colorPrimario, fontWeight: FontWeight.bold)),
            title: Text(cita['perfiles']['nombre'] ?? 'Cliente'),
            subtitle: Text("${cita['servicios']['nombre']}"),
            trailing: IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green), 
              onPressed: () => _contactarCliente(cita['perfiles']['telefono']),
            ),
          ),
        );
      },
    );
  }

Widget _buildTabEspera() {
    if (_espera.isEmpty) return const Center(child: Text("Nadie en espera"));
    return ListView.builder(
      itemCount: _espera.length,
      padding: const EdgeInsets.all(10),
      itemBuilder: (context, index) {
        final item = _espera[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppConfig.colorPrimario,
              child: Text("${index + 1}", style: const TextStyle(color: Colors.black)),
            ),
            title: Text(item['perfiles']['nombre']),
            subtitle: const Text("Esperando un espacio..."),
            trailing: IconButton(
              icon: const FaIcon(FontAwesomeIcons.message, color: Colors.amber, size: 20),
              onPressed: () => _contactarCliente(item['perfiles']['telefono']),
            ),
          ),
        );
      },
    );
  }
}