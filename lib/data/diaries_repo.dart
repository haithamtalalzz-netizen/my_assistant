import '../core/db.dart';
import '../models/models.dart';

class DiariesRepo {
  Future<int> add(Diary d) async {
    final db = await AppDb.instance;
    return db.insert('diaries', d.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('diaries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Diary>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('diaries', orderBy: 'day DESC, id DESC');
    return rows.map(Diary.fromMap).toList();
  }
}
