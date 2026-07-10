import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class AppointmentsRepo {
  Future<List<Appointment>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('appointments', orderBy: 'when_at');
    return rows.map(Appointment.fromMap).toList();
  }

  /// مواعيد يوم معين اللي لسه ماتمتش — لشاشة اليوم.
  Future<List<Appointment>> forDay(DateTime day) async {
    final db = await AppDb.instance;
    final rows = await db.query('appointments',
        where: 'when_at LIKE ? AND done = 0',
        whereArgs: ['${dayKey(day)}%'],
        orderBy: 'when_at');
    return rows.map(Appointment.fromMap).toList();
  }

  /// حفظ (إضافة أو تعديل) + إعادة جدولة التنبيه.
  /// تعديل الميعاد لوقت أبعد بيتحسب "تأجيل" — لكاشف التسويف.
  Future<int> save(Appointment a) async {
    final db = await AppDb.instance;
    final int id;
    if (a.id == null) {
      id = await db.insert('appointments', a.toMap());
    } else {
      id = a.id!;
      final map = a.toMap();
      final oldRows =
          await db.query('appointments', where: 'id = ?', whereArgs: [id]);
      if (oldRows.isNotEmpty) {
        final old = Appointment.fromMap(oldRows.first);
        var count = old.postponeCount;
        if (a.when.isAfter(old.when)) count++;
        map['postpone_count'] = count;
      }
      await db.update('appointments', map, where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id);
    return id;
  }

  /// المواعيد اللي اتأجلت [minTimes] مرات أو أكتر ولسه ماتمتش.
  Future<List<Appointment>> chronicallyPostponed({int minTimes = 3}) async {
    final db = await AppDb.instance;
    final rows = await db.query('appointments',
        where: 'postpone_count >= ? AND done = 0',
        whereArgs: [minTimes],
        orderBy: 'postpone_count DESC');
    return rows.map(Appointment.fromMap).toList();
  }

  /// بعد الاستعادة من نسخة احتياطية: إعادة جدولة كل التنبيهات.
  Future<void> rescheduleAll() async {
    final db = await AppDb.instance;
    final rows = await db.query('appointments', where: 'done = 0');
    for (final r in rows) {
      await _reschedule(r['id'] as int);
    }
  }

  Future<void> setDone(int id, bool done) async {
    final db = await AppDb.instance;
    // موعد متكرر اتعمله «تم» → ننقله للمرة الجاية بدل ما نقفله.
    if (done) {
      final rows =
          await db.query('appointments', where: 'id = ?', whereArgs: [id]);
      if (rows.isNotEmpty) {
        final a = Appointment.fromMap(rows.first);
        if (a.isRecurring) {
          await db.update(
              'appointments',
              {
                'when_at': a.nextOccurrence().toIso8601String(),
                'done': 0,
                'postpone_count': 0,
              },
              where: 'id = ?',
              whereArgs: [id]);
          await _reschedule(id);
          return;
        }
      }
    }
    await db.update('appointments', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
    await _reschedule(id);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('appointments', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.apptNotifId(id));
  }

  Future<void> _reschedule(int id) async {
    final db = await AppDb.instance;
    await Notifications.cancel(Notifications.apptNotifId(id));
    await Notifications.cancel(Notifications.leaveNotifId(id));
    final rows =
        await db.query('appointments', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final a = Appointment.fromMap(rows.first);
    if (a.done) return;
    await Notifications.scheduleOnce(
      id: Notifications.apptNotifId(id),
      title: tr('موعد: ${a.title}', 'Appointment: ${a.title}'),
      body: tr('${arFullDate(a.when)} — الساعة ${arTime(a.when)}',
          '${arFullDate(a.when)} — at ${arTime(a.when)}'),
      when: a.when.subtract(Duration(minutes: a.remindBeforeMin)),
      payload: 'appt|$id',
      actions: [
        AndroidNotificationAction('appt_done', tr('تم ✓', 'Done ✓'),
            showsUserInterface: false, cancelNotification: true),
      ],
    );
    // «اتحرك دلوقتي» — تنبيه وقت التحرك (الموعد − مدة المشوار).
    if (a.travelMin > 0) {
      final leaveAt = a.when.subtract(Duration(minutes: a.travelMin));
      await Notifications.scheduleOnce(
        id: Notifications.leaveNotifId(id),
        title: tr('اتحرك دلوقتي 🚗', 'Time to leave 🚗'),
        body: tr('لازم تتحرك دلوقتي عشان تلحق «${a.title}» الساعة ${arTime(a.when)}',
            'Leave now to make "${a.title}" at ${arTime(a.when)}'),
        when: leaveAt,
      );
    }
  }
}
