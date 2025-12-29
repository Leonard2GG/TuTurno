import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
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
                  id: 1, titulo: "Nueva Cita", cuerpo: "Un cliente reservo un turno.");
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
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Panel Barbero', style: GoogleFonts.poppins(color: AppConfig.colorPrimario, fontWeight: FontWeight.bold)),
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
          bottom: TabBar(
            indicatorColor: AppConfig.colorPrimario,
            tabs: [
              Tab(text: "AGENDA HOY", icon: Icon(Icons.calendar_today)),
              Tab(text: "LISTA ESPERA", icon: Icon(Icons.people)),
            ],
          ),
        ),
        body: _cargando ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario)) : TabBarView(children: [_buildAgendaList(), _buildEsperaList()]),
      ),
    );
  }

  Widget _buildAgendaList() {
    if (_citas.isEmpty) return Center(child: Text('No hay citas programadas', style: GoogleFonts.poppins()));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _citas.length,
      itemBuilder: (context, i) {
        final c = _citas[i];
        final hora = DateFormat('hh:mm a').format(DateTime.parse(c['fecha_hora']).toLocal());
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: CircleAvatar(backgroundColor: AppConfig.colorPrimario, child: Text(hora.split(' ')[0], style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold))),
            title: Text(c['perfiles']['nombre'] ?? 'Cliente', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text(c['servicios']['nombre'] ?? 'Servicio', style: GoogleFonts.poppins()),
            trailing: IconButton(icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green), onPressed: () => _abrirWhatsApp(c['perfiles']['telefono'])),
          ),
        );
      },
    );
  }

  Widget _buildEsperaList() {
    if (_espera.isEmpty) return Center(child: Text('Lista de espera vacia', style: GoogleFonts.poppins()));
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _espera.length,
      itemBuilder: (context, i) {
        final e = _espera[i];
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(backgroundColor: AppConfig.colorPrimario, child: Text('${i + 1}', style: GoogleFonts.poppins(color: Colors.black, fontWeight: FontWeight.bold))),
            title: Text(e['perfiles']['nombre'] ?? 'Cliente', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            subtitle: Text('Esperando turno...', style: GoogleFonts.poppins()),
            trailing: IconButton(icon: const FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green), onPressed: () => _abrirWhatsApp(e['perfiles']['telefono'])),
          ),
        );
      },
    );
  }
}