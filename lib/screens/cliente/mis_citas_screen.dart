import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';

class MisCitasScreen extends StatefulWidget {
  const MisCitasScreen({super.key});

  @override
  State<MisCitasScreen> createState() => _MisCitasScreenState();
}

class _MisCitasScreenState extends State<MisCitasScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _citas = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCitas();
  }

  Future<void> _cargarCitas() async {
    try {
      final data = await _service.getMisCitas();
      setState(() {
        _citas = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint("Error al cargar citas: $e");
    }
  }

  Future<void> _confirmarCancelacion(String idCita) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cancelar Cita?"),
        content: const Text("Esta accion liberara tu turno y otros podran reservarlo."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("NO, VOLVER"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _cargando = true);
              await _service.cancelarCita(idCita);
              _cargarCitas();
            },
            child: const Text("SI, CANCELAR", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Turnos")),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : _citas.isEmpty
              ? const Center(child: Text("No tienes citas programadas"))
              : RefreshIndicator(
                  onRefresh: _cargarCitas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: _citas.length,
                    itemBuilder: (context, i) {
                      final cita = _citas[i];
                      final fechaHora = DateTime.parse(cita['fecha_hora']).toLocal();
                      final esCancelada = cita['estado'] == 'cancelada';

                      return Card(
                        color: esCancelada ? Colors.grey.withOpacity(0.1) : null,
                        margin: const EdgeInsets.only(bottom: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(
                            color: esCancelada ? Colors.transparent : AppConfig.colorPrimario.withOpacity(0.5),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(15),
                          title: Text(
                            cita['servicios']['nombre'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              decoration: esCancelada ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 5),
                              Text("Fecha: ${DateFormat('dd/MM/yyyy').format(fechaHora)}"),
                              Text("Hora: ${DateFormat('hh:mm a').format(fechaHora)}"),
                              const SizedBox(height: 5),
                              Text(
                                esCancelada ? "ESTADO: CANCELADA" : "ESTADO: CONFIRMADA",
                                style: TextStyle(
                                  color: esCancelada ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: !esCancelada
                              ? IconButton(
                                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                                  onPressed: () => _confirmarCancelacion(cita['id'].toString()),
                                )
                              : const Icon(Icons.block, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}