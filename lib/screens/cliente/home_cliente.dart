import 'package:flutter/material.dart';
import '../../config.dart';
import '../../services/supabase_service.dart';
import 'reserva_screen.dart';
import 'mis_citas_screen.dart'; // Nueva importación

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
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final data = await _supabaseService.getServicios();
      setState(() {
        _servicios = data;
        _cargando = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TUTURNO"),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month), // Botón para ver mis citas
            onPressed: () => Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const MisCitasScreen())
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _supabaseService.cerrarSesion();
              if (mounted) Navigator.pushReplacementNamed(context, '/auth');
            },
          )
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator(color: AppConfig.colorPrimario))
          : _servicios.isEmpty
              ? _buildPantallaVacia()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _servicios.length,
                  itemBuilder: (context, index) {
                    final servicio = _servicios[index];
                    return Card(
                      color: Colors.white.withAlpha(20),
                      margin: const EdgeInsets.only(bottom: 15),
                      child: ListTile(
                        title: Text(servicio['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${servicio['duracion_minutos']} min"),
                        trailing: Text("\$${servicio['precio']}", 
                          style: const TextStyle(color: AppConfig.colorPrimario, fontSize: 18)),
                        onTap: () => _mostrarAlertaReserva(servicio),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildPantallaVacia() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text("No hay servicios disponibles", style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text("Asegúrate de agregar servicios en Supabase", style: TextStyle(color: Colors.white54)),
          TextButton(onPressed: _cargarDatos, child: const Text("REINTENTAR"))
        ],
      ),
    );
  }

  void _mostrarAlertaReserva(Map<String, dynamic> servicio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppConfig.colorFondo,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        height: 200,
        child: Column(
          children: [
            Text("Reservar ${servicio['nombre']}", 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppConfig.colorPrimario),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservaScreen(servicio: servicio),
                    ),
                  );
                },
                child: const Text("CONTINUAR", style: TextStyle(color: Colors.black)),
              ),
            )
          ],
        ),
      ),
    );
  }
}