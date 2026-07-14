import '../core/db.dart';
import '../models/models.dart';

/// تتبّع القراءة — كتب بتقدّم صفحات + حالة (بقرأه/خلصته/قائمة أمنيات).
class ReadingRepo {
  Future<List<Book>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('books',
        orderBy: "CASE status WHEN 'reading' THEN 0 "
            "WHEN 'wishlist' THEN 1 ELSE 2 END, id DESC");
    return rows.map(Book.fromMap).toList();
  }

  Future<int> save(Book b) async {
    final db = await AppDb.instance;
    if (b.id == null) return db.insert('books', b.toMap());
    await db.update('books', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
    return b.id!;
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /// يقدّم صفحات القراءة، ويعلّم «خلصته» عند بلوغ الإجمالى.
  Future<void> setPage(Book b, int page) async {
    final db = await AppDb.instance;
    final p = b.totalPages == 0 ? page : page.clamp(0, b.totalPages);
    final status =
        (b.totalPages > 0 && p >= b.totalPages) ? 'done' : (b.status == 'done' ? 'reading' : b.status);
    await db.update('books', {'current_page': p, 'status': status},
        where: 'id = ?', whereArgs: [b.id]);
  }

  Future<void> setStatus(int id, String status) async {
    final db = await AppDb.instance;
    await db.update('books', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  /// عدد الكتب المكتملة (لإحصائية سنوية).
  Future<int> finishedCount() async {
    final db = await AppDb.instance;
    final r = await db.rawQuery(
        "SELECT COUNT(*) c FROM books WHERE status = 'done'");
    return (r.first['c'] as int?) ?? 0;
  }
}
