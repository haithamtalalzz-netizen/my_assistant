import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';

/// تتبّع المزاج — تسجيل يومى بمقياس ١..٥.
class MoodRepo {
  Future<List<MoodLog>> recent({int limit = 60}) async {
    final db = await AppDb.instance;
    final rows = await db.query('mood_logs',
        orderBy: 'day DESC, id DESC', limit: limit);
    return rows.map(MoodLog.fromMap).toList();
  }

  Future<MoodLog?> forDay(String day) async {
    final db = await AppDb.instance;
    final rows =
        await db.query('mood_logs', where: 'day = ?', whereArgs: [day], limit: 1);
    return rows.isEmpty ? null : MoodLog.fromMap(rows.first);
  }

  /// يسجّل/يحدّث مزاج اليوم (صف واحد لكل يوم).
  Future<void> setToday(int score, {String note = ''}) async {
    final db = await AppDb.instance;
    final day = dayKey(DateTime.now());
    final existing = await forDay(day);
    if (existing != null) {
      await db.update('mood_logs', {'score': score, 'note': note},
          where: 'id = ?', whereArgs: [existing.id]);
    } else {
      await db.insert('mood_logs', {
        'day': day,
        'score': score,
        'note': note,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('mood_logs', where: 'id = ?', whereArgs: [id]);
  }

  /// متوسط المزاج خلال آخر [days] يوم (null لو مفيش).
  Future<double?> average({int days = 30}) async {
    final db = await AppDb.instance;
    final from =
        dayKey(dateOnly(DateTime.now()).subtract(Duration(days: days - 1)));
    final r = await db.rawQuery(
        'SELECT AVG(score) a FROM mood_logs WHERE day >= ?', [from]);
    return (r.first['a'] as num?)?.toDouble();
  }

  Future<int> loggedDays() async {
    final db = await AppDb.instance;
    return Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM mood_logs')) ??
        0;
  }
}
