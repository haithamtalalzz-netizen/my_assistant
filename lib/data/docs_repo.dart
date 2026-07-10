import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class DocsRepo {
  Future<List<DocItem>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('documents',
        orderBy: 'CASE WHEN expiry IS NULL THEN 1 ELSE 0 END, expiry, id DESC');
    return rows.map(DocItem.fromMap).toList();
  }

  /// المستندات اللي هتنتهي خلال [days] يوم — وتشمل المنتهية بالفعل.
  Future<List<DocItem>> expiringSoon({int days = 30}) async {
    final db = await AppDb.instance;
    final limit = dayKey(DateTime.now().add(Duration(days: days)));
    final rows = await db.query('documents',
        where: 'expiry IS NOT NULL AND expiry <= ?',
        whereArgs: [limit],
        orderBy: 'expiry');
    return rows.map(DocItem.fromMap).toList();
  }

  Future<int> save(DocItem d) async {
    final db = await AppDb.instance;
    final int id;
    if (d.id == null) {
      id = await db.insert('documents', d.toMap());
    } else {
      id = d.id!;
      await db.update('documents', d.toMap(), where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(id, d);
    return id;
  }

  /// بعد الاستعادة من نسخة احتياطية: إعادة جدولة تنبيهات الانتهاء.
  Future<void> rescheduleAll() async {
    for (final d in await all()) {
      await _reschedule(d.id!, d);
    }
  }

  Future<void> _reschedule(int id, DocItem d) async {
    await Notifications.cancel(Notifications.docNotifId(id));
    if (d.expiry == null) return;
    final exp = DateTime.parse(d.expiry!);
    final remindAt = DateTime(exp.year, exp.month, exp.day, 9)
        .subtract(Duration(days: d.remindDays));
    await Notifications.scheduleOnce(
      id: Notifications.docNotifId(id),
      title: tr('مستند قرب يخلص: ${d.title}', 'Document expiring soon: ${d.title}'),
      body: tr('ينتهي يوم ${arShortDate(exp)} — جدده بدري',
          'Expires on ${arShortDate(exp)} — renew early'),
      when: remindAt,
    );
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('documents', where: 'id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.docNotifId(id));
  }
}
