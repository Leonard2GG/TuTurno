import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../config.dart';

class GestionServiciosScreen extends StatefulWidget {
  const GestionServiciosScreen({super.key});

  @override
  State<GestionServiciosScreen> createState() => _GestionServiciosScreenState();
}

class _GestionServiciosScreenState extends State<GestionServiciosScreen> {
  final _service = SupabaseService();
  List<Map<String, dynamic>> _servicios = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarServicios();
  }

  Future<void> _cargarServicios() async {
    final data = await _service.getServicios();
    setState(() {
      _servicios = data;
      _cargando = false;
    });
  }

  void _mostrarFormulario({Map<String, dynamic>? servicio}) {
    final nombreCtrl = TextEditingController(text: servicio?['nombre']);
    final precioCtrl = TextEditingController(text: servicio?['precio']?.toString());
    final duracionCtrl = TextEditingController(text: servicio?['duracion_minutos']?.toString() ?? "30");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(servicio == null ? "Nuevo Servicio" : "Editar Servicio"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: "Nombre (ej: Corte)")),
            TextField(controller: precioCtrl, decoration: const InputDecoration(labelText: "Precio"), keyboardType: TextInputType.number),
            TextField(controller: duracionCtrl, decoration: const InputDecoration(labelText: "Duración (minutos)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          ElevatedButton(
            onPressed: () async {
              if (servicio == null) {
                await _service.crearServicio(
                  nombre: nombreCtrl.text,
                  precio: double.parse(precioCtrl.text),
                  duracion: int.parse(duracionCtrl.text),
                );
              } else {
                await _service.editarServicio(
                  id: servicio['id'],
                  nombre: nombreCtrl.text,
                  precio: double.parse(precioCtrl.text),
                  duracion: int.parse(duracionCtrl.text),
                );
              }
              Navigator.pop(context);
              _cargarServicios();
            },
            child: const Text("GUARDAR"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mis Servicios")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConfig.colorPrimario,
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: _cargando 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _servicios.length,
            itemBuilder: (context, i) {
              final s = _servicios[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                child: ListTile(
                  title: Text(s['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${s['duracion_minutos']} min - \$${s['precio']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _mostrarFormulario(servicio: s)),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _service.eliminarServicio(s['id']);
                          _cargarServicios();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }
}