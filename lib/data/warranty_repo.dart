import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class WarrantyRepo {
  Future<int> save(Warranty w) async {
    final db = await AppDb.instance;
    final int id;
    if (w.id == null) {
      id = await db.insert('warranties', w.toMap());
    } else {
      id = w.id!;
      await db.update('warranties', w.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(Warranty(
        id: id,
        itemName: w.itemName,
        purchaseDate: w.purchaseDate,
        warrantyMonths: w.warrantyMonths,
        photo: w.photo,
        notes: w.notes));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('warranties', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.warrantyNotifId(id));
  }

  Future<List<Warranty>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('warranties', orderBy: 'purchase_date DESC');
    return rows.map(Warranty.fromMap).toList();
  }

  Future<void> rescheduleAll() async {
    for (final w in await all()) {
      await _reschedule(w);
    }
  }

  Future<void> _reschedule(Warranty w) async {
    if (w.id == null) return;
    await Notifications.cancel(Notifications.warrantyNotifId(w.id!));
    final exp = w.expiry;
    // تذكير قبل انتهاء الضمان بـ ١٤ يوم.
    final when = DateTime(exp.year, exp.month, exp.day, 10)
        .subtract(const Duration(days: 14));
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.warrantyNotifId(w.id!),
      title: tr('ضمان قرب يخلص: ${w.itemName}',
          'Warranty expiring soon: ${w.itemName}'),
      body: tr('الضمان بينتهي ${arShortDate(exp)}',
          'Warranty ends ${arShortDate(exp)}'),
      when: when,
    );
  }
}
