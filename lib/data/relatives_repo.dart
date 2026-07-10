import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class RelativesRepo {
  Future<int> save(Relative r) async {
    final db = await AppDb.instance;
    final int id;
    if (r.id == null) {
      id = await db.insert('relatives', r.toMap());
    } else {
      id = r.id!;
      await db.update('relatives', r.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(Relative(
        id: id,
        name: r.name,
        phone: r.phone,
        intervalDays: r.intervalDays,
        lastContacted: r.lastContacted));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('relatives', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.relativeNotifId(id));
  }

  /// «اتصلت» — بيسجّل النهارده ويعيد جدولة المكالمة الجاية.
  Future<void> markContacted(Relative r, {DateTime? now}) async {
    final db = await AppDb.instance;
    await db.update(
        'relatives', {'last_contacted': dayKey(now ?? DateTime.now())},
        where: 'id = ?', whereArgs: [r.id]);
    final updated = Relative(
        id: r.id,
        name: r.name,
        phone: r.phone,
        intervalDays: r.intervalDays,
        lastContacted: dayKey(now ?? DateTime.now()));
    await _reschedule(updated);
  }

  Future<List<Relative>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('relatives', orderBy: 'last_contacted');
    return rows.map(Relative.fromMap).toList();
  }

  Future<List<Relative>> due(DateTime now) async {
    final all = await this.all();
    return [for (final r in all) if (r.isDue(now)) r];
  }

  Future<void> rescheduleAll() async {
    for (final r in await all()) {
      await _reschedule(r);
    }
  }

  Future<void> _reschedule(Relative r) async {
    if (r.id == null) return;
    await Notifications.cancel(Notifications.relativeNotifId(r.id!));
    final due = r.nextDue();
    final when = DateTime(due.year, due.month, due.day, 18);
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.relativeNotifId(r.id!),
      title: tr('صلة رحم', 'Keep in touch'),
      body: tr('بقالك فترة ما اتصلتش بـ ${r.name} — اطمن عليه',
          "It's been a while since you called ${r.name} — check on them"),
      when: when,
    );
  }
}
