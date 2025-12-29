import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';

class ReservaScreen extends StatefulWidget {
  final Map<String, dynamic> servicio;
  const ReservaScreen({super.key, required this.servicio});

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final _service = SupabaseService();
  DateTime _fecha = DateTime.now();
  DateTime? _horaSeleccionada;
  List<DateTime> _disponibles = [];
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _generarTurnos();
  }

  Future<void> _generarTurnos() async {
    setState(() => _cargando = true);
    final config = await _service.getHorarioConfig();
    final ocupadas = await _service.getHorasOcupadas(_fecha);
    
    List<DateTime> temporal = [];

    void agregarRango(String inicio, String fin) {
      DateTime horaActual = DateTime(_fecha.year, _fecha.month, _fecha.day, 
          int.parse(inicio.split(':')[0]), int.parse(inicio.split(':')[1]));
      DateTime horaFin = DateTime(_fecha.year, _fecha.month, _fecha.day, 
          int.parse(fin.split(':')[0]), int.parse(fin.split(':')[1]));

      while (horaActual.isBefore(horaFin)) {
        if (!ocupadas.any((o) => o.hour == horaActual.hour && o.minute == horaActual.minute)) {
          temporal.add(horaActual);
        }
        horaActual = horaActual.add(Duration(minutes: config['duracion_turno_minutos']));
      }
    }

    agregarRango(config['h_inicio_manana'], config['h_fin_manana']);
    if (config['almuerzo_activo']) {
      agregarRango(config['h_inicio_tarde'], config['h_fin_tarde']);
    }

    setState(() {
      _disponibles = temporal;
      _cargando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Reservar ${widget.servicio['nombre']}")),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _fecha,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 15)),
            onDateChanged: (d) {
              setState(() => _fecha = d);
              _generarTurnos();
            },
          ),
          Expanded(
            child: _cargando 
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, childAspectRatio: 2.5, mainAxisSpacing: 10, crossAxisSpacing: 10
                  ),
                  itemCount: _disponibles.length,
                  itemBuilder: (context, i) {
                    final h = _disponibles[i];
                    bool esSel = _horaSeleccionada == h;
                    return ActionChip(
                      backgroundColor: esSel ? AppConfig.colorPrimario : Colors.white10,
                      label: Text("${h.hour}:${h.minute.toString().padLeft(2, '0')}", 
                        style: TextStyle(color: esSel ? Colors.black : Colors.white)),
                      onPressed: () => setState(() => _horaSeleccionada = h),
                    );
                  },
                ),
          ),
          ElevatedButton(
            onPressed: _horaSeleccionada == null ? null : () async {
              await _service.crearCita(servicioId: widget.servicio['id'], fechaHora: _horaSeleccionada!);
              Navigator.pop(context);
            },
            child: const Text("CONFIRMAR"),
          )
        ],
      ),
    );
  }
}