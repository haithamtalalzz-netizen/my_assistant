import '../core/db.dart';
import '../models/models.dart';

/// جلسات النشاط بالـGPS (مشي/جري).
class ActivityRepo {
  Future<int> add(ActivitySession s) async {
    final db = await AppDb.instance;
    return db.insert('activity_sessions', s.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('activity_sessions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ActivitySession>> forDay(String day) async {
    final db = await AppDb.instance;
    final rows = await db.query('activity_sessions',
        where: 'day = ?', whereArgs: [day], orderBy: 'id DESC');
    return rows.map(ActivitySession.fromMap).toList();
  }

  Future<List<ActivitySession>> recent({int limit = 30}) async {
    final db = await AppDb.instance;
    final rows = await db.query('activity_sessions',
        orderBy: 'id DESC', limit: limit);
    return rows.map(ActivitySession.fromMap).toList();
  }

  /// إجمالي مسافة وسعرات اليوم من نشاط الـGPS.
  Future<({double distanceKm, int calories})> todayTotals(String day) async {
    final list = await forDay(day);
    var km = 0.0;
    var cal = 0;
    for (final s in list) {
      km += s.distanceKm;
      cal += s.calories;
    }
    return (distanceKm: km, calories: cal);
  }
}
