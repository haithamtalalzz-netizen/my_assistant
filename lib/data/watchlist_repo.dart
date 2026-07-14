import '../core/db.dart';
import '../models/models.dart';

/// قائمة المشاهدة — أفلام ومسلسلات بحالة (هتفرّجه/بتفرّج/اتفرجت).
class WatchlistRepo {
  Future<List<WatchItem>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('watchlist',
        orderBy: "CASE status WHEN 'watching' THEN 0 "
            "WHEN 'want' THEN 1 ELSE 2 END, id DESC");
    return rows.map(WatchItem.fromMap).toList();
  }

  Future<int> save(WatchItem w) async {
    final db = await AppDb.instance;
    if (w.id == null) return db.insert('watchlist', w.toMap());
    await db.update('watchlist', w.toMap(), where: 'id = ?', whereArgs: [w.id]);
    return w.id!;
  }

  Future<void> setStatus(int id, String status) async {
    final db = await AppDb.instance;
    await db.update('watchlist', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('watchlist', where: 'id = ?', whereArgs: [id]);
  }
}
