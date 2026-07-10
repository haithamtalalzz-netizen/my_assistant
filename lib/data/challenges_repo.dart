import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';

class ChallengesRepo {
  Future<int> add(Challenge c) async {
    final db = await AppDb.instance;
    return db.insert('challenges', c.toMap());
  }

  Future<void> delete(int id) async {
    final db = await AppDb.instance;
    await db.delete('challenge_logs', where: 'challenge_id = ?', whereArgs: [id]);
    await db.delete('challenges', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Challenge>> all() async {
    final db = await AppDb.instance;
    final rows = await db.query('challenges', orderBy: 'id DESC');
    return rows.map(Challenge.fromMap).toList();
  }

  /// عدد الأيام اللي اتعلّمت في التحدي.
  Future<int> doneCount(int challengeId) async {
    final db = await AppDb.instance;
    final rows = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM challenge_logs WHERE challenge_id = ?',
        [challengeId]);
    return (rows.first['c'] as num).toInt();
  }

  Future<bool> isDoneOn(int challengeId, String day) async {
    final db = await AppDb.instance;
    final rows = await db.query('challenge_logs',
        where: 'challenge_id = ? AND day = ?', whereArgs: [challengeId, day]);
    return rows.isNotEmpty;
  }

  Future<void> setDone(int challengeId, String day, bool done) async {
    final db = await AppDb.instance;
    if (done) {
      await db.insert('challenge_logs',
          {'challenge_id': challengeId, 'day': day},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    } else {
      await db.delete('challenge_logs',
          where: 'challenge_id = ? AND day = ?', whereArgs: [challengeId, day]);
    }
  }

  String todayKey() => dayKey(DateTime.now());
}
