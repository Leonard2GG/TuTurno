import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

class ReservaScreen extends StatefulWidget {
  final Map<String, dynamic> servicio;
  const ReservaScreen({super.key, required this.servicio});

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final _supabaseService = SupabaseService();
  DateTime _fechaSeleccionada = DateTime.now();
  String? _horaSeleccionada;
  List<String> _horasOcupadas = [];
  bool _cargandoHoras = false;

  final List<String> _horariosBase = [
    "09:00", "09:30", "10:00", "10:30", "11:00", "11:30", 
    "13:00", "13:30", "14:00", "14:30", "15:00", "15:30"
  ];

  @override
  void initState() {
    super.initState();
    _cargarOcupacion(_fechaSeleccionada);
  }

  Future<void> _cargarOcupacion(DateTime fecha) async {
    setState(() => _cargandoHoras = true);
    try {
      final ocupadas = await _supabaseService.getHorasOcupadas(fecha);
      setState(() {
        _horasOcupadas = ocupadas;
        _cargandoHoras = false;
      });
    } catch (e) {
      if (mounted) setState(() => _cargandoHoras = false);
    }
  }

  Future<void> _confirmarReserva() async {
    if (_horaSeleccionada == null) return;

    final partesHora = _horaSeleccionada!.split(':');
    final fechaFinal = DateTime(
      _fechaSeleccionada.year,
      _fechaSeleccionada.month,
      _fechaSeleccionada.day,
      int.parse(partesHora[0]),
      int.parse(partesHora[1]),
    );

    try {
      await _supabaseService.crearCita(
        servicioId: widget.servicio['id'],
        fechaHora: fechaFinal,
      );

      // Notificación local de éxito
      await NotificationService.mostrarNotificacion(
        id: 1,
        titulo: "Reserva Confirmada",
        cuerpo: "Tu turno para ${widget.servicio['nombre']} ha sido agendado.",
      );

      if (mounted) {
        _mostrarExito();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.check_circle, color: Colors.green, size: 50),
        content: const Text(
          "¡Turno Reservado!\n\nSi estabas en lista de espera, tu solicitud ha sido actualizada automáticamente.",
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("VOLVER AL INICIO", style: TextStyle(color: AppConfig.colorPrimario)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Finalizar Reserva")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CalendarDatePicker(
              initialDate: _fechaSeleccionada,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
              onDateChanged: (date) {
                setState(() {
                  _fechaSeleccionada = date;
                  _horaSeleccionada = null;
                });
                _cargarOcupacion(date);
              },
            ),
            const Divider(),
            if (_cargandoHoras)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppConfig.colorPrimario),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, childAspectRatio: 2, crossAxisSpacing: 10, mainAxisSpacing: 10
                ),
                itemCount: _horariosBase.length,
                itemBuilder: (context, index) {
                  final hora = _horariosBase[index];
                  final estaOcupada = _horasOcupadas.contains(hora);
                  final esSeleccionada = _horaSeleccionada == hora;

                  return InkWell(
                    onTap: estaOcupada ? null : () => setState(() => _horaSeleccionada = hora),
                    child: Container(
                      decoration: BoxDecoration(
                        color: estaOcupada 
                            ? Colors.red.withAlpha(40) 
                            : (esSeleccionada ? AppConfig.colorPrimario : Colors.white10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        estaOcupada ? "Ocupado" : hora,
                        style: TextStyle(
                          color: estaOcupada ? Colors.red : (esSeleccionada ? Colors.black : Colors.white),
                          fontWeight: FontWeight.bold,
                          fontSize: 12
                        ),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario),
                  onPressed: _horaSeleccionada == null ? null : _confirmarReserva,
                  child: const Text("RESERVAR AHORA", 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}