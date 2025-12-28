import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';

class ReservaScreen extends StatefulWidget {
  final Map<String, dynamic> servicio;
  const ReservaScreen({super.key, required this.servicio});
  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final _supabaseService = SupabaseService();
  DateTime _fecha = DateTime.now();
  String? _hora;
  List<String> _ocupadas = [];

  final List<String> _horarios = ["09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00", "18:00"];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  _cargar() async {
    final res = await _supabaseService.getHorasOcupadas(_fecha);
    setState(() => _ocupadas = res);
  }

  bool _esPasada(String h) {
    final ahora = DateTime.now();
    if (_fecha.day != ahora.day) return false;
    final hInt = int.parse(h.split(':')[0]);
    return hInt <= ahora.hour;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Reservar Turno")),
      body: Column(
        children: [
          CalendarDatePicker(
            initialDate: _fecha, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)),
            onDateChanged: (d) { setState(() => _fecha = d); _cargar(); }
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 2.5, mainAxisSpacing: 10, crossAxisSpacing: 10),
              itemCount: _horarios.length,
              itemBuilder: (context, i) {
                final h = _horarios[i];
                final bloqueada = _ocupadas.contains(h) || _esPasada(h);
                return InkWell(
                  onTap: bloqueada ? null : () => setState(() => _hora = h),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bloqueada ? Colors.white10 : (_hora == h ? AppConfig.colorPrimario : Colors.white24),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    alignment: Alignment.center,
                    child: Text(h, style: TextStyle(color: bloqueada ? Colors.white30 : (_hora == h ? Colors.black : Colors.white))),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario, minimumSize: const Size(double.infinity, 55)),
              onPressed: _hora == null ? null : () async {
                final dt = DateTime(_fecha.year, _fecha.month, _fecha.day, int.parse(_hora!.split(':')[0]));
                await _supabaseService.crearCita(servicioId: widget.servicio['id'], fechaHora: dt);
                Navigator.pop(context);
              },
              child: const Text("CONFIRMAR TURNO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}