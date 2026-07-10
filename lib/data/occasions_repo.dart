import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class OccasionsRepo {
  Future<List<Occasion>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('occasions');
    final list = rows.map(Occasion.fromMap).toList();
    final now = DateTime.now();
    list.sort((a, b) => a.nextOccurrence(now).compareTo(b.nextOccurrence(now)));
    return list;
  }

  Future<int> save(Occasion o) async {
    final db = await AppDb.instance;
    final int id;
    if (o.id == null) {
      id = await db.insert('occasions', o.toMap());
    } else {
      id = o.id!;
      await db.update('occasions', o.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await rescheduleAll();
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('occasions', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.occasionNotifId(id));
  }

  /// المناسبات اللي جوه نافذة التذكير بتاعتها دلوقتي — لملخص المدير.
  Future<List<Occasion>> upcomingWithinWindow(DateTime now) async {
    final result = <Occasion>[];
    for (final o in await all()) {
      final days =
          o.nextOccurrence(now).difference(dateOnly(now)).inDays;
      if (days <= o.remindDays) result.add(o);
    }
    return result;
  }

  /// إشعار واحد لكل مناسبة عند أقرب حدوث — بيتجدد مع كل فتحة للتطبيق.
  Future<void> rescheduleAll() async {
    final now = DateTime.now();
    for (final o in await all()) {
      await Notifications.cancel(Notifications.occasionNotifId(o.id!));
      final occurrence = o.nextOccurrence(now);
      final remindAt = DateTime(
              occurrence.year, occurrence.month, occurrence.day, 9)
          .subtract(Duration(days: o.remindDays));
      final label = o.person.isEmpty ? o.title : '${o.title} — ${o.person}';
      await Notifications.scheduleOnce(
        id: Notifications.occasionNotifId(o.id!),
        title: tr('مناسبة قريبة: $label', 'Occasion coming up: $label'),
        body: tr('يوم ${arShortDate(occurrence)} — جهز نفسك',
            'On ${arShortDate(occurrence)} — get ready'),
        when: remindAt,
      );
    }
  }
}
