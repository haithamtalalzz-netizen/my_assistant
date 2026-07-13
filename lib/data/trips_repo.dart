import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

const List<String> kTripItemKinds = ['packing', 'todo', 'booking'];

String tripItemKindLabel(String k) => switch (k) {
      'packing' => tr('شنطة', 'Packing'),
      'todo' => tr('مهام', 'To-do'),
      'booking' => tr('حجوزات', 'Bookings'),
      _ => k,
    };

/// السفر — رحلات + قوائم (تجهيز شنطة/مهام/حجوزات) + تنبيه قبل موعد الرحلة.
class TripsRepo {
  Future<List<Trip>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('trips', orderBy: 'start_day IS NULL, start_day');
    return rows.map(Trip.fromMap).toList();
  }

  Future<int> save(Trip t) async {
    final db = await AppDb.instance;
    final int id;
    if (t.id == null) {
      id = await db.insert('trips', t.toMap());
    } else {
      id = t.id!;
      await db.update('trips', t.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id, t);
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('trip_items', where: 'trip_id = ?', whereArgs: [id]);
    await db.delete('trips', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.tripNotifId(id));
  }

  Future<void> _reschedule(int id, Trip t) async {
    await Notifications.cancel(Notifications.tripNotifId(id));
    final s = t.start;
    if (s == null) return;
    final when = DateTime(s.year, s.month, s.day, 9)
        .subtract(const Duration(days: 3));
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.tripNotifId(id),
      title: tr('قربت رحلة ${t.title}', 'Trip soon: ${t.title}'),
      body: tr('باقى ٣ أيام — راجع قائمة التجهيز',
          '3 days left — check your packing list'),
      when: when,
    );
  }

  Future<void> rescheduleAll() async {
    for (final t in await all()) {
      if (t.id != null) await _reschedule(t.id!, t);
    }
  }

  // ---- عناصر الرحلة ----

  Future<List<TripItem>> items(int tripId) async {
    final db = await AppDb.instance;
    final rows = await db.query('trip_items',
        where: 'trip_id = ?', whereArgs: [tripId], orderBy: 'kind, sort, id');
    return rows.map(TripItem.fromMap).toList();
  }

  Future<int> addItem(int tripId, String kind, String text) async {
    final db = await AppDb.instance;
    final sort = (await items(tripId)).where((i) => i.kind == kind).length;
    return db.insert('trip_items',
        TripItem(tripId: tripId, kind: kind, text: text, sort: sort).toMap());
  }

  Future<void> toggleItem(int id, bool done) async {
    final db = await AppDb.instance;
    await db.update('trip_items', {'done': done ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteItem(int id) async {
    final db = await AppDb.instance;
    await db.delete('trip_items', where: 'id = ?', whereArgs: [id]);
  }
}
