import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config.dart';

class OfflineService {
  static const String _boxName = 'tuturno_queue';
  static const String _notifiedBox = 'tuturno_notified';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
    await Hive.openBox(_notifiedBox);
    // box for permanently failed items
    if (!Hive.isBoxOpen('tuturno_failed')) await Hive.openBox('tuturno_failed');
    // start listening to connectivity to sync when online
    Connectivity().onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncQueue();
      }
    });
  }

  static Box _box() => Hive.box(_boxName);
  static Box _notified() => Hive.box(_notifiedBox);

  static Future<void> enqueueCita(Map<String, dynamic> cita) async {
    final box = _box();
    final key = DateTime.now().millisecondsSinceEpoch.toString();
    final item = {
      'payload': cita,
      'attempts': 0,
      'lastAttempt': null,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put(key, item);
  }

  static Future<void> syncQueue() async {
    final box = _box();
    if (box.isEmpty) return;

    final client = Supabase.instance.client;
    final now = DateTime.now();
    final keys = box.keys.toList();
    for (var k in keys) {
      try {
        final stored = Map<String, dynamic>.from(box.get(k));
        final payload = Map<String, dynamic>.from(stored['payload']);
        int attempts = stored['attempts'] ?? 0;
        final lastAttempt = stored['lastAttempt'] != null ? DateTime.parse(stored['lastAttempt']) : null;

        // Exponential backoff: wait 2^attempts minutes since lastAttempt
        if (lastAttempt != null) {
          final wait = Duration(minutes: (1 << attempts));
          if (now.difference(lastAttempt) < wait) continue;
        }

        await client.from('citas').insert({
          'negocio_id': payload['negocio_id'],
          'cliente_id': payload['cliente_id'],
          'servicio_id': payload['servicio_id'],
          'fecha_hora': payload['fecha_hora'],
        });

        await box.delete(k);
      } catch (e) {
        // update attempts and lastAttempt
        try {
          final stored = Map<String, dynamic>.from(box.get(k));
          stored['attempts'] = (stored['attempts'] ?? 0) + 1;
          stored['lastAttempt'] = DateTime.now().toIso8601String();
          await box.put(k, stored);

          // if attempts exceed threshold, move to failed box
          final attemptsNow = stored['attempts'] as int;
          if (attemptsNow >= 6) {
            try {
              final failedBox = Hive.box('tuturno_failed');
              await failedBox.put(k, stored);
              await box.delete(k);
            } catch (_) {}
          }
        } catch (_) {}
      }
    }
  }

  // Notified ids helpers to avoid duplicate local notifications
  static Future<bool> wasNotified(String id) async {
    final b = _notified();
    return b.get(id) == true;
  }

  static Future<void> markNotified(String id) async {
    final b = _notified();
    await b.put(id, true);
  }
}
