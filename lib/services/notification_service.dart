import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:supabase/supabase.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../config.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // inicializar Hive en el isolate de background para deduplicacion
      try {
        await Hive.initFlutter();
        if (!Hive.isBoxOpen('tuturno_notified')) await Hive.openBox('tuturno_notified');
      } catch (_) {}

      final client = SupabaseClient(AppConfig.supabaseUrl, AppConfig.supabaseKey);

      final ahoraUtc = DateTime.now().toUtc();
      final desde = ahoraUtc.subtract(const Duration(minutes: 15));

      final res = await client
          .from('citas')
          .select('id, fecha_hora, created_at, creado_en')
          .eq('negocio_id', AppConfig.negocioId)
          .neq('estado', 'cancelada');

      final listRes = res as List;
      if (listRes.isNotEmpty) {
        final nuevos = listRes.where((item) {
          try {
            final ca = item['created_at'];
            final ce = item['creado_en'];
            DateTime? fechaCreado;
            if (ca != null) fechaCreado = DateTime.parse(ca).toUtc();
            if (fechaCreado == null && ce != null) fechaCreado = DateTime.parse(ce).toUtc();
            if (fechaCreado == null) return false;
            return fechaCreado.isAfter(desde);
          } catch (_) {
            return false;
          }
        }).toList();

        if (nuevos.isNotEmpty) {
          final fln = FlutterLocalNotificationsPlugin();
          const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
          const initSettings = InitializationSettings(android: androidInit);
          await fln.initialize(initSettings);

          final Box? notifiedBox = Hive.isBoxOpen('tuturno_notified') ? Hive.box('tuturno_notified') : null;

          for (var item in nuevos) {
            final id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
            final already = notifiedBox?.get(id) == true;
            if (already) continue;

            final nid = DateTime.now().millisecondsSinceEpoch ~/ 1000;
            await fln.show(
              nid,
              'Nueva cita',
              'Se registro una nueva cita',
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'tuturno_channel',
                  'TuTurno',
                  importance: Importance.max,
                  priority: Priority.high,
                ),
              ),
            );

            try {
              await notifiedBox?.put(id, true);
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      // Ignorar errores en el callback de background
    }

    return Future.value(true);
  });
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

  static Future<void> inicializar() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _fln.initialize(initSettings);

    // Nota: solicitar permisos en Android 13+ requiere manejo via Permission API
    // No llamamos a un metodo inexistente en el plugin aqui.

    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);

    try {
      await Workmanager().registerPeriodicTask(
        'tuturno_check_citas',
        'checkCitas',
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingWorkPolicy.keep,
        initialDelay: const Duration(minutes: 1),
      );
    } catch (_) {}
  }

  static Future<void> mostrarNotificacion({required int id, required String titulo, required String cuerpo}) async {
    await _fln.show(
      id,
      titulo,
      cuerpo,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'tuturno_channel',
          'TuTurno',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }
}