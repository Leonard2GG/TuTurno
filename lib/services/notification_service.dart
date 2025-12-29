import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class NotificationService {
  static final _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _notifications.initialize(settings);
    
    // Inicializar Workmanager para tareas de fondo
    Workmanager().initialize(callbackDispatcher);
  }

  static void mostrarNotificacion({required int id, required String titulo, required String cuerpo}) {
    _notifications.show(
      id,
      titulo,
      cuerpo,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'canal_citas',
          'Notificaciones de Citas',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        ),
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Usamos las credenciales centralizadas de AppConfig
    final client = SupabaseClient(AppConfig.supabaseUrl, AppConfig.supabaseKey);
    
    try {
      final ahora = DateTime.now().toUtc();
      // Buscamos citas creadas en los últimos 16 minutos (margen de seguridad)
      final hace15Min = ahora.subtract(const Duration(minutes: 16)).toIso8601String();

      final List<dynamic> data = await client
          .from('citas')
          .select()
          .eq('negocio_id', AppConfig.negocioId)
          .gte('creado_en', hace15Min);

      if (data.isNotEmpty) {
        NotificationService.mostrarNotificacion(
          id: 99,
          titulo: "Nuevo turno reservado",
          cuerpo: "Tienes una nueva cita en tu agenda.",
        );
      }
    } catch (e) {
      print("Error en Workmanager: $e");
    }
    return Future.value(true);
  });
}