import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import 'reserva_screen.dart';

class HomeCliente extends StatefulWidget {
  const HomeCliente({super.key});

  @override
  State<HomeCliente> createState() => _HomeClienteState();
}

class _HomeClienteState extends State<HomeCliente> {
  final _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _servicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    try {
      final data = await _supabaseService.getServicios();
      setState(() {
        _servicios = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TuTurno"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppConfig.colorPrimario),
            onPressed: () => Navigator.pushNamed(context, '/mis_citas'),
            tooltip: "Mis Turnos",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.cerrarSesion();
              if (mounted) Navigator.pushReplacementNamed(context, '/auth');
            },
          ),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "¡Hola de nuevo!",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Text("¿Qué servicio necesitas hoy?", 
                    style: TextStyle(color: Colors.grey)),
                  
                  const SizedBox(height: 30),

                  // SECCIÓN: SERVICIOS
                  const Text("Nuestros Servicios", 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _servicios.length,
                    itemBuilder: (context, index) {
                      final servicio = _servicios[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 15),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          title: Text(servicio['nombre'], 
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${servicio['duracion_minutos']} min - \$${servicio['precio']}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 15, color: AppConfig.colorPrimario),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReservaScreen(servicio: servicio),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // SECCIÓN: LISTA DE ESPERA
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white24)
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.hourglass_empty, color: Colors.amber, size: 40),
                        const SizedBox(height: 10),
                        const Text(
                          "¿No hay turnos disponibles?",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          "Únete a la lista de espera y te avisaremos si alguien cancela.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: () async {
                            try {
                              await _supabaseService.unirseAListaEspera();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("¡Te has unido a la lista de espera!")),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Ya estás en la lista")),
                                );
                              }
                            }
                          },
                          child: const Text("UNIRME AHORA"),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}