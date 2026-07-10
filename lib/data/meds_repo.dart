import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite/sqflite.dart';

import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class MedsRepo {
  /// أقصى عدد جرعات لليوم الواحد — مربوط بنطاق معرفات الإشعارات.
  static const int maxSlots = 10;

  Future<List<Medication>> all({bool activeOnly = false}) async {
    final db = await AppDb.instance;
    final rows = await db.query('medications',
        where: activeOnly ? 'active = 1' : null, orderBy: 'id');
    return rows.map(Medication.fromMap).toList();
  }

  Future<int> save(Medication m) async {
    final db = await AppDb.instance;
    final int id;
    if (m.id == null) {
      id = await db.insert('medications', m.toMap());
    } else {
      id = m.id!;
      await db.update('medications', m.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _cancelSlots(id);
    if (m.active) await _scheduleSlots(id, m);
    return id;
  }

  Future<void> setActive(int id, bool active) async {
    final db = await AppDb.instance;
    await db.update('medications', {'active': active ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    await _cancelSlots(id);
    if (active) {
      final rows =
          await db.query('medications', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) await _scheduleSlots(id, Medication.fromMap(rows.first));
    }
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('medications', where: 'id = ?', whereArgs: [id]);
    await db.delete('med_logs', where: 'med_id = ?', whereArgs: [id]);
    await _cancelSlots(id);
  }

  /// الجرعات المتاخدة في يوم معين كمفاتيح "medId|HH:mm".
  Future<Set<String>> takenOn(String day) async {
    final db = await AppDb.instance;
    final rows = await db.query('med_logs', where: 'day = ?', whereArgs: [day]);
    return rows.map((r) => '${r['med_id']}|${r['time_slot']}').toSet();
  }

  Future<void> setTaken(int medId, String day, String slot, bool taken) async {
    final db = await AppDb.instance;
    if (taken) {
      await db.insert(
          'med_logs', {'med_id': medId, 'day': day, 'time_slot': slot},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('med_logs',
          where: 'med_id = ? AND day = ? AND time_slot = ?',
          whereArgs: [medId, day, slot]);
    }
  }

  /// كورسات الدوا اللي خلصت مدتها بتتوقف لوحدها + إشعار فوري.
  Future<void> deactivateExpiredCourses() async {
    final today = DateTime.now();
    for (final m in await all(activeOnly: true)) {
      final left = m.daysLeft(today);
      if (left != null && left <= 0) {
        await setActive(m.id!, false);
        await Notifications.showNow(
          id: 940000 + m.id!,
          title: tr('كورس الدوا خلص', 'Medication course ended'),
          body: tr(
              '«${m.name}» وصل لآخر يوم في الكورس — وقفنا تذكيراته تلقائيًا',
              '"${m.name}" reached its last day — we stopped its reminders automatically'),
        );
      }
    }
  }

  /// بعد الاستعادة من نسخة احتياطية: إعادة جدولة تنبيهات الأدوية النشطة.
  Future<void> rescheduleAll() async {
    for (final m in await all()) {
      await _cancelSlots(m.id!);
      if (m.active) await _scheduleSlots(m.id!, m);
    }
  }

  Future<void> _scheduleSlots(int id, Medication m) async {
    for (var i = 0; i < m.times.length && i < maxSlots; i++) {
      final parts = m.times[i].split(':');
      await Notifications.scheduleDaily(
        id: Notifications.medNotifId(id, i),
        title: tr('دواء: ${m.name}', 'Medication: ${m.name}'),
        body: m.dosage.isEmpty
            ? tr('وقت الجرعة', 'Dose time')
            : tr('الجرعة: ${m.dosage}', 'Dose: ${m.dosage}'),
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        payload: 'med|$id|${m.times[i]}',
        actions: [
          AndroidNotificationAction('med_taken', tr('اتاخد ✓', 'Taken ✓'),
              showsUserInterface: false, cancelNotification: true),
        ],
      );
    }
  }

  Future<void> _cancelSlots(int id) async {
    for (var i = 0; i < maxSlots; i++) {
      await Notifications.cancel(Notifications.medNotifId(id, i));
    }
  }
}
