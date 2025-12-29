import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';

class ConfigHorarioScreen extends StatefulWidget {
  const ConfigHorarioScreen({super.key});

  @override
  State<ConfigHorarioScreen> createState() => _ConfigHorarioScreenState();
}

class _ConfigHorarioScreenState extends State<ConfigHorarioScreen> {
  final _service = SupabaseService();
  bool _cargando = true;
  bool _almuerzoActivo = true;

  // Variables limpias de caracteres especiales
  TimeOfDay _hInicioAM = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _hFinAM = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _hInicioPM = const TimeOfDay(hour: 13, minute: 30);
  TimeOfDay _hFinPM = const TimeOfDay(hour: 18, minute: 0);
  int _duracionTurno = 30;

  @override
  void initState() {
    super.initState();
    _cargarConfiguracionActual();
  }

  Future<void> _cargarConfiguracionActual() async {
    try {
      final config = await _service.getHorarioConfig();
      setState(() {
        _hInicioAM = _parseTime(config['h_inicio_manana']);
        _hFinAM = _parseTime(config['h_fin_manana']);
        _almuerzoActivo = config['almuerzo_activo'] ?? false;
        if (config['h_inicio_tarde'] != null) {
          _hInicioPM = _parseTime(config['h_inicio_tarde']);
        }
        if (config['h_fin_tarde'] != null) {
          _hFinPM = _parseTime(config['h_fin_tarde']);
        }
        _duracionTurno = config['duracion_turno_minutos'] ?? 30;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return "$h:$m:00";
  }

  Future<void> _guardar() async {
    setState(() => _cargando = true);
    try {
      await Supabase.instance.client.from('configuracion_horario').update({
        'h_inicio_manana': _formatTimeOfDay(_hInicioAM),
        'h_fin_manana': _formatTimeOfDay(_hFinAM),
        'almuerzo_activo': _almuerzoActivo,
        'h_inicio_tarde': _almuerzoActivo ? _formatTimeOfDay(_hInicioPM) : null,
        'h_fin_tarde': _almuerzoActivo ? _formatTimeOfDay(_hFinPM) : null,
        'duracion_turno_minutos': _duracionTurno,
      }).eq('negocio_id', AppConfig.negocioId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuracion guardada con exito")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al guardar: $e")),
      );
    }
  }

  Future<void> _seleccionarHora(BuildContext context, bool esPrimerTurno, bool esInicio) async {
    final inicial = esPrimerTurno 
        ? (esInicio ? _hInicioAM : _hFinAM) 
        : (esInicio ? _hInicioPM : _hFinPM);
    
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: inicial);
    
    if (picked != null) {
      setState(() {
        if (esPrimerTurno) {
          if (esInicio) _hInicioAM = picked; else _hFinAM = picked;
        } else {
          if (esInicio) _hInicioPM = picked; else _hFinPM = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Horarios Laborales")),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Primer Turno", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.colorPrimario)),
                ListTile(
                  title: const Text("Hora de Apertura"),
                  trailing: Text(_hInicioAM.format(context)),
                  onTap: () => _seleccionarHora(context, true, true),
                ),
                ListTile(
                  title: const Text("Inicio de Almuerzo"),
                  trailing: Text(_hFinAM.format(context)),
                  onTap: () => _seleccionarHora(context, true, false),
                ),
                const Divider(),
                SwitchListTile(
                  title: const Text("¿Trabaja por la tarde?"),
                  subtitle: const Text("Activa si abre despues de almorzar"),
                  value: _almuerzoActivo,
                  activeColor: AppConfig.colorPrimario,
                  onChanged: (val) => setState(() => _almuerzoActivo = val),
                ),
                if (_almuerzoActivo) ...[
                  const Text("Segundo Turno", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConfig.colorPrimario)),
                  ListTile(
                    title: const Text("Regreso de Almuerzo"),
                    trailing: Text(_hInicioPM.format(context)),
                    onTap: () => _seleccionarHora(context, false, true),
                  ),
                  ListTile(
                    title: const Text("Hora de Cierre"),
                    trailing: Text(_hFinPM.format(context)),
                    onTap: () => _seleccionarHora(context, false, false),
                  ),
                ],
                const Divider(),
                const Text("Duracion de Citas", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Slider(
                  value: _duracionTurno.toDouble(),
                  min: 15, max: 120, divisions: 7,
                  label: "$_duracionTurno min",
                  activeColor: AppConfig.colorPrimario,
                  onChanged: (val) => setState(() => _duracionTurno = val.toInt()),
                ),
                Center(child: Text("Cada turno dura: $_duracionTurno minutos")),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario),
                    onPressed: _guardar,
                    child: const Text("GUARDAR CONFIGURACION", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
    );
  }
}