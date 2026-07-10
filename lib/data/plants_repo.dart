import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class PlantsRepo {
  Future<int> save(Plant p) async {
    final db = await AppDb.instance;
    final int id;
    if (p.id == null) {
      id = await db.insert('plants', p.toMap());
    } else {
      id = p.id!;
      await db.update('plants', p.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(Plant(
      id: id,
      name: p.name,
      location: p.location,
      waterIntervalDays: p.waterIntervalDays,
      lastWatered: p.lastWatered,
      note: p.note,
    ));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('plants', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.plantNotifId(id));
  }

  /// «سقيت» — بيسجّل النهارده ويعيد جدولة الري الجاي.
  Future<void> markWatered(Plant p, {DateTime? now}) async {
    final db = await AppDb.instance;
    final today = dayKey(now ?? DateTime.now());
    await db.update('plants', {'last_watered': today},
        where: 'id = ?', whereArgs: [p.id]);
    await _reschedule(Plant(
      id: p.id,
      name: p.name,
      location: p.location,
      waterIntervalDays: p.waterIntervalDays,
      lastWatered: today,
      note: p.note,
    ));
  }

  Future<List<Plant>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('plants', orderBy: 'last_watered');
    return rows.map(Plant.fromMap).toList();
  }

  Future<List<Plant>> due(DateTime now) async {
    final all = await this.all();
    return [for (final p in all) if (p.isDue(now)) p];
  }

  Future<void> rescheduleAll() async {
    for (final p in await all()) {
      await _reschedule(p);
    }
  }

  Future<void> _reschedule(Plant p) async {
    if (p.id == null) return;
    await Notifications.cancel(Notifications.plantNotifId(p.id!));
    final due = p.nextWater();
    final when = DateTime(due.year, due.month, due.day, 8);
    if (when.isBefore(DateTime.now())) return;
    final where = p.location.isEmpty ? '' : ' (${p.location})';
    await Notifications.scheduleOnce(
      id: Notifications.plantNotifId(p.id!),
      title: tr('اسقي النبات 🪴', 'Water your plant 🪴'),
      body: tr('${p.name}$where محتاجة مياه النهارده',
          '${p.name}$where needs water today'),
      when: when,
    );
  }
}
