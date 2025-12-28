import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';


class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final _supabaseService = SupabaseService();
  bool _cargando = true;
  List<Map<String, dynamic>> _misCitas = [];

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    setState(() => _cargando = true);
    try {
      final citas = await _supabaseService.getMisCitas();
      setState(() {
        _misCitas = citas;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cargar citas: $e")),
      );
    }
  }

  Future<void> _cancelar(String id) async {
    try {
      await _supabaseService.cancelarCita(id);
      _cargarCitas();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo cancelar la cita")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Turnos")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _misCitas.isEmpty
              ? const Center(child: Text("No tienes citas programadas"))
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _misCitas.length,
                  itemBuilder: (context, index) {
                    final cita = _misCitas[index];
                    final fecha = DateTime.parse(cita['fecha_hora']).toLocal();
                    final formateada = DateFormat('dd/MM - hh:mm a').format(fecha);

                    return Card(
                      child: ListTile(
                        title: Text(cita['servicios']['nombre']),
                        subtitle: Text(formateada),
                        trailing: cita['estado'] == 'confirmada'
                            ? IconButton(
                                icon: const Icon(Icons.delete, color: Colors.redAccent),
                                onPressed: () => _cancelar(cita['id']),
                              )
                            : Text(cita['estado'].toUpperCase()),
                      ),
                    );
                  },
                ),
    );
  }
}