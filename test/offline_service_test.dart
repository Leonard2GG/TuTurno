import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as p;
import 'package:tuturno/services/offline_service.dart';

void main() {
  group('OfflineService', () {
    late Directory tmpDir;

    setUp(() async {
      tmpDir = await Directory.systemTemp.createTemp('tuturno_test_');
      Hive.init(tmpDir.path);
      await Hive.openBox('tuturno_queue');
      await Hive.openBox('tuturno_notified');
      await Hive.openBox('tuturno_failed');
    });

    tearDown(() async {
      await Hive.close();
      if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
    });

    test('enqueueCita stores item with attempts 0', () async {
      final cita = {
        'negocio_id': '000',
        'cliente_id': 'abc',
        'servicio_id': 'svc1',
        'fecha_hora': DateTime.now().toIso8601String(),
      };

      await OfflineService.enqueueCita(cita);

      final box = Hive.box('tuturno_queue');
      expect(box.isNotEmpty, true);

      final stored = Map<String, dynamic>.from(box.get(box.keys.first));
      expect(stored['attempts'], 0);
      expect(stored['payload']['cliente_id'], 'abc');
    });
  });
}
