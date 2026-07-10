import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class CapsuleRepo {
  Future<int> add(TimeCapsule c) async {
    final db = await AppDb.instance;
    final id = await db.insert('time_capsules', c.toMap());
    await _reschedule(TimeCapsule(
        id: id,
        message: c.message,
        openDate: c.openDate,
        createdAt: c.createdAt,
        opened: c.opened));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('time_capsules', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.capsuleNotifId(id));
  }

  Future<void> markOpened(int id) async {
    final db = await AppDb.instance;
    await db.update('time_capsules', {'opened': 1},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<TimeCapsule>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('time_capsules', orderBy: 'open_date');
    return rows.map(TimeCapsule.fromMap).toList();
  }

  Future<void> rescheduleAll() async {
    for (final c in await all()) {
      await _reschedule(c);
    }
  }

  Future<void> _reschedule(TimeCapsule c) async {
    if (c.id == null || c.opened) return;
    await Notifications.cancel(Notifications.capsuleNotifId(c.id!));
    final open = DateTime.tryParse(c.openDate);
    if (open == null) return;
    final when = DateTime(open.year, open.month, open.day, 10);
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.capsuleNotifId(c.id!),
      title: tr('كبسولة زمنية اتفتحت 🎁', 'A time capsule opened 🎁'),
      body: tr('فيه رسالة كتبتها لنفسك النهارده — افتحها',
          'A message you wrote to yourself is ready — open it'),
      when: when,
    );
  }
}
