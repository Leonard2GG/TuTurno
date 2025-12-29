import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';
import 'reserva_screen.dart';
import 'mis_citas_screen.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _servicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    try {
      final data = await _service.getServicios();
      setState(() {
        _servicios = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
      debugPrint("Error al cargar servicios: $e");
    }
  }

  Future<void> _unirseEspera() async {
    try {
      await _service.unirseAListaEspera();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Te has unido a la lista de espera")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ya estas en la lista o hubo un error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("TuTurno", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppConfig.colorPrimario)),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MisCitasScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () async { await _service.cerrarSesion(); Navigator.pushReplacementNamed(context, '/auth'); }),
        ],
      ),
      body: _cargando ? const Center(child: CircularProgressIndicator()) : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(child: Text('Nuestros Servicios', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600))),
                ElevatedButton.icon(
                  onPressed: _unirseEspera,
                  icon: const Icon(Icons.people),
                  label: const Text('Lista de espera'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario, foregroundColor: Colors.black),
                )
              ],
            ),
          ),
          Expanded(
            child: _servicios.isEmpty ? Center(child: Text('No hay servicios disponibles', style: GoogleFonts.poppins())) : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.85, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: _servicios.length,
              itemBuilder: (context, i) {
                final s = _servicios[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReservaScreen(servicio: s))),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConfig.colorPrimario.withAlpha((0.2 * 255).round())),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Center(child: Icon(Icons.content_cut, size: 48, color: AppConfig.colorPrimario))),
                        const SizedBox(height: 8),
                        Text(s['nombre'], style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('${s['duracion_minutos']} min • \$${s['precio']}', style: GoogleFonts.poppins(color: Colors.white70)),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReservaScreen(servicio: s))),
                            style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: const Text('RESERVAR'),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildEsperaBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConfig.colorPrimario.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConfig.colorPrimario, width: 2),
      ),
      child: Column(
        children: [
          const Text(
            "¿No encuentras turno hoy?",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text("Unete a la lista de espera y te avisaremos"),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: _unirseEspera,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConfig.colorPrimario,
              foregroundColor: Colors.black,
            ),
            child: const Text("UNIRME A LA LISTA"),
          )
        ],
      ),
    );
  }
}