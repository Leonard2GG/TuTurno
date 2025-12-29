import 'package:flutter/material.dart';
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
        title: const Text("BARBERIA TUTURNO"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MisCitasScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _service.cerrarSesion();
              Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : Column(
              children: [
                // Banner de Lista de Espera
                _buildEsperaBanner(),
                
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Nuestros Servicios",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: _servicios.isEmpty
                      ? const Center(child: Text("No hay servicios disponibles"))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          itemCount: _servicios.length,
                          itemBuilder: (context, i) {
                            final s = _servicios[i];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(15),
                                title: Text(s['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                subtitle: Text("${s['duracion_minutos']} min | \$${s['precio']}"),
                                trailing: ElevatedButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ReservaScreen(servicio: s),
                                    ),
                                  ),
                                  child: const Text("RESERVAR"),
                                ),
                              ),
                            );
                          },
                        ),
                ),
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
        color: AppConfig.colorPrimario.withOpacity(0.1),
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