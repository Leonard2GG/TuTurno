import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../config.dart';
import 'gestion_servicios_screen.dart'; // Asegurate de crear este archivo
import 'config_horario_screen.dart';    // Asegurate de crear este archivo

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _espera = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _escucharRealtime();
  }

  void _escucharRealtime() {
    Supabase.instance.client
        .channel('admin_changes')
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'citas',
            callback: (p) {
              _cargarDatos();
              if (p.eventType == PostgresChangeEvent.insert) {
                NotificationService.mostrarNotificacion(
                    id: 1, titulo: "Nueva Cita", cuerpo: "Un cliente reservó un turno.");
              }
            })
        .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'lista_espera',
            callback: (p) => _cargarDatos())
        .subscribe();
  }

  Future<void> _cargarDatos() async {
    try {
      final resCitas = await Supabase.instance.client
          .from('citas')
          .select('*, perfiles(nombre, telefono), servicios(nombre)')
          .eq('negocio_id', AppConfig.negocioId)
          .neq('estado', 'cancelada')
          .order('fecha_hora');

      final resEspera = await Supabase.instance.client
          .from('lista_espera')
          .select('*, perfiles(nombre, telefono)')
          .eq('negocio_id', AppConfig.negocioId)
          .order('creado_en');

      setState(() {
        _citas = List<Map<String, dynamic>>.from(resCitas);
        _espera = List<Map<String, dynamic>>.from(resEspera);
        _cargando = false;
      });
    } catch (e) {
      debugPrint("Error cargando datos: $e");
    }
  }

  Future<void> _abrirWhatsApp(String tel) async {
    final url = "https://wa.me/$tel";
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No se pudo abrir WhatsApp")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("PANEL BARBERO"),
          actions: [
            IconButton(
              icon: const Icon(Icons.content_cut),
              tooltip: "Gestionar Servicios",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GestionServiciosScreen())).then((_) => _cargarDatos()),
            ),
            IconButton(
              icon: const Icon(Icons.access_time),
              tooltip: "Configurar Horario",
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ConfigHorarioScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _service.cerrarSesion();
                Navigator.pushReplacementNamed(context, '/auth');
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: AppConfig.colorPrimario,
            tabs: [
              Tab(text: "AGENDA HOY", icon: Icon(Icons.calendar_today)),
              Tab(text: "LISTA ESPERA", icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
            : TabBarView(
                children: [
                  _buildAgendaList(),
                  _buildEsperaList(),
                ],
              ),
      ),
    );
  }

  Widget _buildAgendaList() {
    if (_citas.isEmpty) return const Center(child: Text("No hay citas programadas"));
    return ListView.builder(
      itemCount: _citas.length,
      itemBuilder: (context, i) {
        final c = _citas[i];
        final hora = DateFormat('hh:mm a').format(DateTime.parse(c['fecha_hora']).toLocal());
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: Text(hora, style: const TextStyle(fontWeight: FontWeight.bold, color: AppConfig.colorPrimario)),
            title: Text(c['perfiles']['nombre'] ?? "Cliente"),
            subtitle: Text(c['servicios']['nombre'] ?? "Servicio"),
            trailing: IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
              onPressed: () => _abrirWhatsApp(c['perfiles']['telefono']),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEsperaList() {
    if (_espera.isEmpty) return const Center(child: Text("Lista de espera vacía"));
    return ListView.builder(
      itemCount: _espera.length,
      itemBuilder: (context, i) {
        final e = _espera[i];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppConfig.colorPrimario, child: Text("${i + 1}")),
            title: Text(e['perfiles']['nombre'] ?? "Cliente"),
            subtitle: const Text("Esperando turno..."),
            trailing: IconButton(
              icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
              onPressed: () => _abrirWhatsApp(e['perfiles']['telefono']),
            ),
          ),
        );
      },
    );
  }
}