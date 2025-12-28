class Perfil {
  final String id;
  final String negocioId;
  final String nombre;
  final String rol;

  Perfil({
    required this.id,
    required this.negocioId,
    required this.nombre,
    required this.rol,
  });

  // Convertir de formato Supabase (JSON) a objeto de Flutter
  factory Perfil.fromMap(Map<String, dynamic> map) {
    return Perfil(
      id: map['id'],
      negocioId: map['negocio_id'],
      nombre: map['nombre'],
      rol: map['rol'],
    );
  }
}