import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';

/// مفكرة الامتنان — تسجّل كل يوم حاجات إنت شاكرها.
class GratitudeRepo {
  Future<List<GratitudeEntry>> recent({int limit = 200}) async {
    final db = await AppDb.instance;
    final rows = await db.query('gratitude',
        orderBy: 'day DESC, id DESC', limit: limit);
    return rows.map(GratitudeEntry.fromMap).toList();
  }

  Future<int> add(String text, {DateTime? day}) async {
    final db = await AppDb.instance;
    return db.insert('gratitude', {
      'day': dayKey(day ?? DateTime.now()),
      'text': text,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('gratitude', where: 'id = ?', whereArgs: [id]);
  }

  /// عدد الأيام اللى سجّلت فيها امتنان.
  Future<int> daysCount() async {
    final db = await AppDb.instance;
    final r = await db
        .rawQuery('SELECT COUNT(DISTINCT day) c FROM gratitude');
    return (r.first['c'] as int?) ?? 0;
  }
}
