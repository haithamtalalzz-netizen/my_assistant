import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';

class QuitRepo {
  Future<int> add(QuitCounter c) async {
    final db = await AppDb.instance;
    return db.insert('quit_counters', c.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('quit_counters', where: 'id = ?', whereArgs: [id]);
  }

  /// إعادة العدّاد لليوم (ابتديت من جديد).
  Future<void> reset(int id, {DateTime? now}) async {
    final db = await AppDb.instance;
    await db.update('quit_counters', {'start_date': dayKey(now ?? DateTime.now())},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<QuitCounter>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('quit_counters', orderBy: 'start_date');
    return rows.map(QuitCounter.fromMap).toList();
  }
}
