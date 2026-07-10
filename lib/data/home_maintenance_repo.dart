import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

/// اقتراحات جاهزة لصيانة البيت — (الاسم، كل كام شهر).
const List<(String, int)> kMaintenanceSuggestions = [
  ('شمعة فلتر المياه', 6),
  ('غسيل التكييف', 6),
  ('صيانة السخان', 12),
  ('تنضيف خزان المياه', 6),
  ('صيانة الغسالة', 12),
  ('فحص أسطوانة الغاز', 12),
  ('صيانة المصعد', 3),
];

class HomeMaintenanceRepo {
  Future<List<HomeMaintenance>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('home_maintenance');
    final list = rows.map(HomeMaintenance.fromMap).toList();
    list.sort((a, b) => a.nextDue().compareTo(b.nextDue()));
    return list;
  }

  Future<List<HomeMaintenance>> due(DateTime now) async =>
      [for (final m in await all()) if (m.isDue(now)) m];

  Future<int> save(HomeMaintenance m) async {
    final db = await AppDb.instance;
    final int id;
    if (m.id == null) {
      id = await db.insert('home_maintenance', m.toMap());
    } else {
      id = m.id!;
      await db.update('home_maintenance', m.toMap(),
          where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(HomeMaintenance(
      id: id,
      name: m.name,
      intervalMonths: m.intervalMonths,
      lastDone: m.lastDone,
      notes: m.notes,
    ));
    return id;
  }

  /// «اتعملت النهارده» = صفّر العداد من تاريخ النهارده.
  Future<void> markDone(int id) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('home_maintenance', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final m = HomeMaintenance.fromMap(rows.first);
    await save(HomeMaintenance(
      id: id,
      name: m.name,
      intervalMonths: m.intervalMonths,
      lastDone: dayKey(DateTime.now()),
      notes: m.notes,
    ));
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('home_maintenance', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.homeMaintNotifId(id));
  }

  Future<void> rescheduleAll() async {
    for (final m in await all()) {
      await _reschedule(m);
    }
  }

  Future<void> _reschedule(HomeMaintenance m) async {
    await Notifications.cancel(Notifications.homeMaintNotifId(m.id!));
    final due = m.nextDue();
    await Notifications.scheduleOnce(
      id: Notifications.homeMaintNotifId(m.id!),
      title: tr('صيانة البيت: ${m.name}', 'Home maintenance: ${m.name}'),
      body: tr('ميعادها جه — كل ${arNum(m.intervalMonths)} شهور',
          'It\'s due — every ${arNum(m.intervalMonths)} months'),
      when: DateTime(due.year, due.month, due.day, 10),
    );
  }
}
