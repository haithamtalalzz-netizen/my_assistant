import 'package:sqflite/sqflite.dart';

import '../core/ar.dart';
import '../core/db.dart';
import '../models/models.dart';
import 'appointments_repo.dart';

/// مفتاح الأسبوع = يوم الجمعة الأحدث (النهارده لو النهارده جمعة).
String currentWeekKey(DateTime now) {
  final diff = (now.weekday - DateTime.friday) % 7;
  return dayKey(dateOnly(now).subtract(Duration(days: diff)));
}

/// إحصائيات آخر ٧ أيام — لخطوة "مراجعة الأسبوع".
class WeekStats {
  final int apptsDone;
  final int apptsMissed;
  final int habitsDone;
  final int habitsPossible;
  final double totalSpent;
  final double? avgSleep;
  final double avgWater;
  final List<Appointment> chronicPostponed;

  const WeekStats({
    required this.apptsDone,
    required this.apptsMissed,
    required this.habitsDone,
    required this.habitsPossible,
    required this.totalSpent,
    required this.avgSleep,
    required this.avgWater,
    required this.chronicPostponed,
  });

  int get habitPercent =>
      habitsPossible == 0 ? 0 : (habitsDone * 100 ~/ habitsPossible);
}

class WeeklyRepo {
  Future<WeeklyReview?> forWeek(String weekKey) async {
    final db = await AppDb.instance;
    final rows = await db
        .query('weekly_reviews', where: 'week_key = ?', whereArgs: [weekKey]);
    if (rows.isEmpty) return null;
    return WeeklyReview.fromMap(rows.first);
  }

  Future<void> save(WeeklyReview r) async {
    final db = await AppDb.instance;
    await db.insert('weekly_reviews', r.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<WeekStats> statsForLastWeek(DateTime now) async {
    final db = await AppDb.instance;
    final end = dateOnly(now);
    final start = end.subtract(const Duration(days: 6));
    final startKey = dayKey(start);
    final endKey = dayKey(end);
    // when_at بصيغة ISO فالمقارنة النصية مع اليوم التالي بتغطي اليوم كله.
    final endExclusive = dayKey(end.add(const Duration(days: 1)));

    final doneRow = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM appointments '
        'WHERE done = 1 AND when_at >= ? AND when_at < ?',
        [startKey, endExclusive]);
    final missedRow = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM appointments '
        'WHERE done = 0 AND when_at >= ? AND when_at < ?',
        [startKey, dayKey(end)]);

    final habitsCountRow = await db
        .rawQuery('SELECT COUNT(*) AS c FROM habits WHERE archived = 0');
    final habitsDoneRow = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM habit_logs WHERE day >= ? AND day <= ?',
        [startKey, endKey]);

    final spentRow = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) AS total FROM expenses '
        'WHERE day >= ? AND day <= ?',
        [startKey, endKey]);
    final sleepRow = await db.rawQuery(
        'SELECT AVG(hours) AS avg FROM sleep_logs WHERE day >= ? AND day <= ?',
        [startKey, endKey]);
    final waterRow = await db.rawQuery(
        'SELECT AVG(glasses) AS avg FROM water_logs WHERE day >= ? AND day <= ?',
        [startKey, endKey]);

    final chronic = await AppointmentsRepo().chronicallyPostponed();

    return WeekStats(
      apptsDone: doneRow.first['c'] as int,
      apptsMissed: missedRow.first['c'] as int,
      habitsDone: habitsDoneRow.first['c'] as int,
      habitsPossible: (habitsCountRow.first['c'] as int) * 7,
      totalSpent: (spentRow.first['total'] as num).toDouble(),
      avgSleep: (sleepRow.first['avg'] as num?)?.toDouble(),
      avgWater: (waterRow.first['avg'] as num?)?.toDouble() ?? 0,
      chronicPostponed: chronic,
    );
  }
}
