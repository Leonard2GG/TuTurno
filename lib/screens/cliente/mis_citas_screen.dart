import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener intl en pubspec.yaml
import '../../config.dart';
import '../../services/supabase_service.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _citas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() => _cargando = true);
    try {
      final data = await _supabaseService.getMisCitas();
      setState(() {
        _citas = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _confirmarCancelacion(String citaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar turno?"),
        content: const Text("Esta acción permitirá que otra persona tome el lugar."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("NO")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("SÍ, CANCELAR", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _supabaseService.cancelarCita(citaId);
        _cargarCitas();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cita cancelada")));
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error al cancelar")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Turnos")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : _citas.isEmpty
              ? const Center(child: Text("No tienes citas registradas", style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _cargarCitas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _citas.length,
                    itemBuilder: (context, index) {
                      final cita = _citas[index];
                      final fecha = DateTime.parse(cita['fecha_hora']).toLocal();
                      final esCancelada = cita['estado'] == 'cancelada';

                      return Card(
                        color: esCancelada ? Colors.black26 : Colors.white.withAlpha(20),
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          title: Text(cita['servicios']['nombre'], style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: esCancelada ? TextDecoration.lineThrough : null
                          )),
                          subtitle: Text(DateFormat('dd/MM/yyyy - hh:mm a').format(fecha)),
                          trailing: esCancelada 
                            ? const Text("CANCELADA", style: TextStyle(color: Colors.red, fontSize: 10))
                            : IconButton(
                                icon: const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                                onPressed: () => _confirmarCancelacion(cita['id']),
                              ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}