import '../core/db.dart';
import '../models/models.dart';

/// قائمة الأمنيات — حاجات عايز تشتريها بأولوية وسعر.
class WishlistRepo {
  Future<List<WishItem>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('wishlist',
        orderBy: 'bought, priority DESC, id DESC');
    return rows.map(WishItem.fromMap).toList();
  }

  Future<double> pendingTotal() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
        'SELECT COALESCE(SUM(price),0) t FROM wishlist WHERE bought = 0');
    return (r.first['t'] as num).toDouble();
  }

  Future<int> save(WishItem w) async {
    final db = await AppDb.instance;
    if (w.id == null) return db.insert('wishlist', w.toMap());
    await db.update('wishlist', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
    return w.id!;
  }

  Future<void> setBought(int id, bool bought) async {
    final db = await AppDb.instance;
    await db.update('wishlist', {'bought': bought ? 1 : 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('wishlist', where: 'id = ?', whereArgs: [id]);
  }
}
