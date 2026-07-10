import '../core/db.dart';
import '../models/models.dart';

class BodyProgressRepo {
  Future<int> add(BodyProgress b) async {
    final db = await AppDb.instance;
    return db.insert('body_progress', b.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('body_progress', where: 'id = ?', whereArgs: [id]);
  }

  /// كل السجلات — الأحدث أولًا.
  Future<List<BodyProgress>> all() async {
    final db = await AppDb.instance;
    final rows =
        await db.query('body_progress', orderBy: 'day DESC, id DESC');
    return rows.map(BodyProgress.fromMap).toList();
  }
}
