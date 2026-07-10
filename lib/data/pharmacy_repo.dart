import '../core/ar.dart';
import '../core/db.dart';
import '../core/l10n.dart';
import '../core/notifications.dart';
import '../models/models.dart';

class PharmacyRepo {
  Future<int> save(PharmacyItem item) async {
    final db = await AppDb.instance;
    final int id;
    if (item.id == null) {
      id = await db.insert('home_pharmacy', item.toMap());
    } else {
      id = item.id!;
      await db.update('home_pharmacy', item.toMap(),
          where: 'id = ?', whereArgs: [id]);
    }
    await _reschedule(PharmacyItem(
        id: id,
        name: item.name,
        quantity: item.quantity,
        expiry: item.expiry,
        notes: item.notes));
    return id;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('home_pharmacy', where: 'id = ?', whereArgs: [id]);
    await db.delete('pharmacy_batches', where: 'item_id = ?', whereArgs: [id]);
    await Notifications.cancel(Notifications.pharmacyNotifId(id));
  }

  // ---- الدفعات (كل كمية بصلاحية مستقلة) ----

  Future<List<PharmacyBatch>> batchesFor(int itemId) async {
    final db = await AppDb.instance;
    final rows = await db.query('pharmacy_batches',
        where: 'item_id = ?', whereArgs: [itemId], orderBy: 'expiry');
    return rows.map(PharmacyBatch.fromMap).toList();
  }

  /// يستبدل كل دفعات الصنف بالقائمة الجديدة + يحدّث إجمالي العدد وأقرب صلاحية.
  Future<void> replaceBatches(int itemId, List<PharmacyBatch> batches) async {
    final db = await AppDb.instance;
    await db.delete('pharmacy_batches', where: 'item_id = ?', whereArgs: [itemId]);
    for (final b in batches) {
      await db.insert('pharmacy_batches',
          PharmacyBatch(itemId: itemId, quantity: b.quantity, expiry: b.expiry)
              .toMap());
    }
    if (batches.isNotEmpty) {
      final totalQty = batches.fold<int>(0, (s, b) => s + b.quantity);
      final expiries = batches
          .map((b) => b.expiry)
          .whereType<String>()
          .toList()
        ..sort();
      final nearest = expiries.isEmpty ? null : expiries.first;
      await db.update('home_pharmacy',
          {'quantity': totalQty, 'expiry': nearest},
          where: 'id = ?', whereArgs: [itemId]);
      final rows =
          await db.query('home_pharmacy', where: 'id = ?', whereArgs: [itemId]);
      if (rows.isNotEmpty) await _reschedule(PharmacyItem.fromMap(rows.first));
    }
  }

  Future<List<PharmacyItem>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('home_pharmacy', orderBy: 'name');
    return rows.map(PharmacyItem.fromMap).toList();
  }

  /// بحث بالاسم — لـ «عندك بانادول؟».
  Future<List<PharmacyItem>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return all();
    final db = await AppDb.instance;
    final rows = await db.query('home_pharmacy',
        where: 'name LIKE ?', whereArgs: ['%$q%'], orderBy: 'name');
    return rows.map(PharmacyItem.fromMap).toList();
  }

  Future<void> rescheduleAll() async {
    for (final item in await all()) {
      await _reschedule(item);
    }
  }

  Future<void> _reschedule(PharmacyItem item) async {
    if (item.id == null) return;
    await Notifications.cancel(Notifications.pharmacyNotifId(item.id!));
    if (item.expiry == null) return;
    final exp = DateTime.tryParse(item.expiry!);
    if (exp == null) return;
    // تذكير قبل الانتهاء بـ ٣٠ يوم.
    final when = DateTime(exp.year, exp.month, exp.day, 10)
        .subtract(const Duration(days: 30));
    if (when.isBefore(DateTime.now())) return;
    await Notifications.scheduleOnce(
      id: Notifications.pharmacyNotifId(item.id!),
      title: tr('دوا قرب يخلص صلاحية: ${item.name}',
          'Medicine expiring soon: ${item.name}'),
      body: tr('ينتهي ${arShortDate(exp)} — استبدله',
          'Expires ${arShortDate(exp)} — replace it'),
      when: when,
    );
  }
}
